MenuMusicModule = MenuMusicModule or BeardLib:ModuleClass("MenuMusic", ItemModuleBase)

function MenuMusicModule:LoadBuffers()
	for _, source in pairs(BeardLib.MusicMods[self._config.id]) do
		if type(source) == "table" and source.module then
			source.buffer = XAudio.Buffer:new(source.path)
		end
	end
end

function MenuMusicModule:UnloadBuffers()
	for _, source in pairs(BeardLib.MusicMods[self._config.id]) do
		if type(source) == "table" and source.module then
			if source.buffer then
				source.buffer:close(true)
			end
			source.buffer = nil
		end
	end
end

function MenuMusicModule:MakeBuffer(source)
	if source then
		if FileIO:Exists(source) then
			return BeardLib.OptimizedMusicLoad and {path = source, module = self} or XAudio.Buffer:new(source)
		else
			self:Err("Source file '%s' does not exist, music id '%s'", tostring(source), tostring(self._config.id))
			return nil
		end
	end
end

function MenuMusicModule:RegisterHook()
	if not XAudio then
		self:Err("Menu music module requires the XAudio API!")
		return
	end

	self._config.id = self._config.id or "Err"
	if BeardLib.MusicMods[self._config.id] and not self._config.force then
		self:Err("Music with the id '%s' already exists!", self._config.id)
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