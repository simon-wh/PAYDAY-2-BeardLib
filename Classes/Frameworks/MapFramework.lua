MapFramework = MapFramework or BeardLib:Class(FrameworkBase)
MapFramework._loaded_instances = {}
MapFramework._ignore_detection_errors = false
MapFramework._ignore_folders = {backups = true, prefabs = true}
MapFramework._directory = BeardLib.config.maps_dir
MapFramework.type_name = "Map"
MapFramework.menu_color = Color(0.1, 0.6, 0.1)

function MapFramework:init()
    -- Deprecated, try not to use.
    if self.type_name == MapFramework.type_name then
        BeardLib.Frameworks.map = self
        BeardLib.managers.MapFramework = self
    end

    MapFramework.super.init(self)
end

function MapFramework:RegisterHooks(...)
	self:AddCustomContact()
    MapFramework.super.RegisterHooks(self, ...)
    Hooks:PostHook(NarrativeTweakData, "init", "MapFrameworkAddFinalNarrativeData", SimpleClbk(NarrativeTweakData.set_job_wrappers))
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