---@class PackageModule : ModuleBase
PackageModule = PackageModule or BeardLib:ModuleClass("Package", ModuleBase)
PackageModule._loose = true
PackageModule.auto_load = false

local Managers = BeardLib.Managers

function PackageModule:init(...)
    self.required_params = table.add(clone(self.required_params), {"id"})
    if not PackageModule.super.init(self, ...) then
        return false
	end

    self._id = self._config.id:id()
    local directory = self._config.full_directory or Path:Combine(self._mod.ModPath, self._config.directory)
    if not Managers.Package:RegisterPackage(self._config.id, directory, self._config) then
        self:Err("Package with key '%s' already exists!", self._config.name)
        return false
    end

    if self._config.unload_on_restart then
        Managers.Package:AddUnloadOnRestart(self)
    end

    return true
end

function PackageModule:Load()
    Managers.Package:LoadPackage(self._id)
end

function PackageModule:Unload()
    Managers.Package:UnloadPackage(self._id)
end

function PackageModule:Loaded()
    return Managers.Package:PackageLoaded(self._id)
end

function PackageModule:loaded()
    return Managers.Package:PackageLoaded(self._id)
end