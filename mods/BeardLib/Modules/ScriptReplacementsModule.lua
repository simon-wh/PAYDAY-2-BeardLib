ScriptReplacementsModule = ScriptReplacementsModule or class(ModuleBase)

--Need a better name for this
ScriptReplacementsModule.type_name = "ScriptReplacementsModule"

function ScriptReplacementsModule:init(core_mod, config)
    self.super.init(self, core_mod, config)

    self.ScriptDirectory = self._config.directory and self._mod.ModPath .. self._config.directory or self._mod.ModPath

    if not string.ends(self.ScriptDirectory, "/") then
        self.ScriptDirectory = self.ScriptDirectory .. "/"
    end

    for _, tbl in ipairs(self._config) do
        if tbl._meta == "repl" then
            log(tbl.file)
            BeardLib:ReplaceScriptData(self.ScriptDirectory .. tbl.file, tbl.type, tbl.target_file, tbl.target_type, tbl.add, tbl.merge_mode)
        end
    end
end
