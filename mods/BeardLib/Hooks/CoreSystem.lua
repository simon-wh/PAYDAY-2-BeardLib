_G.og_idstring = Idstring

function Idstring(str)
    if not str then
        str = ""
    end

    local ids = og_idstring(str)
    ids.s = function(this)
        return str
    end
    
    return ids
end

--[[function print(str, ...)
    local tbl = {...}
    
    log(str)
    
    for i, val in pairs(tbl) do
        log(tostring(val))
    end
end]]--

--[[getmetatable(PackageManager)._unit_data = getmetatable(PackageManager)._unit_data or getmetatable(PackageManager).unit_data

getmetatable(PackageManager).unit_data = function(PackManager, ...)
    log("unit data called")
    local data = PackManager:_unit_data(...)
    SaveTable(data.__index, "UnitDataIndex.txt")
    return data
end]]--

getmetatable(PackageManager)._script_data = getmetatable(PackageManager)._script_data or getmetatable(PackageManager).script_data

getmetatable(PackageManager).script_data = function(PackManager, extension, filepath, name_mt)
	local data = {}
    
	if BeardLib:ShouldGetScriptData(filepath, extension) then
        if name_mt ~= nil then
            data = PackManager:_script_data(extension, filepath, name_mt)
        else
            data = PackManager:_script_data(extension, filepath)
        end
	end
    
    data = BeardLib:ProcessScriptData(PackManager, filepath, extension, data)
    
	return data
end