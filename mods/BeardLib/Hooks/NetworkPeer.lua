local sync_stage_settings_id = "BeardLib_sync_stage_settings"
local sync_game_settings_id = "BeardLib_sync_game_settings"
local lobby_sync_update_level_id = "BeardLib_lobby_sync_update_level_id"
local send_outfit_id = "BCO" --BeardLib compact outfit
local set_equipped_weapon = "BSEW" --BeardLib set equipped weapon
local current_outfit_version = "1.0"

local NetworkPeerSend = NetworkPeer.send

local is_custom = function()
    return managers.job:has_active_job() and (managers.job:current_level_data() and managers.job:current_level_data().custom or managers.job:current_job_data().custom)
end

local parse_as_lnetwork_string = function(type_prm, data)
	local dataString = LuaNetworking.AllPeersString:gsub("{1}", LuaNetworking.AllPeers):gsub("{2}", type_prm):gsub("{3}", data)
	return dataString
end

local function SendMessage(peer, name, msg)
    NetworkPeerSend(peer, "send_chat_message", LuaNetworking.HiddenChannel, parse_as_lnetwork_string(name, msg))
end

local peer_send_hook = "NetworkPeerSend"
Hooks:Register(peer_send_hook)

Hooks:Add(peer_send_hook, "BeardLibCustomHeistFix", function(self, func_name, params)
    if self ~= managers.network:session():local_peer() and is_custom() then
        if func_name == "sync_game_settings" or func_name == "sync_lobby_data" then
            SendMessage(self, sync_game_settings_id, BeardLib.Utils:GetJobString())
        elseif func_name == "lobby_sync_update_level_id" then
            SendMessage(self, lobby_sync_update_level_id, Global.game_settings.level_id)
        elseif func_name == "sync_stage_settings" then
            local glbl = managers.job._global
            SendMessage(self, lobby_sync_update_level_id, string.format("%s|%s|%s|%s", sync_stage_settings_id, tostring(glbl.current_job.current_stage), tostring(glbl.alternative_stage or 0), tostring(glbl.interupt_stage)))
        elseif string.ends(func_name,"join_request_reply") then
            if params[1] == 1 then
                params[15] = BeardLib.Utils:GetJobString()
            end
        end
    end
end)

Hooks:Add(peer_send_hook, "BeardLibCustomWeaponFix", function(self, func_name, params)
    if self ~= managers.network:session():local_peer() then
        if func_name == "sync_outfit" or string.ends(func_name, "set_unit") then
            SendMessage(self, send_outfit_id, managers.blackmarket:compact_outfit_string() .. "|" .. current_outfit_version)
        end
        if func_name == "sync_outfit" then
            params[1] = BeardLib.Utils:CleanOutfitString(params[1])
        elseif string.ends(func_name, "set_unit") then
			params[3] = BeardLib.Utils:CleanOutfitString(params[3], params[4] == 0)
        elseif func_name == "set_equipped_weapon" then            
            if params[2] == -1 then
                local index, data, selection_index = BeardLib.Utils:GetCleanedWeaponData()
                params[2] = index
                params[3] = data
                SendMessage(self, set_equipped_weapon, managers.blackmarket:beardlib_weapon_string(selection_index) .. "|" .. current_outfit_version)
            else              
				local factory_id = PlayerInventory._get_weapon_name_from_sync_index(params[2])
				local blueprint = managers.weapon_factory:unpack_blueprint_from_string(factory_id, params[3])
				local wep = tweak_data.weapon[managers.weapon_factory:get_weapon_id_by_factory_id(factory_id)]
                
				params[3] = managers.weapon_factory:blueprint_to_string(factory_id, BeardLib.Utils:GetCleanedBlueprint(blueprint, factory_id))
				
				if wep then
					local index = wep.use_data.selection_index
					local wep_data = managers.blackmarket:beardlib_get_weapon(index)
					for _, part_id in pairs(wep_data.blueprint) do
						local part = tweak_data.weapon.factory.parts[part_id]
						if part and part.custom then
                            --If the weapon has custom parts, treat it as a custom weapon.
							SendMessage(self, set_equipped_weapon, managers.blackmarket:beardlib_weapon_string(index) .. "|" .. current_outfit_version)
							return
						end
					end
                end
                if type(factory_id) == "string" then
                    SendMessage(self, set_equipped_weapon, "")
                end
            end

		--[[
		OUTDATED CODE!
		elseif func_name == "sync_grenades" then
			params[1] = BeardLib.Utils:GetSpoofedGrenade(params[1])
			params[2] = 3
		elseif func_name == "sync_throw_projectile" then
			local projectile_i = params[4]
			if projectile_i then
				local projectile_name = tweak_data.blackmarket:get_projectile_name_from_index(projectile_i)
				if projectile_name then
					projectile_name = BeardLib.Utils:GetSpoofedGrenade(projectile_name)
					params[4] = tweak_data.blackmarket:get_index_from_projectile_id(projectile_name) or 1
				end
			end
		--]]
        end
    end
end)

function NetworkPeer:send(func_name, ...)
	if not self._ip_verified then
		return
	end
	local params = table.pack(...)
    Hooks:Call(peer_send_hook, self, func_name, params)
    NetworkPeerSend(self, func_name, unpack(params, 1, params.n))
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
        local peer = managers.network:session():peer(sender)
        if peer then
            local str = string.split(data, "|")
            peer:set_outfit_string_beardlib(str[1], str[2])
        end
    end
end)

Hooks:Add("NetworkReceivedData", set_equipped_weapon, function(sender, id, data)
    --[[if id == set_equipped_weapon then
        local peer = managers.network:session():peer(sender)
        if peer then
            if data == "" or not data then
                peer._last_beardlib_weapon_string = nil
            else
                local str = string.split(data, "|")
                peer:set_equipped_weapon_beardlib(str[1], str[2])
            end
        end
    end--]]
end)

function NetworkPeer:set_equipped_weapon_beardlib(weapon_string, outfit_version)
    if outfit_version ~= current_outfit_version then
        return
    end

	local weapon = managers.blackmarket:unpack_beardlib_weapon_string(weapon_string)
    if self._unit and weapon.id then
        local inv = self._unit:inventory()
        local id = weapon.id.."_npc"
        local fac = tweak_data.weapon.factory
        local npc_weapon = fac[id]
        if npc_weapon and DB:has(Idstring("unit"), npc_weapon.unit:id()) then
            self._last_beardlib_weapon_string = weapon_string
            local blueprint = clone(npc_weapon.default_blueprint)

            --Goes through each part and checks if the part can be added
            for _, part in pairs(weapon.blueprint) do
                for _, uses_part in pairs(npc_weapon.uses_parts) do
                    if string.key(uses_part) == part then
                        local ins = true
                        for i, blueprint_part in pairs(blueprint) do
                            if blueprint_part == uses_part then 
                                ins = false 
							elseif (fac.parts[blueprint_part] and fac.parts[uses_part]) and fac.parts[blueprint_part].type == fac.parts[uses_part].type then
                                blueprint[i] = uses_part
                                ins = false
                            end
                        end
                        if ins then
                            table.insert(blueprint, uses_part)
                        end
                        break
                    end
                end
            end
        
            inv:add_unit_by_factory_name(id, true, true, managers.weapon_factory:blueprint_to_string(id, blueprint), weapon.cosmetics or self:cosmetics_string_from_peer(peer, weapon.id))
        end
    else
        self._last_beardlib_weapon_string = nil
    end
end

function NetworkPeer:set_outfit_string_beardlib(outfit_string, outfit_version)
    if outfit_version ~= current_outfit_version then --Avoid sync to avoid issues.
        return
    end
    
    self._last_beardlib_outfit = outfit_string

    local old_outfit_string = self._profile.outfit_string

    local old_outfit = managers.blackmarket:unpack_outfit_from_string(old_outfit_string)
    local new_outfit = managers.blackmarket:unpack_compact_outfit(outfit_string)
    local bm = tweak_data.blackmarket

    local mask =new_outfit.mask 
    if bm.masks[mask.mask_id] and bm.masks[mask.mask_id].custom then
        old_outfit.mask.mask_id = new_outfit.mask.mask_id
    end

    if bm.textures[mask.blueprint.pattern.id] and bm.textures[mask.blueprint.pattern.id].custom then
        old_outfit.mask.blueprint.pattern.id = new_outfit.mask.blueprint.pattern.id
    end

    if bm.materials[mask.blueprint.material.id] and bm.materials[mask.blueprint.material.id].custom then
        old_outfit.mask.blueprint.material.id = new_outfit.mask.blueprint.material.id
    end

    if bm.melee_weapons[new_outfit.melee_weapon] and bm.melee_weapons[new_outfit.melee_weapon].custom then
        old_outfit.melee_weapon = new_outfit.melee_weapon
    end

    --[[
    local skins = tweak_data.blackmarket.weapon_skins
    local factory = tweak_data.weapon.factory
    for i=1,2 do
        local current = i == 1 and "primary" or "secondary"
        local current_new = new_outfit[current]
        local current_old = old_outfit[current]
        if current_new and current_new.factory_id then
            if current_new.cosmetics then
                if skins[current_new.cosmetics.id] and skins[current_new.cosmetics.id].custom then
                    current_old.cosmetics = current_new.cosmetics
                end
            end
            local weapon = factory[current_new.factory_id]
            local npc_weapon = factory[current_new.factory_id.."_npc"]
            if weapon and npc_weapon and weapon.custom then
                if DB:has(Idstring("unit"), npc_weapon.unit:id()) then
                    current_old.factory_id = current_new.factory_id
                    current_old.blueprint = factory[current_new.factory_id].default_blueprint
                end
            end
        end
    end--]]

    self._profile.outfit_string = BeardLib.Utils:OutfitStringFromList(old_outfit)
    
    if old_outfit_string ~= self._profile.outfit_string then
        self:_reload_outfit()
    end

    self:beardlib_reload_outfit()
end

function NetworkPeer:beardlib_reload_outfit()
	local local_peer = managers.network:session() and managers.network:session():local_peer()
    local in_lobby = local_peer and local_peer:in_lobby() and game_state_machine:current_state_name() ~= "ingame_lobby_menu" and not setup:is_unloading()

	if managers.menu_scene and in_lobby then
		managers.menu_scene:set_lobby_character_out_fit(self:id(), self._profile.outfit_string, self:rank())
	end

	local kit_menu = managers.menu:get_menu("kit_menu")

    if kit_menu then
		kit_menu.renderer:set_slot_outfit(self:id(), self:character(), self._profile.outfit_string)
    end
    
	if managers.menu_component then
		managers.menu_component:peer_outfit_updated(self:id())
    end
end

local set_outfit_string = NetworkPeer.set_outfit_string
function NetworkPeer:set_outfit_string(...)
    local a,b,c,d,e = set_outfit_string(self, ...)
    local local_peer = managers.network:session() and managers.network:session():local_peer()

    if self._last_beardlib_outfit then
        self:set_outfit_string_beardlib(self._last_beardlib_outfit, current_outfit_version)
    end

    return a,b,c,d,e
end