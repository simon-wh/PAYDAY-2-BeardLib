
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
local ids_unit = Idstring("unit")

getmetatable(World)._spawn_unit = getmetatable(World)._spawn_unit or getmetatable(World).spawn_unit

getmetatable(World).spawn_unit = function(self, unit_name, pos, rot)
	if Global.added_units[tostring(unit_name:key())] then
		if not managers.dyn_resource:has_resource(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
			managers.dyn_resource:load(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE)
			while not managers.dyn_resource:is_resource_ready(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE) do end
		end
	end

	return self:_spawn_unit(unit_name, pos, rot)
end



getmetatable(PackageManager)._script_data = getmetatable(PackageManager)._script_data or getmetatable(PackageManager).script_data

getmetatable(PackageManager).script_data = function(self, ext, path, name_mt)
	local data = {}

    if DB:_has(ext, path) then
        if name_mt ~= nil then
            data = self:_script_data(ext, path, name_mt)
        else
            data = self:_script_data(ext, path)
        end
    end

	return BeardLib:ProcessScriptData(self, path, ext, data)
end

getmetatable(DB)._has = getmetatable(DB)._has or getmetatable(DB).has

getmetatable(DB).has = function(self, ext, path)

    if BeardLib._replace_script_data[ext:key()] and BeardLib._replace_script_data[ext:key()][path:key()] and #BeardLib._replace_script_data[ext:key()][path:key()] > 0 then
        return true
    end

    return self:_has(ext, path)
end
