CustomSoundManager = CustomSoundManager or {}
local C = CustomSoundManager
C.buffers = {global = {}}
C.delayed_buffers = {global = {}}
C.stop_ids = {}
C.sources = {}
C.engine_sources = {}
local log_incoming = true
function C:CheckSoundID(sound_id, engine_source)
    if log_incoming then
        local prefixes = engine_source:get_prefixes()
        BeardLib:DevLog("Incoming sound check: ID %s Prefixes %s", tostring(sound_id), tostring(prefixes and table.concat(prefixes, ", ") or "none"))
    end

    local stop_id = self.stop_ids[sound_id]
    if stop_id then
        local buffer = self.buffers[stop_id]
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
        return true
    end

    local buffer = self:GetLoadedBuffer(sound_id, engine_source:get_prefixes())

    if buffer then
        local source = self:AddSource(engine_source, buffer).source
        source:set_looping(buffer.data.loop)
        return true
    else
        return false
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

function C:GetLoadedBuffer(sound_id, prefixes)
    local delayed_buffer, prefix_tbl = self:GetDelayedBuffer(sound_id, prefixes)
    if delayed_buffer then
        prefix_tbl[sound_id] = nil
        return self:AddBuffer(delayed_buffer, true)
    end

    if prefixes then
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
    if self._closed then
        return
    end

    local sound_id, stop_id = data.id, data.stop_id
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
    if self._closed then
        return
    end
       
    local source = XAudio.Source:new(buffer)
    local source_tbl = {engine_source = engine_source, source = source}
    if engine_source:is_relative() then
        source:set_relative(true)
        source:set_auto_pause(false)
    else
        source:set_position(engine_source:get_position())
    end
    table.insert(self.sources, source_tbl)
    return source_tbl
end

function C:IsClosed()
    return self._closed
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

function C:Close()
    if not self:IsClosed() then
        for _, prefix_tbl in pairs(self.buffers) do
            for _, buffer in pairs(prefix_tbl) do
                if buffer.close then
                    buffer:close(not not buffer.data.unload)
                end
            end
        end
        self.buffers = {}
        self.sources = {}
        self._closed = true
    end
end

function C:update(t, dt)
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

return C