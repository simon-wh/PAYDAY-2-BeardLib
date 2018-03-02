local sync_stage_settings_id = "BeardLib_sync_stage_settings"
local sync_game_settings_id = "BeardLib_sync_game_settings"
local lobby_sync_update_level_id = "BeardLib_lobby_sync_update_level_id"
local send_outfit_id = "BeardLib_check_send_outfit"

local orig_NetworkPeer_send = NetworkPeer.send

local is_custom = function()
    return managers.job:has_active_job() and (managers.job:current_level_data() and managers.job:current_level_data().custom or managers.job:current_job_data().custom)
end

local parse_as_lnetwork_string = function(type_prm, data)
	local dataString = LuaNetworking.AllPeersString:gsub("{1}", LuaNetworking.AllPeers):gsub("{2}", type_prm):gsub("{3}", data)
	return dataString
end

local peer_send_hook = "NetworkPeerSend"
Hooks:Register(peer_send_hook)

Hooks:Add(peer_send_hook, "BeardLibCustomHeistFix", function(self, func_name, params)
    if self ~= managers.network:session():local_peer() and is_custom() then
        if func_name == "sync_game_settings" or func_name == "sync_lobby_data" then
            orig_NetworkPeer_send(self, "send_chat_message", LuaNetworking.HiddenChannel, parse_as_lnetwork_string(sync_game_settings_id, BeardLib.Utils:GetJobString()))
        elseif func_name == "lobby_sync_update_level_id" then
            orig_NetworkPeer_send(self, "send_chat_message", LuaNetworking.HiddenChannel, parse_as_lnetwork_string(lobby_sync_update_level_id, Global.game_settings.level_id))
        elseif func_name == "sync_stage_settings" then
            orig_NetworkPeer_send(self, "send_chat_message", LuaNetworking.HiddenChannel, parse_as_lnetwork_string(sync_stage_settings_id, string.format("%s|%s|%s|%s", Global.game_settings.level_id, tostring(managers.job._global.current_job.current_stage), tostring(managers.job._global.alternative_stage or 0), tostring(managers.job._global.interupt_stage))))      
		elseif string.ends(func_name,"join_request_reply") then
            if params[1] == 1 then
                params[14] = BeardLib.Utils:GetJobString()
            end
        end
    end
end)

Hooks:Add(peer_send_hook, "BeardLibCustomWeaponFix", function(self, func_name, params)
    if self ~= managers.network:session():local_peer() then
        if func_name == "sync_outfit" then
			local orig_outift = params[1]
			params[1] = BeardLib.Utils:CleanOutfitString(params[1])
			orig_NetworkPeer_send(self, "send_chat_message", LuaNetworking.HiddenChannel, parse_as_lnetwork_string(send_outfit_id, orig_outift .. "|" .. params[2]))
		elseif string.ends(func_name, "set_unit") then
			params[3] = BeardLib.Utils:CleanOutfitString(params[3], params[4] == 0)
        elseif func_name == "set_equipped_weapon" then
            if params[2] == -1 then
                local index, data = BeardLib.Utils:GetCleanedWeaponData()
                params[2] = index
                params[3] = data
            end
        end
    end
end)

function NetworkPeer:send(func_name, ...)
	if not self._ip_verified then
		return
	end
	local params = table.pack(...)
    Hooks:Call(peer_send_hook, self, func_name, params)

    orig_NetworkPeer_send(self, func_name, unpack(params, 1, params.n))
end

Hooks:Add("NetworkReceivedData", lobby_sync_update_level_id, function(sender, id, data)
    if id == lobby_sync_update_level_id then
        local peer = managers.network:session():peer(sender)
        local rpc = peer and peer:rpc()
        if rpc then
            managers.network._handlers.connection:lobby_sync_update_level_id_ignore_once(data)
        end
    end
end)

Hooks:Add("NetworkReceivedData", sync_game_settings_id, function(sender, id, data)
    if id == sync_game_settings_id then
        local split_data = string.split(data, "|")
        local level_name = split_data[4]
        local job_id = split_data[1]
        local update_data = BeardLib.Utils:GetUpdateData(split_data)
        local session = managers.network:session()
        local function continue_sync()
            local peer = session:peer(sender)
            local rpc = peer and peer:rpc()
            if rpc then
                local job_index = tweak_data.narrative:get_index_from_job_id(job_id)
                local level_index = tweak_data.levels:get_index_from_level_id(split_data[2])
                local difficulty_index = tweak_data:difficulty_to_index(split_data[3])
                managers.network._handlers.connection:sync_game_settings(job_index, level_index, difficulty_index, Global.game_settings.one_down, rpc)
            end
        end
        local function disconnect()
            if managers.network:session() then
                managers.network:queue_stop_network()
                managers.platform:set_presence("Idle")
                managers.network.matchmake:leave_game()
                managers.network.voice_chat:destroy_voice(true)
                managers.menu:exit_online_menues()
            end
        end
        if tweak_data.narrative.jobs[job_id] == nil then
            if update_data then
                session._ignore_load = true
                BeardLib.Utils:DownloadMap(level_name, job_id, update_data, function(success)
                    if success then
                        continue_sync()
                        session._ignore_load = nil
                        if session._ignored_load then
                            session:ok_to_load_level(unpack(session._ignored_load))
                        end
                    else
                        disconnect()
                    end               
                end)
            else
                disconnect()
                BeardLibEditor.managers.Dialog:Show({title = managers.localization:text("mod_assets_error"), message = managers.localization:text("custom_map_cant_download"), force = true})
                return
            end
        end
        continue_sync()
    end
end)

Hooks:Add("NetworkReceivedData", sync_stage_settings_id, function(sender, id, data)
    if id == sync_stage_settings_id then
        local split_data = string.split(data, "|")
        local peer = managers.network:session():peer(sender)
        local rpc = peer and peer:rpc()
        if rpc then
            managers.network._handlers.connection:sync_stage_settings_ignore_once(tweak_data.levels:get_index_from_level_id(split_data[1]),
            tonumber(split_data[2]),
            tonumber(split_data[3]),
            tweak_data.levels:get_index_from_level_id(split_data[4]) or 0,
            rpc)
        else
            log("[ERROR] RPC is nil!")
        end
    end

end)

Hooks:Add("NetworkReceivedData", send_outfit_id, function(sender, id, data)
    if id == send_outfit_id then
        local outfit = string.split(data, "|")
        local peer = managers.network:session():peer(sender)
        if peer then
            peer:set_outfit_string(outfit[1], outfit[2], false)
        end
    end
end)


local orig_NetworkPeer_set_outfit_string = NetworkPeer.set_outfit_string

function NetworkPeer:set_outfit_string(outfit_string, outfit_version, outfit_signature)
	if outfit_signature == false then
		self._real_outfit_string = outfit_string
		return
	end

    orig_NetworkPeer_set_outfit_string(self, outfit_string, outfit_version, outfit_signature or self._signature)

    if self._real_outfit_string then

    	local old_outfit_string = self._profile.outfit_string

        local old_outfit_list = managers.blackmarket:unpack_outfit_from_string(old_outfit_string)
        local new_outfit_list = managers.blackmarket:unpack_outfit_from_string(self._real_outfit_string)

        if tweak_data.blackmarket.masks[new_outfit_list.mask.mask_id] and tweak_data.blackmarket.masks[new_outfit_list.mask.mask_id].custom then
            old_outfit_list.mask.mask_id = new_outfit_list.mask.mask_id
        end

        if tweak_data.blackmarket.textures[new_outfit_list.mask.blueprint.pattern.id] and tweak_data.blackmarket.textures[new_outfit_list.mask.blueprint.pattern.id].custom then
    		old_outfit_list.mask.blueprint.pattern.id = new_outfit_list.mask.blueprint.pattern.id
    	end

    	if tweak_data.blackmarket.materials[new_outfit_list.mask.blueprint.material.id] and tweak_data.blackmarket.materials[new_outfit_list.mask.blueprint.material.id].custom then
    		old_outfit_list.mask.blueprint.material.id = new_outfit_list.mask.blueprint.material.id
    	end

        if tweak_data.blackmarket.melee_weapons[new_outfit_list.melee_weapon] and tweak_data.blackmarket.melee_weapons[new_outfit_list.melee_weapon].custom then
            old_outfit_list.melee_weapon = new_outfit_list.melee_weapon
        end

        self._profile.outfit_string = BeardLib.Utils:OutfitStringFromList(old_outfit_list)
        
        if old_outfit_string ~= self._profile.outfit_string then
    		self:_reload_outfit()
    	end
    end

	return self._profile.outfit_string, self._outfit_version, self._signature
end
