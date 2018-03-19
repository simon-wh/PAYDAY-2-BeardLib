Hooks:PostHook(Setup, "init_managers", "BeardLibAddMissingDLCPackages", function(ply)
	if managers.dlc.give_missing_package then
    	managers.dlc:give_missing_package()
    end
    Hooks:Call("SetupInitManagers")
end)

if XAudio and SoundSource then
    local SoundSource = SoundSource
    if type(SoundSource) == "userdata" then
        SoundSource = getmetatable(SoundSource)
    end
    local sources = CustomSoundManager.engine_sources
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

    function SoundSource:get_prefix()
        local switch = self:get_data().switch
        return switch and switch.state or nil
    end

    Hooks:PostHook(SoundSource, "link", "BeardLibLink", function(self, object)
        self:get_data().linking = object
    end)

    Hooks:PostHook(SoundSource, "link_position", "BeardLibLinkPosition", function(self, object)
        self:get_data().linking = object
    end)

    Hooks:PostHook(SoundSource, "set_position", "BeardLibSetPosition", function(self, position)
        self:get_data().position = position
    end)

    Hooks:PostHook(SoundSource, "set_switch", "BeardLibSetSwitch", function(self, group, state)
        self:get_data().switch = {group = group, state = state}
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