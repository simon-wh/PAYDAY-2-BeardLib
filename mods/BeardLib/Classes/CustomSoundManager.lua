CustomSoundManager = CustomSoundManager or {}
local C = CustomSoundManager
C.sources = {}
C.stop_ids = {}
C.float_ids = {}
C.engine_sources = {}
C.buffers = {global = {}}
C.redirects = {global = {}}
C.delayed_buffers = {global = {}}
C.Closed = XAudio == nil

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
		function SoundSource:post_event(event, ...)
			event = CustomSoundManager:Redirect(event, self:get_prefixes())
			local custom_source = CustomSoundManager:CheckSoundID(event, self)
			if custom_source then
				return custom_source
			else
				return self:_post_event(event, ...)
			end
		end
	else
		BeardLib:log("Something went wrong when trying to initialize the custom sound manager hook")
	end
end

function C:CheckSoundID(sound_id, engine_source)
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

    local stop_id = self.stop_ids[sound_id]
    if stop_id then
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
        return nil
    end

    local buffer = self:GetLoadedBuffer(sound_id, prefixes)
    if buffer then
		return self:AddSource(engine_source, buffer)
    else
        return nil
    end
end

function C:Sources()
    return self.sources
end

function C:Buffers()
    return self.buffers
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

function C:AddBuffer(data, force)
    if self.Closed then
        return
    end

    local sound_id, stop_id = data.id, data.stop_id
    if not data.dont_store_float then
        self.float_ids[SoundDevice:string_to_id(sound_id)] = sound_id
        if stop_id then
            self.float_ids[SoundDevice:string_to_id(stop_id)] = stop_id
        end
    end
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
    
    if stop_id then
        self.stop_ids[stop_id] = sound_id
    end
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
    return buffer
end

function C:AddSource(engine_source, buffer) 
    if self.Closed then
        return
    end
       
	local source = XAudio.Source:new(buffer)
	local dummy = DummySoundSource:new(source, engine_source)
    if engine_source:is_relative() or buffer.data.relative then
        source:set_relative(true)
        if not buffer.data.auto_pause then
            source:set_auto_pause(false)
        end
    else
        source:set_position(engine_source:get_position())
    end
    source:set_looping(buffer.data.loop)
    table.insert(self.sources, dummy)
    return dummy
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

function C:IsClosed()
    return self.Closed
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
    for _, tbl in pairs(self.sources) do
        local source = tbl.source
        if source and not source:is_closed() then
            if tbl.engine_source == engine_source then
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
    for i, tbl in pairs(self.sources) do
        local source = tbl.source
        local engine_source = tbl.engine_source
        if source and not source:is_closed() then
            local position = engine_source:get_position()
            if position then
                source:set_position(position)
            end
        else
            table.remove(self.sources, i)
        end
    end
end


DummySoundSource = DummySoundSource or class()
function DummySoundSource:init(source, engine_source)
	self.engine_source = engine_source
	self.source = source
end

-- \o\
function DummySoundSource:stop()
	if not self.source:is_closed() then
		self.source:stop()
	end
end

return C