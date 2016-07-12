local orig_NetworkMatchMakingSTEAM_set_attributes = NetworkMatchMakingSTEAM.set_attributes

function NetworkMatchMakingSTEAM:set_attributes(settings)
	if not self.lobby_handler then
		return
	end
	self.lobby_handler:delete_lobby_data ("level_id")
	self.lobby_handler:delete_lobby_data ("job_key")

    local level_index, job_index = self:_split_attribute_number(settings.numbers[1], 1000)
    local _level_id = tweak_data.levels._level_index[level_index]
    local _job_key = tweak_data.narrative._jobs_index[job_index]
    local level_id = (_level_id and tweak_data.levels[_level_id] and tweak_data.levels[_level_id].custom) and _level_id or nil
    local job_key = (_job_key and tweak_data.narrative.jobs[_job_key] and tweak_data.narrative.jobs[_job_key].custom) and _job_key or nil
    if job_key or level_id then
        local permissions = {
    		"public",
    		"friend",
    		"private"
    	}
		log("Added level: " .. tostring(level_id))
		log("Added narrative: " .. tostring(job_key))
    	local lobby_attributes = {
    		owner_name = managers.network.account:username_id(),
    		owner_id = managers.network.account:player_id(),
    		level = level_index,
            level_id = level_id,
    		difficulty = settings.numbers[2],
    		permission = settings.numbers[3],
    		state = settings.numbers[4] or self._lobby_attributes and self._lobby_attributes.state or 1,
    		min_level = settings.numbers[7] or 0,
    		num_players = self._num_players or 1,
    		drop_in = settings.numbers[6] or 1,
    		job_id = job_index or 0,
            job_key = job_key,
    		kick_option = settings.numbers[8] or 0,
    		job_class_min = settings.numbers[9] or 10,
    		job_class_max = settings.numbers[9] or 10,
    		job_plan = settings.numbers[10]
    	}
    	if self._BUILD_SEARCH_INTEREST_KEY then
    		lobby_attributes[self._BUILD_SEARCH_INTEREST_KEY] = "true"
    	end
    	self._lobby_attributes = lobby_attributes
    	self.lobby_handler:set_lobby_data(lobby_attributes)
    	self.lobby_handler:set_lobby_type(permissions[settings.numbers[3]])
    else
        orig_NetworkMatchMakingSTEAM_set_attributes(self, settings)
    end
end

local orig_NetworkMatchMakingSTEAM_lobby_to_numbers = NetworkMatchMakingSTEAM._lobby_to_numbers

function NetworkMatchMakingSTEAM:_lobby_to_numbers(lobby)
	log("Received level: " .. tostring(lobby:key_value("level_id")))
	log("Received narrative: " .. tostring(lobby:key_value("job_key")))
    if lobby:key_value("level_id") ~= "value_missing" or lobby:key_value("job_key") ~= "value_missing" then
        local _level_index = table.index_of(tweak_data.levels._level_index, lobby:key_value("level_id"))
        local _job_index = table.index_of(tweak_data.narrative._jobs_index, lobby:key_value("job_key"))
        if _level_index ~= -1 or _job_index ~= -1 then
            local level_index = _level_index == -1 and tonumber(lobby:key_value("level")) or _level_index
            local job_index = _job_index == -1 and tonumber(lobby:key_value("job_id")) or _job_index
			log("level_index: " .. tostring(level_index))
			log("job_index: " .. tostring(job_index))
            return {
        		level_index + 1000 * job_index,
        		tonumber(lobby:key_value("difficulty")),
        		tonumber(lobby:key_value("permission")),
        		tonumber(lobby:key_value("state")),
        		tonumber(lobby:key_value("num_players")),
        		tonumber(lobby:key_value("drop_in")),
        		tonumber(lobby:key_value("min_level")),
        		tonumber(lobby:key_value("kick_option")),
        		tonumber(lobby:key_value("job_class")),
        		tonumber(lobby:key_value("job_plan"))
        	}
        end
    end
    return orig_NetworkMatchMakingSTEAM_lobby_to_numbers(self, lobby)
end
