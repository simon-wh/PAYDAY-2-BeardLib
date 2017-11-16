AddFilesModule = AddFilesModule or class(ModuleBase)

AddFilesModule.type_name = "AddFiles"

function AddFilesModule:init(core_mod, config)
    if not AddFilesModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()

    return true
end

function AddFilesModule:Load()
    local use_clbk = self._config.use_clbk and self._mod:StringToCallback(self._config.use_clbk) or nil
    if use_clbk and not use_clbk() then
        return
    end
    
    local directory = self._config.full_directory or BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.directory)
    if self._config.force_all then
    	for _, v in pairs(self._config) do
    		if type(v) == "table" then
    			v.force = true
    		end
    	end
    end
    CustomPackageManager:LoadPackageConfig(directory, self._config)
end

function AddFilesModule:Unload()
    CustomPackageManager:UnloadPackageConfig(self._config)
end

BeardLib:RegisterModule(AddFilesModule.type_name, AddFilesModule)