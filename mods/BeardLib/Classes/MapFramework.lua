MapFramework = MapFramework or class(FrameworkBase)

function MapFramework:init()
    self._directory = BeardLib.config.maps_dir
    self.super.init(self)
end

function MapFramework:RegisterHooks()
    for _, mod in pairs(self._loaded_mods) do
        for _, module in pairs(mod._modules) do
            if module.RegisterHook then
                local success, err = pcall(function() module:RegisterHook() end)

                if not success then
                    BeardLib:log("[ERROR] An error occured on the hook registration of %s. Error:\n%s", module._name, tostring(err))
                end
            end
        end
    end
end

return MapFramework
