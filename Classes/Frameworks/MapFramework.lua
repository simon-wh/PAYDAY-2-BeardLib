MapFramework = MapFramework or BeardLib:Class(FrameworkBase)
MapFramework._ignore_folders = {backups = true, prefabs = true}
MapFramework._directory = BeardLib.config.maps_dir
MapFramework.type_name = "Map"

function MapFramework:init()
    -- Deprecated, try not to use.
    if self.type_name == MapFramework.type_name then
        BeardLib.Frameworks.map = self
        BeardLib.managers.MapFramework = self
    end

    MapFramework.super.init(self)
end

---@deprecated
---Use BeardLib.Utils:GetMapByJobId instead
function MapFramework:GetMapByJobId(job_id)
    for _, map in pairs(self._loaded_mods) do
        if map._modules then
            for _, module in pairs(map._modules) do
                if module.type_name == "narrative" and module._config and module._config.id == job_id then
                    return map
                end
            end
        end
    end
    return nil
end