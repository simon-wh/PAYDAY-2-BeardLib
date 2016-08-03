HooksModule = HooksModule or class(ModuleBase)

HooksModule.type_name = "Hooks"

function HooksModule:init(core_mod, config)
    if not self.super.init(self, core_mod, config) then
        return false
    end

    self:Load()

    return true
end

function HooksModule:Load()
    local path = BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.directory)
    for _, hook in ipairs(self._config) do
        if hook._meta == "hook" then
            local dest_tbl = hook.type == "pre" and _prehooks or _posthooks
            local hook_file = BeardLib.Utils.Path:Combine(path, hook.file)
            local use_clbk = hook.use_clbk and self._mod:StringToCallback(hook.use_clbk) or nil
            if io.file_is_readable(hook_file) and (not use_clbk or use_clbk()) then
                local req_script = hook.source_file:lower()

                dest_tbl[req_script] = dest_tbl[req_script] or {}
                table.insert(dest_tbl[req_script], {
                    mod_path = path,
                    script = hook_file
                })
            else
                self:log("[ERROR] Hook file not readable by the lua state! File: %s", hook_file)
            end
        end
    end
end

BeardLib:RegisterModule(HooksModule.type_name, HooksModule)
