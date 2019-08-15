AddFilesModule = AddFilesModule or class(ModuleBase)
AddFilesModule.type_name = "AddFiles"

function AddFilesModule:Load()
    local directory = self._config.full_directory or Path:Combine(self._mod.ModPath, self._config.directory)
    self:LoadPackageConfig(directory, self._config)
end

function AddFilesModule:Unload()
    self:UnloadPackageConfig(self._config)
end

AddFilesModule.LoadPackageConfig = CustomPackageManager.LoadPackageConfig
AddFilesModule.UnloadPackageConfig = CustomPackageManager.UnloadPackageConfig
AddFilesModule.AddFileWithCheck = CustomPackageManager.AddFileWithCheck

BeardLib:RegisterModule(AddFilesModule.type_name, AddFilesModule)