local peer_send_hook = "NetworkPeerSend"

local SyncUtils = BeardLib.Utils.Sync
local SyncConsts = BeardLib.Constants.Sync

Hooks:Register(peer_send_hook)

Hooks:Add(peer_send_hook, "BeardLibCustomWeaponFix", function(self, func_name, params)
    if self == managers.network:session():local_peer() then
        return
    end

    if func_name == "sync_outfit" or string.ends(func_name, "set_unit") then
        SyncUtils:Send(self, SyncConsts.SendOutfit, SyncUtils:CompactOutfit() .. "|" .. SyncConsts.OutfitVersion)
        local in_lobby = self:in_lobby() and game_state_machine:current_state_name() ~= "ingame_lobby_menu" and not setup:is_unloading()
        if in_lobby then
            self:beardlib_send_modded_weapon(math.random(1, 2)) --Send a random weapon instead of based on weapon skin rarity.
        end

        local extra_outfit_string = SyncUtils:ExtraOutfitString()
        local split_number = SyncConsts.ExtraOutfitSplitSize
        local current_sub_start = 1
        local data_length = #extra_outfit_string
        local index = 0
        while current_sub_start <= data_length do
            index = index + 1
            SyncUtils:Send(self, SyncConsts.SendExtraOutfit .. "|" .. tostring(index), extra_outfit_string:sub(current_sub_start, current_sub_start + (split_number - 1)))

            current_sub_start = current_sub_start + split_number
        end

        SyncUtils:Send(self, SyncConsts.SendExtraOutfitDone, tostring(index))
    end
    if func_name == "sync_outfit" then
        params[1] = SyncUtils:CleanOutfitString(params[1])
    elseif string.ends(func_name, "set_unit") then
        params[3] = SyncUtils:CleanOutfitString(params[3], params[4] == 0)
    elseif func_name == "set_equipped_weapon" then
        if params[2] == -1 then
            local index, data, selection_index = SyncUtils:GetCleanedWeaponData(params[1])
            params[2] = index
            params[3] = data
            if params[1] == managers.player:local_player() then
                self:beardlib_send_modded_weapon(selection_index)
            end
        else
            local factory_id = PlayerInventory._get_weapon_name_from_sync_index(params[2])
            -- Don't care about npc weapons, they dont have a blueprint
            if type(factory_id) == "string" then
                local blueprint = managers.weapon_factory:unpack_blueprint_from_string(factory_id, params[3])
                local wep = tweak_data.weapon[managers.weapon_factory:get_weapon_id_by_factory_id(factory_id)]

                params[3] = managers.weapon_factory:blueprint_to_string(factory_id, SyncUtils:GetCleanedBlueprint(blueprint, factory_id))

                if wep and params[1] == managers.player:local_player() then
                    self:beardlib_send_modded_weapon(wep.use_data.selection_index)
                end
            end
        end
    end
end)

function NetworkPeer:beardlib_send_modded_weapon(selection_index)
    local wep_data = SyncUtils:GetEquippedWeapon(selection_index)
    local factory = tweak_data.weapon.factory
    local weapon = factory[wep_data.factory_id]
    local send = weapon.custom == true
    if not send then
        for _, part_id in pairs(wep_data.blueprint) do
            local part = tweak_data.weapon.factory.parts[part_id]
            if part and part.custom then
                --If the weapon has custom parts, treat it as a custom weapon.
                send = true
                break
            end
        end
    end

    if send then
        SyncUtils:Send(self, SyncConsts.SetEqippedWeapon, SyncUtils:BeardLibWeaponString(selection_index) .. "|" .. SyncConsts.WeaponVersion)
    end
end

Hooks:Add("NetworkReceivedData", SyncConsts.SendOutfit, function(sender, id, data)
    if id == SyncConsts.SendOutfit then
        local peer = managers.network:session():peer(sender)
        if peer then
            local str = string.split(data, "|")
            peer:set_outfit_string_beardlib(str[1], str[2])
        end
    end
end)

Hooks:Add("NetworkReceivedData", SyncConsts.SetEqippedWeapon, function(sender, id, data)
    if id == SyncConsts.SetEqippedWeapon then
        local peer = managers.network:session():peer(sender)
        if peer then
            if data == "" or not data then
                peer._last_beardlib_weapon_string = nil
            else
                local str = string.split(data, "|")
                local in_lobby = local_peer and local_peer:in_lobby() and game_state_machine:current_state_name() ~= "ingame_lobby_menu" and not setup:is_unloading()
                peer:set_equipped_weapon_beardlib(str[1], str[2], in_lobby) --Handled by a different event.
            end
        end
    end
end)

Hooks:Add("NetworkReceivedData", SyncConsts.SendExtraOutfit, function(sender, id, data)
    if SyncConsts.SendExtraOutfit .. "|" == id:sub(1, #SyncConsts.SendExtraOutfit + 1) then
        local section_number = tonumber(string.split(id, "|")[2])
        local peer = managers.network:session():peer(sender)
        if peer then
            peer:add_extra_outfit_string_beardlib(section_number, data)
        end
    end
end)

Hooks:Add("NetworkReceivedData", SyncConsts.SendExtraOutfitDone, function(sender, id, data)
    if id == SyncConsts.SendExtraOutfitDone then
        local section_count = tonumber(data)
        local peer = managers.network:session():peer(sender)
        if peer then
            peer:done_extra_outfit_string_beardlib(section_count)
        end
    end
end)

function NetworkPeer:set_equipped_weapon_beardlib(weapon_string, outfit_version, only_verify)
    if outfit_version ~= SyncConsts.WeaponVersion then
        return false
    end

    self._last_beardlib_weapon_string = weapon_string

    if only_verify then
        return
    end

    local weapon = SyncUtils:UnpackBeardLibWeaponString(weapon_string)
    if weapon.id then
        local id = weapon.id.."_npc"
        local fac = tweak_data.weapon.factory
        local npc_weapon = fac[id]
        if npc_weapon and DB:has(Idstring("unit"), npc_weapon.unit:id()) then
            local blueprint = clone(npc_weapon.default_blueprint)

            --Goes through each part and checks if the part can be added
            for _, part in pairs(weapon.blueprint) do
                for _, uses_part in pairs(npc_weapon.uses_parts) do
                    if CRC32Hash(uses_part) == tonumber(part) then
                        local ins = true
                        local tweak = tweak_data.weapon.factory.parts[uses_part]
                        if tweak.custom and not tweak.supports_sync then
                            BeardLib:log("Part %s does not support synching", tostring(uses_part))
                            self._last_beardlib_weapon_string = nil
                            return --This waapon has problematic parts!
                        end
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

            managers.weapon_factory:set_use_thq_weapon_parts(true) -- Force THQ if we are dealing with custom weapons.
            local in_lobby = self:in_lobby() and game_state_machine:current_state_name() ~= "ingame_lobby_menu" and not setup:is_unloading()
            if in_lobby and managers.menu_scene then
                local scene = managers.menu_scene
                local i = self._id
                local unit = scene._lobby_characters[self._id]
                if alive(unit) then
                    -- Check against cached weapon string to prevent duplicate weapon load
                    if not scene._last_beardlib_weapon_strings then
                        scene._last_beardlib_weapon_strings = {}
                    elseif scene._last_beardlib_weapon_strings[self._id] == weapon_string then
                        return true
                    end
                    scene._last_beardlib_weapon_strings[self._id] = weapon_string

                    local local_peer = managers.network:session() and managers.network:session():local_peer()
                    local rank = self == local_peer and managers.experience:current_rank() or self:rank()

                    if rank > 0 and math.random(1,5) == 1 then
                        scene:_delete_character_weapon(unit, "all")
                        scene:set_character_card(i, rank, unit)
                    else
                        local guess_id = id:gsub("_npc", "")
                        if fac[guess_id] ~= nil then
                            scene:_delete_character_weapon(unit, "all")
                            scene:_select_lobby_character_pose(i, unit, {factory_id = id:gsub("_npc", "")})
                            scene:set_character_equipped_weapon(unit, guess_id, blueprint, "primary", weapon.cosmetics)
                        end
                    end
                end
            elseif alive(self._unit) then
                local inv = self._unit:inventory()
                inv:add_unit_by_factory_name(id, true, true, managers.weapon_factory:blueprint_to_string(id, blueprint), weapon.data_split[3].cosmetics or inv:cosmetics_string_from_peer(peer, weapon.id) or "")
            end
            return true
        else
            self._last_beardlib_weapon_string = nil
            return false
        end
    else
        return false
    end
end

function NetworkPeer:set_outfit_string_beardlib(outfit_string, outfit_version)
    if outfit_version ~= SyncConsts.OutfitVersion then --Avoid sync to avoid issues.
        return
    end

    self._last_beardlib_outfit = outfit_string

    local old_outfit_string = self._profile.outfit_string

    local old_outfit = managers.blackmarket:unpack_outfit_from_string(old_outfit_string)
    local new_outfit = SyncUtils:UnpackCompactOutfit(outfit_string)
    local bm = tweak_data.blackmarket

    local mask = new_outfit.mask
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

    if bm.player_styles[new_outfit.player_style] and bm.player_styles[new_outfit.player_style].custom then
        old_outfit.player_style = new_outfit.player_style
    end

    -- First check if the outfit we are trying to find the variant for exists and has variants.
    if bm.player_styles[new_outfit.player_style] and bm.player_styles[new_outfit.player_style].material_variations then
        local suit_variation_td = bm.player_styles[new_outfit.player_style].material_variations[new_outfit.suit_variation]
        --Now check that the variant we are looking for exists and is custom.
        if suit_variation_td and suit_variation_td.custom then
            old_outfit.suit_variation = new_outfit.suit_variation
        end
    end

    if bm.gloves[new_outfit.glove_id] and bm.gloves[new_outfit.glove_id].custom then
        old_outfit.glove_id = new_outfit.glove_id
    end 

    self._profile.outfit_string = SyncUtils:OutfitStringFromList(old_outfit)
    if old_outfit_string ~= self._profile.outfit_string then
        self:_reload_outfit()
    end

    self:beardlib_reload_outfit()
end

function NetworkPeer:add_extra_outfit_string_beardlib(section_number, extra_outfit_string_section)
    self._last_beardlib_extra_outfit_sections = self._last_beardlib_extra_outfit_sections or {}
    self._last_beardlib_extra_outfit_sections[section_number] = extra_outfit_string_section

    self:check_extra_outfit_string_sections()
end

function NetworkPeer:set_extra_outfit_string_beardlib(extra_outfit_string)
    self._last_beardlib_extra_outfit = extra_outfit_string

    if extra_outfit_string then
        self._profile.beardlib_extra_outfit_string = extra_outfit_string
        self._profile.beardlib_extra_outfit_data = SyncUtils:BeardLibJSONToData(extra_outfit_string)
    end

    self:beardlib_reload_outfit()
    self:beardlib_reload_extra_outfit()
end

function NetworkPeer:done_extra_outfit_string_beardlib(section_count)
    self._last_beardlib_extra_outfit_sections = self._last_beardlib_extra_outfit_sections or {}

    self._last_beardlib_extra_outfit_section_count = section_count
    self._last_beardlib_extra_outfit_done_received = true

    self:check_extra_outfit_string_sections()
end

function NetworkPeer:check_extra_outfit_string_sections()
    if self._last_beardlib_extra_outfit_done_received then
        local extra_outfit_string_finished = true
        local extra_outfit_string = ""

        for index=1, self._last_beardlib_extra_outfit_section_count do
            local potential_section = self._last_beardlib_extra_outfit_sections[index]

            if potential_section then
                extra_outfit_string = extra_outfit_string .. potential_section
            else
                extra_outfit_string_finished = false
                break
            end
        end

        if extra_outfit_string_finished then
            self:set_extra_outfit_string_beardlib(extra_outfit_string)
            self._last_beardlib_extra_outfit_done_received = false
        end
    end
end

function NetworkPeer:beardlib_reload_outfit()
    local local_peer = managers.network:session() and managers.network:session():local_peer()
    local in_lobby = local_peer and local_peer:in_lobby() and game_state_machine:current_state_name() ~= "ingame_lobby_menu" and not setup:is_unloading()

    local scene = managers.menu_scene
    if scene and in_lobby then
        -- Set all the stuff that's part of the compact BeardLib outift manually
        -- Don't use set_lobby_character_out_fit as it will unload stuff and cause frame drops
        -- and all the other stuff has been set by the game already due to regular outfit sync
        local i = self:id()
        local unit = scene._lobby_characters[i]
        local outfit = managers.blackmarket:unpack_outfit_from_string(self._profile.outfit_string)
        scene:set_character_mask_by_id(outfit.mask.mask_id, outfit.mask.blueprint, unit, i)
        scene:set_character_armor_skin(outfit.armor_skin or "none", unit)
        scene:set_character_player_style(outfit.player_style or "none", outfit.suit_variation or "default", unit)
        scene:set_character_gloves(outfit.glove_id or "default", unit)

        if self._last_beardlib_weapon_string ~= nil then
            self:set_equipped_weapon_beardlib(self._last_beardlib_weapon_string, SyncConsts.WeaponVersion)
        end
    end

    local kit_menu = managers.menu:get_menu("kit_menu")
    if kit_menu then
        kit_menu.renderer:set_slot_outfit(self:id(), self:character(), self._profile.outfit_string)
    end

    if managers.menu_component then
        managers.menu_component:peer_outfit_updated(self:id())
    end
end

function NetworkPeer:beardlib_reload_extra_outfit()
    Hooks:Call("BeardLibExtraOutfitReload", self._unit, self:character(), self._profile.beardlib_extra_outfit_data)
end

function NetworkPeer:beardlib_extra_outfit()
    return self._profile.beardlib_extra_outfit_data or {}
end

local set_outfit_string = NetworkPeer.set_outfit_string
function NetworkPeer:set_outfit_string(...)
    local a,b,c,d,e = set_outfit_string(self, ...)

    if self._last_beardlib_outfit then
        self:set_outfit_string_beardlib(self._last_beardlib_outfit, SyncConsts.OutfitVersion)
    end

    if self._last_beardlib_extra_outfit then
        self:set_extra_outfit_string_beardlib(self._last_beardlib_extra_outfit)
    end

    return a,b,c,d,e
end
