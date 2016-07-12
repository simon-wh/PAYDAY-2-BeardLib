AddFramework = AddFramework or class(FrameworkBase)
AddFramework._ignore_detection_errors = true
function AddFramework:init()
    self._directory = BeardLib.definitions.mod_override
    self.super.init(self)
end

function AddFramework:RegisterHooks()
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
