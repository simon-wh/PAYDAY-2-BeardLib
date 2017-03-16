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
    if self._config.scan_directory then
    	self:ScanForFiles(directory)
    end
    if self._config.force_all then
    	for _, v in pairs(self._config) do
    		if type(v) == "table" then
    			v.force = true
    		end
    	end
    end
    CustomPackageManager:LoadPackageConfig(directory, self._config)
end

function AddFilesModule:ScanForFiles(dir)
	for _, file in pairs(SystemFS:list(dir)) do
		table.insert(self._config, {_meta = BeardLib.Utils.Path:GetFileExtension(file), path  = BeardLib.Utils.Path:GetFileNameWithoutExtension(file)})
    end
    for _, folder in pairs(SystemFS:list(dir, true)) do
    	self:ScanForFiles(BeardLib.Utils.Path:Combine(dir, folder))
    end
end

function AddFilesModule:Unload()
    CustomPackageManager:UnloadPackageConfig(self._config)
end

BeardLib:RegisterModule(AddFilesModule.type_name, AddFilesModule)
