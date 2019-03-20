FileIO = FileIO or {}
function FileIO:Open(path, flags)
	if SystemFS and SystemFS.open then
		return SystemFS:open(path, flags)
	else
		return io.open(path, flags)
	end
end

function FileIO:WriteTo(path, data, flags)
	local dir = Path:GetDirectory(path)
	if not self:Exists(dir) then
		self:MakeDir(dir)
	end
 	local file = self:Open(path, flags or "w")
 	if file then
	 	file:write(data)
	 	file:close()
	 	return true
	else
		log("[FileIO][ERROR] Failed opening file at path " .. tostring(path))
		return false
	end
end

function FileIO:ReadFrom(path, flags, method)
 	local file = self:Open(path, flags or "r")
 	if file then
 		local data = file:read(method or "*all")
	 	file:close()
	 	return data
	else
		log("[FileIO][ERROR] Failed opening file at path " .. tostring(path))
		return false
	end
end

function FileIO:ReadConfig(path, tbl)
	local file = self:Open(path, "r")
	if file then
		local config = ScriptSerializer:from_custom_xml(file:read("*all"))
		for i, var in pairs(config) do
			if type(var) == "string" then
				config[i] = string.gsub(var, "%$(%w+)%$", tbl or self)
			end
		end
		return config
	else
		log("[FileIO][ERROR] Config at %s doesn't exist!", tostring(path))
	end
end

function FileIO:ConvertScriptData(data, typ, clean) 
	local new_data
    if typ == "json" then
        new_data = json.custom_decode(data)
    elseif typ == "xml" then
        new_data = ScriptSerializer:from_xml(data)
    elseif typ == "custom_xml" then
        new_data = ScriptSerializer:from_custom_xml(data)
    elseif typ == "generic_xml" then
        new_data = ScriptSerializer:from_generic_xml(data)
    elseif typ == "binary" then
        if blt and blt.scriptdata then
            local info = blt.scriptdata.identify(data)
            local sys32bit = blt.blt_info().arch == "x86"

            -- If we're trying to load a 32-bit encoded file on a 64-bit encoded platform or vice-versa, convert it
            if info.is32bit ~= sys32bit then
                data = blt.scriptdata.recode(data, {
                    is32bit = sys32bit,
                })
            end
        end

        new_data = ScriptSerializer:from_binary(data)
    end
    return clean and BeardLib.Utils.XML:Clean(new_data) or new_data
end

function FileIO:ConvertToScriptData(data, typ, clean)
	data = clean and BeardLib.Utils.XML:Clean(data) or data
    if typ == "json" then
        return json.custom_encode(data, true)
    elseif typ == "custom_xml" then
        return ScriptSerializer:to_custom_xml(data)
    elseif typ == "generic_xml" then
        return ScriptSerializer:to_generic_xml(data)
    elseif typ == "binary" then
        return ScriptSerializer:to_binary(data)
    end
end

function FileIO:ReadScriptData(path, typ, clean) 
	local read = self:ReadFrom(path, typ == "binary" and "rb")
	if read then
		return self:ConvertScriptData(read, typ, clean)
	end
    return false
end

function FileIO:WriteScriptData(path, data, typ, clean)
	return self:WriteTo(path, self:ConvertToScriptData(data, typ, clean), typ == "binary" and "wb")
end

function FileIO:Exists(path)
	if not path then
		return false
	end
	if SystemFS and SystemFS.exists then
		return SystemFS:exists(path)
	else
		if self:Open(path, "r") or file.GetFiles(path) then
			return true
		else
			return false
		end
	end
end

function FileIO:CopyFileTo(path, to_path)
	local dir = Path:GetDirectory(to_path)
	if not self:Exists(dir) then
		self:MakeDir(dir)
	end
	if SystemFS and SystemFS.copy_file then
		SystemFS:copy_file(path, dir)
	else
		os.execute(string.format("copy \"%s\" \"%s\" /e /i /h /y /c", path, to_path))
	end
end

function FileIO:CopyTo(path, to_path) 
	os.execute(string.format("xcopy \"%s\" \"%s\" /e /i /h /y /c", path, to_path))
end

function FileIO:PrepareFilesForCopy(path, to_path)
	local files = {}
	local function PrepareCopy(p)
		local _, e = p:find(path, nil, true)
		local new_path = Path:Normalize(Path:Combine(to_path, p:sub(e + 1)))
	    for _, file in pairs(FileIO:GetFiles(p)) do
	        table.insert(files, {Path:Combine(p,file), Path:Combine(new_path, file)})
	    end
	    for _, folder in pairs(FileIO:GetFolders(p)) do
	        PrepareCopy(Path:Normalize(Path:Combine(p, folder)))
	        FileIO:MakeDir(Path:Combine(new_path, folder))
	    end
	end
	PrepareCopy(path)
	return files
end

function FileIO:CopyDirTo(path, to_path)
	for _, file in pairs(self:PrepareFilesForCopy(path, to_path)) do
		SystemFS:copy_file(file[1], file[2])
	end
end

function FileIO:CopyFilesToAsync(copy_data, callback)
	SystemFS:copy_files_async(copy_data, callback or function(success, message)
		if success then
			BeardLib:log("[FileIO] Done copying files")
		else
			BeardLib:log("[FileIO] Something went wrong when files")
		end
	end)	
end

function FileIO:CopyToAsync(path, to_path, callback)
	self:CopyFilesToAsync(self:PrepareFilesForCopy(path, to_path), callback or function(success, message)
		if success then
			BeardLib:log("[FileIO] Done copying directory %s to %s", path, to_path)
		else
			BeardLib:log("[FileIO] Something went wrong when copying directory %s to %s, \n %s", path, to_path, message)
		end
	end)
end

function FileIO:MoveTo(path, to_path)
	SystemFS:rename_file(path, to_path)
end

function FileIO:CanWriteTo(path)
	if SystemFS and SystemFS.can_write_to then
		return SystemFS:can_write_to(path)
	else
		return true --Assume it's writable in linux for now, feel free to push a pull if you know how to do it.
	end
end

function FileIO:Delete(path)
	if SystemFS and SystemFS.delete_file then
		SystemFS:delete_file(path)
	else
		error("[BeardLib] Cannot delete files or folders [SystemFS not available]")
	end
end

function FileIO:DeleteEmptyFolders(path, delete_current) 
	for _, folder in pairs(self:GetFolders(path)) do
		self:DeleteEmptyFolders(Path:Combine(path, folder), true)
	end
	if delete_current then
		if #self:GetFolders(path) == 0 and #self:GetFiles(path) == 0 then
			self:Delete(path)	
		end
	end
end

function FileIO:MakeDir(path) 
    if SystemFS and SystemFS.make_dir then
    	local p
    	for _, s in pairs(string.split(path, "/")) do
    		p = p and p .. "/" .. s  or s
    		if not self:Exists(p) then
    			SystemFS:make_dir(p)
    		end
    	end
    else
        os.execute(string.format("mkdir \"%s\"", path))
    end
end
--Changed to SystemFS because blt's one sometimes fucks up the strings.
function FileIO:GetFiles(path)
	if SystemFS and SystemFS.list then
		return SystemFS:list(path)
	else
		return file.GetFiles(path)
	end
end

function FileIO:GetFolders(path)
	if SystemFS and SystemFS.list then
		return SystemFS:list(path, true)
	elseif self:Exists(path) then
		return file.GetDirectories(path)
	else
		return {}
	end
end

function FileIO:ReadScriptDataFrom(...) return self:ReadScriptData(...) end
function FileIO:WriteScriptDataTo(...) return self:WriteScriptData(...) end


function FileIO:LoadLocalization(path, overwrite)
	-- Should we overwrite existing localization strings
	if overwrite == nil then
		overwrite = true
	end

	local file = io.open(path, "r")
	if file then
		local data = file:read("*all")
		file:close()
		local contents
		local passed = pcall(function()
			contents = json10.decode(data)
		end)
		if not passed then
			return false
		end
		LocalizationManager:add_localized_strings(contents, overwrite)
		return true
	end
end
