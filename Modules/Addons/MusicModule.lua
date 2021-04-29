MusicModule = MusicModule or BeardLib:ModuleClass("Music", ItemModuleBase)

function MusicModule:RegisterHook()
	self._config.id = self._config.id or "Err"

	local dir = self._config.directory
	dir = (dir and dir .. "/") or ""

	local music = {menu = self._config.menu, heist = self._config.heist, volume = self._config.volume, events = {}}

	for k,v in ipairs(self._config) do
		if type(v) == "table" and v._meta == "event" then
			local tracks = {}
			-- Track handling as part of child track tags
			for _,t in ipairs(v) do
				if type(t) == "table" and t._meta == "track" then
					table.insert(tracks, {
						start_source = (t.start_source or v.start_source) and Path:Combine(dir, (t.start_source or v.start_source)),
						source = (t.source or v.source) and Path:Combine(dir, (t.source or v.source)),
						weight = t.weight or v.weight or 1,
						volume = t.volume or v.volume or music.volume
					})
				end
			end
			-- Track handling as part of event tag
			if #tracks == 0 then
				table.insert(tracks, {
					start_source = v.start_source and Path:Combine(dir, v.start_source),
					source = v.source and Path:Combine(dir, v.source),
					weight = v.alt_chance and v.alt_chance * 100 or 1,
					volume = v.volume or music.volume
				})
				if v.alt_source then -- backwards compat for old alternate track system
					table.insert(tracks, {
						start_source = (v.alt_start_source or v.start_source) and Path:Combine(dir, (v.alt_start_source or v.start_source)),
						source = v.alt_source and Path:Combine(dir, v.alt_source),
						weight = v.alt_chance and v.alt_chance * 100 or 1,
						volume = v.volume or music.volume
					})
				end
			end
			for i,t in ipairs(tracks) do
				if not t.start_source and not t.source then
					self:Err("Event named %s in heist music %s has no defined source for track %i", tostring(self._config.id), tostring(v.name), i)
					return
				end
			end
			music.events[v.name] = {
				tracks = tracks,
				volume = v.volume or music.volume,
				allow_switch = NotNil(v.allow_switch, true)
			}
		end
	end

	if self._config.source and music.menu then
		self._config.preview_event = self._config.preview_event or self._config.source
		if not music.events[self._config.preview_event] then
			music.events[self._config.preview_event] = {
				tracks = {
					start_source = self._config.start_source and Path:Combine(dir, self._config.start_source),
					source = self._config.source and Path:Combine(dir, self._config.source),
					volume = music.volume
				},
				volume = music.volume
			}
		end
	end

	if not self._mod._config.AddFiles then
		local add = {directory = self._config.assets_directory or "Assets"}
		for _, event in pairs(music.events) do
			for _, track in pairs(event.tracks) do
				table.insert(add, {_meta = "movie", path = track.source})
				if track.start_source then
					table.insert(add, {_meta = "movie", path = track.start_source})
				end
			end
		end
		self._mod._config.AddFiles = AddFilesModule:new(self._mod, add)
	end

	local event = music.events[self._config.preview_event or "assault"]
	music.tracks = event and event.tracks

	BeardLib.MusicMods[self._config.id] = music
end