HooksModule = HooksModule or class(ModuleBase)

HooksModule.type_name = "Hooks"

function HooksModule:init(core_mod, config)
    self.super.init(self, core_mod, config)

    self:Load()
end

function HooksModule:Load()
    local path = BeardLib.Utils.Path.Combine(self._mod.ModPath, self._config.directory)
    for _, hook in ipairs(self._config) do
        if hook._meta == "hook" then
            local dest_tbl = hook.type == "pre" and _prehooks or _posthooks
            local hook_file = BeardLib.Utils.Path.Combine(path, hook.file)
            if io.file_is_readable(hook_file) then
                local req_script = hook.source_file:lower()

                dest_tbl[req_script] = dest_tbl[req_script] or {}
                table.insert(dest_tbl[req_script], {
                    mod_path = path,
                    script = hook_file
                })
            else
                BeardLib:log("[ERROR] Hook file not readable by the lua state! File: %s", hook_file)
            end
        end
    end
end

BeardLib:RegisterModule(HooksModule.type_name, HooksModule)
