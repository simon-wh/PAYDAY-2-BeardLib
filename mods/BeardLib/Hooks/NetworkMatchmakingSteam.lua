-- API Calls --

local orig_NetworkMatchMakingSTEAM_set_attributes = NetworkMatchMakingSTEAM.set_attributes

local seta_hook = "BeardLibSteamLobbySetAttributes"

Hooks:Register(seta_hook)

function NetworkMatchMakingSTEAM:set_attributes(settings, ...)
	if not self.lobby_handler then
		return
	end

	orig_NetworkMatchMakingSTEAM_set_attributes(self, settings, ...)

	local new_data = {}

	Hooks:Call(seta_hook, self, new_data, settings, ...)

	if table.size(new_data) > 0 then

		table.merge(self._lobby_attributes, new_data)

	    self.lobby_handler:set_lobby_data(new_data)
	end
end

local orig_NetworkMatchMakingSTEAM_lobby_to_numbers = NetworkMatchMakingSTEAM._lobby_to_numbers

function NetworkMatchMakingSTEAM:_lobby_to_numbers(lobby, ...)
	log("Received level: " .. tostring(lobby:key_value("level_id")))
	log("Received narrative: " .. tostring(lobby:key_value("job_key")))
	local data = orig_NetworkMatchMakingSTEAM_lobby_to_numbers(self, lobby, ...)

    if lobby:key_value("level_id") ~= "value_missing" or lobby:key_value("job_key") ~= "value_missing" then
        local _level_index = table.index_of(tweak_data.levels._level_index, lobby:key_value("level_id"))
        local _job_index = table.index_of(tweak_data.narrative._jobs_index, lobby:key_value("job_key"))
        if _level_index ~= -1 or _job_index ~= -1 then
            local level_index = _level_index == -1 and tonumber(lobby:key_value("level")) or _level_index
            local job_index = _job_index == -1 and tonumber(lobby:key_value("job_id")) or _job_index
			log("level_index: " .. tostring(level_index))
			log("job_index: " .. tostring(job_index))
			data[1] = level_index + 1000 * job_index
        end
    end
	return data
end

-- BEARDLIB API ADDITIONS --

Hooks:Add(seta_hook, "BeardLibCorrectCustomHeist", function( self, new_data, settings, ... )
	self.lobby_handler:delete_lobby_data ("level_id")
	self.lobby_handler:delete_lobby_data ("job_key")

	local level_index, job_index = self:_split_attribute_number(settings.numbers[1], 1000)
	local _level_id = tweak_data.levels._level_index[level_index]
	local _job_key = tweak_data.narrative._jobs_index[job_index]
	local level_id = (_level_id and tweak_data.levels[_level_id] and tweak_data.levels[_level_id].custom) and _level_id or nil
	local job_key = (_job_key and tweak_data.narrative.jobs[_job_key] and tweak_data.narrative.jobs[_job_key].custom) and _job_key or nil
	if level_id or job_key then
		table.merge(new_data, {level_id = level_id, job_key = job_key})
	end
end)
