
--Unneeded memory usage, should only be used for dedicated editor
--[[_G.og_idstring = Idstring

function Idstring(str)
    if not str then
        str = ""
    end

    local ids = og_idstring(str)
    ids.s = function(this)
        return str
    end

    return ids
end]]--

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

getmetatable(PackageManager).script_data = function(self, extension, filepath, name_mt)
	local data = {}

    if BeardLib:ShouldGetScriptData(filepath, extension) then
        if name_mt ~= nil then
            data = self:_script_data(extension, filepath, name_mt)
        else
            data = self:_script_data(extension, filepath)
        end
    end

	return BeardLib:ProcessScriptData(self, filepath, extension, data)
end

getmetatable(DB)._has = getmetatable(DB)._has or getmetatable(DB).has

getmetatable(DB).has = function(self, extension, filepath)

    if BeardLib._replace_script_data[filepath:key()] and BeardLib._replace_script_data[filepath:key()][extension:key()] then
        return true
    end

    return self:_has(extension, filepath)
end
