MenuMusicModule = MenuMusicModule or class(ItemModuleBase)
MenuMusicModule.type_id = "MenuMusic"

function MenuMusicModule:init(core_mod, config)
    if not self.super.init(self, core_mod, config) then
        return false
    end
    return true
end

function MenuMusicModule:MakeBuffer(source)
	if source then
		if FileIO:Exists(source) then
			return XAudio.Buffer:new(source)
		else
			BeardLib:log("[ERROR] Source file '%s' does not exist, music id '%s'", tostring(source), tostring(self._config.id))
			return nil
		end
	end
end

function MenuMusicModule:RegisterHook()
	self._config.id = self._config.id or "Err"
	if BeardLib.MusicMods[self._config.id] and not self._config.force then
		self:log("[ERROR] Music with the id '%s' already exists!", self._config.id)
		return
	end	

	if self._config.source then
		self._config.source = Path:Combine(self._mod.ModPath, self._config.source)
	else
		self:log("[Warning] No source was specified for the menu music %s", self._config.id)
	end

	if self._config.start_source then
		self._config.start_source = Path:Combine(self._mod.ModPath, self._config.start_source)
	end

	BeardLib.Utils:SetupXAudio()
	local music = {menu = true, volume = self._config.volume, xaudio = true}
	music.source = self:MakeBuffer(self._config.source)
	music.start_source = self:MakeBuffer(self._config.start_source)
	BeardLib.MusicMods[self._config.id] = music
end

BeardLib:RegisterModule(MenuMusicModule.type_id, MenuMusicModule)