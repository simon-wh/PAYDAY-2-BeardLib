--[[

    Maintenance by Cpone (Cpone#8463 on Discord).
    Don't spam Luffy or whatever about this shite, this is all mine.

]]

local F = table.remove(RequiredScript:split("/"))
local Hooks = Hooks

if F == "blackmarkettweakdata" then
	Hooks:PostHook(BlackMarketTweakData, "init", "BeardLibInitGloves", function(self, tweak_data)
		-- Move default gloves to the the player style tweak data because it makes more sense there, plus it'll allow variants to override them.

		for player_style_id, glove_id in pairs(self.suit_default_gloves) do
			local player_style_td = self.player_styles[player_style_id]
			local glove_td = self.gloves[glove_id]

			if player_style_td and glove_td then
				player_style_td.default_glove_id = player_style_td.default_glove_id or glove_id
			end
		end

		for index, player_style_id in pairs(self.glove_adapter.player_style_exclude_list) do
			local player_style_td = self.player_styles[player_style_id]

			if player_style_td then
				player_style_td.glove_adapter = false
			end
		end
	end)
elseif F == "glovestweakdata" then
	function BlackMarketTweakData:get_glove_value(glove_id, character_name, key, player_style, material_variation)
		if key == nil then
			return
		end

		glove_id = glove_id or "default"

		if glove_id == "default" then
			glove_id = tweak_data.blackmarket:get_suit_variation_value(player_style, material_variation, character_name, "default_glove_id")
			if glove_id == nil then
				glove_id = tweak_data.blackmarket:get_player_style_value(player_style, character_name, "default_glove_id")
			end

			if glove_id == false then
				return false
			end
		end

		local data = self.gloves[glove_id or "default"]
		if data == nil then
			return nil
		end

		character_name = CriminalsManager.convert_old_to_new_character_workname(character_name)
		local character_value = data.characters and data.characters[character_name] and data.characters[character_name][key]

		if character_value ~= nil then
			return character_value
		end

		local tweak_value = data and data[key]
		return tweak_value
	end

	function BlackMarketTweakData:get_glove_variation_value(glove_id, glove_variation, character_name, key, player_style, material_variation)
		if key == nil then
			return
		end

		glove_id = glove_id or "default"
		glove_variation = glove_variation or "default"

		if glove_id == "default" then
			glove_id = tweak_data.blackmarket:get_suit_variation_value(player_style, material_variation, character_name, "default_glove_id")
			if glove_id == nil then
				glove_id = tweak_data.blackmarket:get_player_style_value(player_style, character_name, "default_glove_id")
			end

			glove_variation = tweak_data.blackmarket:get_suit_variation_value(player_style, material_variation, character_name, "default_glove_variation")
			if glove_variation == nil then
				glove_variation = tweak_data.blackmarket:get_player_style_value(player_style, character_name, "default_glove_variation") or "default"
			end

			if glove_id == false then
				return false
			end
		end

		local data = self.gloves[glove_id or "default"]
		local variation_data = data and data.variations and data.variations[glove_variation]

		if variation_data == nil then
			return nil
		end

		character_name = CriminalsManager.convert_old_to_new_character_workname(character_name)
		local character_variations = data.characters and data.characters[character_name] and data.characters[character_name].variations
		local character_value = character_variations and character_variations[glove_variation] and character_variations[glove_variation][key]

		if character_value ~= nil then
			return character_value
		end

		local tweak_value = variation_data and variation_data[key]
		return tweak_value
	end

	function BlackMarketTweakData:have_glove_variations(glove_id)
		local data = self.gloves[glove_id]

		if not data then
			return false
		end

		local variation_data = data.variations
		if not variation_data then
			return false
		end

		local num_variations = table.size(variation_data)
		if num_variations == 0 then
			return false
		end

		if num_variations == 1 and variation_data.default then
			return false
		end

		return true
	end

	function BlackMarketTweakData:get_glove_variations_sorted(glove_id)
		local data = self.gloves[glove_id]

		if not data then
			return {}
		end

		local variations = {
			"default"
		}

		if data.variations then
			for id, _ in pairs(data.variations) do
				if id ~= "default" then
					table.insert(variations, id)
				end
			end
		end

		local x_prio, y_prio
		table.sort(variations, function(x, y)
			if x == "default" then
				return true
			end

			if y == "default" then
				return false
			end

			x_prio = data.variations[x].prio or 1
			y_prio = data.variations[y].prio or 1

			if x_prio ~= y_prio then
				return x_prio < y_prio
			end

			return y < x
		end)

		return variations
	end
elseif F == "criminalsmanager" then
	Hooks:PostHook(CriminalsManager, "_create_characters", "BeardLibCreateCharacters", function(self)
		for _, character_data in ipairs(self._characters) do
			character_data.extra_visual_state = {}
		end
	end)

	Hooks:PostHook(CriminalsManager, "update_character_visual_state", "BeardLibUpdateCharacterVisualState", function(self, character_name, visual_state)
		local character = self:character_by_name(character_name)
		if not character or not character.taken or not alive(character.unit) then return end

		visual_state = visual_state or {}
		local unit = character.unit
		local is_local_peer = visual_state.is_local_peer or character.visual_state.is_local_peer or false
		local visual_seed = visual_state.visual_seed or character.visual_state.visual_seed or CriminalsManager.get_new_visual_seed()

		local mask_id = visual_state.mask_id or character.visual_state.mask_id

		local armor_id = visual_state.armor_id or character.visual_state.armor_id or "level_1"
		local armor_skin = visual_state.armor_skin or character.visual_state.armor_skin or "none"

		local player_style = self:active_player_style() or managers.blackmarket:get_default_player_style()
		local suit_variation = nil

		local user_player_style = visual_state.player_style or character.visual_state.player_style or managers.blackmarket:get_default_player_style()
		if not self:is_active_player_style_locked() and user_player_style ~= managers.blackmarket:get_default_player_style() then
			player_style = user_player_style
			suit_variation = visual_state.suit_variation or character.visual_state.suit_variation or "default"
		end

		local glove_id = visual_state.glove_id or character.visual_state.glove_id or managers.blackmarket:get_default_glove_id()
		local glove_variation = visual_state.glove_variation or character.extra_visual_state.glove_variation or "default"

		local beardlib_character_visual_state = {
			is_local_peer = is_local_peer,
			visual_seed = visual_seed,
			player_style = player_style,
			suit_variation = suit_variation,
			glove_id = glove_id,
			glove_variation = glove_variation,
			mask_id = mask_id,
			armor_id = armor_id,
			armor_skin = armor_skin
		}

		local function get_value_string(value)
			return is_local_peer and tostring(value) or "third_" .. tostring(value)
		end

		local function get_player_style_value(value, fallback)
			if player_style then
				local value_string = get_value_string(value)
				local output = tweak_data.blackmarket:get_suit_variation_value(player_style, suit_variation, character_name, value_string)
				if output == nil then
					output = tweak_data.blackmarket:get_player_style_value(player_style, character_name, value_string)

					if output == nil then
						output = fallback
					end
				end

				return output
			end
		end

		local function get_glove_value(value, fallback)
			if glove_id then
				local output = tweak_data.blackmarket:get_glove_variation_value(glove_id, glove_variation, character_name, value, player_style, suit_variation)
				if output == nil then
					output = tweak_data.blackmarket:get_glove_value(glove_id, character_name, value, player_style, suit_variation)

					if output == nil then
						output = fallback
					end
				end

				return output
			end
		end

		local unit_name = get_player_style_value("unit")
		if unit_name then
			self:safe_load_asset(character, unit_name, "player_style")
		end

		local glove_unit_name = get_glove_value("unit")
		if glove_unit_name then
			self:safe_load_asset(character, glove_unit_name, "glove_id")
		end

		CriminalsManager.set_beardlib_character_visual_state(unit, character_name, beardlib_character_visual_state)

		character.extra_visual_state = character.extra_visual_state or {}
		character.extra_visual_state.glove_variation = glove_variation
	end)

	function CriminalsManager.set_beardlib_character_visual_state(unit, character_name, visual_state)
		if not alive(unit) then return end
		if _G.IS_VR and unit:camera() then return end

		local is_local_peer = visual_state.is_local_peer
		local visual_seed = visual_state.visual_seed
		local player_style = visual_state.player_style
		local suit_variation = visual_state.suit_variation
		local glove_id = visual_state.glove_id
		local glove_variation = visual_state.glove_variation
		local mask_id = visual_state.mask_id
		local armor_id = visual_state.armor_id
		local armor_skin = visual_state.armor_skin

		if unit:camera() and alive(unit:camera():camera_unit()) and unit:camera():camera_unit():damage() then
			unit = unit:camera():camera_unit()
		end

		local unit_damage = unit:damage()
		if not unit_damage then return end

		if unit:inventory() and unit:inventory().mask_visibility and not unit:inventory():mask_visibility() then
			mask_id = nil
		end

		local function run_sequence_safe(sequence, sequence_unit)
			if not sequence then
				return
			end

			local sequence_unit_damage = (sequence_unit or unit):damage()

			if sequence_unit_damage and sequence_unit_damage:has_sequence(sequence) then
				sequence_unit_damage:run_sequence_simple(sequence)
			end
		end

		local function get_value_string(value)
			return is_local_peer and tostring(value) or "third_" .. tostring(value)
		end

		local function get_player_style_value(value, check_third, fallback)
			local value_string = check_third and get_value_string(value) or value
			local output = tweak_data.blackmarket:get_suit_variation_value(player_style, suit_variation, character_name, value_string)
			if output == nil then
				output = tweak_data.blackmarket:get_player_style_value(player_style, character_name, value_string)

				if output == nil then
					output = fallback
				end
			end

			return output
		end

		local function get_gloves_value(value, check_third, fallback)
			local value_string = check_third and get_value_string(value) or value

			local output = tweak_data.blackmarket:get_glove_variation_value(glove_id, glove_variation, character_name, value_string, player_style, suit_variation)
			if output == nil then
				output = tweak_data.blackmarket:get_glove_value(glove_id, character_name, value_string, player_style, suit_variation)

				if output == nil then
					output = fallback
				end
			end

			return output
		end

		local body_replacement = get_player_style_value("body_replacement", true, {})
		local gloves_unit_name = get_gloves_value("unit", false)
		local replace_character_hands = gloves_unit_name or gloves_unit_name == false and body_replacement.hands

		unit_damage:set_variable("var_head_replace", body_replacement.head and 1 or 0)
		unit_damage:set_variable("var_body_replace", body_replacement.body and 1 or 0)
		unit_damage:set_variable("var_hands_replace", replace_character_hands and 1 or 0)
		unit_damage:set_variable("var_arms_replace", body_replacement.arms and 1 or 0)
		unit_damage:set_variable("var_vest_replace", body_replacement.vest and 1 or 0)
		unit_damage:set_variable("var_armor_replace", body_replacement.armor and 1 or 0)

		local material_sequence = managers.blackmarket:character_sequence_by_character_name(character_name)
		run_sequence_safe(material_sequence)

		if not is_local_peer then
			local armor_sequence = tweak_data.blackmarket.armors[armor_id] and tweak_data.blackmarket.armors[armor_id].sequence
			run_sequence_safe(armor_sequence)
		end

		local mask_data = tweak_data.blackmarket.masks[mask_id]
		if not is_local_peer and mask_data then
			if mask_data.skip_mask_on_sequence then
				run_sequence_safe(managers.blackmarket:character_mask_off_sequence_by_character_name(character_name))
			else
				run_sequence_safe(managers.blackmarket:character_mask_on_sequence_by_character_name(character_name))
			end
		end

		local spawn_manager = unit:spawn_manager()
		if spawn_manager then
			-- Player Style
			spawn_manager:remove_unit("char_mesh")

			local unit_name = get_player_style_value("unit", true)
			local char_mesh_unit = nil
			if unit_name then
				spawn_manager:spawn_and_link_unit("_char_joint_names", "char_mesh", unit_name)
				char_mesh_unit = spawn_manager:get_unit("char_mesh")
			end

			if alive(char_mesh_unit) then
				char_mesh_unit:unit_data().original_material_config = char_mesh_unit:material_config()

				local unit_sequence = get_player_style_value("sequence", false)
				if unit_sequence then
					run_sequence_safe(unit_sequence, char_mesh_unit)
				end

				local variation_material_config = get_player_style_value("material", true)
				local wanted_config_ids = variation_material_config and Idstring(variation_material_config) or char_mesh_unit:unit_data().original_material_config

				if wanted_config_ids and char_mesh_unit:material_config() ~= wanted_config_ids then
					managers.dyn_resource:change_material_config(wanted_config_ids, char_mesh_unit, true)
				end

				char_mesh_unit:set_enabled(unit:enabled())
			end

			-- Gloves
			spawn_manager:remove_unit("char_gloves")

			local char_gloves_unit = nil
			if gloves_unit_name then
				spawn_manager:spawn_and_link_unit("_char_joint_names", "char_gloves", gloves_unit_name)
				char_gloves_unit = spawn_manager:get_unit("char_gloves")
			end

			if alive(char_gloves_unit) then
				char_gloves_unit:unit_data().original_material_config = char_gloves_unit:material_config()

				local unit_sequence = get_gloves_value("sequence", false)
				if unit_sequence then
					run_sequence_safe(unit_sequence, char_gloves_unit)
				end

				local variation_material_config = get_gloves_value("material", true)
				local wanted_config_ids = variation_material_config and Idstring(variation_material_config) or char_gloves_unit:unit_data().original_material_config

				if wanted_config_ids and char_gloves_unit:material_config() ~= wanted_config_ids then
					managers.dyn_resource:change_material_config(wanted_config_ids, char_gloves_unit, true)
				end

				char_gloves_unit:set_enabled(unit:enabled())
			end

			-- Glove Adapter
			spawn_manager:remove_unit("char_glove_adapter")

			local default_adapter_data = tweak_data.blackmarket.glove_adapter

			local gloves_adapter_data = get_gloves_value("glove_adapter", false)
			local player_style_adapter_data = get_player_style_value("glove_adapter", false)

			local final_adapter_data = deep_clone(default_adapter_data)

			if gloves_adapter_data == false then
				final_adapter_data = false
			elseif player_style_adapter_data == false then
				final_adapter_data = false
			else
				table.merge(final_adapter_data, gloves_adapter_data or player_style_adapter_data or {})
			end

			if final_adapter_data then
				unit:spawn_manager():spawn_and_link_unit("_char_joint_names", "char_glove_adapter", final_adapter_data.unit)

				local glove_adapter_unit = unit:spawn_manager():get_unit("char_glove_adapter")

				if alive(glove_adapter_unit) then
					local new_character_name = CriminalsManager.convert_old_to_new_character_workname(character_name)

					run_sequence_safe(final_adapter_data.character_sequence[new_character_name], glove_adapter_unit)

					local material_td_name = is_local_peer and "material" or "third_material"
					if final_adapter_data[material_td_name] then
						glove_adapter_unit:unit_data().original_material_config = glove_adapter_unit:material_config()
						local material_config = final_adapter_data[material_td_name]
						local wanted_config_ids = material_config and Idstring(material_config) or glove_adapter_unit:unit_data().original_material_config

						if wanted_config_ids and glove_adapter_unit:material_config() ~= wanted_config_ids then
							managers.dyn_resource:change_material_config(wanted_config_ids, glove_adapter_unit, true)
						end
					end
				end
			end
		end

		if unit:interaction() then
			unit:interaction():refresh_material()
		end

		if unit:contour() then
			unit:contour():update_materials()
		end
	end
elseif F == "menuarmourbase" then
	function MenuArmourBase:set_gloves(glove_id, glove_variation)
		self._glove_id = glove_id
		self._glove_variation = glove_variation

		self:request_cosmetics_update()
	end

	function MenuArmourBase:glove_variation()
		return self._glove_variation
	end

	function MenuArmourBase:_apply_beardlib_cosmetics()
		if self._applying_cosmetics then
			call_on_next_update(callback(self, self, "_apply_beardlib_cosmetics"))

			return
		end

		local old_cosmetics = self._cosmetics
		local new_cosmetics = deep_clone(old_cosmetics)
		new_cosmetics.applied = false
		new_cosmetics.loading = false
		new_cosmetics.loaded = false

		local units = new_cosmetics.unit
		local material_configs = new_cosmetics.material_config
		local textures = new_cosmetics.texture

		local visual_state = new_cosmetics.state
		visual_state.glove_variation = self._glove_variation

		local function get_player_style_value(value)
			local output = tweak_data.blackmarket:get_suit_variation_value(visual_state.player_style, visual_state.suit_variation, visual_state.character_name, value)
			if output == nil then
				output = tweak_data.blackmarket:get_player_style_value(visual_state.player_style, visual_state.character_name, value)
			end

			return output
		end

		local player_style_name = get_player_style_value("third_unit")
		if player_style_name then
			self:_add_asset(units, player_style_name)
		end

		local material_variation_name = get_player_style_value("third_material")
		if material_variation_name then
			self:_add_asset(material_configs, material_variation_name)
		end

		local function get_glove_value(value)
			local output = tweak_data.blackmarket:get_glove_variation_value(visual_state.glove_id, visual_state.glove_variation, visual_state.character_name, value, visual_state.player_style, visual_state.suit_variation)
			if output == nil then
				output = tweak_data.blackmarket:get_glove_value(visual_state.glove_id, visual_state.character_name, value, visual_state.player_style, visual_state.suit_variation)
			end

			return output
		end

		local glove_unit_name = get_glove_value("unit")
		if glove_unit_name then
			self:_add_asset(units, glove_unit_name)
		end

		local glove_material_name = get_player_style_value("third_material")
		if glove_material_name then
			self:_add_asset(material_configs, glove_material_name)
		end

		if table.size(new_cosmetics.unit) > 0 or table.size(new_cosmetics.material_config) > 0 or table.size(new_cosmetics.texture) > 0 then
			self:execute_callbacks("assets_to_load", new_cosmetics)
		end

		self._applying_cosmetics = true
		self._cosmetics = new_cosmetics
		self._old_cosmetics = old_cosmetics

		self:_load_cosmetic_assets(self._cosmetics)
	end

	Hooks:PostHook(MenuArmourBase, "_apply_cosmetics","BeardLibApplyCosmetics", function(self, clbks)
		self:_apply_beardlib_cosmetics()
	end)

	Hooks:PostHook(MenuArmourBase, "update_character_visuals", "BeardLibUpdateCharacterVisuals", function(self, cosmetics)
		local visual_state = cosmetics and cosmetics.state or {}
		local character_name = visual_state.character_name or self._character_name
		local character_visual_state = {
			is_local_peer = false,
			visual_seed = self._visual_seed,
			player_style = visual_state.player_style or "none",
			suit_variation = visual_state.suit_variation or "default",
			glove_id = visual_state.glove_id or managers.blackmarket:get_default_glove_id(),
			glove_variation = visual_state.glove_variation or "default",
			mask_id = visual_state.mask or self._mask_id,
			armor_id = visual_state.armor or "level_1",
			armor_skin = visual_state.armor_skin or "none"
		}

		CriminalsManager.set_beardlib_character_visual_state(self._unit, character_name, character_visual_state)
	end)
elseif F == "menuscenemanager" then
	Hooks:PostHook(MenuSceneManager, "_set_character_equipment", "BeardLibSetCharacterEquipmentGloveVars", function(self)
		local unit = self._character_unit

		if not alive(unit) then
			return
		end

		local glove_id, glove_variation
		if self._henchmen_player_override then
			local loadout = managers.blackmarket:henchman_loadout(self._henchmen_player_override)
			glove_id = loadout.glove_id 
			glove_variation = loadout.glove_variation
		else
			glove_id = managers.blackmarket:equipped_glove_id()
			glove_variation = managers.blackmarket:get_glove_variation()
		end

		self:set_character_gloves_and_variation(glove_id, glove_variation, unit)
	end)

	Hooks:PostHook(MenuSceneManager, "set_henchmen_loadout", "BeardLibSetHenchmanLoadoutGloveVars", function(self, index, character, loadout)
		loadout = loadout or managers.blackmarket:henchman_loadout(index)
		self:set_character_gloves_and_variation(loadout.glove_id, loadout.glove_variation, self._henchmen_characters[index])
	end)

	Hooks:PostHook(MenuSceneManager, "set_lobby_character_out_fit", "BeardlibSetLobbyGloveVars", function(self, i, outfit_string, rank)
		if managers.network:session() then
			local peer = managers.network:session():peer(i)
			if not peer then return end

			local outfit = managers.blackmarket:unpack_outfit_from_string(outfit_string)
			local extra_outfit = peer:beardlib_extra_outfit()

			local glove_id = outfit and outfit.glove_id
			local glove_variation = extra_outfit and extra_outfit.glove_variation

			if glove_id and glove_variation then
				local unit = self._lobby_characters[i]
				self:set_character_gloves_and_variation(glove_id, glove_variation, unit)
			end
		end
	end)

	Hooks:PostHook(MenuSceneManager, "on_set_preferred_character", "BeardLibOnSetPreferredCharacterGloveVars", function(self)
		self:set_character_gloves_and_variation(managers.blackmarket:equipped_glove_id(), managers.blackmarket:get_glove_variation(), self._character_unit)
	end)

	Hooks:PostHook(MenuSceneManager, "on_close_infamy_menu", "BeardLibOnCloseInfamyMenuGloveVars", function(self)
		if _G.IS_VR then
			self:set_character_gloves_and_variation(managers.blackmarket:equipped_glove_id(), managers.blackmarket:get_glove_variation(), self._character_unit)
		end
	end)

	Hooks:PostHook(MenuSceneManager, "remove_gloves", "BeardLibRemoveGlovesGloveVars", function(self)
		if _G.IS_VR then
			self:set_character_gloves_and_variation(managers.blackmarket:equipped_glove_id(), managers.blackmarket:get_glove_variation(), self._character_unit)
		end
	end)

	Hooks:PostHook(MenuSceneManager, "set_character_gloves", "BeardLibSetGlovesGloveVars", function(self, glove_id, unit)
		local glove_variation = managers.blackmarket:get_glove_variation(glove_id) or "default"
		if self._henchmen_player_override then
			local loadout = managers.blackmarket:henchman_loadout(self._henchmen_player_override)
			glove_variation = loadout.glove_variation or "default"
		end

		self:set_character_gloves_and_variation(glove_id, glove_variation, unit)
	end)

	function MenuSceneManager:set_character_gloves_and_variation(glove_id, material_variation, unit)
		unit = unit or self._character_unit

		if not alive(unit) or not unit:base() then
			return
		end

		unit:base():set_gloves(glove_id, material_variation)
	end

	function MenuSceneManager:preview_gloves_and_variation(glove_id, glove_variation, unit, clbks)
		unit = unit or self._character_unit

		self:set_character_gloves_and_variation(glove_id, glove_variation, unit)
	end

	function MenuSceneManager:get_glove_variation(unit)
		return (unit or self._character_unit):base():glove_variation()
	end
elseif F == "blackmarketmanager" then
	Hooks:PostHook(BlackMarketManager, "_load_done", "BeardLibLoadDoneGloveVars", function(self)
		if managers.menu_scene then
			managers.menu_scene:set_character_gloves_and_variation(self:equipped_glove_id(), self:get_glove_variation())
		end
	end)

	Hooks:PostHook(BlackMarketManager, "_setup_gloves", "BeardLibSetupGloves", function(self)
		local gloves = Global.blackmarket_manager.gloves
		local stored_variations = nil

		for glove_id, data in pairs(tweak_data.blackmarket.gloves) do
			gloves[glove_id] = Global.blackmarket_manager.gloves and Global.blackmarket_manager.gloves[glove_id] or {}
			gloves[glove_id].unlocked = gloves[glove_id].unlocked or data.unlocked or false

			gloves[glove_id].equipped_material_variation = gloves[glove_id].equipped_material_variation or "default"
			stored_variations = gloves[glove_id].variations or {}
			gloves[glove_id].variations = {}

			for var_id, var_data in pairs(data.variations or {}) do
				gloves[glove_id].variations[var_id] = stored_variations[var_id] or {}
				gloves[glove_id].variations[var_id].unlocked = gloves[glove_id].variations[var_id].unlocked or var_data.unlocked or var_data.auto_aquire and gloves[player_style].unlocked or false
			end

			gloves[glove_id].variations.default = {
				unlocked = true
			}
		end
	end)

	function BlackMarketManager:_is_glove_id_valid(glove_id)
		local tweak_data = tweak_data.blackmarket.gloves[glove_id]
		local glowobal_bmm = Global.blackmarket_manager.gloves[glove_id]

		return (tweak_data and glowobal_bmm) and true or false
	end

	function BlackMarketManager:_is_glove_variation_valid(glove_id, variation)
		if not self:_is_glove_id_valid(glove_id) then
			return false
		end

		variation = variation or "default"

		local glowobal_bmm = Global.blackmarket_manager.gloves[glove_id].variations and Global.blackmarket_manager.gloves[glove_id].variations[variation]
		if variation ~= "default" then
			local tweak_data = tweak_data.blackmarket.gloves[glove_id].variations and tweak_data.blackmarket.gloves[glove_id].variations[variation]
			return (tweak_data and glowobal_bmm) and true or false
		end

		return glowobal_bmm and true or false
	end

	function BlackMarketManager:_is_player_style_valid(player_style)
		local tweak_data = tweak_data.blackmarket.player_styles[player_style]
		local glowobal_bmm = Global.blackmarket_manager.player_styles[player_style]

		return (tweak_data and glowobal_bmm) and true or false
	end

	function BlackMarketManager:_is_suit_variation_valid(player_style, material_variation)
		if not self:_is_player_style_valid(player_style) then
			return false
		end

		material_variation = material_variation or "default"

		local glowobal_bmm = Global.blackmarket_manager.player_styles[player_style].material_variations[material_variation]
		if material_variation ~= "default" then
			if not tweak_data.blackmarket.player_styles[player_style].material_variations then
				return false
			end
			local tweak_data = tweak_data.blackmarket.player_styles[player_style].material_variations[material_variation]
			return (tweak_data and glowobal_bmm) and true or false
		end

		return glowobal_bmm and true or false
	end

	function BlackMarketManager:glove_variation_unlocked(glove_id, variation)
		if not self:_is_glove_variation_valid(glove_id, variation) then
			return false
		end

		variation = variation or "default"

		if variation == "default" then
			return self:glove_id_unlocked(glove_id)
		end

		return Global.blackmarket_manager.gloves[glove_id].variations[variation].unlocked and true or false
	end

	function BlackMarketManager:set_glove_variation(glove_id, variation, loading)
		glove_id = glove_id or self:equipped_glove_id()

		if self:glove_variation_unlocked(glove_id, variation) then
			Global.blackmarket_manager.gloves[glove_id].equipped_variation = variation

			if not loading and (glove_id == self:equipped_glove_id() or glove_id == (managers.menu_scene and managers.menu_scene:get_glove_id())) then
				if managers.menu_scene then
					managers.menu_scene:set_character_gloves_and_variation(glove_id, variation)
				end

				MenuCallbackHandler:_update_outfit_information()
			end

			return true
		end

		return false
	end

	function BlackMarketManager:get_glove_variation(glove_id)
		glove_id = glove_id or self:equipped_glove_id()

		return self:_is_glove_id_valid(glove_id) and Global.blackmarket_manager.gloves[glove_id].equipped_variation or "default"
	end

	function BlackMarketManager:get_glove_variations()
		local glove_variations = {}

		for glove_id, data in pairs(Global.blackmarket_manager.gloves) do
			glove_variations[glove_id] = data.equipped_variation
		end

		return glove_variations
	end

	function BlackMarketManager:set_glove_variations(glove_variations, loading)
		local equipped_glove_id = self:equipped_glove_id()
		local equipped_variation, variation

		for glove_id, data in pairs(Global.blackmarket_manager.gloves) do
			variation = glove_variations[glove_id] or "default"
			data.equipped_variation = glove_variations[glove_id]

			if glove_id == equipped_glove_id then
				equipped_variation = glove_variations[glove_id]
			end
		end

		if not loading and equipped_glove_id and equipped_variation then
			if managers.menu_scene then
				managers.menu_scene:set_character_gloves_and_variation(equipped_glove_id, equipped_variation)
			end

			MenuCallbackHandler:_update_outfit_information()
		end
	end

	function BlackMarketManager:get_all_glove_variations(glove_id)
		glove_id = glove_id or self:equipped_glove_id()

		if not self:_is_glove_id_valid(glove_id) then
			return {}
		end

		return tweak_data.blackmarket:get_glove_variations_sorted(glove_id)
	end

	function BlackMarketManager:view_gloves_and_variation(glove_id, glove_variation, done_cb)
		local resources = {}
		local character_name = managers.menu_scene:get_character_name()
		local player_style = managers.menu_scene:get_player_style()
		local suit_variation = managers.menu_scene:get_suit_variation()

		local function get_glove_value(value)
			local output = tweak_data.blackmarket:get_glove_variation_value(glove_id, glove_variation, character_name, value, player_style, suit_variation)
			if output == nil then
				output = tweak_data.blackmarket:get_glove_value(glove_id, character_name, value, player_style, suit_variation)
			end

			return output
		end

		local unit_name = get_glove_value("unit")
		if unit_name then
			if type_name(unit_name) ~= "Idstring" then
				unit_name = Idstring(unit_name)
			end

			table.insert(self._preloading_list, {load_me = {name = unit_name}})
			resources[unit_name:key()] = {name = unit_name}
		end

		if not next(resources) then
			managers.menu_scene:preview_gloves_and_variation(glove_id, glove_variation)
			if done_cb then done_cb() end

			return
		end

		table.insert(self._preloading_list, {"gloves", resources})
		table.insert(self._preloading_list, {
			done_cb = function () managers.menu_scene:preview_gloves_and_variation(glove_id, glove_variation) end
		})

		if done_cb then
			table.insert(self._preloading_list, {done_cb = done_cb})
		end
	end

	function BlackMarketManager:on_aquired_glove_variation(glove_id, glove_variation)
		glove_variation = glove_variation or "default"
		if glove_variation == "default" then return end

		if not self:_is_glove_variation_valid(glove_id, glove_variation) then
			return
		end

		Global.blackmarket_manager.gloves[glove_id].variations[glove_variation].unlocked = true
	end

	function BlackMarketManager:on_unaquired_glove_variation(glove_id, glove_variation)
		glove_variation = glove_variation or "default"
		if glove_variation == "default" then return end

		if not self:_is_glove_variation_valid(glove_id, glove_variation) then
			return
		end

		Global.blackmarket_manager.gloves[glove_id].variations[glove_variation].unlocked = tweak_data.blackmarket.gloves[glove_id].unlocked or false

		if self:get_glove_variation(glove_id) == glove_variation then
			self:set_glove_variation("default")
		end
	end

	Hooks:PostHook(BlackMarketManager, "_verify_dlc_items", "BeardLibVerifyDLCGloveVariations", function(self)
		local achievement, glove_tweak, glove_variation_tweak, glove_variation_dlc

		for glove_id, glove_data in pairs(Global.blackmarket_manager.gloves or {}) do
			glove_tweak = tweak_data.blackmarket.gloves[glove_id]

			for variation_id, variation_data in pairs(glove_data.variations or {}) do
				glove_variation_tweak = variation_id ~= "default" and glove_tweak.variations and glove_tweak.variations[variation_id]
				glove_variation_dlc = glove_variation_tweak and not glove_variation_tweak.unlocked and (glove_variation_tweak.dlc or managers.dlc:global_value_to_dlc(glove_variation_tweak.global_value))

				if glove_variation_dlc and not managers.dlc:is_dlc_unlocked(glove_variation_dlc) then
					variation_data.unlocked = false

					if glove_data.equipped_variation == variation_id and glove_data.unlocked then
						glove_data.equipped_variation = "default"
					end
				end

				if variation_data.unlocked and variation_id ~= "default" then
					glove_variation_tweak = glove_tweak.variations and glove_tweak.variations[variation_id]
					achievement = glove_variation_tweak and glove_variation_tweak.locks and glove_variation_tweak.locks.achievement

					if achievement and managers.achievment:get_info(achievement) and not managers.achievment:get_info(achievement).awarded then
						variation_data.unlocked = false
					end
				end
			end
		end
	end)
elseif F == "blackmarketgui" then
	Hooks:PostHook(BlackMarketGui, "_setup", "BeardLibSetupBMG", function(self, is_start_page, component_data)
		local BTNS = {
			hnd_customize = {
				btn = "BTN_Y",
				name = "bm_menu_btn_customize_gloves",
				prio = 2,
				pc_btn = "menu_modify_item",
				callback = callback(self, self, "customize_glove_callback")
			},
			hnd_mod_equip = {
				btn = "BTN_A",
				prio = 1,
				name = "bm_menu_btn_equip_suit_variation",
				callback = callback(self, self, "equip_glove_variation_callback")
			},
			hnd_mod_preview = {
				btn = "BTN_STICK_R",
				name = "bm_menu_btn_preview_suit_variation",
				prio = 2,
				pc_btn = "menu_preview_item",
				callback = callback(self, self, "preview_glove_variation_callback")
			}
		}

		for btn, data in pairs(BTNS) do
			data.callback = callback(self, self, "overridable_callback", {
				button = btn,
				callback = data.callback
			})
		end

		for btn, btn_data in pairs(BTNS) do
			local new_btn = BlackMarketGuiButtonItem:new(self._buttons, btn_data, 10)
			self._btns[btn] = new_btn
		end

		-- Refresh the buttons for any new buttons.
		if self._selected_slot then
			self:show_btns(self._selected_slot)
		end
	end)

	Hooks:PostHook(BlackMarketGui, "populate_gloves", "BeardLibPopulateGloves", function(self, data)
		for i = 1, #data do
			local new_data = data[i]

			if type(new_data) == "table" and new_data.name then
				local glove_id = new_data.name

				local allow_customize = not data.customize_equipped_only or new_data.equipped
				local have_glove_variations = tweak_data.blackmarket:have_glove_variations(glove_id)

				if have_glove_variations then
					if allow_customize then
						table.insert(new_data, "hnd_customize")
					end

					new_data.mini_icons = {}
					table.insert(new_data.mini_icons, {
						texture = "guis/dlcs/trd/textures/pd2/blackmarket/paintbrush_icon",
						top = 5,
						h = 16,
						layer = 1,
						w = 16,
						blend_mode = "add",
						right = 5,
						alpha = allow_customize and 0.8 or 0.4
					})

					local glove_data = tweak_data.blackmarket.gloves[glove_id]
					local variations = glove_data and glove_data.variations or {}

					if glove_data and glove_data.force_icon then
						new_data.bitmap_texture = glove_data.force_icon
					end

					if allow_customize then
						local equipped_glove_variation = managers.blackmarket:get_glove_variation(glove_id) or "default"
						if data.henchman_index then
							local loadout = managers.blackmarket:henchman_loadout(data.henchman_index)
							equipped_glove_variation = loadout.glove_variation or "default"
						end

						local glove_variation_data = variations[equipped_glove_variation]

						if glove_variation_data then

							local texture_path
							if glove_variation_data.force_icon then
								texture_path = glove_variation_data.force_icon
							else
								local guis_catalog = "guis/"
								local bundle_folder = glove_variation_data and glove_variation_data.texture_bundle_folder or glove_data.texture_bundle_folder

								if bundle_folder then
									guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
								end

								texture_path = guis_catalog .. "textures/pd2/blackmarket/icons/gloves/" .. glove_id .. "_" .. equipped_glove_variation
							end

							new_data.bitmap_texture = texture_path
						end
					end
				end

				data[i] = new_data
			end
		end
	end)

	function BlackMarketGui:populate_glove_variations(data)
		for i = 1, #data do
			data[i] = nil
		end

		local glove_id = data.prev_node_data.name
		local glove_data = tweak_data.blackmarket.gloves[glove_id]
		local variations = glove_data and glove_data.variations or {}

		local achievement_locked_content_gloves = managers.dlc:achievement_locked_content().gloves or {}

		local mannequin_glove_variation = managers.menu_scene and managers.menu_scene:get_glove_variation() or "default"
		local equipped_glove_variation = data.glove_variation or managers.blackmarket:get_glove_variation(glove_id)

		local new_data, allow_preview, guis_catalog, bundle_folder, texture_path, glove_variation, glove_variation_data
		local sort_data = managers.blackmarket:get_all_glove_variations(glove_id)

		local max_items = self:calc_max_items(#sort_data, data.override_slots)
		for i = 1, max_items do
			new_data = {
				comparision_data = nil,
				category = "glove_variation",
				slot = i
			}
			glove_variation = sort_data[i]

			if glove_variation then
				allow_preview = true
				glove_variation_data = variations[glove_variation]
				guis_catalog = "guis/"
				bundle_folder = glove_variation_data and glove_variation_data.texture_bundle_folder or glove_data.texture_bundle_folder

				if bundle_folder then
					guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
				end

				new_data.name = glove_variation
				new_data.name_localized = glove_variation_data and managers.localization:text(glove_variation_data.name_id) or managers.localization:text("menu_default")
				new_data.global_value = glove_variation_data and glove_variation_data.global_value or "normal"

				new_data.unlocked = managers.blackmarket:glove_variation_unlocked(glove_id, glove_variation)
				new_data.equipped = equipped_glove_variation == glove_variation

				new_data.lock_color = self:get_lock_color(new_data)
				if glove_variation_data.force_icon then
					texture_path = glove_variation_data.force_icon
				else
					texture_path = guis_catalog .. "textures/pd2/blackmarket/icons/gloves/" .. glove_id .. "_" .. glove_variation
				end

				new_data.bitmap_texture = texture_path
				local is_dlc_locked = not managers.dlc:is_global_value_unlocked(new_data.global_value)

				-- Inherit the locked status of the parent gloves.
				new_data.unlocked = data.prev_node_data.unlocked
				new_data.lock_texture = data.prev_node_data.lock_texture
				new_data.dlc_locked = data.prev_node_data.dlc_locked

				if data.prev_node_data.unlocked then
					if is_dlc_locked then
						new_data.unlocked = false
						new_data.lock_texture = self:get_lock_icon(new_data, "guis/textures/pd2/lock_dlc")
						new_data.dlc_locked = tweak_data.lootdrop.global_values[new_data.global_value] and tweak_data.lootdrop.global_values[new_data.global_value].unlock_id or "bm_menu_dlc_locked"
					elseif managers.dlc:is_content_infamy_locked("gloves", glove_id) and not new_data.unlocked then
						new_data.lock_texture = "guis/textures/pd2/lock_infamy"
						new_data.dlc_locked = "menu_infamy_lock_info"
					elseif not new_data.unlocked then
						local achievement = glove_variation_data and glove_variation_data.locks and glove_variation_data.locks.achievement
						if glove_variation == "default" then
							local glove_achievement_lock_id = achievement_locked_content_gloves[glove_id]
							local dlc_tweak = glove_achievement_lock_id and tweak_data.dlc[glove_achievement_lock_id]
							achievement = dlc_tweak and dlc_tweak.achievement_id
						end

						if achievement and managers.achievment:get_info(achievement) and not managers.achievment:get_info(achievement).awarded then
							local achievement_visual = tweak_data.achievement.visual[achievement]
							new_data.lock_texture = "guis/textures/pd2/lock_achievement"
							new_data.dlc_locked = achievement_visual and achievement_visual.desc_id or "achievement_" .. tostring(achievement) .. "_desc"
						else
							new_data.lock_texture = "guis/textures/pd2/skilltree/padlock"
						end
					end
				end

				if new_data.unlocked then
					if not new_data.equipped then
						table.insert(new_data, "hnd_mod_equip")
					end
				else
					new_data.bitmap_locked_color = Color.white
					new_data.bitmap_locked_blend_mode = "normal"
					new_data.bitmap_locked_alpha = 0.4
					local dlc_data = Global.dlc_manager.all_dlc_data[new_data.global_value]

					if dlc_data and dlc_data.app_id and not dlc_data.external and not managers.dlc:is_dlc_unlocked(new_data.global_value) then
						table.insert(new_data, "bw_buy_dlc")
					end
				end

				if allow_preview and mannequin_glove_variation ~= glove_variation then
					table.insert(new_data, "hnd_mod_preview")
				end
			else
				new_data.name = "empty"
				new_data.name_localized = ""
				new_data.unlocked = true
				new_data.equipped = false
			end

			table.insert(data, new_data)
		end
	end

	function BlackMarketGui:_preview_gloves_and_variation(glove_id, glove_variation, done_clbk)
		managers.blackmarket:view_gloves_and_variation(glove_id, glove_variation, done_clbk)
	end

	function BlackMarketGui.glove_variation_info_text(slot_data, updated_texts, bmg_self)
		local glove_id = bmg_self._data.prev_node_data.name
		local glove_tweak = tweak_data.blackmarket.gloves[glove_id]
		local glove_variation = slot_data.name
		local glove_variation_tweak = glove_tweak.variations[glove_variation]
		updated_texts[1].text = slot_data.name_localized

		if not slot_data.unlocked then
			updated_texts[2].text = "##" .. managers.localization:to_upper_text("bm_menu_item_locked") .. "##"
			updated_texts[2].resource_color = tweak_data.screen_colors.important_1
			updated_texts[3].text = slot_data.dlc_locked and managers.localization:to_upper_text(slot_data.dlc_locked) or managers.localization:to_upper_text("bm_menu_dlc_locked")
		end

		local desc_id = glove_variation_tweak and glove_variation_tweak.desc_id or "menu_default"
		local desc_colors = {}
		updated_texts[4].text = desc_id and managers.localization:text(desc_id) or ""

		if slot_data.global_value and slot_data.global_value ~= "normal" then
			local gvalue_tweak = tweak_data.lootdrop.global_values[slot_data.global_value]

			if gvalue_tweak.desc_id then
				updated_texts[4].text = updated_texts[4].text .. "\n##" .. managers.localization:to_upper_text(gvalue_tweak.desc_id) .. "##"

				table.insert(desc_colors, gvalue_tweak.color)
			end
		end

		if #desc_colors == 1 then
			updated_texts[4].resource_color = desc_colors[1]
		else
			updated_texts[4].resource_color = desc_colors
		end
	end

	function BlackMarketGui:customize_glove_callback(data)
		local function open_node_clbk()
			local new_node_data = {}

			table.insert(new_node_data, {
				name = "bm_menu_glove_variations",
				on_create_func_name = "populate_glove_variations",
				category = "glove_variations",
				override_slots = {
					3,
					3
				},
				identifier = BlackMarketGui.identifiers.custom,
				prev_node_data = data,
			})

			new_node_data.custom_update_text_info = BlackMarketGui.glove_variation_info_text
			new_node_data.topic_id = "bm_menu_glove_variations"
			new_node_data.panel_grid_w_mul = 0.6
			new_node_data.skip_blur = true
			new_node_data.use_bgs = true
			new_node_data.hide_detection_panel = true
			new_node_data.prev_node_data = data

			managers.menu:open_node("blackmarket_outfit_customize_node", {
				new_node_data
			})
		end

		local glove_id = data.name
		local glove_variation = managers.blackmarket:get_glove_variation(glove_id)

		self:_preview_gloves_and_variation(glove_id, glove_variation, open_node_clbk)
	end

	Hooks:PostHook(BlackMarketGui, "equip_gloves_callback", "BeardLibBMGEquipGloves", function(self, data)
		local glove_id = data.name
		local glove_variation = managers.blackmarket:get_glove_variation(glove_id)

		managers.blackmarket:set_glove_variation(glove_id, glove_variation)
	end)

	function BlackMarketGui:equip_glove_variation_callback(data)
		local glove_id = self._data.prev_node_data.name
		local glove_variation = data.name

		managers.blackmarket:set_glove_variation(glove_id, glove_variation)
		self:reload()
	end

	Hooks:PostHook(BlackMarketGui, "preview_gloves_callback", "BeardLibBMGEquipGloves", function(self, data)
		local glove_id = data.name
		local glove_variation = managers.blackmarket:get_glove_variation(glove_id)

		self:_preview_gloves_and_variation(glove_id, glove_variation, callback(self, self, "reload"))
	end)

	function BlackMarketGui:preview_glove_variation_callback(data)
		local glove_id = self._data.prev_node_data.name
		local glove_variation = data.name

		self:_preview_gloves_and_variation(glove_id, glove_variation, callback(self, self, "reload"))
	end
elseif F == "dlcmanager" then
	-- Just do our unlocking first, and then kill them off so the vanilla DLC check doesn't try and unlock them.

	Hooks:PreHook(GenericDLCManager, "give_dlc_package", "BeardLibGiveDLCGlovesVariations", function(self)
		for package_id, data in pairs(tweak_data.dlc) do
			if self:is_dlc_unlocked(package_id) and not Global.dlc_save.packages[package_id] then
				local loot_drops = data.content.loot_drops or {}

				for index, loot_drop in ipairs(loot_drops) do
					local loot_drop = #loot_drop > 0 and loot_drop[math.random(#loot_drop)] or loot_drop

					if loot_drop.type_items == "glove_variations" then
						managers.blackmarket:on_aquired_glove_variation(loot_drop.item_entry[1], loot_drop.item_entry[2])

						loot_drops[index] = nil
					end
				end
			end
		end
	end)

	Hooks:PreHook(GenericDLCManager, "give_missing_package", "BeardLibGiveMissingDLCGlovesVariations", function(self)
		for package_id, data in pairs(tweak_data.dlc) do
			if package_id ~= "freed_old_hoxton" then
				if Global.dlc_save.packages[package_id] and self:is_dlc_unlocked(package_id) then
					local loot_drops = data.content and data.content.loot_drops or {}

					for index, loot_drop in ipairs(loot_drops) do
						local check_loot_drop = #loot_drop == 0

						if check_loot_drop and loot_drop.type_items == "glove_variations" then
							if not managers.blackmarket:glove_variation_unlocked(loot_drop.item_entry[1], loot_drop.item_entry[2]) then
								managers.blackmarket:on_aquired_glove_variation(loot_drop.item_entry[1], loot_drop.item_entry[2])
							end

							loot_drops[index] = nil
						end
					end
				end
			end
		end
	end)
elseif F == "infamymanagernew" then
	function InfamyManager:reward_glove_variations(global_value, category, glove_id, glove_variation)
		managers.blackmarket:on_aquired_glove_variation(glove_id, glove_variation)
	end
elseif F == "multiprofilemanager" then
	Hooks:PostHook(MultiProfileManager, "save_current", "BeardLibMPMSaveGloveVariants", function(self)
		self._global._profiles[self._global._current_profile].glove_variations = managers.blackmarket:get_glove_variations()
	end)

	Hooks:PostHook(MultiProfileManager, "load_current", "BeardLibMPMLoadGloveVariants", function(self)
		local profile = self:current_profile()
		managers.blackmarket:set_glove_variations(profile.glove_variations or {})
	end)
elseif F == "crewmanagementgui" then
	-- I'm sorry, but overkill dumbness means I have to, ;-; 
	function CrewManagementGui:open_suit_menu(henchman_index)
		local loadout = managers.blackmarket:henchman_loadout(henchman_index)
		local new_node_data = {
			category = "suits"
		}

		self:create_pages(new_node_data, henchman_index, "player_style", loadout.player_style, 3, 3, 1, "bm_menu_player_styles")

		new_node_data[1].mannequin_player_style = loadout.player_style
		new_node_data.category = "gloves"

		self:create_pages(new_node_data, henchman_index, "glove", loadout.glove_id, 3, 3, 1, "bm_menu_gloves")

		new_node_data[2].mannequin_glove_id = loadout.glove_id
		new_node_data.category = "suits"
		new_node_data.hide_detection_panel = true
		new_node_data.character_id = managers.menu_scene:get_henchmen_character(henchman_index) or managers.blackmarket:preferred_henchmen(henchman_index)
		new_node_data.custom_callback = {
			trd_equip = callback(self, self, "select_player_style", henchman_index),
			trd_customize = callback(self, self, "open_suit_customize_menu", henchman_index),
			hnd_equip = callback(self, self, "select_glove", henchman_index),
			hnd_customize = callback(self, self, "open_glove_customize_menu", henchman_index)
		}
		new_node_data.skip_blur = true
		new_node_data.use_bgs = true
		new_node_data.panel_grid_w_mul = 0.6

		managers.environment_controller:set_dof_distance(10, false)
		managers.menu_scene:remove_item()

		new_node_data.topic_id = "bm_menu_player_styles"
		new_node_data.topic_params = {
			weapon_category = managers.localization:text("bm_menu_player_styles")
		}
		new_node_data.back_callback = callback(MenuCallbackHandler, MenuCallbackHandler, "reset_henchmen_player_override")

		managers.menu_scene:set_henchmen_player_override(henchman_index)
		managers.menu:open_node("blackmarket_outfit_node", {
			new_node_data
		})
	end

	function CrewManagementGui:open_glove_customize_menu(henchman_index, data)
		local function open_node_clbk()
			local loadout = managers.blackmarket:henchman_loadout(henchman_index)
			local new_node_data = {
				category = "glove_variations"
			}
			local selected_tab = self:create_pages(new_node_data, henchman_index, "custom", loadout.glove_variation, 3, 3, 1)
			new_node_data[1].prev_node_data = data
			new_node_data.selected_tab = selected_tab
			new_node_data.hide_detection_panel = true
			new_node_data.character_id = managers.menu_scene:get_henchmen_character(henchman_index) or managers.blackmarket:preferred_henchmen(henchman_index)
			new_node_data.custom_callback = {
				hnd_mod_equip = callback(self, self, "select_glove_variation", henchman_index)
			}
			new_node_data.prev_node_data = data
			new_node_data.skip_blur = true
			new_node_data.use_bgs = true
			new_node_data.panel_grid_w_mul = 0.6
			new_node_data.custom_update_text_info = BlackMarketGui.glove_variation_info_text
			new_node_data.topic_id = "bm_menu_glove_variations"
			new_node_data.topic_params = {
				weapon_category = managers.localization:text("bm_menu_glove_variations")
			}

			managers.menu:open_node("blackmarket_outfit_customize_node", {
				new_node_data
			})
		end

		local loadout = managers.blackmarket:henchman_loadout(henchman_index)
		local glove_id = loadout.glove_id
		local glove_variation = loadout.glove_variation

		managers.blackmarket:view_gloves_and_variation(glove_id, glove_variation, open_node_clbk)
	end

	function CrewManagementGui:select_glove_variation(index, data, gui)
		local loadout = managers.blackmarket:henchman_loadout(index)
		loadout.glove_variation = data.name

		managers.menu_scene:set_character_gloves_and_variation(loadout.glove_id, loadout.glove_variation)
		gui:reload()
	end

	function CrewManagementGui:populate_glove_variations(henchman_index, data, gui)
		local loadout = managers.blackmarket:henchman_loadout(henchman_index)
		data.glove_variation = loadout.glove_variation or "default"

		gui:populate_glove_variations(data)
	end

	Hooks:PostHook(CrewManagementGui, "select_glove", "BeardLibSelectCrewGlove", function(self, index, data, gui)
		local loadout = managers.blackmarket:henchman_loadout(index)
		loadout.glove_variation = "default"

		managers.menu_scene:set_character_gloves_and_variation(loadout.glove_id, loadout.glove_variation)
	end)

	Hooks:PostHook(CrewManagementGui, "populate_gloves", "BeardLibPopulateCrewGloves", function(self, henchman_index, data, gui)
		data.customize_equipped_only = true
		data.henchman_index = henchman_index

		gui:populate_gloves(data)

		data.mannequin_glove_id = nil
	end)
elseif F == "networkpeer" then
	Hooks:Add("BeardLibExtraOutfit", "BeardLibGloveVariantsExtraOutfit", function(data, is_henchman, henchman_index)
		if is_henchman then
			local loadout = managers.blackmarket:henchman_loadout(henchman_index)
			data.glove_variation = loadout.glove_variation or "default"
		else
			data.glove_variation = managers.blackmarket:get_glove_variation() or "default"
		end
	end)

	NetworkPeer._pre_beardlib_update_character_visual_state = NetworkPeer._pre_beardlib_update_character_visual_state or NetworkPeer.update_character_visual_state
	function NetworkPeer:update_character_visual_state(visual_state)
		if managers.criminals and alive(self._unit) then
			local outfit_loaded = self:is_outfit_loaded()
			if outfit_loaded then
				local extra_outfit = self:beardlib_extra_outfit()
				local complete_outfit = self:blackmarket_outfit()

				visual_state = visual_state or {}

				local glove_variation = "default"
				if tweak_data.blackmarket.gloves[complete_outfit.glove_id] and tweak_data.blackmarket.gloves[complete_outfit.glove_id].variations then
					if tweak_data.blackmarket.gloves[complete_outfit.glove_id].variations[extra_outfit.glove_variation] then
						glove_variation = extra_outfit.glove_variation
					end
				end

				visual_state.glove_variation = glove_variation
			end
		end

		self:_pre_beardlib_update_character_visual_state(visual_state)
	end
elseif F == "groupaistatebase" then
	local ids_unit = Idstring("unit")
	Hooks:PostHook(GroupAIStateBase, "set_unit_teamAI", "BeardLibSetUnitTeamAIGloveVars", function(self, unit, character_name, team_id, visual_seed, loadout)
		local character = managers.criminals:character_by_name(character_name)
		if not character then
			return
		end

		local player_style = loadout and loadout.player_style or managers.blackmarket:get_default_player_style()
		local suit_variation = loadout and loadout.suit_variation or "default"
		local glove_id = loadout and loadout.glove_id or managers.blackmarket:get_default_glove_id()
		local visual_state = {
			armor_skin = "none",
			armor_id = "level_1",
			visual_seed = visual_seed,
			player_style = player_style,
			suit_variation = suit_variation,
			glove_id = glove_id,
			glove_variation = "default",
			mask_id = character.data.mask_id
		}

		if unit and alive(unit) then
			local extra_loadout = unit:base():beardlib_extra_loadout()

			if extra_loadout and extra_loadout.glove_variation then
				visual_state.glove_variation = extra_loadout.glove_variation
			end
		end

		self:remove_gloves_teamAI(character_name)

		local function get_glove_value(value)
			local output = tweak_data.blackmarket:get_glove_variation_value(glove_id, glove_variation, character_name, value, player_style, suit_variation)
			if output == nil then
				output = tweak_data.blackmarket:get_glove_value(glove_id, character_name, value, player_style, suit_variation)
			end

			return output
		end

		local crim_data = character.data
		crim_data.current_glove_id = visual_state.glove_id
		crim_data.current_glove_variation = visual_state.glove_variation
		crim_data.gloves_ready = true
		local new_unit = get_glove_value("unit")

		if new_unit then
			local new_unit_ids = Idstring(new_unit)
			crim_data.glove_unit_ids = new_unit_ids
		end

		managers.criminals:update_character_visual_state(character_name, visual_state)
	end)
end
