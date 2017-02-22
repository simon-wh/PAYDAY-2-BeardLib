FileIO = FileIO or class()
function FileIO:Open(path, flags)
	return io.open(path, flags)
end

function FileIO:WriteTo(path, data)
 	local file = self:Open(path, "w")
 	if file then
	 	file:write(data)
	 	file:close()
	else
		log("[FileIO][ERROR] Failed opening file at path " .. tostring(path))
	end
end

function FileIO:ReadFrom(path, method)
 	local file = self:Open(path, "r")
 	if file then
 		local data = file:read(method or "*all")
	 	file:close()
	 	return data
	else
		log("[FileIO][ERROR] Failed opening file at path " .. tostring(path))
	end
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

function FileIO:CopyTo(path, to_path) 
	os.execute(string.format("xcopy \"%s\" \"%s\" /e /i /h /y /c", path, to_path))
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
        SystemFS:make_dir(map_path)
	else
		os.execute("mkdir -p " .. path)
	end
end