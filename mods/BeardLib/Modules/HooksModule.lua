HooksModule = HooksModule or class(ModuleBase)
HooksModule.type_name = "Hooks"

function HooksModule:init(core_mod, config)
    if not HooksModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()

    return true
end

function HooksModule:Load(config, prev_dir)
    config = config or self._config
	local dir = self:GetPath(config.directory, prev_dir)
	
    for _, hook in ipairs(config) do
        if hook._meta == "hook" then
            ModManager:RegisterHook(hook.source_file, dir, hook.file, hook.type, self)
        elseif hook._meta == "hooks" then
            self:Load(hook, dir)
        end
    end
end

BeardLib:RegisterModule(HooksModule.type_name, HooksModule)