getmetatable(PackageManager)._script_data = getmetatable(PackageManager)._script_data or getmetatable(PackageManager).script_data

getmetatable(PackageManager).script_data = function(PackManager, extension, filepath, ...)
	local data, arg1, arg2, arg3, arg4
    
	--if (BeardLib and BeardLib.ScriptExceptions and not BeardLib.ScriptExceptions[filepath:key()]) or not BeardLib or not (BeardLib and BeardLib.ScriptExceptions) then
	if BeardLib:ShouldGetScriptData(filepath, extension) then	
        data, arg1, arg2, arg3, arg4 = (PackManager:_script_data(extension, filepath, ...))
	end
    
    data = BeardLib:ProcessScriptData(PackManager, filepath, extension, data)
    
	return data, arg1, arg2, arg3, arg4
end