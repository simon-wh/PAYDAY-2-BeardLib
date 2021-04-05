MenuMusicModule = MenuMusicModule or BeardLib:ModuleClass("MenuMusic", ItemModuleBase)

function MenuMusicModule:LoadBuffers()
	for _, track in pairs(BeardLib.MusicMods[self._config.id].tracks) do
		if track.source and track.source.module then
			track.source.buffer = XAudio.Buffer:new(track.source.path)
		end
		if track.start_source and track.start_source.module then
			track.start_source.buffer = XAudio.Buffer:new(track.start_source.path)
		end
	end
end

function MenuMusicModule:UnloadBuffers()
	for _, track in pairs(BeardLib.MusicMods[self._config.id].tracks) do
		if track.source and track.source.module then
			if track.source.buffer then
				track.source.buffer:close(true)
			end
			track.source.buffer = nil
		end
		if track.start_source and track.start_source.module then
			if track.start_source.buffer then
				track.start_source.buffer:close(true)
			end
			track.start_source.buffer = nil
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
	music.tracks = {
		{
			source = self:MakeBuffer(self._config.source),
			start_source = self:MakeBuffer(self._config.start_source)
		}
	}
	BeardLib.MusicMods[self._config.id] = music
end