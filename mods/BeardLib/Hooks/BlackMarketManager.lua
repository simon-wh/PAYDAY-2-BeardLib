
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
	secondary_cosmetics = 12
}

function BlackMarketManager:unpack_compact_outfit(outfit_string)
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
		melee_weapon = get("melee_weapon") or self._defaults.melee_weapon
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
				outfit.primary.cosmetics = {id = weapon_skin_id, quality = quality, bonus = bonus_id_s == "1" and true or false}
			end
		end
	end

	return outfit
end

function BlackMarketManager:compact_outfit_string()
	local s = ""
	s = s .. self:_outfit_string_mask()
	s = s .. " " .. tostring(self:equipped_armor_skin())

	local equipped_primary = self:equipped_primary()
	local equipped_secondary = self:equipped_secondary()

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

	s = s .. " " .. tostring(self:equipped_melee_weapon())

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

	return s
end

function BlackMarketManager:beardlib_get_weapon(selection_index)
	return selection_index == 2 and self:equipped_primary() or self:equipped_secondary()
end

function BlackMarketManager:beardlib_weapon_string(selection_index)
	local s = ""

	local equipped = self:beardlib_get_weapon(selection_index)
	if equipped then
		local blueprint = {}
		for _, part in pairs(equipped.blueprint) do
			table.insert(blueprint, string.key(part))
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

function BlackMarketManager:unpack_beardlib_weapon_string(outfit_string)
	local data = string.split(outfit_string or "", " ")

	local function get(i) return data[i] end
	for k, v in pairs(data) do
		if v == "nil" or v == "" then data[k] = nil end
	end

	return {
		id = get(1) or "wpn_fps_ass_amcar",
		blueprint = string.split(get(2), "_"),
		cosmetics = get(3)
	}
end