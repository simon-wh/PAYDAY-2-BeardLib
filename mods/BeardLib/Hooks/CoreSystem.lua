--[[function print(str, ...)
    local tbl = {...}
    
    log(str)
    
    for i, val in pairs(tbl) do
        log(tostring(val))
    end
end]]--

getmetatable(PackageManager)._script_data = getmetatable(PackageManager)._script_data or getmetatable(PackageManager).script_data

getmetatable(PackageManager).script_data = function(PackManager, extension, filepath, ...)
	local data = {}
    local arg1, arg2, arg3, arg4
    
	if BeardLib:ShouldGetScriptData(filepath, extension) then	
        data, arg1, arg2, arg3, arg4 = (PackManager:_script_data(extension, filepath, ...))
	end
    
    data = BeardLib:ProcessScriptData(PackManager, filepath, extension, data)
    
	return data, arg1, arg2, arg3, arg4
end