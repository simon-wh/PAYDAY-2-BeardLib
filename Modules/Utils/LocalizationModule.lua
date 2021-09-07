LocalizationModule = LocalizationModule or BeardLib:ModuleClass("Localization", ModuleBase)
LocalizationModule.forced_language = nil

function LocalizationModule:Load()
	self.LocalizationDirectory = self._config.directory and Path:Combine(self._mod.ModPath, self._config.directory) or self._mod.ModPath
    self.Localizations = {}

    self.DefaultLocalization = self._config.default
    self:LoadGroup(self._config, self.LocalizationDirectory)

    if managers.localization then
        self:LoadLocalization()
    else
        Hooks:Add("LocalizationManagerPostInit", self._mod.ModPath .. "_Localization", function(loc)
            self:LoadLocalization()
    	end)
    end
end

function LocalizationModule:LoadGroup(data, directory, language)
    for _, tbl in ipairs(data) do
        local meta = tbl._meta
        if meta == "localization" or meta == "loc" then
            if not self.DefaultLocalization then
                self.DefaultLocalization = tbl.file
            end
            local lang = (tbl.language or language):key()
            self.Localizations[lang] = self.Localizations[lang] or {}
            local path = Path:Combine(directory, tbl.file)
            if FileIO:Exists(path) then
                table.insert(self.Localizations[lang], path)
            else
                self:Err("Localization file with path %s for language %s doesn't exist!", tostring(path), tostring(tbl.language or language))
            end
        elseif meta == "group" then
            self:LoadGroup(tbl, Path:Combine(directory, tbl.directory), tbl.language)
        end
    end
end

function LocalizationModule:LoadLocalization()
    local path
    local lang_key = (LocalizationModule.forced_language or SystemInfo:language()):key()
    local latam = string.key("latam")
    -- Fallback to Spanish if there is no specific localization for Latin American Spanish
    if lang_key == latam and not self.Localizations[latam] then
        lang_key = string.key("spanish")
    end

    if self.Localizations[lang_key] then
        for _, path in pairs(self.Localizations[lang_key]) do
            if not FileIO:LoadLocalization(path) then
                self:Err("Language file has errors and cannot be loaded! Path %s", path)
            end
        end
    else
        if not FileIO:LoadLocalization(Path:Combine(self.LocalizationDirectory, self.DefaultLocalization)) then
            self:Err("Language file has errors and cannot be loaded! Path %s", path)
        end
    end
end