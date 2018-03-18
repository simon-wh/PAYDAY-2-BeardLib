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
	--Thanks for not making get functions ovk :)
    SoundSource.script = {} --Userdatas in nutshell
    function SoundSource:get_link()
        return self.script.linking
    end

    --If no position is set or is not linking to anything then we can assume it's a 2D sound.
    function SoundSource:is_relative()
        return self:get_position() == nil
    end

    function SoundSource:get_position()
        if self.script.position then
            return self.script.position 
        else
            local link = self:get_link()
            return alive(link) and link:position() or nil
        end
    end

    function SoundSource:get_switch()
        return self.script.switch
    end

    Hooks:PostHook(SoundSource, "link", "BeardLibLink", function(self, object)
        self.script.linking = object
    end)

    Hooks:PostHook(SoundSource, "link_position", "BeardLibLinkPosition", function(self, object)
        self.script.linking = object
    end)

    Hooks:PostHook(SoundSource, "set_position", "BeardLibSetPosition", function(self, position)
        self.script.position = position
    end)

    Hooks:PostHook(SoundSource, "set_switch", "BeardLibSetSwitch", function(self, group, state)
        self.script.switch = {group = group, state = state}
    end)

    SoundSource._post_event = SoundSource._post_event or SoundSource.post_event
	function SoundSource:post_event(event, ...)
		if not CustomSoundManager:CheckSoundID(event, self) then
			return self:_post_event(event, ...)
		end
	end
end