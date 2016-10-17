AddFilesModule = AddFilesModule or class(ModuleBase)

AddFilesModule.type_name = "AddFiles"

function AddFilesModule:init(core_mod, config)
    if not self.super.init(self, core_mod, config) then
        return false
    end

    self:Load()

    return true
end

function AddFilesModule:Load()
    local directory = BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.directory)
    CustomPackageManager:LoadPackageConfig(directory, self._config)
end

function AddFilesModule:Unload()
    CustomPackageManager:UnloadPackageConfig(self._config)
end

BeardLib:RegisterModule(AddFilesModule.type_name, AddFilesModule)
