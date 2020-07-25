HooksModule = HooksModule or BeardLib:ModuleClass("Hooks", ModuleBase)

local PRE = "pre"
local POST = "post"
function HooksModule:Load(config, prev_dir)
	config = config or self._config
    local dir = self:GetPath(config.directory, prev_dir)
    config.pre = NotNil(config.pre, config.type == PRE)
    for _, hook in ipairs(config) do
        if hook._meta == "hook" then
            hook.pre = NotNil(hook.pre, config.pre, hook.type == PRE)
            hook.file = hook.file or config.file
            type = type or hook.type or (hook.pre and PRE) or (hook.post and POST)
            self._mod:RegisterHook(hook.source_file, dir and Path:Combine(dir, hook.file) or hook.file, hook.pre == true)
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