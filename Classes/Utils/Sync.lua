BeardLib.Utils.Sync = BeardLib.Utils.Sync or {}
local Sync = BeardLib.Utils.Sync

local sync_game_settings_id = "BeardLib_sync_game_settings"

function Sync:SyncGameSettings(peer_id)
    if Network:is_server() and managers.job:current_job_id() and Global.game_settings.level_id and Global.game_settings.difficulty and (managers.job:current_level_data().custom or managers.job:current_job_data().custom) then
        local data = self:GetJobString()
        if peer_id then
            LuaNetworking:SendToPeer(peer_id, sync_game_settings_id, data)
        else
            LuaNetworking:SendToPeers(sync_game_settings_id, data)
        end
		managers.platform:refresh_rich_presence_state()
    end
end

function Sync:DownloadMap(level_name, job_id, udata, done_callback)
    if not udata then
        return
	end
	local provider = ModAssetsModule._providers[udata.provider or "modworkshop"]
	if provider then
		local download_url = ""
		if provider.page_url then
			download_url = ModCore:GetRealFilePath(provider.page_url, {id = udata.id})
		end
		QuickDialog({
			title = managers.localization:text("custom_map_alert"),
			message = managers.localization:text("custom_map_needs_download", {url = download_url, name = level_name}),
			no = "No",
			no_callback = SimpleClbk(done_callback, false, true),
			items = {
				{"Yes", function(dialog)
					local map = DownloadCustomMap:new()
					map.provider = provider
					map.id = udata.id
					map.level_name = level_name
					map.failed_map_downloaed = SimpleClbk(done_callback, false)
					map.done_map_download = function()
						BeardLib.Frameworks.Base:Load()
						BeardLib.Frameworks.Base:RegisterHooks()
						managers.job:_check_add_heat_to_jobs()
						managers.crimenet:find_online_games(Global.game_settings.search_friends_only)
						if done_callback then
							done_callback(tweak_data.narrative.jobs[job_id] ~= nil)
						end
					end
					map:DownloadAssets()
				end},
				string.len(download_url) > 0 and {"Visit Page", function()
					if managers.network and managers.network.account and managers.network.account:is_overlay_enabled() then
						managers.network.account:overlay_activate("url", download_url)
					else
						os.execute("cmd /c start " .. download_url)
					end
				end, false} or nil
			}
		})
	elseif done_callback then
		done_callback(false)
	end
end

function Sync:GetUpdateData(data)
    local function parse_network_str(s)
        return s ~= "null" and s or nil
    end
    local res =  {id = parse_network_str(data[5]), provider = parse_network_str(data[6])}
    return table.size(res) > 0 and res or false
end

function Sync:GetJobString()
    local level_id = Global.game_settings.level_id
    local job_id = managers.job:current_job_id()
    local level = tweak_data.levels[level_id]
    local level_name = managers.localization:to_upper_text(level and level.name_id or "")
    local mod = BeardLib.Utils:GetMapByJobId(job_id)
    local update = {}
    if mod then
        local mod_assets = mod:GetModule(ModAssetsModule.type_name)
		if mod_assets and mod_assets._data then
            update = mod_assets._data
        end
    end
    local cat = table.concat({job_id, level_id, Global.game_settings.difficulty, level_name, update.id or "null", update.provider or "null"}, "|")
    return cat
end

Sync.WeapConv = {"wpn_fps_pis_g17", "wpn_fps_ass_amcar"}

function Sync:GetBasedOnFactoryId(id, wep)
    wep = wep or tweak_data.weapon[managers.weapon_factory:get_weapon_id_by_factory_id(id)]
    local based_on
    if wep then
        based_on = wep.based_on and tweak_data.upgrades.definitions[wep.based_on]
        if based_on then
            local based_on_wep = tweak_data.weapon[wep.based_on]
            if not based_on_wep then
                based_on = nil --Unsupported!
            end
        end
    end
    return based_on and (not based_on.dlc or managers.dlc:is_dlc_unlocked(based_on.dlc)) and based_on.factory_id or nil
end

function Sync:GetCleanedWeaponData(unit)
    local factory_id = alive(unit) and unit:inventory():equipped_unit():base()._factory_id

    -- This shouldn't ever happen unless something majorly fucked up
    -- In that case just return some default data to not crash anyone
    if not factory_id then
      local new_weap_name = self.WeapConv[1]
      local sync_index = PlayerInventory._get_weapon_sync_index(new_weap_name)
      local blueprint_string = managers.weapon_factory:blueprint_to_string(new_weap_name, tweak_data.weapon.factory[new_weap_name].default_blueprint)
      return sync_index, blueprint_string, 1
    end

    local is_npc = string.ends(factory_id, "_npc")
    local weap_tweak = tweak_data.weapon[managers.weapon_factory:get_weapon_id_by_factory_id(is_npc and factory_id:gsub("_npc", "") or factory_id)]
    local based_on_fac = self:GetBasedOnFactoryId(nil, weap_tweak)

    local new_weap_name = (not is_npc and based_on_fac) or self.WeapConv[weap_tweak.use_data.selection_index] .. (is_npc and "_npc" or "")
    local sync_index = PlayerInventory._get_weapon_sync_index(new_weap_name)
    local blueprint_string = managers.weapon_factory:blueprint_to_string(new_weap_name, tweak_data.weapon.factory[new_weap_name].default_blueprint)

    return sync_index, blueprint_string, weap_tweak.use_data.selection_index
end

function Sync:OutfitStringFromList(outfit, is_henchman)
    local bm = managers.blackmarket
    is_henchman = is_henchman and bm.henchman_loadout_string_from_loadout
    return is_henchman and bm:henchman_loadout_string_from_loadout(outfit) or bm:outfit_string_from_list(outfit)
end

function Sync:GetCleanedBlueprint(blueprint, factory_id)
    local new_blueprint = {}
    local factory = tweak_data.weapon.factory

    for _, part_id in pairs(blueprint) do
        local part = factory.parts[part_id]
        if part then
            if part.custom then
                local fac = factory[factory_id]
                --TODO: deal with mods that force add those parts if it becomes an issue
                if fac and part.based_on then
                    if table.contains(fac.uses_parts, part.based_on) then
                        table.insert(new_blueprint, part.based_on)
                    else --fuck lol, search for a default weapon part to replace it.
                        local fac_part = factory.parts[part.based_on]
                        for _, def_part in pairs(fac.default_blueprint) do
                            local fac_def_part = factory.parts[def_part]
                            if fac_def_part.type == fac_part.type then
                                table.insert(new_blueprint, def_part)
                                break
                            end
                        end
                    end
                end
            else
                table.insert(new_blueprint, part_id)
            end
        end
    end

    return new_blueprint
end

function Sync:GetSpoofedGrenade(grenade)
	local grenade_tweak = tweak_data.blackmarket.projectiles[grenade]
	if grenade_tweak and grenade_tweak.custom then
		return grenade_tweak.based_on or managers.blackmarket._defaults.grenade
	end
	return grenade
end

function Sync:CleanOutfitString(str, is_henchman)
    local bm = managers.blackmarket
    local factory = tweak_data.weapon.factory
    if is_henchman and not bm.unpack_henchman_loadout_string then --thx ovk for the headaches henchman beta caused me <3
        is_henchman = false
    end
    local list = (is_henchman and bm.unpack_henchman_loadout_string) and bm:unpack_henchman_loadout_string(str) or bm:unpack_outfit_from_string(str)
    local mask = list.mask and tweak_data.blackmarket.masks[is_henchman and list.mask or list.mask.mask_id]
    if mask and mask.custom then
        local based_on = mask.based_on
        local mask_tweak = tweak_data.blackmarket.masks[based_on]
        if not mask_tweak or (mask.dlc and not managers.dlc:is_dlc_unlocked(mask_tweak.dlc)) then
            based_on = nil
        end

        local mask_id = based_on or "character_locked"
        if is_henchman then
            list.mask = mask_id
        else
            list.mask.mask_id = mask_id
        end
	end

    local pattern = is_henchman and list.mask_blueprint.pattern or list.mask.blueprint.pattern
	if pattern and tweak_data.blackmarket.textures[pattern.id].custom then
		pattern.id = "no_color_no_material"
	end

    local material = is_henchman and list.mask_blueprint.material or list.mask.blueprint.material
	if material and tweak_data.blackmarket.materials[material.id].custom then
		material.id = "plastic"
    end

    if list.primary and list.primary.cosmetics then
        local cosmetic_primary = tweak_data.blackmarket.weapon_skins[list.primary.cosmetics.id]
        if cosmetic_primary and cosmetic_primary.custom then
            list.primary.cosmetics = nil
        end
    end

    if list.secondary and list.secondary.cosmetics then
        local cosmetic_secondary = tweak_data.blackmarket.weapon_skins[list.secondary.cosmetics.id]
        if cosmetic_secondary and cosmetic_secondary.custom then
            list.secondary.cosmetics = nil
        end
    end

    if list.primary then
        local primary = is_henchman and list.primary or list.primary.factory_id
    	if tweak_data.weapon.factory[primary].custom then
            local based_on = self:GetBasedOnFactoryId(primary) or self.WeapConv[2]
            if is_henchman then
                list.primary = based_on
            else
                list.primary.factory_id = based_on
                list.primary.blueprint = factory[list.primary.factory_id].default_blueprint
            end
    	end
    end

	if not is_henchman then
		if list.secondary then
			local secondary = list.secondary.factory_id
			if factory[secondary].custom then
				list.secondary.factory_id = self:GetBasedOnFactoryId(secondary) or self.WeapConv[1]
				list.secondary.blueprint = factory[list.secondary.factory_id].default_blueprint
			end

			local melee = tweak_data.blackmarket.melee_weapons[list.melee_weapon]
			if melee and melee.custom then
				local based_on = melee.based_on
				local melee_tweak = tweak_data.upgrades.definitions[based_on]
				if not melee_tweak or (melee_tweak.dlc and not managers.dlc:is_dlc_unlocked(melee_tweak.dlc)) then
					based_on = nil
				end
				list.melee_weapon = based_on or "weapon"
			end

			for _, weap in pairs({list.primary, list.secondary}) do
				weap.blueprint = self:GetCleanedBlueprint(weap.blueprint, weap.factory_id)
			end
		end

        list.grenade = self:GetSpoofedGrenade(list.grenade)
    end
	
	local skills = list.skills
	if skills then
		-- Perk deck id spoofing
		local specializations = skills and skills.specializations
		local current_specialization_index = specializations[1] and tonumber(specializations[1])
		if tweak_data.skilltree and current_specialization_index then
			local specialization_data = tweak_data.skilltree.specializations[current_specialization_index]
			if specialization_data and specialization_data.based_on and type(specialization_data.based_on) == "number" then
				-- Spoof the sent specialization id 
				list.skills.specializations[1] = tonumber(specialization_data.based_on)
			end
		end
	end
	

    local player_style = tweak_data.blackmarket.player_styles[list.player_style]
    if player_style then
        -- Got to do the checks individually, otherwise we can't have custom variations on non custom outfits.
        if player_style.custom then
            list.player_style = "continental" -- Sync an actual outfit to stop invisible bodies because of weird object sync.
        end

        if player_style.material_variations then
            local suit_variation = player_style.material_variations[list.suit_variation]
            if suit_variation and suit_variation.custom then
            	list.suit_variation = "default"
            end
        end
    end

    local gloves = tweak_data.blackmarket.gloves[list.glove_id]
    if gloves and gloves.custom then
        list.glove_id = "default"
    end

	return self:OutfitStringFromList(list, is_henchman)
end

function Sync:IsCurrentJobCustom()
    return managers.job:has_active_job() and (managers.job:current_level_data() and managers.job:current_level_data().custom or managers.job:current_job_data().custom)
end

function Sync:Send(peer, name, msg)
    LuaNetworking:SendToPeer(peer:id(), name, msg)
end

local STRING_TO_INDEX = {
	mask = 1,
	mask_color = 2,
	mask_pattern = 3,
	mask_material = 4,
	armor_skin = 5,
	primary = 6,
	primary_blueprint = 7,
	secondary = 8,
	secondary_blueprint = 9,
	melee_weapon = 10,
	primary_cosmetics = 11,
	secondary_cosmetics = 12,
	player_style = 13,
	suit_variation = 14,
	glove_id = 15
}

function Sync:UnpackCompactOutfit(outfit_string)
	local data = string.split(outfit_string or "", " ")

	local function get(type) return data[STRING_TO_INDEX[type]] end
	for k, v in pairs(data) do
		if v == "!" or v == "" then	data[k] = nil end
	end

	local outfit = {
		mask = {
			mask_id = get("mask") or self._defaults.mask,
			blueprint = {
				color = {id = get("mask_color") or "nothing"},
				pattern = {id = get("mask_pattern") or "no_color_no_material"},
				material = {id = get("mask_material") or "plastic"}
			}
		},
		armor_skin = get("armor_skin") or "none",
		primary = {factory_id = get("primary") or "wpn_fps_ass_amcar"},
		secondary = {factory_id = get("secondary") or "wpn_fps_pis_g17"},
		melee_weapon = get("melee_weapon") or self._defaults.melee_weapon,
		player_style = get("player_style") or "none",
		suit_variation = get("suit_variation") or "default",
		glove_id = get("glove_id") or "default"
	}

	for i=1,2 do
		local current = i == 1 and "primary" or "secondary"

		local blueprint_string = get(current.."_blueprint")
		local cosmetics_string = get(current.."_cosmetics")

		if blueprint_string then
			blueprint_string = string.gsub(blueprint_string, "_", " ")
			outfit[current].blueprint = managers.weapon_factory:unpack_blueprint_from_string(outfit[current].factory_id, blueprint_string)
		else
			outfit[current].blueprint = managers.weapon_factory:get_default_blueprint_by_factory_id(outfit[current].factory_id)
		end

		if cosmetics_string then
			local cosmetics_data = string.split(cosmetics_string, "-")
			local weapon_skin_id = cosmetics_data[1] or "!"
			local quality_index_s = cosmetics_data[2] or "1"
			local bonus_id_s = cosmetics_data[3] or "0"

			if weapon_skin_id ~= "!" then
				local quality = tweak_data.economy:get_entry_from_index("qualities", tonumber(quality_index_s))
				outfit[current].cosmetics = {id = weapon_skin_id, quality = quality, bonus = bonus_id_s == "1" and true or false}
			end
		end
	end

	return outfit
end

function Sync:CompactOutfit()
    local bm = managers.blackmarket

	local s = ""
	s = s .. bm:_outfit_string_mask()
	s = s .. " " .. tostring(bm:equipped_armor_skin())

	local equipped_primary = bm:equipped_primary()
	local equipped_secondary = bm:equipped_secondary()

	for i=1,2 do
		local current = i == 1 and equipped_primary or equipped_secondary
		if current then
			local str = managers.weapon_factory:blueprint_to_string(current.factory_id, current.blueprint)
			str = string.gsub(str, " ", "_")
			s = s .. " " .. current.factory_id .. " " .. str
		else
			s = s .. " " .. "!" .. " " .. "0"
		end
	end

	s = s .. " " .. tostring(bm:equipped_melee_weapon())

	for i=1,2 do
		local current = i == 1 and equipped_primary or equipped_secondary
		if current and current.cosmetics then
			local entry = tostring(current.cosmetics.id)
			local quality = tostring(tweak_data.economy:get_index_from_entry("qualities", current.cosmetics.quality) or 1)
			local bonus = current.cosmetics.bonus and "1" or "0"
			s = s .. " " .. entry .. "-" .. quality .. "-" .. bonus
		else
			s = s .. " " .. "!-1-0"
		end
	end

	s = s .. " " .. tostring(bm:equipped_player_style())
	s = s .. " " .. tostring(bm:equipped_suit_variation())
	s = s .. " " .. tostring(bm:equipped_glove_id())

	return s
end

function Sync:GetEquippedWeapon(selection_index)
    local bm = managers.blackmarket
	return selection_index == 2 and bm:equipped_primary() or bm:equipped_secondary()
end

function Sync:BeardLibWeaponString(selection_index)
	local s = ""

	local equipped = self:GetEquippedWeapon(selection_index)
	if equipped then
		local blueprint = {}
		for _, part in pairs(equipped.blueprint) do
			table.insert(blueprint, CRC32Hash(part))
		end
		s = s .. " " .. equipped.factory_id .. " " .. table.concat(blueprint, "_")
	else
		s = s .. " " .. "nil" .. " " .. "0"
	end

	if equipped and equipped.cosmetics then
		local entry = tostring(equipped.cosmetics.id)
		local quality = tostring(tweak_data.economy:get_index_from_entry("qualities", equipped.cosmetics.quality) or 1)
		local bonus = equipped.cosmetics.bonus and "1" or "0"
		s = s .. " " .. entry .. "-" .. quality .. "-" .. bonus
	else
		s = s .. " " .. "nil-1-0"
	end

	return s
end

function Sync:UnpackBeardLibWeaponString(outfit_string)
	local data = string.split(outfit_string or "", " ")

	local function get(i) return data[i] end
	for k, v in pairs(data) do
		if v == "nil" or v == "" then data[k] = nil end
	end

	local tbl = {
		id = get(1),
		blueprint = string.split(get(2), "_"),
		data_split = data
	}

	local cosmetics_string = get(3)

	if cosmetics_string then
		local cosmetics_data = string.split(cosmetics_string, "-")
		local weapon_skin_id = cosmetics_data[1] or "!"
		local quality_index_s = cosmetics_data[2] or "1"
		local bonus_id_s = cosmetics_data[3] or "0"

		if weapon_skin_id ~= "!" then
			local quality = tweak_data.economy:get_entry_from_index("qualities", tonumber(quality_index_s))
			data.cosmetics = {id = weapon_skin_id, quality = quality, bonus = bonus_id_s == "1" and true or false}
		end
	end

	return tbl
end

function Sync:BeardLibDataToJSON(data)
	data = deep_clone(data) -- Preserve the original table.

	-- Maybe handle non generic types?

	return json.encode(data)
end

function Sync:BeardLibJSONToData(json_string)
	local data = json.decode(json_string)

	-- Maybe handle non generic types?

	return data
end

function Sync:ExtraOutfit(is_henchman, henchman_index)
	local data = {}

	Hooks:Call("BeardLibExtraOutfit", data, is_henchman, henchman_index)

	return data
end

function Sync:ExtraOutfitString(is_henchman, henchman_index)
	return self:BeardLibDataToJSON(self:ExtraOutfit(is_henchman, henchman_index))
end
