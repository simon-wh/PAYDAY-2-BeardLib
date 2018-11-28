CustomSoundManager = CustomSoundManager or {}
local C = CustomSoundManager
C.sources = {}
C.stop_ids = {}
C.float_ids = {}
C.engine_sources = {}
C.sound_ids = {}
C.buffers = {}
C.redirects = {}
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
        return nil
    end

    local source = self:AddSource(sound_id, prefixes, engine_source, clbk, cookie)
    if source then
		return source
    else
        return nil
    end
end

function C:GetLoadedBuffer(sound_id, prefixes, no_load)
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

function C:StoreFloat(sound_id, stop_id)
	self.float_ids[SoundDevice:string_to_id(sound_id)] = sound_id
	if stop_id then
		self.float_ids[SoundDevice:string_to_id(stop_id)] = stop_id
	end
end

function C:AddStop(stop_id, sound_id)
	self.stop_ids[stop_id] = self.stop_ids[stop_id] or {}
	table.insert(self.stop_ids[stop_id], sound_id)
end

function C:AddSoundID(data)
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

function C:AddBuffer(data, force)
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
        self:AddSoundID(table.merge({queue = {{id = sound_id}}}, data))
    end

    return buffer
end

function C:CompareSound(data, sound_id, prefixes)
    return data.id == sound_id 
    and ((prefixes == nil and data.prefixes == nil) 
    or (prefixes ~= nil and data.prefixes ~= nil and table.equals(prefixes, data.prefixes)))
end

function C:ComparePrefixes(data, sound_id, prefixes)
    if data.id == sound_id then
        if data.prefixes and prefixes then
            local match = false
            for _, snd_prefix in pairs(data.prefixes) do
                if data.prefixes_strict then
                    match = table.contains(prefixes, snd_prefix)
                else
                    for _, prefix in pairs(prefixes) do
                        if prefix == snd_prefix then return true end
                    end
                end
            end
            if match then return true end
        elseif data.prefix == nil then --Global
            return true
        end
    end
end

function C:GetSound(sound_id, prefixes)
    for _, sound in pairs(self.sound_ids) do
        if self:ComparePrefixes(sound, sound_id, prefixes) then
            return sound
        end
    end
end

function C:AddSource(sound_id, prefixes, engine_source, clbk, cookie) 
	if self.Closed then
		return
	end
	
	local sound = self:GetSound(sound_id, prefixes)

	if sound then
		local queue = {}
        --if not buffer, assume it's a vanilla sound. 

        if sound.is_random then
            local data = table.random(sound.queue)
            if data then
                table.insert(queue, {buffer = self:GetLoadedBuffer(data.id, prefixes), data = data})
            end
        else
            for _, data in pairs(sound.queue) do
                table.insert(queue, {buffer = self:GetLoadedBuffer(data.id, prefixes), data = data})
            end
        end

		if #queue > 0 then
			local source = MixedSoundSource:new(sound_id, queue, engine_source, clbk, cookie)
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
    for _, redirect in pairs(self.redirects) do
        if self:ComparePrefixes(redirect, id, prefixes) then
            return redirect.to
        end
    end
    return id --No need to redirect.
end

function C:AddRedirect(data)
    table.insert(self.redirects, data)
end

function C:CloseBuffer(sound_id, prefixes, soft)
    for i, buffer in pairs(self.buffers) do
        local sound = buffer.load_on_play and buffer or buffer.data
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

return C