ScriptReplacementsModule = ScriptReplacementsModule or class(ModuleBase)

--Need a better name for this
ScriptReplacementsModule.type_name = "ScriptMods"

function ScriptReplacementsModule:init(core_mod, config)
    if not self.super.init(self, core_mod, config) then
        return false
    end

    self.ScriptDirectory = self._config.directory and self._mod.ModPath .. self._config.directory or self._mod.ModPath

    return true
end

function ScriptReplacementsModule:post_init()
    for _, tbl in ipairs(self._config) do
        if tbl._meta == "mod" then
            local options = tbl.options
            if options and options.use_clbk then
                options.use_clbk = self._mod:StringToCallback(options.use_clbk)
            end

            BeardLib:ReplaceScriptData(BeardLib.Utils.Path:Combine(self.ScriptDirectory, tbl.file or tbl.replacement), tbl.type or tbl.replacement_type, tbl.target_file or tbl.target_path, tbl.target_type or tbl.target_ext, options)
        end
    end
end

BeardLib:RegisterModule(ScriptReplacementsModule.type_name, ScriptReplacementsModule)
