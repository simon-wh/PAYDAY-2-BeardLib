LocalizationModule = LocalizationModule or class(ModuleBase)

--Need a better name for this
LocalizationModule.type_name = "LocalizationModule"

function LocalizationModule:init(core_mod, config)
    self.super.init(self, core_mod, config)
    
    self.LocalizationDirectory = self._config.directory and self._mod.ModPath .. self._config.directory or self._mod.ModPath
    
    if not string.ends(self.LocalizationDirectory, "/") then
        self.LocalizationDirectory = self.LocalizationDirectory .. "/"
    end
    
    self.Localizations = {}
    
    for _, tbl in pairs(self._config) do
        if tbl._meta == "localization" then
            self.Localizations[Idstring(tbl.language):key()] = tbl.file
        end
    end
    
    self.DefaultLocalization = self._config.default or self.Localizations[1]
    
    self:RegisterHooks()
end

function LocalizationModule:RegisterHooks()
    Hooks:Add("LocalizationManagerPostInit", self._mod.Name .. "_Localization", function(loc)
        if self.Localizations[SystemInfo:language():key()] then
            LocalizationManager:load_localization_file(self.LocalizationDirectory .. self.Localizations[SystemInfo:language():key()])
        else
            LocalizationManager:load_localization_file(self.LocalizationDirectory .. self.DefaultLocalization)
        end
	end)
end