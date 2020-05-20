HeistMusic = HeistMusic or class(ItemModuleBase)
HeistMusic.type_name = "HeistMusic"

function HeistMusic:LoadBuffers()
    for _, event in pairs(BeardLib.MusicMods[self._config.id].events) do
        for _, source in pairs(event) do
            if type(source) == "table" and source.module then
                source.buffer = XAudio.Buffer:new(source.path)
            end
        end
	end
end

function HeistMusic:UnloadBuffers()
    for _, event in pairs(BeardLib.MusicMods[self._config.id].events) do
        for _, source in pairs(event) do
            if type(source) == "table" and source.module then
                if source.buffer then
                    source.buffer:close(true)
                end
                source.buffer = nil
            end
		end
	end
end

function HeistMusic:MakeBuffer(source)
	if source then
		if FileIO:Exists(source) then
			return BeardLib.OptimizedMusicLoad and {path = source, module = self} or XAudio.Buffer:new(source)
		else
			self:Err("Source file '%s' does not exist, music id '%s'", tostring(source), tostring(self._config.id))
			return nil
		end
	end
end

function HeistMusic:RegisterHook()
	if not XAudio then
		self:Err("Heist music module requires the XAudio API!")
		return
	end

	self._config.id = self._config.id or "Err"
	if BeardLib.MusicMods[self._config.id] then
		self:Err("Music with the id '%s' already exists!", self._config.id)
		return
	end

	local dir = self._config.directory
	if dir then
		dir = Path:Combine(self._mod.ModPath, dir)
	else
		dir = self._mod.ModPath
	end
	local music = {heist = true, volume = self._config.volume, xaudio = true, events = {}}
	BeardLib.Utils:SetupXAudio()

	for k,v in ipairs(self._config) do
		if type(v) == "table" and v._meta == "event" then
			if v.start_source then
				v.start_source = Path:Combine(dir, v.start_source)
			end
			if v.alt_source then
				v.alt_source = Path:Combine(dir, v.alt_source)
				v.alt_start_source = v.alt_start_source and Path:Combine(dir, v.alt_start_source)
				v.alt_chance = v.alt_chance and tonumber(v.alt_chance) or 0.1
				v.allow_switch = NotNil(v.allow_switch, true)
			end
			if v.source then
				v.source = Path:Combine(dir, v.source)
			elseif not v.start_source then
				self:log("[Warning] Event named %s in heist music %s has no defined source", tostring(self._config.id), tostring(v.name))
			end
			music.events[v.name] = {
				source = self:MakeBuffer(v.source),
				start_source = self:MakeBuffer(v.start_source),
				alt_source = self:MakeBuffer(v.alt_source),
				alt_start_source = self:MakeBuffer(v.alt_start_source),
				alt_chance = v.alt_chance,
				volume = v.volume or music.volume,
				allow_switch = v.allow_switch
			}
		end
	end

	local preview_event = self._config.preview_event or "assault"
	local event = music.events[preview_event]
	if event then
		music.source = event.source
		music.start_source = event.source
	end

	BeardLib.MusicMods[self._config.id] = music
end

BeardLib:RegisterModule(HeistMusic.type_name, HeistMusic)