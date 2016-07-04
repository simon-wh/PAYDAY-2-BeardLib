ScriptReplacementsModule = ScriptReplacementsModule or class(ModuleBase)

--Need a better name for this
ScriptReplacementsModule.type_name = "ScriptReplacementsModule"

function ScriptReplacementsModule:init(core_mod, config)
    self.super.init(self, core_mod, config)

    self.ScriptDirectory = self._config.directory and self._mod.ModPath .. self._config.directory or self._mod.ModPath
end

function ScriptReplacementsModule:post_init()
    for _, tbl in ipairs(self._config) do
        if tbl._meta == "mod" then
            local options = tbl.options
            if options and options.use_clbk then
                options.use_clbk = self._mod:StringToCallback(tbl.use_clbk)
            end

            BeardLib:ReplaceScriptData(BeardLib.Utils.Path.Combine(self.ScriptDirectory, tbl.file), tbl.type, tbl.target_file, tbl.target_type, options)
        end
    end
end
