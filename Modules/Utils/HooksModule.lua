HooksModule = HooksModule or BeardLib:ModuleClass("Hooks", ModuleBase)

local PRE = "pre"
local POST = "post"
function HooksModule:Load(config, prev_dir)
	config = config or self._config
    local dir = self:GetPath(config.directory, prev_dir)
    config.pre = NotNil(config.pre, config.type == PRE)
    for _, hook in ipairs(config) do
        if hook._meta == "hook" or hook._meta == POST or hook._meta == PRE then
            local file = hook.file or config.file or hook.script_path or config.script_path
            local pre = hook.type == PRE or config.type == PRE or hook.pre or hook._meta == PRE

            self._mod:RegisterHook(hook.source_file or hook.hook_id, dir and Path:Combine(dir, file) or file, pre)
        elseif hook._meta == "hooks" or hook._meta == "group" then
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