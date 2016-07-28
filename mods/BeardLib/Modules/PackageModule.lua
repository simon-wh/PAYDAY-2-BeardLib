PackageModule = PackageModule or class(ModuleBase)

PackageModule.type_name = "Package"
PackageModule._loose = true

function PackageModule:init(core_mod, config)
    self.required_params = table.add(clone(self.required_params), {"id"})
    if not self.super.init(self, core_mod, config) then
        return false
    end
    self._id = self._config.id:key()
    if BeardLib._custom_packages[self._id] then
        self:log("[ERROR] Package with key '%s' already exists!", self._config.name)
        return false
    end
    Global.custom_loaded_packages[self._id] = Global.custom_loaded_packages[self._id] ~= nil and Global.custom_loaded_packages[self._id] or false

    BeardLib._custom_packages[self._id] = self

    return true
end

function PackageModule:Load()
    local directory = BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.directory)
    BeardLib:LoadAddConfig(directory, self._config)
    Global.custom_loaded_packages[self._id] = true
end

function PackageModule:Unload()
    BeardLib:UnloadAddConfig(self._config)
    Global.custom_loaded_packages[self._id] = false
end

function PackageModule:loaded()
    return Global.custom_loaded_packages[self._id]
end

BeardLib:RegisterModule(PackageModule.type_name, PackageModule)
