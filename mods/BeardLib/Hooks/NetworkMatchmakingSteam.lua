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
	local is_key_valid = function(key)
		return key ~= "value_missing" and key ~= "value_pending"
	end

	if is_key_valid(lobby:key_value("custom_level_name")) then
	    if not is_key_valid(lobby:key_value("level_id")) or not is_key_valid(lobby:key_value("job_key")) then
	        local _level_index = table.index_of(tweak_data.levels._level_index, lobby:key_value("level_id"))
	        local _job_index = table.index_of(tweak_data.narrative._jobs_index, lobby:key_value("job_key"))
	        if _level_index ~= -1 or _job_index ~= -1 then
	            local level_index = _level_index == -1 and tonumber(lobby:key_value("level")) or _level_index
	            local job_index = _job_index == -1 and tonumber(lobby:key_value("job_id")) or _job_index
				log("level_index: " .. tostring(level_index))
				log("job_index: " .. tostring(job_index))
				data[1] = level_index + 1000 * job_index
			elseif is_key_valid(lobby:key_value("level_update_key")) then
				data[1] = 1001
				data["level_update_key"] = lobby:key_value("level_update_key")
				data["level_id"] = lobby:key_value("level_id")
				data["job_key"] = lobby:key_value("job_key")
				data["custom_level_name"] = lobby:key_value("custom_level_name")
			else
			 	data[1] = 0
	        end
	    end
	end
	return data
end

Hooks:PostHook(NetworkMatchMakingSTEAM, "_call_callback", "BeardLibSearchLobbyFix", function(self, name, info)
	if name == "search_lobby" then
		local attribute_list = info.attribute_list
		for i, room in ipairs(info.room_list) do
			local numbers = attribute_list[i].numbers
			if numbers.level_update_key then
				local comp = managers.menu_component
				local cmgui = comp and comp._crimenet_gui
				local state_string_id = tweak_data:index_to_server_state(numbers[4])
				local difficulty_id = numbers[2]
				local is_friend = false
				if Steam:logged_on() and Steam:friends() then
					for _, friend in ipairs(Steam:friends()) do
						if friend:id() == room.owner_id then
							is_friend = true
						end
					end
				end
				if cmgui and cmgui._jobs and cmgui._jobs[room.room_id] then
					cmgui._jobs[room.room_id].job_id = nil
					cmgui._jobs[room.room_id].level_id = nil
					local level_name = "Custom Heist: "..tostring(numbers.custom_level_name)
					comp:update_crimenet_server_job({
						room_id = room.room_id,
						id = room.room_id,
						difficulty = tweak_data:index_to_difficulty(difficulty_id),
						difficulty_id = difficulty_id,
						num_plrs = numbers[5],
						host_name = tostring(room.owner_name),
						state_name = state_string_id and managers.localization:text("menu_lobby_server_state_" .. state_string_id) or "UNKNOWN",
						state = numbers[4],
						is_friend = is_friend,
						kick_option = numbers[8],
						job_plan = numbers[10],
						mutators = numbers.mutators,
						is_crime_spree = numbers.crime_spree and 0 <= numbers.crime_spree,
						crime_spree = numbers.crime_spree,
						crime_spree_mission = numbers.crime_spree_mission,
						custom = true,
						level_name = level_name,
					})
					cmgui._jobs[room.room_id].update_key = numbers.level_update_key
					cmgui._jobs[room.room_id].level_name = level_name
				end
			end
		end
	end
end)

-- BEARDLIB API ADDITIONS --

Hooks:Add(seta_hook, "BeardLibCorrectCustomHeist", function( self, new_data, settings, ... )
	self.lobby_handler:delete_lobby_data("level_id")
	self.lobby_handler:delete_lobby_data("job_key")

	local level_index, job_index = self:_split_attribute_number(settings.numbers[1], 1000)
	local _level_id = tweak_data.levels._level_index[level_index]
	local _job_key = tweak_data.narrative._jobs_index[job_index]
	local level_id = (_level_id and tweak_data.levels[_level_id] and tweak_data.levels[_level_id].custom) and _level_id or nil
	local job_key = (_job_key and tweak_data.narrative.jobs[_job_key] and tweak_data.narrative.jobs[_job_key].custom) and _job_key or nil
	if level_id or job_key then
		local mod = BeardLib.managers.MapFramework:GetModByName(_job_key)
		--Localization might be an issue..
		table.merge(new_data, {custom_level_name = managers.localization:to_upper_text(tweak_data.levels[level_id].name_id), level_id = level_id, job_key = job_key, level_update_key = mod and mod.update_key})
	end
end)