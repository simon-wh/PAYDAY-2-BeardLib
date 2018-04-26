HooksModule = HooksModule or class(BasicModuleBase)
HooksModule.type_name = "Hooks"

function HooksModule:Load(config, prev_dir)
	config = config or self._config
	local dir = self:GetPath(config.directory, prev_dir)
    for _, hook in ipairs(config) do
        if hook._meta == "hook" then
            self._mod:RegisterHook(hook.source_file, dir and Path:Combine(dir, hook.file) or hook.file, hook.type)
        elseif hook._meta == "hooks" then
            self:Load(hook, dir)
        end
    end
end

function HooksModule:GetPath(directory, prev_dir)
	if prev_dir then
		return Path:CombineDir(prev_dir, directory)
	else
		return directory
	end
end

BeardLib:RegisterModule(HooksModule.type_name, HooksModule)