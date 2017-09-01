HooksModule = HooksModule or class(ModuleBase)

HooksModule.type_name = "Hooks"

function HooksModule:init(core_mod, config)
    if not HooksModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()

    return true
end

function HooksModule:Load()
    local path = self:GetPath()
    for _, hook in ipairs(self._config) do
        if hook._meta == "hook" then
            ModManager:RegisterHook(hook.source_file, path, hook.file, hook.type, self)
        end
    end
end

function HooksModule:GetPath()
    return BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.directory, "")
end

BeardLib:RegisterModule(HooksModule.type_name, HooksModule)
