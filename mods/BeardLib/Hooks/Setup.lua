Hooks:PostHook(Setup, "init_managers", "BeardLibAddMissingDLCPackages", function(ply)
	if managers.dlc.give_missing_package then
    	managers.dlc:give_missing_package()
    end
    Hooks:Call("SetupInitManagers")
end)

Hooks:PostHook(Setup, "unload_packages", "BeardLibUnloadPackages", function(ply)
    CustomSoundManager:Close()
end)

if XAudio and SoundSource then
    local SoundSource = SoundSource
    if type(SoundSource) == "userdata" then
        SoundSource = getmetatable(SoundSource)
    end
    local sources = CustomSoundManager.engine_sources

    local Unit = Unit
    if type(Unit) == "userdata" then
        Unit = getmetatable(Unit)
    end

    --I love overkill, they make get functions, but they crash at some instances :)
    --This is the best way I could find to get these sound sources so :shrug:
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
        local switch = self:get_data().switch
        return switch and table.map_values(switch) or nil
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
        --Group: Not sure what it is exactly, guessing like a folder, gonna ignore for now.
        --State: Where the voice prefix actually goes to.
    end)

    SoundSource._post_event = SoundSource._post_event or SoundSource.post_event
    function SoundSource:post_event(event, ...)
		if not CustomSoundManager:CheckSoundID(event, self) then
            return self:_post_event(event, ...)
		end
	end
end