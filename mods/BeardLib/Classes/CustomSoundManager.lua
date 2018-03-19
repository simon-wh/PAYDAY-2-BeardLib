CustomSoundManager = CustomSoundManager or {}
CustomSoundManager.buffers = {global = {}}
CustomSoundManager.stop_ids = {}
CustomSoundManager.sources = {}
CustomSoundManager.engine_sources = {}

local log_incoming = true
function CustomSoundManager:CheckSoundID(sound_id, engine_source)
    if log_incoming then
        BeardLib:DevLog("Incoming sound check %s", tostring(sound_id))
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

    local prefix = engine_source:get_prefix()
    local buffer
    if prefix then
        local prefix_tbl = self.buffers[prefix]
        buffer = prefix_tbl and prefix_tbl[sound_id] or nil
    else
        buffer = self.buffers.global[sound_id]
    end

    if buffer then
        local source = self:AddSource(engine_source, buffer).source
        source:set_buffer(buffer)
        source:set_looping(buffer.loop)
        return true
    else
        return false
    end
end

function CustomSoundManager:Sources()
    return self.sources
end

function CustomSoundManager:Buffers()
    return self.buffers
end

function CustomSoundManager:AddBuffer(path, data)
    local buffer = XAudio.Buffer:new(path)
    local sound_id, stop_id = data.id, data.stop_id
    local prefix = data.prefix
    
    buffer.loop = data.loop
    if stop_id then
        self.stop_ids[stop_id] = sound_id
    end
    if prefix then
        if not self.buffers[prefix] then
            self.buffers[prefix] = {}
        end
        self.buffers[prefix][sound_id] = buffer
    else
        self.buffers.global[sound_id] = buffer
    end
    return buffer
end

function CustomSoundManager:AddSource(engine_source, buffer)    
    local source = XAudio.Source:new(buffer)
    local source_tbl = {engine_source = engine_source, source = source}
    if engine_source:is_relative() then
        source:set_relative(true)
        source:set_auto_pause(false)
    end
    table.insert(self.sources, source_tbl)
    return source_tbl
end

function CustomSoundManager:update(t, dt)
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

return CustomSoundManager