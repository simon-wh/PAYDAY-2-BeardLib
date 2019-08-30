LocalizationModule = LocalizationModule or class(ModuleBase)
LocalizationModule.type_name = "Localization"
LocalizationModule.forced_language = nil

function LocalizationModule:Load()
	self.LocalizationDirectory = self._config.directory and Path:Combine(self._mod.ModPath, self._config.directory) or self._mod.ModPath
    self.Localizations = {}

    for _, tbl in ipairs(self._config) do
        if tbl._meta == "localization" or tbl._meta == "loc" then
            if not self.DefaultLocalization then
                self.DefaultLocalization = tbl.file
            end
            self.Localizations[Idstring(tbl.language):key()] = tbl.file
        end
    end

    self.DefaultLocalization = self._config.default or self.DefaultLocalization

    if managers.localization then
        self:LoadLocalization()
    else
        Hooks:Add("LocalizationManagerPostInit", self._mod.ModPath .. "_Localization", function(loc)
            self:LoadLocalization()
    	end)
    end
end

function LocalizationModule:LoadLocalization()
    local path
    local lang_key = (LocalizationModule.forced_language or SystemInfo:language()):key()
    if self.Localizations[lang_key] then
        path = Path:Combine(self.LocalizationDirectory, self.Localizations[lang_key])
    else
        path = Path:Combine(self.LocalizationDirectory, self.DefaultLocalization)
    end

    --if it fails, just force the author to fix their errors.
    if not FileIO:Exists(path) then
        self:Err("JSON file not found! Path %s", path)
    elseif not FileIO:LoadLocalization(path) then
        self:Err("JSON file has errors and cannot be loaded! Path %s", path)
    end
end

BeardLib:RegisterModule(LocalizationModule.type_name, LocalizationModule)