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
	if not self._config.source then
		self:log("[ERROR] No source was specified for the music %s", self._config.id)
		return
	end	
	if BeardLib.MusicMods[self._config.id] then
		self:log("[ERROR] Music with the id '%s' already exists!", self._config.id)
		return
	end
	local dir = self._config.directory
	self._config.directory = (dir and dir .. "/") or ""
	self._config.source = self._config.directory .. self._config.source
	local sources = {}

	for k,v in pairs(self._config) do
		if type(k) == "number" and type(v) == "table" and v._meta == "event" then
			if v.start_source then
				v.start_source = self._config.directory .. v.start_source
				sources[v.start_source] = true
			end
			if v.source then
				v.source = self._config.directory .. v.source
				sources[v.source] = true
			else
				self:log("[ERROR] Music with the id '%s' has an event that has no source!", self._config.id)
				return
			end
		end
	end
	if not self._mod._config.AddFiles then
		local add = {directory = self._config.assets_directory or "Assets"}
		for source in pairs(sources) do
			table.insert(add, {_meta = "movie", path = source})
		end
		self._mod._config.AddFiles = AddFilesModule:new(self._mod, add)
	end
	BeardLib.MusicMods[self._config.id] = self._config
end

BeardLib:RegisterModule(MusicModule.type_id, MusicModule)
