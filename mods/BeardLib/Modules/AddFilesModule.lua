AddFilesModule = AddFilesModule or class(BasicModuleBase)
AddFilesModule.type_name = "AddFiles"

function AddFilesModule:Load()
    local use_clbk = self._config.use_clbk and self._mod:StringToCallback(self._config.use_clbk) or nil
    if use_clbk and not use_clbk() then
        return
    end
    
    local directory = self._config.full_directory or Path:Combine(self._mod.ModPath, self._config.directory)
    CustomPackageManager:LoadPackageConfig(directory, self._config)
end

function AddFilesModule:Unload()
    CustomPackageManager:UnloadPackageConfig(self._config)
end

BeardLib:RegisterModule(AddFilesModule.type_name, AddFilesModule)