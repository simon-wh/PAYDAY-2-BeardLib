MusicModule = MusicModule or class(ItemModuleBase)
MusicModule.type_id = "Music"

function MusicModule:init(core_mod, config)
    if not self.super.init(self, core_mod, config) then
        return false
    end
    return true
end

function MusicModule:RegisterHook()
	self._config.id = self._config.id or "Err"
	
	local dir = self._config.directory
	dir = (dir and dir .. "/") or ""
	
	if self._config.source then
		self._config.source = dir .. self._config.source
	end
	if self._config.start_source then
		self._config.start_source = dir .. self._config.start_source
	end

	local music = {menu = self._config.menu, heist = self._config.heist, source = self._config.source, start_source = self._config.start_source, events = {}}

	for k,v in ipairs(self._config) do
		if type(v) == "table" and v._meta == "event" then
			if v.start_source then
				v.start_source = dir .. v.start_source
			end
			if v.alt_source then
				v.alt_source = Path:Combine(dir, v.alt_source)
				v.alt_start_source = v.alt_start_source and Path:Combine(dir, v.alt_start_source)
				v.alt_chance = v.alt_chance and tonumber(v.alt_chance) or 0.1
			end
			if v.source then
				v.source = dir .. v.source
			else
				self:log("[ERROR] Music with the id '%s' has an event that has no source!", self._config.id)
				return
			end
			music.events[v.name] = {source = v.source, start_source = v.start_source, alt_source = v.alt_source, alt_start_source = v.alt_start_source, alt_chance = v.alt_chance}
		end
	end

	if not self._mod._config.AddFiles then
		local add = {directory = self._config.assets_directory or "Assets"}
		table.insert(add, {_meta = "movie", path = music.source})
		if music.start_source then
			table.insert(add, {_meta = "movie", path = music.start_source})
		end
		if music.alt_source then
			table.insert(add, {_meta = "movie", path = music.alt_source})
			if music.alt_start_source then
				table.insert(add, {_meta = "movie", path = music.alt_start_source})
			end
		end
		for _, event in pairs(music.events) do
			table.insert(add, {_meta = "movie", path = event.source})
			if event.start_source then
				table.insert(add, {_meta = "movie", path = event.start_source})
			end
			if event.alt_source then
				table.insert(add, {_meta = "movie", path = event.alt_source})
				if event.alt_start_source then
					table.insert(add, {_meta = "movie", path = event.alt_start_source})
				end
			end
		end
		self._mod._config.AddFiles = AddFilesModule:new(self._mod, add)
	end

	BeardLib.MusicMods[self._config.id] = music
end

BeardLib:RegisterModule(MusicModule.type_id, MusicModule)