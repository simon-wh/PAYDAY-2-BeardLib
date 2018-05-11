CustomSoundManager = CustomSoundManager or {}
local C = CustomSoundManager
local default_prefix = {"global"}
C.sources = {}
C.stop_ids = {}
C.float_ids = {}
C.engine_sources = {}
C.sound_ids = {global = {}}
C.buffers = {global = {}}
C.redirects = {global = {}}
C.delayed_buffers = {global = {}}
C.Closed = XAudio == nil

function C:CheckSoundID(sound_id, engine_source, clbk, cookie)
	if self.Closed then
        return nil
    end
    
    if tonumber(sound_id) then
        local convert = self.float_ids[sound_id]
        if convert then
            sound_id = convert
        end
    end

    local prefixes = engine_source:get_prefixes()
    if BeardLib.DevMode then
        BeardLib:log("Incoming sound check: ID %s Prefixes %s", tostring(sound_id), tostring(prefixes and table.concat(prefixes, ", ") or "none"))
    end

    local stop_ids = self.stop_ids[sound_id]
	if stop_ids then
		for _, stop_id in pairs(stop_ids) do
			local buffer = self:GetLoadedBuffer(stop_id, prefixes, true)
			if buffer then
				local new_sources = {}
				for _, tbl in pairs(self.sources) do
					local source = tbl.source
					if source and not source:is_closed() then
						local sndbuff = source._buffer
						if sndbuff then
							if sndbuff == buffer then
								source:close()
							else
								table.insert(new_sources, tbl)
							end
						end
					end
				end
				self.sources = new_sources
			end
		end
        return nil
    end

    local source = self:AddSource(sound_id, prefixes, engine_source, clbk, cookie)
    if source then
		return source
    else
        return nil
    end
end

function C:GetDelayedBuffer(sound_id, prefixes)
    if prefixes then
        for _, prefix in pairs(prefixes) do
            local prefix_tbl = self.delayed_buffers[prefix]
            local buffer = prefix_tbl and prefix_tbl[sound_id] or nil
            if buffer then
                return buffer, prefix_tbl
            end
        end
    else
        local global_prefix = self.delayed_buffers.global
        return global_prefix[sound_id], global_prefix
    end
    return nil
end

function C:GetLoadedBuffer(sound_id, prefixes, no_load)
    local delayed_buffer, prefix_tbl = self:GetDelayedBuffer(sound_id, prefixes)
    if delayed_buffer then
        if not no_load then
            prefix_tbl[sound_id] = nil
            return self:AddBuffer(delayed_buffer, true)
        else
            return nil
        end
    end

    if prefixes and #prefixes > 0 then
        for _, prefix in pairs(prefixes) do
            local prefix_tbl = self.buffers[prefix]
            local buffer = prefix_tbl and prefix_tbl[sound_id] or nil
            if buffer then
                return buffer
            end
        end
    else
        return self.buffers.global[sound_id]
    end
    return nil
end

function C:StoreFloat(sound_id, stop_id)
	self.float_ids[SoundDevice:string_to_id(sound_id)] = sound_id
	if stop_id then
		self.float_ids[SoundDevice:string_to_id(stop_id)] = stop_id
	end
end

function C:AddSoundID(data)
	local sound_id, stop_id = data.id, data.stop_id
    if not data.dont_store_float then
		self:StoreFloat(sound_id, stop_id)
	end
	if stop_id then
		self.stop_ids[stop_id] = self.stop_ids[stop_id] or {}
		table.insert(self.stop_ids[stop_id], sound_id)
	end
	for _, prefix in pairs(data.prefixes or default_prefix) do
		self.sound_ids[prefix] = self.sound_ids[prefix] or {}
		self.sound_ids[prefix][sound_id] = data
	end
end

function C:AddBuffer(data, force)
    if self.Closed then
        return
	end
	
	local sound_id = data.id
    local prefix = data.prefix
    if not force and data.load_on_play then
        if prefix then
            if not self.delayed_buffers[prefix] then
                self.delayed_buffers[prefix] = {}
            end
            local prefix_tbl = self.delayed_buffers[prefix]
            if not prefix_tbl then
                prefix_tbl = {}
                self.delayed_buffers[prefix] = prefix_tbl
            end
            prefix_tbl[sound_id] = data
        else
            self.delayed_buffers.global[sound_id] = data
        end
        return
    end
    
    local buffer = XAudio.Buffer:new(data.full_path)
    local close_previous = data.close_previous
    buffer.data = data

    if prefix then
        local prefix_tbl = self.buffers[prefix]
        if not prefix_tbl then
            prefix_tbl = {}
            self.buffers[prefix] = prefix_tbl
        end
        if close_previous then
            local buffer = prefix_tbl[sound_id]
            if buffer then
                buffer:close(true)
            end
        end
        prefix_tbl[sound_id] = buffer
    else
        if close_previous then
            local buffer = self.buffers.global[sound_id]
            if buffer then
                buffer:close(true)
            end
        end
        self.buffers.global[sound_id] = buffer
	end
	
	self:AddSoundID(table.merge({queue = {{id = sound_id}}}, data))

    return buffer
end

function C:GetSound(sound_id, prefixes) 
	prefixes = prefixes or default_prefix
	for _, prefix in pairs(prefixes) do
		local sound = self.sound_ids[prefix] and self.sound_ids[prefix][sound_id]
		if sound then
			return sound
		end
	end
end

function C:AddSource(sound_id, prefixes, engine_source, clbk, cookie) 
	if self.Closed then
		return
	end
	
	prefixes = prefixes or default_prefix
	local sound = self:GetSound(sound_id, prefixes)

	if sound then
		local queue = {}
		for _, data in pairs(sound.queue) do
			--if not buffer, assume it's a vanilla sound.
			table.insert(queue, {buffer = self:GetLoadedBuffer(data.id, prefixes), data = data})
		end

		if #queue > 0 then
			local source = MixedSoundSource:new(queue, engine_source, clbk, cookie)
			if sound.loop then
				source:set_looping(sound.loop)
			end
			if sound.volume then
				source:set_volume(sound.volume)
			end
			table.insert(self.sources, source)
			return source
		end
	end
	
	return nil
end

function C:Redirect(id, prefixes)
    if prefixes and #prefixes > 0 then
        for _, prefix in pairs(prefixes) do
            local prefix_tbl = self.redirects[prefix]
            if prefix_tbl and prefix_tbl[id] then
                return prefix_tbl[id]
            end
        end
    elseif self.redirects.global[id] then
        return self.redirects.global[id]
    end
    return id --No need to redirect.
end

function C:AddRedirect(id, to, prefix) 
    if prefix then
        self.redirects[prefix] = self.redirects[prefix] or {}
        self.redirects[prefix][id] = to
    else
        self.redirects.global[id] = to
    end
end

function C:CloseBuffer(sound_id, prefix, soft)
    local prefix_tbl
    if prefix then
        prefix_tbl = self.buffers[prefix]
        local buffer = prefix_tbl and prefix_tbl[sound_id] or nil
        if buffer then
            buffer:close(not soft and true)
            if not soft then
                prefix_tbl[sound_id] = nil
            end
        end
    else
        local buffer = self.buffers.global[sound_id]
        if buffer then
            buffer:close(not soft and true)
            if not soft then
                self.buffers.global[sound_id] = nil 
            end
        end
    end
end

function C:Stop(engine_source)
    local new_sources = {}
	for _, source in pairs(self.sources) do
		if not source:is_closed() then
            if source._engine_source == engine_source then
                source:close()
            else
                table.insert(new_sources, tbl)
            end
        end
    end
    self.sources = new_sources
end

function C:Close()
    if not self:IsClosed() then
        for _, prefix_tbl in pairs(self.buffers) do
            for _, buffer in pairs(prefix_tbl) do
                if buffer.close then
                    buffer:close(not not buffer.data.unload)
                end
            end
        end
        self.buffers = {global = {}}
        self.sources = {}
        self.Closed = true
    end
end

function C:update(t, dt)
    if self.Closed then
        return
    end
    for i, source in pairs(self.sources) do
        if source:is_closed() then
			table.remove(self.sources, i)
		end
    end
end

function C:IsClosed() return self.Closed end
function C:Queued() return self.queued end
function C:Redirects() return self.redirects end
function C:DelayedBuffers() return self.delayed_buffers end
function C:Sources() return self.sources end
function C:Buffers() return self.buffers end

function C:Open()
	if self.Closed then
		return
	end
	if XAudio and SoundSource and Unit then
		local SoundSource = SoundSource
		if type(SoundSource) == "userdata" then
			SoundSource = getmetatable(SoundSource)
		end
		local sources = CustomSoundManager.engine_sources
	
		local Unit = Unit
		if type(Unit) == "userdata" then
			Unit = getmetatable(Unit)
		end
	
		local orig = Unit.sound_source
		function Unit:sound_source(...)
			local ss = orig(self, ...)
			if ss then
				ss:set_link_object(self)
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
	
		--Thanks for not making get functions ovk :)
		function SoundSource:get_link()
			return self:get_data().linking
		end
	
		--If no position is set or is not linking to anything then we can assume it's a 2D sound.
		function SoundSource:is_relative()
			return self:get_position() == nil
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
	
		Hooks:PostHook(SoundSource, "stop", "BeardLibStopSounds", function(self)
			CustomSoundManager:Stop(self)
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
			event = CustomSoundManager:Redirect(event, self:get_prefixes())
			local custom_source = CustomSoundManager:CheckSoundID(event, self, clbk, cookie)
			if custom_source then
				return custom_source
			else
				return self:_post_event(event, clbk, cookie, ...)
			end
		end
	else
		BeardLib:log("Something went wrong when trying to initialize the custom sound manager hook")
	end
end

MixedSoundSource = MixedSoundSource or class(XAudio.Source)
function MixedSoundSource:init(queue, engine_source, clbk, cookie)
	MixedSoundSource.super.init(self)
	self._engine_source = engine_source
	self._callback = clbk
	self._queue = queue
	self._cookie = cookie
	self._closed = false
	self._queue_is_table = type(self._queue) == "table"
end

-- \o\
function MixedSoundSource:stop()
	if not self:is_closed() then
		MixedSoundSource.super.stop(self)
	end
end

function MixedSoundSource:post_event(sound_id)
	if self._engine_source then
		local pass = self._engine_source:_post_event(sound_id, function(event_ins, instance, event)
			if event == "end_of_event" then
				self:next_in_queue()
			end
		end, nil, "end_of_event")

		if not pass then
			self:next_in_queue()
		end
	end
end

function MixedSoundSource:callback(event)
	if self._callback then
		--EventInstance is used?
		--Is the order of parameters always like this?
		--What is marker event and how can we implement it in here?
		--This shit is confusing aaa
		self._callback(nil, self._engine_source, event, self._cookie)
	end
end

function MixedSoundSource:next_in_queue()
	self._playing = nil
	if self._queue_is_table then
		if self._queue[2] == nil then
			self:close()
			self:callback("end_of_event")
		else
			table.remove(self._queue, 1)
		end
	else
		self:close()
		self:callback("end_of_event")
	end
end

function MixedSoundSource:update(t, dt)
	if self:is_closed() then
		return
	end

	self._single_sound = nil

	MixedSoundSource.super.update(self, t, dt)

	local sound

	if self._playing then
		local engine_source, buffer = self._engine_source, self._buffer
		if engine_source then
			if engine_source:is_relative() or (buffer and buffer.data.relative) then
				self:set_relative(true)
				if buffer and not buffer.data.auto_pause then
					self:set_auto_pause(false)
				end
			else
				local position = engine_source:get_position()
				if position then
					self:set_position(position)
				end
			end
		end
	else
		if self._queue_is_table then
			sound = self._queue[1]
		else
			sound = self._queue
		end
		if not sound then
			self:close()
			self:callback("end_of_event")
			return
		end
	end

	if sound and not self._playing then
		local buffer = sound.buffer
		local wait = buffer and buffer.wait or sound.data.wait
		local volume = buffer and buffer.volume or sound.data.volume
		if wait then
			self._play_t = t + wait
		end

		self._playing = sound
		self._initial = true
		if volume then
			self._source_volume = self._raw_gain
			self:set_volume(volume)
		elseif self._source_volume then
			self:set_volume(self._source_volume)
		end

		if buffer then
			self:set_buffer(buffer, true)
		elseif not wait then
			self:post_event(sound.data.id)
		end
	end

	local state = self:get_state()
	local can_play = not self._play_t or self._play_t <= t
	if self._playing and not self._playing.buffer then
		if can_play then
			self:post_event(self._playing.id)
		end
	else
		if self._initial or state == MixedSoundSource.INITIAL then
			if can_play then
				self:play()
				self._play_t = nil
				self._initial = nil
			end
		elseif state == MixedSoundSource.STOPPED then
			self:next_in_queue()
		end
	end
end

return C