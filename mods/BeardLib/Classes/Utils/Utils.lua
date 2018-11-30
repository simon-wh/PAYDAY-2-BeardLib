local Utils = {}
BeardLib.Utils = Utils

function Utils:RefreshCurrentNode()
    local selected_node = managers.menu:active_menu().logic:selected_node()
    managers.menu:active_menu().renderer:refresh_node(selected_node)
    local selected_item = selected_node:selected_item()
    selected_node:select_item(selected_item and selected_item:name())
    managers.menu:active_menu().renderer:highlight_item(selected_item)
end

function Utils:CheckParamsValidty(tbl, schema)
    local ret = true
    for i = 1, #schema.params do
        local var = tbl[i]
        local sc = schema.params[i]
        if not self:CheckParamValidty(schema.func_name, i, var, sc.type, sc.allow_nil) then
            ret = false
        end
    end
    return ret
end

function Utils:CheckParamValidty(func_name, vari, var, desired_type, allow_nil)
    if (var == nil and not allow_nil) or type(var) ~= desired_type then
        log(string.format("[%s] Parameter #%s, expected %s, got %s", func_name, vari, desired_type, tostring(var and type(var) or nil)))
        return false
    end

    return true
end

function Utils:DownloadMap(level_name, job_id, udata, done_callback)
    if not udata then
        return
    end
    local msg = managers.localization:text("custom_map_needs_download", {url = udata.download_url or ""})
    QuickMenuPlus:new(managers.localization:text("custom_map_alert"), msg, {{text = "Yes", callback = function()
        local provider = ModAssetsModule._providers[udata.provider or (not udata.download_url and "modworkshop") or nil]
        local dialog = BeardLib.managers.dialog.download
        local map = DownloadCustomMap:new()
        map.provider = provider or {download_url = udata.download_url}
        map.id = udata.id
        map.steamid = Steam:userid()
        map.level_name = level_name
        map.failed_map_downloaed = SimpleClbk(done_callback, false)
        map.done_map_download = function()
            BeardLib.managers.MapFramework:Load()
            BeardLib.managers.MapFramework:RegisterHooks()
            managers.job:_check_add_heat_to_jobs()
            managers.crimenet:find_online_games(Global.game_settings.search_friends_only)
            if done_callback then
                done_callback(tweak_data.narrative.jobs[job_id] ~= nil)
            end
        end

        map:DownloadAssets()
    end},{text = "No", is_cancel_button = true, callback = function()
        if done_callback then
            done_callback(false)
        end
    end}}, {force = true})
end

function Utils:GetUpdateData(data)
    local function parse_network_str(s)
        return s ~= "null" and s or nil
    end
    local res =  {id = parse_network_str(data[5]), provider = parse_network_str(data[6]), download_url = parse_network_str(data[7])}
    return table.size(res) > 0 and res or false
end

function Utils:GetJobString()
    local level_id = Global.game_settings.level_id
    local job_id = managers.job:current_job_id()
    local level = tweak_data.levels[level_id]
    local level_name = managers.localization:to_upper_text(level and level.name_id or "")
    local mod = BeardLib.managers.MapFramework:GetMapByJobId(job_id)
    local update = mod and mod.update_module_data or {}
    local cat = table.concat({job_id, level_id, Global.game_settings.difficulty, level_name, update.id or "null", update.provider or "null", update.download_url or "null"}, "|")
    return cat
end

Utils.WeapConv = {"wpn_fps_pis_g17", "wpn_fps_ass_amcar"}

function Utils:GetBasedOnFactoryId(id, wep)
    wep = wep or tweak_data.weapon[managers.weapon_factory:get_weapon_id_by_factory_id(id)]
    local based_on
    if wep then
        based_on = wep.based_on and tweak_data.upgrades.definitions[wep.based_on]
        if based_on then
            local based_on_wep = tweak_data.weapon[wep.based_on]
            if not based_on_wep or (based_on_wep.use_data.selection_index ~= wep.use_data.selection_index) then
                based_on = nil --Unsupported!
            end
        end
    end
    return based_on and (not based_on.dlc or managers.dlc:is_dlc_unlocked(based_on.dlc)) and based_on.factory_id or nil
end

function Utils:GetCleanedWeaponData(unit)
    local player_inv = unit and unit:inventory() or managers.player:player_unit():inventory()
    local name = tostring(player_inv:equipped_unit():base()._factory_id or player_inv:equipped_unit():name())
    local is_npc = string.ends(name, "_npc")
    local wep = tweak_data.weapon[managers.weapon_factory:get_weapon_id_by_factory_id(is_npc and name:gsub("_npc", "") or name)]
    local based_on_fac = self:GetBasedOnFactoryId(nil, wep)

    local new_weap_name = (not is_npc and based_on_fac) or self.WeapConv[wep.use_data.selection_index] .. (is_npc and "_npc" or "")
    return PlayerInventory._get_weapon_sync_index(new_weap_name), managers.weapon_factory:blueprint_to_string(new_weap_name, tweak_data.weapon.factory[new_weap_name].default_blueprint)
end

function Utils:OutfitStringFromList(outfit, is_henchman)
    local bm = managers.blackmarket
    is_henchman = is_henchman and bm.henchman_loadout_string_from_loadout
    local str = is_henchman and bm:henchman_loadout_string_from_loadout(outfit) or bm:outfit_string_from_list(outfit)
     --Remove when overkill decides to add armor_skin to BlackMarketManager:outfit_string_from_list
     --Still missing :)))
    return is_henchman and str or str:gsub(outfit.armor.."%-"..outfit.armor_current.."%-"..outfit.armor_current_state, outfit.armor.."-"..outfit.armor_current.."-"..outfit.armor_current_state.."-"..outfit.armor_skin)
end

function Utils:GetCleanedBlueprint(blueprint, factory_id)
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

function Utils:GetSpoofedGrenade(grenade)
	local grenade_tweak = tweak_data.blackmarket.projectiles[grenade]
	if grenade_tweak and grenade_tweak.custom then
		return grenade_tweak.based_on or managers.blackmarket._defaults.grenade
	end
	return grenade
end

function Utils:CleanOutfitString(str, is_henchman)
    local bm = managers.blackmarket
    local factory = tweak_data.weapon.factory
    if is_henchman and not bm.unpack_henchman_loadout_string then --thx ovk for the headaches henchman beta caused me <3
        is_henchman = false
    end
    local list = (is_henchman and bm.unpack_henchman_loadout_string) and bm:unpack_henchman_loadout_string(str) or bm:unpack_outfit_from_string(str)
    local mask = list.mask and tweak_data.blackmarket.masks[is_henchman and list.mask or list.mask.mask_id]
    if mask and mask.custom then
        local based_on = mask.based_on
        local mask = tweak_data.blackmarket.masks[based_on] 
        if not mask or (mask.dlc and not managers.dlc:is_dlc_unlocked(mask.dlc)) then
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
				local melee = tweak_data.upgrades.definitions[based_on] 
				if not melee or (melee.dlc and not managers.dlc:is_dlc_unlocked(melee.dlc)) then
					based_on = nil
				end
				list.melee_weapon = based_on or "weapon"
			end

			for _, weap in pairs({list.primary, list.secondary}) do
				weap.blueprint = self:GetCleanedBlueprint(weap.blueprint, weap.factory_id)
			end
		end

		--list.grenade = self:GetSpoofedGrenade(list.grenade)
	end
	return self:OutfitStringFromList(list, is_henchman)
end

function Utils:GetSubValues(tbl, key)
    local new_tbl = {}
    for i, vals in pairs(tbl) do
        if vals[key] then
            new_tbl[i] = vals[key]
        end
    end

    return new_tbl
end

local searchTypes = {
    "Vector3",
    "Rotation",
	"Color",
	"SimpleClbk",
	"ClassClbk",
	"SafeClassClbk",
	"SafeClbk",
    "callback"
}

function Utils:normalize_string_value(value)
    if type(value) ~= "string" then
        return value
    end

	for _, search in pairs(searchTypes) do
		if string.begins(value, search) then
			value = loadstring("return " .. value)()
			break
		end
	end
	return value
end

function Utils:StringToTable(global_tbl_name, global_tbl, silent)
    local global_tbl = global_tbl or _G
    if string.find(global_tbl_name, "%.") then
        local global_tbl_split = string.split(global_tbl_name, "[.]")

        for _, str in pairs(global_tbl_split) do
            global_tbl = rawget(global_tbl, str)
            if not global_tbl then
                if not silent then
                    BeardLib:log("[ERROR] Key " .. str .. " does not exist in the current global table.")
                end
                return nil
            end
        end
    else
        global_tbl = rawget(global_tbl, global_tbl_name)
        if not global_tbl then
            if not silent then
                BeardLib:log("[ERROR] Key " .. global_tbl_name .. " does not exist in the current global table.")
            end
            return nil
        end
    end

    return global_tbl
end

function Utils:RemoveAllSubTables(tbl)
    for i, sub in pairs(tbl) do
        if type(sub) == "table" then
            tbl[i] = nil
        end
    end
    return tbl
end

function Utils:RemoveAllNumberIndexes(tbl, shallow)
	if not tbl then return nil end

    if type(tbl) ~= "table" then
        return tbl
    end

	if shallow then
		for i, sub in ipairs(tbl) do
			tbl[i] = nil
		end
	else
	    for i, sub in pairs(tbl) do
	        if tonumber(i) ~= nil then
	            tbl[i] = nil
	        elseif type(sub) == "table" and not shallow then
	            tbl[i] = self:RemoveAllNumberIndexes(sub)
	        end
	    end
	end
    return tbl
end

function Utils:GetNodeByMeta(tbl, meta, multi)
    if not tbl then return nil end
    local t = {}
    for _, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            if multi then
                table.insert(t, v)
            else
                return v
            end
        end
    end

    return multi and t or nil
end

function Utils:GetIndexNodeByMeta(tbl, meta, multi)
    if not tbl then return nil end
    local t = {}
    for i, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            if multi then
                table.insert(t, i)
            else
                return i
            end
        end
    end

    return multi and t or nil
end

function Utils:CleanCustomXmlTable(tbl, shallow)
    if not tbl then return nil end

    for i, v in pairs(tbl) do
        if type(v) == "table" then
            if tonumber(i) == nil then
                tbl[i] = nil
            elseif not shallow then
                self:CleanCustomXmlTable(v, shallow)
            end
        end
    end

    return tbl
end

function Utils:RemoveNonNumberIndexes(tbl)
	if not tbl then return nil end

    if type(tbl) ~= "table" then
        return tbl
    end

    for i, _ in pairs(tbl) do
        if tonumber(i) == nil then
            tbl[i] = nil
        end
    end

    return tbl
end

function Utils:RemoveMetas(tbl, shallow)
	if not tbl then return nil end
	tbl._meta = nil

	if not shallow then
	    for i, data in pairs(tbl) do
	        if type(data) == "table" then
	            self:RemoveMetas(data, shallow)
	        end
	    end
	end
	return tbl
end

local encode_chars = {
	["\t"] = "%09",
	["\n"] = "%0A",
	["\r"] = "%0D",
	[" "] = "+",
	["!"] = "%21",
	['"'] = "%22",
	[":"] = "%3A",
	["{"] = "%7B",
	["}"] = "%7D",
	["["] = "%5B",
	["]"] = "%5D",
	[","] = "%2C"
}
function Utils:UrlEncode(str)
	if not str then
		return ""
	end

	return string.gsub(str, ".", encode_chars)
end

function Utils:ModExists(name)
	local mod = self:FindMod(name)
	return mod and mod:IsEnabled() or false
end

function Utils:ModLoaded(name)
	return self:FindMod(name) ~= nil
end

function Utils:FindMod(name)
    for _, mod in pairs(BeardLib.Mods) do
        if mod.Name == name then
            return mod
        end
    end
    return nil
end

function NotNil(...)
    local args = {...}
    for k, v in pairs(args) do
        if v ~= nil or k == #args then
            return v
        end
    end
end

--Pretty much CoreClass.type_name with support for tables.
function type_name(value)
    local t = type(value)
    if t == "userdata" or t == "table" and value.type_name then
        return value.type_name
    end
    return t
end

--Safe call
function Utils:SetupXAudio()
    if blt and blt.xaudio then
        blt.xaudio.setup()
    end
end