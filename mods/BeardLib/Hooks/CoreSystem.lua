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
local key_unit = ids_unit:key()

overwrite_meta_function(World, "spawn_unit", function(self, unit_name, ...)
	--log("Spawned unit: " .. tostring(unit_name:key()))
	if (unit_name and Global.fm.added_files[key_unit] and Global.fm.added_files[key_unit][unit_name:key()]) or unit_name:key() == "0d8ea9bdcebaaf64" then
		FileManager:LoadAsset(ids_unit, unit_name)
		--while not managers.dyn_resource:is_resource_ready(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE) do end
	end
	--STOP REPORTING THIS AS A BEARLID ISSUE PLEASE
	return self:_spawn_unit(unit_name, ...)
end)

overwrite_meta_function(PackageManager, "unit_data", function(self, unit_name, ...)
	if Global.fm.added_files[key_unit] and Global.fm.added_files[key_unit][tostring(unit_name:key())] then
		FileManager:LoadAsset(ids_unit, unit_name)
		--while not managers.dyn_resource:is_resource_ready(ids_unit, unit_name, managers.dyn_resource.DYN_RESOURCES_PACKAGE) do end
	end
	return self:_unit_data(unit_name, ...)
end)

overwrite_meta_function(PackageManager, "script_data", function(self, ext, path, name_mt)
	--[[local data = {}

    if DB:_has(ext, path) then
        if name_mt ~= nil then
            data = self:_script_data(ext, path, name_mt)
        else
            data = self:_script_data(ext, path)
        end
    end]]

	return FileManager:Process(ext, path, name_mt)
end)

overwrite_meta_function(DB, "has", function(self, ext, path)
    if FileManager:HasScriptMod(ext, path) then
        return true
    end

    return self:_has(ext, path)
end)

overwrite_meta_function(PackageManager, "load", function(self, pck, ...)
	if not pck then
		return true
	end

	log("Load package: " .. tostring(pck))
	if CustomPackageManager:LoadPackage(pck) then
		return
	end

	self:_load(pck, ...)
end)

overwrite_meta_function(PackageManager, "unload", function(self, pck)
	if not pck then
		return
	end

	if CustomPackageManager:HasPackage(pck) then
		CustomPackageManager:UnLoadPackage(pck)
		return
	end

	self:_unload(pck)
end)

overwrite_meta_function(PackageManager, "loaded", function(self, pck)
	if not pck then
		return false
	end

	if CustomPackageManager:HasPackage(pck) then
		return CustomPackageManager:PackageLoaded(pck)
	end

	return self:_loaded(pck)
end)

overwrite_meta_function(PackageManager, "package_exists", function(self, pck)
	if not pck then
		return false
	end

	if CustomPackageManager:HasPackage(pck) then
		return true
	end

	return self:_package_exists(pck)
end)

--[[function print(...)
	log(string.format(...))
end]]--
