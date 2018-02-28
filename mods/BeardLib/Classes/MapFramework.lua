MapFramework = MapFramework or class(FrameworkBase)
MapFramework._loaded_instances = {}
MapFramework._ignore_folders = {"backups", "prefabs"}
MapFramework._directory = BeardLib.config.maps_dir

function MapFramework:RegisterHooks()
    self:AddCustomContact()
    table.sort(self._loaded_mods, function(a,b)
        return a.Priority < b.Priority
    end)
    for _, mod in pairs(self._loaded_mods) do
        if not mod._disabled and mod._modules then
            for _, module in pairs(mod._modules) do
                if module.RegisterHook and not module.Registered then
                    local success, err = pcall(function() module:RegisterHook() end)
                    module.Registered = true
                    if not success then
                        BeardLib:log("[ERROR] An error occured on the hook registration of %s. Error:\n%s", module._name, tostring(err))
                    end
                end
            end
        end
    end
end

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

function MapFramework:AddCustomContact()
    ContactModule:new(BeardLib, {
        id = "custom",
        name_id = "heist_contact_custom",
        description_id = "heist_contact_custom_description",
        package = "packages/contact_bain",
        assets_gui = "guis/mission_briefing/preload_contact_bain"
    }):RegisterHook()
end

return MapFramework