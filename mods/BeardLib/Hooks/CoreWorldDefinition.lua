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
    if self._custom_loaded_packages then
        if not BeardLibEditor then
            for _, pck in pairs(self._custom_loaded_packages) do
                self:_unload_package(pck)
            end
        end
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
