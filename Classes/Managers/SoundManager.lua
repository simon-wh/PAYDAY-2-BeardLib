BeardLibSoundManager = BeardLibSoundManager or BeardLib:ManagerClass("Sound")

function BeardLibSoundManager:init()
	self.sources = {}
	self.stop_ids = {}
	self.float_ids = {}
	self.engine_sources = {}
	self.create_source_hooks = {}
	self.sound_ids = {}
	self.buffers = {}
	self.redirects = {}
	self.Closed = XAudio == nil

	-- Deprecated, try not to use.
	CustomSoundManager = self
	BeardLib.managers.sound = self
end

function BeardLibSoundManager:CheckSoundID(sound_id, engine_source, clbk, cookie)
	if self.Closed then
		return
	end

	sound_id = self:GetFloat(sound_id) or sound_id

	local prefixes = engine_source:get_prefixes()
	if BeardLib.LogSounds then
		BeardLib:log("Incoming sound check: ID %s Prefixes %s", tostring(sound_id), tostring(prefixes and table.concat(prefixes, ", ") or "none"))
	end

	local stop_ids = self.stop_ids[sound_id]
	if stop_ids then
		for _, stop_id in pairs(stop_ids) do
			local new_sources = {}
			for _, source in pairs(self.sources) do
				if source and not source:is_closed() then
					if source:sound_id() == stop_id then
						source:close()
					else
						table.insert(new_sources, source)
					end
				end
			end
			self.sources = new_sources
		end

		return
	end

	return self:AddSource(sound_id, prefixes, engine_source, clbk, cookie)
end

function BeardLibSoundManager:GetLoadedBuffer(sound_id, prefixes, no_load)
	for i, buffer in pairs(self.buffers) do
		local sound = buffer.load_on_play and buffer or buffer.data
		if self:ComparePrefixes(sound, sound_id, prefixes) then
			if buffer.load_on_play then
				if no_load then
					return nil
				else
					table.remove(self.buffers, i)
					return self:AddBuffer(buffer, true)
				end
			else
				return buffer
			end
		end
	end

	return nil
end

function BeardLibSoundManager:StoreFloat(sound_id, stop_id)
	-- Convert it to a string cause the floats are too small for comparing, epic
	self.float_ids[tostring(SoundDevice:string_to_id(sound_id))] = sound_id
	if stop_id then
		self.float_ids[tostring(SoundDevice:string_to_id(stop_id))] = stop_id
	end
end

function BeardLibSoundManager:GetFloat(float)
	-- Convert it to a string cause the floats are too small for comparing, epic
	return self.float_ids[tostring(float)]
end

function BeardLibSoundManager:AddStop(stop_id, sound_id)
	self.stop_ids[stop_id] = self.stop_ids[stop_id] or {}
	table.insert(self.stop_ids[stop_id], sound_id)
end

function BeardLibSoundManager:AddSoundID(data)
	local sound_id, stop_id = data.id, data.stop_id
	if not data.dont_store_float then
		self:StoreFloat(sound_id, stop_id)
	end

	if stop_id then
		self:AddStop(stop_id, sound_id)
	end

	for i, sound in pairs(self.sound_ids) do
		if self:CompareSound(sound, sound_id, data.prefixes) then
			table.remove(self.sound_ids, i)
			break
		end
	end
	table.insert(self.sound_ids, data)
end

function BeardLibSoundManager:AddBuffer(data, force)
	if self.Closed then
		return
	end

	local close_previous = data.close_previous
	local sound_id = data.id
	local buffer

	if not data.load_on_play or force then
		buffer = XAudio.Buffer:new(data.full_path)
		buffer.data = data
	end

	for i, other_buffer in pairs(self.buffers) do
		local sound = other_buffer.load_on_play and other_buffer or other_buffer.data
		if self:CompareSound(sound, sound_id, data.prefixes) then
			table.remove(self.buffers, i)
			if not other_buffer.close and close_previous then
				other_buffer:close(true)
			end
			break
		end
	end
	table.insert(self.buffers, buffer or data)

	if buffer then
		self:AddSoundID(data)
	end

	return buffer
end

function BeardLibSoundManager:CompareSound(data, sound_id, prefixes)
	return data.id == sound_id
	and ((prefixes == nil and data.prefixes == nil)
	or (prefixes ~= nil and data.prefixes ~= nil and table.equals(prefixes, data.prefixes)))
end

function BeardLibSoundManager:ComparePrefixes(data, sound_id, prefixes)
	if data.id == sound_id then
		if data.prefixes and prefixes then
			if data.prefixes_strict then
				return table.contains_all(prefixes, data.prefixes)
			else
				return table.contains_any(data.prefixes, prefixes)
			end
		elseif data.prefix == nil then --Global
			return true
		end
	end
end

function BeardLibSoundManager:GetSound(sound_id, prefixes)
	for _, sound in pairs(self.sound_ids) do
		if self:ComparePrefixes(sound, sound_id, prefixes) then
			return sound
		end
	end
end

function BeardLibSoundManager:GenerateQueue(sound_id, prefixes, queue, sound_queue_data)
	queue = queue or {}

	local sound = self:GetSound(sound_id, prefixes)

	if sound then
		if sound.queue then
			if sound.is_random then
				local data = table.random(sound.queue)
				if data then
					self:GenerateQueue(data.id, prefixes, queue, data)
				end
			else
				for _, data in pairs(sound.queue) do
					self:GenerateQueue(data.id, prefixes, queue, data)
				end
			end
		else
			table.insert(queue, {buffer = self:GetLoadedBuffer(sound.id, prefixes), data = sound_queue_data or {}})
		end
	end

	return queue
end

function BeardLibSoundManager:AddSource(sound_id, prefixes, engine_source, clbk, cookie)
	if self.Closed then
		return
	end

	local sound = self:GetSound(sound_id, prefixes)
	if not sound then
		return
	end

	local queue = self:GenerateQueue(sound_id, prefixes)
	if #queue == 0 then
		return
	end

	local source = MixedSoundSource:new(sound_id, queue, engine_source, clbk, cookie)

	if sound.loop then
		source:set_looping(sound.loop)
	end

	if sound.volume then
		source:set_volume(sound.volume)
	end

	-- check for set_min_distance and set_max_distance existing on source for now since it's a new feature
	if sound.min_distance and source.set_min_distance then
		source:set_min_distance(sound.min_distance)
	end

	if sound.max_distance and source.set_max_distance then
		source:set_max_distance(sound.max_distance)
	end

	table.insert(self.sources, source)

	return source
end

function BeardLibSoundManager:Redirect(id, prefixes)
	id = self:GetFloat(id) or id

	for _, redirect in pairs(self.redirects) do
		if self:ComparePrefixes(redirect, id, prefixes) then
			return redirect.to
		end
	end
end

function BeardLibSoundManager:AddRedirect(data)
	table.insert(self.redirects, data)
	-- We need to be able to detect redirects when sound events are network synced so store float version of the redirect id
	self:StoreFloat(data.id)
end

function BeardLibSoundManager:CloseBuffer(sound_id, prefixes, soft)
	for i, buffer in pairs(self.buffers) do
		if (buffer.prefixes == nil and prefixes == nil) or (buffer.prefixes ~= nil and prefixes ~= nil and table.equals(buffer.prefixes, prefixes)) then
			if not buffer.load_on_play then
				buffer:close(not soft and true)
			end
			if not soft then
				table.remove(self.buffers, i)
			end
			return
		end
	end
end

function BeardLibSoundManager:Stop(engine_source)
	local new_sources = {}
	for _, source in pairs(self.sources) do
		if not source:is_closed() then
			if source._engine_source == engine_source then
				source:close()
			else
				table.insert(new_sources, source)
			end
		end
	end
	self.sources = new_sources
end

function BeardLibSoundManager:Close()
	if not self:IsClosed() then
		for _, source in pairs(self.sources) do
			source:close()
		end
		for _, buffer in pairs(self.buffers) do
			if buffer.close then
				buffer:close(not not buffer.data.unload)
			end
		end
		self.buffers = {}
		self.sources = {}
		self.Closed = true
	end
end

function BeardLibSoundManager:Update(t, dt)
	if self.Closed then
		return
	end
	for i, source in pairs(self.sources) do
		if source:is_closed() then
			table.remove(self.sources, i)
		end
	end
end

function BeardLibSoundManager:IsClosed() return self.Closed end
function BeardLibSoundManager:Queued() return self.queued end
function BeardLibSoundManager:Redirects() return self.redirects end
function BeardLibSoundManager:Sources() return self.sources end
function BeardLibSoundManager:Buffers() return self.buffers end

function BeardLibSoundManager:CreateSourceHook(id, func)
	table.insert(self.create_source_hooks, {id = id, func = func})
end

function BeardLibSoundManager:RemoveCreateSourceHook(id)
	for i, hook in pairs(self.create_source_hooks) do
		if hook.id == id then
			table.remove(self.create_source_hooks, i)
			return
		end
	end
end

function BeardLibSoundManager:Open()
	if self.Closed then
		return
	end

	if not XAudio or not SoundSource or not Unit then
		BeardLib:log("Something went wrong when trying to initialize the custom sound manager hook")
		return
	end

	local SoundSource = SoundSource
	if type(SoundSource) == "userdata" then
		SoundSource = getmetatable(SoundSource)
	end
	local sources = self.engine_sources
	local create_source_hooks = self.create_source_hooks

	local Unit = Unit
	if type(Unit) == "userdata" then
		Unit = getmetatable(Unit)
	end

	local SoundDevice = SoundDevice
	if type(SoundDevice) == "userdata" then
		SoundDevice = getmetatable(SoundDevice)
	end

	local create_source = SoundDevice.create_source
	function SoundDevice:create_source(name, ...)
		local source = create_source(self, name, ...)
		if source then
			source:get_data().name = name
			for _, hook in pairs(create_source_hooks) do
				hook.func(name, source)
			end
		end
		return source
	end

	local orig = Unit.sound_source
	function Unit:sound_source(...)
		local ss = orig(self, ...)
		if ss then
			ss:set_link_object(self)
			ss:set_unit(self) -- Link object can change so keep track of the unit as well.
		end
		return ss
	end

	function SoundSource:get_data()
		--:(
		local key = self:key()
		local data = sources[key] or {}
		sources[key] = data
		return data
	end

	function SoundSource:hook(id, func)
		local data = self:get_data()
		data.hooks = data.hooks or {}
		table.insert(data.hooks, {func = func, id = id})
	end

	function SoundSource:pre_hook(id, func)
		local data = self:get_data()
		data.pre_hooks = data.pre_hooks or {}
		table.insert(data.pre_hooks, {func = func, id = id})
	end
	--Thanks for not making get functions ovk :)
	function SoundSource:get_link()
		return self:get_data().linking
	end

	--If no position is set or if first person switch is set we can assume it's a 2D sound.
	function SoundSource:is_relative()
		return self:get_position() == nil or self:get_switch() and self:get_switch().int_ext == "first"
	end

	function SoundSource:get_position()
		local data = self:get_data()
		if data.position then
			return data.position
		else
			local link = self:get_link()
			return alive(link) and link:position() or nil
		end
	end

	function SoundSource:get_switch()
		return self:get_data().switch
	end

	function SoundSource:get_prefixes()
		return self:get_data().mapped_prefixes
	end

	function SoundSource:set_link_object(object)
		self:get_data().linking = object
	end

	function SoundSource:get_unit()
		return self:get_data().unit
	end

	function SoundSource:set_unit(unit)
		self:get_data().unit = unit
	end

	Hooks:PostHook(SoundSource, "stop", "BeardLibStopSounds", function(self)
		BeardLib.Managers.Sound:Stop(self)
	end)

	Hooks:PostHook(SoundSource, "link", "BeardLibLink", function(self, object)
		self:set_link_object(object)
	end)

	Hooks:PostHook(SoundSource, "link_position", "BeardLibLinkPosition", function(self, object)
		self:set_link_object(object)
	end)

	Hooks:PostHook(SoundSource, "set_position", "BeardLibSetPosition", function(self, position)
		self:get_data().position = position
	end)

	Hooks:PostHook(SoundSource, "set_switch", "BeardLibSetSwitch", function(self, group, state)
		local data = self:get_data()
		data.switch = data.switch or {}
		data.switch[group] = state
		data.mapped_prefixes = table.map_values(data.switch)
	end)

	SoundSource._post_event = SoundSource._post_event or SoundSource.post_event
	function SoundSource:post_event(event, clbk, cookie, ...)
		local data = self:get_data()

		if data.pre_hooks then
			for _, hook in pairs(data.pre_hooks) do
				if hook.func(event, clbk, cookie) == true then
					return
				end
			end
		end

		event = BeardLib.Managers.Sound:Redirect(event, self:get_prefixes()) or event

		local result = BeardLib.Managers.Sound:CheckSoundID(event, self, clbk, cookie)
		if not result then
			result = self:_post_event(event, clbk, cookie, ...)
		end

		if data.hooks then
			for _, hook in pairs(data.hooks) do
				if hook.func(event, clbk, cookie) == true then
					break
				end
			end
		end

		return result
	end
end
