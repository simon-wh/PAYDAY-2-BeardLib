-- From: http://stackoverflow.com/questions/7183998/in-lua-what-is-the-right-way-to-handle-varargs-which-contains-nil
function table.pack(...)
  return { n = select("#", ...), ... }
end

function table.merge(og_table, new_table)
	for i, data in pairs(new_table) do
		i = type(data) == "table" and data.index or i
		if type(data) == "table" and type(og_table[i]) == "table" then
			og_table[i] = table.merge(og_table[i], data)
		else
			og_table[i] = data
		end
	end
	return og_table
end

function table.add_merge(og_table, new_table)
	for i, data in pairs(new_table) do
		i = (type(data) == "table" and data.index) or i
        if type(i) == "number" and og_table[i] then
            table.insert(og_table, data)
        else
    		if type(data) == "table" and og_table[i] then
    			og_table[i] = table.add_merge(og_table[i], data)
    		else
    			og_table[i] = data
    		end
        end
	end
	return og_table
end

function table.add(t, items)
	for i, sub_item in ipairs(items) do
		if t[i] then
			table.insert(t, sub_item)
		else
			t[i] = sub_item
		end
	end
	return t
end

function table.search(tbl, search_term)
    local search_terms = {search_term}

    if string.find(search_term, "/") then
        search_terms = string.split(search_term, "/")
    end

	local index
    for _, term in pairs(search_terms) do
        local term_parts = {term}
        if string.find(term, ";") then
            term_parts = string.split(term, ";")
        end
        local search_keys = {
            params = {}
        }
        for _, term in pairs(term_parts) do
            if string.find(term, "=") then
                local term_split = string.split(term, "=")
                search_keys.params[term_split[1]] = assert(loadstring("return " .. term_split[2]))()
				if not search_keys.params[term_split[1]] then
					BeardLib:log(string.format("[ERROR] An error occured while trying to parse the value %s", term_split[2]))
				end
            elseif not search_keys._meta then
                search_keys._meta = term
            end
        end

		local found_tbl = false
        for i, sub in ipairs(tbl) do
            if type(sub) == "table" then
                local valid = true
                if search_keys._meta and sub._meta ~= search_keys._meta then
                    valid = false
                end

                for k, v in pairs(search_keys.params) do
                    if sub[k] == nil or (sub[k] and sub[k] ~= v) then
                        valid = false
                        break
                    end
                end

                if valid then
                    if i == 1 then
                        if tbl[sub._meta] then
                            tbl[sub._meta] = sub
                        end
                    end

                    tbl = sub
					found_tbl = true
					index = i
                    break
                end
            end
        end
		if not found_tbl then
			return nil
		end
    end
	return index, tbl
end

function table.custom_insert(tbl, add_tbl, pos_phrase)
	if not pos_phrase then
		table.insert(tbl, add_tbl)
		return
	end

	if tonumber(pos_phrase) ~= nil then
		table.insert(tbl, pos_phrase, add_tbl)
	else
		local phrase_split = string.split(pos_phrase, ":")
		local i, _ = table.search(tbl, phrase_split[2])

		if not i then
			BeardLib:log(string.format("[ERROR] Could not find table for relative placement. %s", pos_phrase))
			table.insert(tbl, add_tbl)
		else
			i = phrase_split[1] == "after" and i + 1 or i
			table.insert(tbl, i, add_tbl)
		end
	end
end

local special_params = {
    "search",
	"index"
}

function table.script_merge(base_tbl, new_tbl)
    for i, sub in pairs(new_tbl) do
        if type(sub) == "table" then
            if tonumber(i) ~= nil then
                if sub.search then
                    local index, found_tbl = table.search(base_tbl, sub.search)
                    if found_tbl then
                        table.script_merge(found_tbl, sub)
                    end
                else
                    table.custom_insert(base_tbl, sub, sub.index)
					if not base_tbl[sub._meta] then
						base_tbl[sub._meta] = sub
					end
					for _, param in pairs(special_params) do
						sub[param] = nil
					end
                end
            --[[else
                if not base_tbl[i] then
                    base_tbl[i] = sub
                end]]--
            end
        elseif not table.contains(special_params, i) then
            base_tbl[i] = sub
        end
    end
end

function Hooks:RemovePostHookWithObject(object, id)
    local hooks = self._posthooks[object]
    if not hooks then
        BeardLib:log("[Error] No post hooks for object '%s' while trying to remove id '%s'", tostring(object), tostring(id))
        return
    end
    for func_i, func in pairs(hooks) do
        for override_i, override in ipairs(func.overrides) do
            if override and override.id == id then
                table.remove(func.overrides, override_i)
            end
        end
    end         
end

function Hooks:RemovePreHookWithObject(object, id)
    local hooks = self._prehooks[object]
    if not hooks then
        BeardLib:log("[Error] No pre hooks for object '%s' while trying to remove id '%s'", tostring(object), tostring(id))
        return
    end
    for func_i, func in pairs(hooks) do
        for override_i, override in ipairs(func.overrides) do
            if override and override.id == id then
                table.remove(func.overrides, override_i)
            end
        end
    end         
end

function mrotation.copy(rot)
    if rot then
        return Rotation(rot:yaw(), rot:pitch(), rot:roll())
    end
    return Rotation()
end

function mrotation.set_yaw(rot, yaw)
    return mrotation.set_yaw_pitch_roll(rot, yaw, rot:pitch(), rot:roll())
end

function mrotation.set_pitch(rot, pitch)
    return mrotation.set_yaw_pitch_roll(rot, rot:yaw(), pitch, rot:roll())
end

function mrotation.set_roll(rot, roll)
    return mrotation.set_yaw_pitch_roll(rot, rot:yaw(), rot:pitch(), roll)
end

function string.pretty2(str)
    str = tostring(str)
    return str:gsub("([^A-Z ])([A-Z])", "%1 %2"):gsub("([A-Z]+)([A-Z][^A-Z$])", "%1 %2")
end

function string.key(str)
    local ids = Idstring(str)
    local key = ids:key()
    return tostring(key)
end

function math.EulerToQuarternion(x, y, z)
    local quad = {
        math.cos(z / 2) * math.cos(y / 2) * math.cos(x / 2) + math.sin(z / 2) * math.sin(y / 2) * math.sin(x / 2),
        math.sin(z / 2) * math.cos(y / 2) * math.cos(x / 2) - math.cos(z / 2) * math.sin(y / 2) * math.sin(x / 2),
        math.cos(z / 2) * math.sin(y / 2) * math.cos(x / 2) + math.sin(z / 2) * math.cos(y / 2) * math.sin(x / 2),
        math.cos(z / 2) * math.cos(y / 2) * math.sin(x / 2) - math.sin(z / 2) * math.sin(y / 2) * math.cos(x / 2),
    }
    return quad
end

-- Doesn't produce the same output as the game. Any help on fixing that would be appreciated.
function math.QuaternionToEuler(x, y, z, w)
    local sqw = w * w
    local sqx = x * x
    local sqy = y * y
    local sqz = z * z

    local normal = math.sqrt(sqw + sqx + sqy + sqz)
    local pole_result = (x * z) + (y * w)

    if (pole_result > (0.5 * normal)) then --singularity at north pole
        local ry = math.pi/2 --heading/yaw?
        local rz = 0 --attitude/roll?
        local rx = 2 * math.atan2(x, w) --bank/pitch?
        return Rotation(rx, ry, rz)
    end

    if (pole_result < (-0.5 * normal)) then --singularity at south pole
        local ry = -math.pi/2
        local rz = 0
        local rx = -2 * math.atan2(x, w)
        return Rotation(rx, ry, rz)
    end

    local r11 = 2*(x*y + w*z)
    local r12 = sqw + sqx - sqy - sqz
    local r21 = -2*(x*z - w*y)
    local r31 = 2*(y*z + w*x)
    local r32 = sqw - sqx - sqy + sqz

    local rx = math.atan2( r31, r32 )
    local ry = math.asin ( r21 )
    local rz = math.atan2( r11, r12 )

    return Rotation(rx, ry, rz)



    --[[local yaw = math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z))
    local pitch = math.asin(2 * (w * y - z * x))
    local roll = math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y))

    return Rotation(yaw, pitch, roll)]]--
end

BeardLib.Utils = {}

_G.utils = BeardLib.Utils

function BeardLib.Utils:RefreshCurrentNode()
    local selected_node = managers.menu:active_menu().logic:selected_node()
    managers.menu:active_menu().renderer:refresh_node(selected_node)
    local selected_item = selected_node:selected_item()
    selected_node:select_item(selected_item and selected_item:name())
    managers.menu:active_menu().renderer:highlight_item(selected_item)
end

function BeardLib.Utils:CheckParamsValidty(tbl, schema)
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

function BeardLib.Utils:CheckParamValidty(func_name, vari, var, desired_type, allow_nil)
    if (var == nil and not allow_nil) or type(var) ~= desired_type then
        log(string.format("[%s] Parameter #%s, expected %s, got %s", func_name, vari, desired_type, tostring(var and type(var) or nil)))
        return false
    end

    return true
end

BeardLib.Utils.WeapConv = {
    [1] = "wpn_fps_pis_g17",
    [2] = "wpn_fps_ass_amcar"
}

function BeardLib.Utils:GetBasedOnFactoryId(id, wep)
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

function BeardLib.Utils:GetCleanedWeaponData(unit)
    local player_inv = unit and unit:inventory() or managers.player:player_unit():inventory()
    local wep = tweak_data.weapon[managers.weapon_factory:get_weapon_id_by_factory_id(player_inv:equipped_unit():base()._factory_id or player_inv:equipped_unit():name())]
    local based_on_fac = self:GetBasedOnFactoryId(nil, wep)

    local new_weap_name = based_on_fac or self.WeapConv[wep.use_data.selection_index]
    return PlayerInventory._get_weapon_sync_index(new_weap_name), managers.weapon_factory:blueprint_to_string(new_weap_name, tweak_data.weapon.factory[new_weap_name].default_blueprint)
end

function BeardLib.Utils:OutfitStringFromList(outfit, is_henchman)
    local bm = managers.blackmarket
    is_henchman = is_henchman and bm.henchman_loadout_string_from_loadout
    local str = is_henchman and bm:henchman_loadout_string_from_loadout(outfit) or bm:outfit_string_from_list(outfit)
    --Remove when overkill decides to add armor_skin to BlackMarketManager:outfit_string_from_list
    return is_henchman and str or str:gsub(outfit.armor.."%-"..outfit.armor_current.."%-"..outfit.armor_current_state, outfit.armor.."-"..outfit.armor_current.."-"..outfit.armor_current_state.."-"..outfit.armor_skin)
end

function BeardLib.Utils:CleanOutfitString(str, is_henchman)
    local bm = managers.blackmarket
    if is_henchman and not bm.unpack_henchman_loadout_string then --thx ovk for the headaches henchman beta caused me <3
        is_henchman = false
    end
    local list = (is_henchman and bm.unpack_henchman_loadout_string) and bm:unpack_henchman_loadout_string(str) or bm:unpack_outfit_from_string(str)
    if list.mask and tweak_data.blackmarket.masks[is_henchman and list.mask or list.mask.mask_id].custom then
        if is_henchman then
            list.mask = "character_locked"
        else
            list.mask.mask_id = "character_locked"
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

    if list.primary then
        local primary = is_henchman and list.primary or list.primary.factory_id
        if tweak_data.weapon.factory[primary].custom then
            local based_on = self:GetBasedOnFactoryId(primary) or self.WeapConv[2]
            if is_henchman then
                list.primary = based_on
            else
                list.primary.factory_id = based_on
                list.primary.blueprint = tweak_data.weapon.factory[list.primary.factory_id].default_blueprint
            end
        end
    end

    if not is_henchman and list.secondary then
        local secondary = list.secondary.factory_id
        if tweak_data.weapon.factory[secondary].custom then
            list.secondary.factory_id = self:GetBasedOnFactoryId(secondary) or self.WeapConv[1]
            list.secondary.blueprint = tweak_data.weapon.factory[list.secondary.factory_id].default_blueprint
        end

        if tweak_data.blackmarket.melee_weapons[list.melee_weapon].custom then
            list.melee_weapon = "weapon"
        end

        for _, weap in pairs({list.primary, list.secondary}) do
            for i, part_id in pairs(weap.blueprint) do
                if tweak_data.weapon.factory.parts[part_id] and tweak_data.weapon.factory.parts[part_id].custom then
                    table.remove(weap.blueprint, i)
                end
            end
        end
    end
    return self:OutfitStringFromList(list, is_henchman)
end

function BeardLib.Utils:GetSubValues(tbl, key)
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
    "callback"
}

function BeardLib.Utils:normalize_string_value(value)
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

function BeardLib.Utils:StringToTable(global_tbl_name, global_tbl, silent)
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

function BeardLib.Utils:RemoveAllSubTables(tbl)
    for i, sub in pairs(tbl) do
        if type(sub) == "table" then
            tbl[i] = nil
        end
    end
    return tbl
end

function BeardLib.Utils:RemoveAllNumberIndexes(tbl, shallow)
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

function BeardLib.Utils:GetNodeByMeta(tbl, meta, multi)
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

function BeardLib.Utils:GetIndexNodeByMeta(tbl, meta, multi)
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

function BeardLib.Utils:CleanCustomXmlTable(tbl, shallow)
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

function BeardLib.Utils:RemoveNonNumberIndexes(tbl)
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

function BeardLib.Utils:RemoveMetas(tbl, shallow)
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
function BeardLib.Utils:UrlEncode(str)
	if not str then
		return ""
	end

	return string.gsub(str, ".", encode_chars)
end

BeardLib.Utils.Path = {}

_G.path = BeardLib.Utils.Path
_G.Path = path

BeardLib.Utils.Path._separator_char = "/"

function BeardLib.Utils.Path:GetDirectory(path)
	if not path then return nil end
	local split = string.split(self:Normalize(path), self._separator_char)
	table.remove(split)
	return table.concat(split, self._separator_char)
end

function BeardLib.Utils.Path:GetFileName(str)
	if string.ends(str, self._separator_char) then
		return nil
	end
	str = self:Normalize(str)
	return table.remove(string.split(str, self._separator_char))
end

function BeardLib.Utils.Path:GetFileNameWithoutExtension(str)
    local filename = self:GetFileName(str)
    if not filename then
        return nil
    end

    if string.find(filename, "%.") then
        local split = string.split(filename, "%.")
        table.remove(split)
        filename = table.concat(split, ".")
    end
    return filename
end

function BeardLib.Utils.Path:GetFileExtension(str)
	local filename = self:GetFileName(str)
	if not filename then
		return nil
	end
    local ext = ""
	if string.find(filename, "%.") then
		local split = string.split(filename, "%.")
		ext = split[#split]
	end
	return ext
end

function BeardLib.Utils.Path:Normalize(str)
	if not str then return nil end

	--Clean seperators
	str = string.gsub(str, ".", {
		["\\"] = self._separator_char,
		--["/"] = self._separator_char,
	})

	str = string.gsub(str, "([%w+]/%.%.)", "")
	return str
end

function BeardLib.Utils.Path:Combine(start, ...)
	local paths = {...}
	local final_string = start
	for i, path_part in pairs(paths) do
		if string.begins(path_part, ".") then
			path_part = string.sub(path_part, 2, #path_part)
		end
		if not string.ends(final_string, self._separator_char) and not string.begins(path_part, self._separator_char) then
			final_string = final_string .. self._separator_char
		end
		final_string = final_string .. path_part
	end

	return self:Normalize(final_string)
end

BeardLib.Utils.Math = {}

function BeardLib.Utils.Math:Round(val, dp)
	local mult = 10^(dp or 0)
	local rounded = math.floor(val * mult + 0.5) / mult
	return rounded
end

BeardLib.Utils.Input = {}

function BeardLib.Utils.Input:Class() return Input:keyboard() end
function BeardLib.Utils.Input:Id(str) return str:id() end

--Keyboard
function BeardLib.Utils.Input:Down(key) return self:Class():down(self:Id(key)) end
function BeardLib.Utils.Input:Released(key) return self:Class():released(self:Id(key)) end
function BeardLib.Utils.Input:Pressed(key) return self:Class():pressed(self:Id(key)) end
function BeardLib.Utils.Input:Trigger(key, clbk) return self:Class():add_trigger(self:Id(key), SafeClbk(clbk)) end
function BeardLib.Utils.Input:RemoveTrigger(trigger) return self:Class():remove_trigger(trigger) end
function BeardLib.Utils.Input:TriggerRelease(key, clbk) return self:Class():add_release_trigger(self:Id(key), SafeClbk(clbk)) end
--Mouse
BeardLib.Utils.MouseInput = clone(BeardLib.Utils.Input)
function BeardLib.Utils.MouseInput:Class() return Input:mouse() end
--Keyboard doesn't work without Idstring however mouse works and if you don't use Idstring you can use strings like 'mouse 0' to differentiate between keyboard and mouse
--For example keyboard has the number 0 which is counted as left mouse button for mouse input, this solves it.
function BeardLib.Utils.MouseInput:Id(str) return str end

function BeardLib.Utils.Input:TriggerDataFromString(str, clbk)
    local additional_key
    local key = str
    if str:match("+") then
        local split = string.split(str, "+")
        key = split[1]
        additional_key = split[2]
    end
    return {key = key, additional_key = additional_key, clbk = clbk}
end

function BeardLib.Utils.Input:Triggered(trigger, check_mouse_too)
    if not trigger.key then
        return false
    end
    if check_mouse_too and trigger.key:match("mouse") then
        return BeardLib.Utils.MouseInput:Pressed(trigger.key)
    end
    if trigger.additional_key then
        if self:Down(trigger.key) and self:Pressed(trigger.additional_key) then
            return true
        end
    elseif self:Pressed(trigger.key) then
        return true
    end
    return false
end

function NotNil(...)
    local args = {...}
    for k, v in pairs(args) do
        if v ~= nil or k == #args then
            return v
        end
    end
end

function SimpleClbk(func, ...)
    local params = {...}
    return function(...) return func(unpack(params), ...) end
end

function SafeClbk(func, ...)
    local params = {...}
    return function(...)
        local p = {...}
        local success, ret = pcall(function() ret = func(unpack(params), unpack(p)) end)
        if not success then
            BeardLib:log("[Safe Callback Error] %s", tostring(ret.code))
            return nil
        end
        return ret
    end
end

function ClassClbk(clss, func, ...)
    return SimpleClbk(clss[func], clss, ...)
end

function Color:to_hex()
    local s = "%x"
    local result = ""
    for _, v in pairs({self.r,self.g,self.b}) do
        local hex = s:format(255*v)
        if hex:len() == 0 then
            hex = "00"
        end
        if hex:len() == 1 then
            hex = "0"..hex
        end
        result = result .. hex
    end
    return result
end

function Color:contrast(white, black)
    local col = {r = self.r, g = self.g, b = self.b}

    for k, c in pairs(col) do
        if c <= 0.03928 then 
            col[k] = c/12.92 
        else 
            col[k] = ((c+0.055)/1.055) ^ 2.4 
        end
    end
    local L = 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b
    local color = white or Color.white
    if L > 0.179 then
        color = black or Color.black 
    end
    return color
end