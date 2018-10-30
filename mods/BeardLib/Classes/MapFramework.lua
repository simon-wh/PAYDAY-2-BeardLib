MapFramework = MapFramework or class(FrameworkBase)
local Framework = MapFramework
Framework._loaded_instances = {}
Framework._ignore_detection_errors = false
Framework._ignore_folders = {"backups", "prefabs"}
Framework._directory = BeardLib.config.maps_dir
Framework.type_name = "map"
Framework.menu_color = Color(0.1, 0.6, 0.1)

function Framework:RegisterHooks(...)
	self:AddCustomContact()
	MapFramework.super.RegisterHooks(self, ...)
end

function Framework:GetMapByJobId(job_id)
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

function Framework:AddCustomContact()
    ContactModule:new(BeardLib, {
        id = "custom",
        name_id = "heist_contact_custom",
        description_id = "heist_contact_custom_description",
        package = "packages/contact_bain",
        assets_gui = "guis/mission_briefing/preload_contact_bain"
    }):RegisterHook()
end

return Framework