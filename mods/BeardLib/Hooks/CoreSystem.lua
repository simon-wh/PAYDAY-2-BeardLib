function overwrite_meta_function(tbl, func_name, new_func)
	local old_func_name = "_" .. func_name
	local meta_table = getmetatable(tbl)

	if not meta_table[func_name] then
		log(string.format("[ERROR] Function with name '%s' could not be found in the meta table!", func_name))
		return
	end

	meta_table[old_func_name] = meta_table[old_func_name] or meta_table[func_name]

	meta_table[func_name] = new_func
end

local ids_unit = Idstring("unit")

overwrite_meta_function(World, "spawn_unit", function(self, unit_name, ...)
	if unit_name and Global.added_units[tostring(unit_name:key())] then
		if not managers.dyn_resource:has_resource(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
			managers.dyn_resource:load(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE)
			while not managers.dyn_resource:is_resource_ready(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE) do end
		end
	end
	return self:_spawn_unit(unit_name, ...)
end)

overwrite_meta_function(PackageManager, "unit_data", function(self, unit_name, ...)
	if Global.added_units[tostring(unit_name:key())] then
		if not managers.dyn_resource:has_resource(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
			managers.dyn_resource:load(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE)
			while not managers.dyn_resource:is_resource_ready(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE) do end
		end
	end
	return self:_unit_data(unit_name, ...)
end)

overwrite_meta_function(PackageManager, "script_data", function(self, ext, path, name_mt)
	local data = {}

    if DB:_has(ext, path) then
        if name_mt ~= nil then
            data = self:_script_data(ext, path, name_mt)
        else
            data = self:_script_data(ext, path)
        end
    end

	return BeardLib:ProcessScriptData(self, path, ext, data)
end)

overwrite_meta_function(DB, "has", function(self, ext, path)
    if BeardLib._replace_script_data[ext:key()] and BeardLib._replace_script_data[ext:key()][path:key()] and #BeardLib._replace_script_data[ext:key()][path:key()] > 0 then
        return true
    end

    return self:_has(ext, path)
end)

overwrite_meta_function(PackageManager, "load", function(self, pck, ...)
	if not pck then
		return true
	end

	if BeardLib and BeardLib._custom_packages[pck:key()] then
		local cpck = BeardLib._custom_packages[pck:key()]
		if not cpck:loaded() then
			cpck:Load()
		end
		return true
	end

	self:_load(pck, ...)
end)

overwrite_meta_function(PackageManager, "unload", function(self, pck)
	if not pck then
		return
	end

	if BeardLib and BeardLib._custom_packages[pck:key()] then
		local cpck = BeardLib._custom_packages[pck:key()]
		if cpck:loaded() then
			cpck:Unload()
		end
		return
	end

	self:_unload(pck)
end)

overwrite_meta_function(PackageManager, "loaded", function(self, pck)
	if not pck then
		return false
	end

	if BeardLib and BeardLib._custom_packages[pck:key()] then
		return BeardLib._custom_packages[pck:key()]:loaded()
	end

	return self:_loaded(pck)
end)

overwrite_meta_function(PackageManager, "package_exists", function(self, pck)
	if not pck then
		return false
	end

	if BeardLib and BeardLib._custom_packages[pck:key()] then
		return true
	end

	return self:_package_exists(pck)
end)

--[[function print(...)
	log(string.format(...))
end]]--
