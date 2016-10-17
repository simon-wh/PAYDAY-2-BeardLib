PackageModule = PackageModule or class(ModuleBase)

PackageModule.type_name = "Package"
PackageModule._loose = true

function PackageModule:init(core_mod, config)
    self.required_params = table.add(clone(self.required_params), {"id"})
    if not self.super.init(self, core_mod, config) then
        return false
    end
    self._id = self._config.id:id()
    local directory = BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.directory)
    if not CustomPackageManager:RegisterPackage(self._config.id, directory, self._config) then
        --self:log("[ERROR] Package with key '%s' already exists!", self._config.name)
        return false
    end

    return true
end

function PackageModule:Load()
    CustomPackageManager:LoadPackage(self._id)
end

function PackageModule:Unload()
    CustomPackageManager:UnLoadPackage(self._id)
end

function PackageModule:loaded()
    return CustomPackageManager:PackageLoaded(self._id)
end

BeardLib:RegisterModule(PackageModule.type_name, PackageModule)
