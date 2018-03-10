HooksModule = HooksModule or class(ModuleBase)
HooksModule.type_name = "Hooks"

function HooksModule:init(core_mod, config)
    if not HooksModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()

    return true
end

function HooksModule:Load(config)
    local path = self:GetPath(config and config.directory or nil)
    config = config or self._config
    for _, hook in ipairs(config) do
        if hook._meta == "hook" then
            ModManager:RegisterHook(hook.source_file, path, hook.file, hook.type, self)
        elseif hook._meta == "hooks" then
            self:Load(hook)
        end
    end
end

function HooksModule:GetPath(additional)
    return BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.directory, additional or "")
end

BeardLib:RegisterModule(HooksModule.type_name, HooksModule)