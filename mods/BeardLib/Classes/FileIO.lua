FileIO = FileIO or class()
function FileIO:Open(path, flags)
	if SystemFS then
		return SystemFS:open(path, flags)
	else
		return io.open(path, flags)
	end
end

function FileIO:WriteTo(path, data, flags)
	local dir = BeardLib.Utils.Path:GetDirectory(path)
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
        new_data = ScriptSerializer:from_binary(data)
    end
    return clean and BeardLib.Utils:CleanCustomXmlTable(new_data) or new_data
end

function FileIO:ConvertToScriptData(data, typ) 
	local new_data
    if typ == "json" then
        new_data = json.custom_encode(data, true)
    elseif typ == "custom_xml" then
        new_data = ScriptSerializer:to_custom_xml(data)
    elseif typ == "generic_xml" then
        new_data = ScriptSerializer:to_generic_xml(data)
    elseif typ == "binary" then
        new_data = ScriptSerializer:to_binary(data)
    end
    return new_data
end

function FileIO:ReadScriptDataFrom(path, typ) 
	local read = self:ReadFrom(path, typ == "binary" and "rb")
	if read then
		return self:ConvertScriptData(read, typ)
	end
    return false
end

function FileIO:WriteScriptDataTo(path, data, typ)
	return self:WriteTo(path, self:ConvertToScriptData(data, typ), typ == "binary" and "wb")
end

function FileIO:Exists(path) 
	if SystemFS then
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
	local dir = BeardLib.Utils.Path:GetDirectory(to_path)
	if not self:Exists(dir) then
		self:MakeDir(dir)
	end
	if SystemFS then
		SystemFS:copy_file(path, dir)
	else
		os.execute(string.format("copy \"%s\" \"%s\" /e /i /h /y /c", path, to_path))
	end
end

function FileIO:CopyTo(path, to_path) 
	os.execute(string.format("xcopy \"%s\" \"%s\" /e /i /h /y /c", path, to_path))
end

function FileIO:MoveFileTo(path, to_path)
	self:CopyFileTo(path, to_path)
	self:Delete(path)
end

function FileIO:MoveTo(path, to_path)
	self:CopyTo(path, to_path)
	self:Delete(path)
end

function FileIO:Delete(path) 
	if SystemFS then
		SystemFS:delete_file(path)
	else
		os.execute("rm -r " .. path)
	end
end

function FileIO:MakeDir(path) 
    if SystemFS then
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

function FileIO:GetFiles(path) --Same but having the idea that we use one class for all 
	return file.GetFiles(path)
end

function FileIO:GetFolders(path)
	return file.GetDirectories(path)
end