--[[function NetworkPeer:set_xuid(xuid)
	self._xuid = ""
end]]

local sync_stage_settings_id = "BeardLib_sync_stage_settings"
local sync_game_settings_id = "BeardLib_sync_game_settings"
local send_outfit_id = "BeardLib_check_send_outfit"

local orig_NetworkPeer_send = NetworkPeer.send

local is_custom = function()
    return managers.job:has_active_job() and (managers.job:current_level_data().custom or managers.job:current_job_data().custom)
end

local get_job_string = function()
    return string.format("%s|%s|%s", managers.job:current_job_id(), Global.game_settings.level_id, Global.game_settings.difficulty)
end

local parse_as_lnetwork_string = function(type_prm, data)
	local dataString = LuaNetworking.AllPeersString
	dataString = dataString:gsub("{1}", LuaNetworking.AllPeers)
	dataString = dataString:gsub("{2}", type_prm)
	dataString = dataString:gsub("{3}", data)
	return dataString
end

function NetworkPeer:send(func_name, ...)
	if not self._ip_verified then
		return
	end
	local params = table.pack(...)
	if self ~= managers.network:session():local_peer() then
    	if string.ends(func_name,"join_request_reply") then
	        if params[1] == 1 and is_custom() then
	            params[14] = get_job_string()
	        end
	    elseif func_name == "sync_game_settings" then
	        if is_custom() then
				orig_NetworkPeer_send(self, "send_chat_message", LuaNetworking.HiddenChannel, parse_as_lnetwork_string(sync_game_settings_id, get_job_string()))
	            return
	        end
	    elseif func_name == "sync_stage_settings" then
	        if is_custom() then
				orig_NetworkPeer_send(self, "send_chat_message", LuaNetworking.HiddenChannel, parse_as_lnetwork_string(sync_stage_settings_id, string.format("%s|%s|%s|%s", Global.game_settings.level_id, tostring(self._global.current_job.current_stage), tostring(self._global.alternative_stage or 0), tostring(self._global.interupt_stage))))
	            return
	        end
		elseif func_name == "sync_outfit" then
			local orig_outift = params[1]
			params[1] = BeardLib.Utils:CleanOutfitString(params[1])
			orig_NetworkPeer_send(self, "send_chat_message", LuaNetworking.HiddenChannel, parse_as_lnetwork_string(send_outfit_id, orig_outift .. "|" .. params[2]))
		elseif string.ends(func_name, "set_unit") then
			--local orig_outift = params[3]
			params[3] = BeardLib.Utils:CleanOutfitString(params[3], params[4] == 0)
			--orig_NetworkPeer_send(self, "send_chat_message", LuaNetworking.HiddenChannel, parse_as_lnetwork_string(send_outfit_id, orig_outift .. "|" .. params[4]))
        elseif func_name == "set_equipped_weapon" then
            if params[2] == -1 then
                local index, data = BeardLib.Utils:GetCleanedWeaponData()
                params[2] = index
                params[3] = data
            end
        end
	end

    orig_NetworkPeer_send(self, func_name, unpack(params, 1, params.n))
end

Hooks:Add("NetworkReceivedData", sync_game_settings_id, function(sender, id, data)
    if id == sync_game_settings_id then
        local split_data = string.split(data, "|")
        local peer = managers.network:session():peer(sender)
        local rpc = peer and peer:rpc()
        if rpc then
            managers.network._handlers.connection:sync_game_settings(tweak_data.narrative:get_index_from_job_id(split_data[1]),
            tweak_data.levels:get_index_from_level_id(split_data[2]),
            tweak_data:difficulty_to_index(split_data[3]),
            managers.network:session():peer(sender):rpc())
        else
            log("[ERROR] RPC is nil!")
        end
    end
end)

Hooks:Add("NetworkReceivedData", sync_stage_settings_id, function(sender, id, data)
    if id == sync_stage_settings_id then
        local split_data = string.split(data, "|")
        local peer = managers.network:session():peer(sender)
        local rpc = peer and peer:rpc()
        if rpc then
            managers.network._handlers.connection:sync_stage_settings(tweak_data.narrative:get_index_from_job_id(split_data[1]),
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
        --[[managers.network._handlers.connection:sync_outfit(outfit[1],
        outfit[2],
        false,
        managers.network:session():peer(sender):rpc())]]--
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

        --[[if tweak_data.weapon.factory[new_outfit_list.primary.factory_id] and tweak_data.weapon.factory[new_outfit_list.primary.factory_id].custom then
            old_outfit_list.primary.factory_id = new_outfit_list.primary.factory_id
            old_outfit_list.primary.blueprint = new_outfit_list.primary.blueprint
        end

        if tweak_data.weapon.factory[new_outfit_list.secondary.factory_id] and tweak_data.weapon.factory[new_outfit_list.secondary.factory_id].custom then
            old_outfit_list.secondary.factory_id = new_outfit_list.secondary.factory_id
            old_outfit_list.secondary.blueprint = new_outfit_list.secondary.blueprint
        end]]--

    	self._profile.outfit_string = BeardLib.Utils:OutfitStringFromList(old_outfit_list)
    	--[[if not self._ticket_wait_response then
    		self:verify_outfit()
    	end]]--
        if old_outfit_string ~= self._profile.outfit_string then
    		self:_reload_outfit()
    	end
    	--self:_update_equipped_armor()
    	--[[if self == managers.network:session():local_peer() then
    		self:_increment_outfit_version()
    		if old_outfit_string ~= outfit_string then
    			managers.network.account:inventory_outfit_refresh()
    		end
    	else
    		self._outfit_version = outfit_version or 0
    		if outfit_signature and old_outfit_string ~= outfit_string then
    			self._signature = outfit_signature
    			self:tradable_verify_outfit(outfit_signature)
    		end
    	end]]--
    end

	return self._profile.outfit_string, self._outfit_version, self._signature
end
