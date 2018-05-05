ScriptReplacementsModule = ScriptReplacementsModule or class(ModuleBase)
ScriptReplacementsModule.type_name = "ScriptMods"

function ScriptReplacementsModule:post_init()
	self.ScriptDirectory = self._config.directory and Path:Combine(self._mod.ModPath, self._config.directory) or self._mod.ModPath
    for _, v in ipairs(self._config) do
        if v._meta == "mod" then
            local options = v.options or {} 
            options = table.merge(options, v)

            local clbk = options.use_clbk or options.clbk
            local use_clbk
            if clbk then
                use_clbk = self._mod:StringToCallback(options.use_clbk)
            end            
            
            local target = options.target_file or options.target_path
            local ext = options.target_type or options.target_ext
            local opt = {mode = options.merge_mode, use_clbk = use_clbk}
            local file = options.file or options.replacement
            if file then
                local file = Path:Combine(self.ScriptDirectory, file)
                local file_type = options.type or options.replacement_type
                FileManager:ScriptReplaceFile(ext, target, file, table.merge(opt, {type = file_type}))
            elseif v.tbl then
                FileManager:ScriptReplace(ext, target, options.tbl, opt)
            end
        end
    end
end

BeardLib:RegisterModule(ScriptReplacementsModule.type_name, ScriptReplacementsModule)