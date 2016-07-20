core:module("CoreWorldDefinition")
WorldDefinition = WorldDefinition or CoreWorldDefinition.WorldDefinition

local WorldDefinition_load_world_package = WorldDefinition._load_world_package
function WorldDefinition:_load_world_package()
    local level_tweak = _G.tweak_data.levels[Global.level_data.level_id]
    self._has_package = not not level_tweak.package
    if level_tweak.custom_packages then
        self._custom_loaded_packages = {}
        for _, package in pairs(level_tweak.custom_packages) do
            if  PackageManager:package_exists(package) and not PackageManager:loaded(package) then
        		PackageManager:load(package)
                log("Loaded package: "..package)
        		table.insert(self._custom_loaded_packages, package)
        	end
        end
        if not self._has_package then
            return
        end
    end
    WorldDefinition_load_world_package(self)
end

local WorldDefinitionunload_packages = WorldDefinition.unload_packages
function WorldDefinition:unload_packages()
    if Global.level_data._add then
        Global.level_data._add:Unload()
        Global.level_data._add = nil
    end
    if self._custom_loaded_packages then
        --if not Global.editor_mode then
            for _, pck in pairs(self._custom_loaded_packages) do
                self:_unload_package(pck)
            end
        --end
        return
    end

    WorldDefinitionunload_packages(self)
end

local WorldDefinition_load_continent_init_package = WorldDefinition._load_continent_init_package
function WorldDefinition:_load_continent_init_package(path)
    if self._custom_loaded_packages and not self._has_package then
        return
    end

    WorldDefinition_load_continent_init_package(self, path)
end

local WorldDefinition_load_continent_package =  WorldDefinition._load_continent_package
function WorldDefinition:_load_continent_package(path)
    if self._custom_loaded_packages and not self._has_package then
        return
    end

    WorldDefinition_load_continent_package(self, path)
end

local WorldDefinition_create_environment = WorldDefinition._create_environment
function WorldDefinition:_create_environment(data, offset)

    local shape_data
    if data.dome_occ_shapes and data.dome_occ_shapes[1] and data.dome_occ_shapes[1].world_dir then
        shape_data = data.dome_occ_shapes[1]
        data.dome_occ_shapes = nil
    end

    WorldDefinition_create_environment(self, data, offset)

	if shape_data then
		local corner = shape_data.position
		local size = Vector3(shape_data.depth, shape_data.width, shape_data.height)
		local texture_name = shape_data.world_dir .. "cube_lights/" .. "dome_occlusion"
		if not DB:has(Idstring("texture"), Idstring(texture_name)) then
			Application:error("Dome occlusion texture doesn't exists, probably needs to be generated", texture_name)
		else
			managers.environment_controller:set_dome_occ_params(corner, size, texture_name)
		end
	end
end
