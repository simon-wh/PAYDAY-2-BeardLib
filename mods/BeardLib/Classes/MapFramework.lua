MapFramework = MapFramework or class(FrameworkBase)

function MapFramework:init()
    self._directory = BeardLib.config.maps_dir
    self._ignore_folders = {"backups", "prefabs"}
    self.super.init(self)
end

function MapFramework:RegisterHooks()
    self:AddCustomContact()
    for _, mod in pairs(self._loaded_mods) do
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