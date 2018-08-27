AddFilesModule = AddFilesModule or class(BasicModuleBase)
AddFilesModule.type_name = "AddFiles"

function AddFilesModule:Load()
    local directory = self._config.full_directory or Path:Combine(self._mod.ModPath, self._config.directory)
    CustomPackageManager:LoadPackageConfig(directory, self._config, self._mod)
end

function AddFilesModule:Unload()
    CustomPackageManager:UnloadPackageConfig(self._config)
end

BeardLib:RegisterModule(AddFilesModule.type_name, AddFilesModule)