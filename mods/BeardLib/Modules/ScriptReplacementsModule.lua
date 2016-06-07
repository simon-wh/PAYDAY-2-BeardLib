ScriptReplacementsModule = ScriptReplacementsModule or class(ModuleBase)

--Need a better name for this
ScriptReplacementsModule.type_name = "ScriptReplacementsModule"

function ScriptReplacementsModule:init(core_mod, config)
    self.super.init(self, core_mod, config)

    self.ScriptDirectory = self._config.directory and self._mod.ModPath .. self._config.directory or self._mod.ModPath
end

function ScriptReplacementsModule:post_init()
    for _, tbl in ipairs(self._config) do
        local use_clbk = tbl.use_callback and self._mod:StringToCallback(tbl.use_callback)
        if tbl._meta == "repl" then
            BeardLib:ReplaceScriptData(BeardLib.Utils.Path.Combine(self.ScriptDirectory, tbl.file), tbl.type, tbl.target_file, tbl.target_type, {add = tbl.add, merge_mode = tbl.merge_mode, use_clbk = use_clbk})
        end
    end
end
