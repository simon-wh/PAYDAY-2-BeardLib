ScriptReplacementsModule = ScriptReplacementsModule or class(ModuleBase)

--Need a better name for this
ScriptReplacementsModule.type_name = "ScriptMods"

function ScriptReplacementsModule:init(core_mod, config)
    if not ScriptReplacementsModule.super.init(self, core_mod, config) then
        return false
    end

    self.ScriptDirectory = self._config.directory and BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.directory) or self._mod.ModPath

    return true
end

function ScriptReplacementsModule:post_init()
    for _, v in ipairs(self._config) do
        if v._meta == "mod" then
            local options = v.options or v
            local clbk = options.use_clbk or options.clbk
            local use_clbk
            if clbk then
                use_clbk = self._mod:StringToCallback(options.use_clbk)
            end            
            local target = options.target_file or options.target_path
            local ext = options.target_type or options.target_ext
            local opt = {mode = options.merge_mode, use_clbk = use_clbk}
            if v.file then
                local file = BeardLib.Utils.Path:Combine(self.ScriptDirectory, v.file or v.replacement)
                local file_type = options.type or options.replacement_type
                FileManager:ScriptReplaceFile(ext, target, file, table.merge(opt, {type = file_type}))
            elseif v.tbl then
                FileManager:ScriptReplace(ext, target, v.tbl, opt)
            end
        end
    end
end

BeardLib:RegisterModule(ScriptReplacementsModule.type_name, ScriptReplacementsModule)