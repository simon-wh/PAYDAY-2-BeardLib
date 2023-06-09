local F = table.remove(RequiredScript:split("/"))
local Hooks = Hooks
if F == "weaponfactorymanager" then
    --Custom weapons crash fix based of Rokk's mod.
    --I wish I could make a warning dialog for custom weapon crash fix but you'd need to pause the save manager or something..
    local orig_unpack = WeaponFactoryManager.unpack_blueprint_from_string
    function WeaponFactoryManager:unpack_blueprint_from_string(factory_id, ...)
        local factory = tweak_data.weapon.factory
        if not factory[factory_id] then
            return {}
        end
        return orig_unpack(self, factory_id, ...)
    end
    

    local orig_has = WeaponFactoryManager.has_perk
    function WeaponFactoryManager:has_perk(perk_name, factory_id, blueprint, ...)
        local factory = tweak_data.weapon.factory

        for _, part_id in pairs(blueprint) do
            if not factory.parts[part_id] then
                BeardLib:log("[Fixes][Warning] Weapon mod with the ID '%s' was found in the save but was missing, the weapon mod will be deleted from the save", tostring(part_id))
                return false
            elseif type(factory.parts[part_id].perks) == "string" then
                BeardLib:log("[Fixes][Warning] Perks value is a string when it's supposed to be a table, weapon mod id %s, perk value %s", tostring(part_id), tostring(factory.parts[part_id].perks))
                factory.parts[part_id].perks = {factory.parts[part_id].perks}
            end
        end

        return orig_has(self, perk_name, factory_id, blueprint, ...)
    end

    --https://github.com/simon-wh/PAYDAY-2-BeardLib/issues/112
    Hooks:PreHook(WeaponFactoryManager, "_read_factory_data", "BeardLibFixMissingParts", function(self)
        local tweak = tweak_data.weapon.factory
        for factory_id, data in pairs(tweak) do
            if factory_id ~= "parts" and type(data.uses_parts) == "table" then
                local new_uses_parts = {}
                for _, part_id in pairs(data.uses_parts) do
                    if tweak.parts[part_id] then
                        table.insert(new_uses_parts, part_id)
                    elseif not factory_id:ends("_npc") then
                        BeardLib:log("[Fixes][Warning] Weapon with the factory ID %s has the part %s defined but the part does not exist", tostring(factory_id), tostring(part_id))
                    end
                end
                data.uses_parts = new_uses_parts
            end
        end
    end)
elseif F == "blackmarketmanager" then
    local orig_get = BlackMarketManager.get_silencer_concealment_modifiers
    function BlackMarketManager:get_silencer_concealment_modifiers(weapon, ...)
        local weapon_id = weapon.weapon_id or managers.weapon_factory:get_weapon_id_by_factory_id(weapon.factory_id)
        if tweak_data.weapon[weapon_id] then
            return orig_get(self, weapon, ...)
        else
            BeardLib:log("[Fixes][Warning] Weapon with the ID '%s' was found in the save but was missing, the weapon will be deleted from the save", tostring(weapon_id))
            return 0
        end
    end

    local orig_string_mask = BlackMarketManager._outfit_string_mask
    function BlackMarketManager:_outfit_string_mask(...)
        if not managers.blackmarket:equipped_mask() then
            BeardLib:log("[Fixes][Warning] Mask is null, returning default.")
            return "character_locked"
        end
        return orig_string_mask(self, ...)
    end

    --Fixes #211.
    --Fixes duplicates with custom weapon mods that use gloval values by forcing 1 of each weapon mod.
    local orig_get_mods = BlackMarketManager.get_dropable_mods_by_weapon_id
    function BlackMarketManager:get_dropable_mods_by_weapon_id(weapon_id, weapon_data)
        local parts = tweak_data.weapon.factory.parts
        local droppable_mods = orig_get_mods(self, weapon_id, weapon_data)
        for k, v in pairs(droppable_mods) do
            local new_tbl = {}
            local duplicate = {}
            for _, drop in pairs(v) do
                if not duplicate[drop[1]] then
                    local part = parts[drop[1]]
                    if part and part.global_value and not part.allow_duplicates then
                        drop[2] = part.global_value
                        duplicate[drop[1]] = true
                    end
                    table.insert(new_tbl, drop)
                end
            end
            droppable_mods[k] = new_tbl
        end
        return droppable_mods
    end

    --WARNING: this function has been completely replaced. If anything fucks up, please removed it.
    --Fixes sorting for custom melee.
    function BlackMarketManager:get_sorted_melee_weapons(hide_locked, id_list_only)
        local items = {}
        local global_value, td, category

        for id, item in pairs(Global.blackmarket_manager.melee_weapons) do
            td = tweak_data.blackmarket.melee_weapons[id]
            global_value = td.dlc or td.global_value or "normal"
            category = td.type or "unknown"
            local add_item = item.unlocked or item.equipped or not hide_locked and not tweak_data:get_raw_value("lootdrop", "global_values", global_value, "hide_unavailable")

            if add_item then
                table.insert(items, {
                    id,
                    item
                })
            end
        end

        local xd, yd, x_td, y_td, x_sn, y_sn, x_gv, y_gv
        local m_tweak_data = tweak_data.blackmarket.melee_weapons
        local l_tweak_data = tweak_data.lootdrop.global_values

        local function sort_func(x, y)
            xd = x[2]
            yd = y[2]
            x_td = m_tweak_data[x[1]]
            y_td = m_tweak_data[y[1]]

            if x_td.custom ~= y_td.custom then
                return x_td.custom == nil
            end

            if _G.IS_VR and xd.vr_locked ~= yd.vr_locked then
                return not xd.vr_locked
            end

            if xd.unlocked ~= yd.unlocked then
                return xd.unlocked
            end

            if xd.level ~= yd.level then
                return xd.level < yd.level
            end

            if x_td.instant ~= y_td.instant then
                return x_td.instant
            end

            if xd.skill_based ~= yd.skill_based then
                return xd.skill_based
            end

            if x_td.free ~= y_td.free then
                return x_td.free
            end

            x_gv = x_td.global_value or x_td.dlc or "normal"
            y_gv = y_td.global_value or y_td.dlc or "normal"
            x_sn = l_tweak_data[x_gv]
            y_sn = l_tweak_data[y_gv]
            x_sn = x_sn and x_sn.sort_number or 1
            y_sn = y_sn and y_sn.sort_number or 1

            if x_sn ~= y_sn then
                return x_sn < y_sn
            end

            if xd.level ~= yd.level then
                return xd.level < yd.level
            end

            return x[1] < y[1]
        end

        table.sort(items, sort_func)

        if id_list_only then
            local id_list = {}

            for _, data in ipairs(items) do
                table.insert(id_list, data[1])
            end

            return id_list
        end

        local override_slots = {
            4,
            4
        }
        local num_slots_per_category = override_slots[1] * override_slots[2]
        local sorted_categories = {}
        local item_categories = {}
        local category = nil

        for index, item in ipairs(items) do
            category = math.max(1, math.ceil(index / num_slots_per_category))
            item_categories[category] = item_categories[category] or {}

            table.insert(item_categories[category], item)
        end

        for i = 1, #item_categories, 1 do
            table.insert(sorted_categories, i)
        end

        return sorted_categories, item_categories, override_slots
    end

    --No clue how but sometimes the first function (get_silencer_concealment_modifiers) fails to remove the weapon so this comes as a backup.
    local orig_weapons_unlocked = BlackMarketManager.weapon_unlocked_by_crafted
    function BlackMarketManager:weapon_unlocked_by_crafted(category, slot, ...)
        local crafted = self._global and self._global.crafted_items[category][slot]

        if not crafted then
            return false
        end
        local data = Global.blackmarket_manager.weapons[crafted.weapon_id]
        if data then
            return orig_weapons_unlocked(self, category, slot, ...)
        else
            BeardLib:log("[Fixes][Warning #2] Weapon with the ID '%s' was found in the save but was missing, the weapon will be deleted from the save", tostring(weapon_id))
            return false
        end
    end

    -- This is literally just a check if they exist, even in vanilla this wouldn't mark pirates. 
    function BlackMarketManager:verfify_recived_crew_loadout(loadout, mark_host_as_cheater)
        return true
    end
elseif F == "crewmanagementgui" then
    local orig = CrewManagementGui.populate_primaries
    --Blocks out custom weapons that don't have support for AI.
    function CrewManagementGui:populate_primaries(i, data, ...)
        local res = orig(self, i, data, ...)
        for k, v in ipairs(data) do
            local fac_id = managers.weapon_factory:get_factory_id_by_weapon_id(v.name)
            if fac_id then
                local factory = tweak_data.weapon.factory[fac_id.."_npc"]
                if factory and factory.custom and not DB:has(Idstring("unit"), factory.unit:id()) then
                    v.buttons = {}
                    v.unlocked = false
                    v.lock_texture = "guis/textures/pd2/lock_incompatible"
                    v.lock_text = managers.localization:text("menu_data_crew_not_allowed")
                end
            end
        end
        return res
    end
elseif F == "connectionnetworkhandler" then
    --Fixes level id being set wrong with custom maps
    function ConnectionNetworkHandler:sync_stage_settings_ignore_once(...)
        self:sync_stage_settings(...)
        self._ignore_stage_settings_once = true
    end

    --Sets the correct data out of NetworkPeer instead of straight from the parameters
    Hooks:PostHook(ConnectionNetworkHandler, "sync_outfit", "BeardLibSyncOutfitProperly", function(self, outfit_string, outfit_version, outfit_signature, sender)
        local peer = self._verify_sender(sender)
        if not peer then
            return
        end

        peer:beardlib_reload_outfit()
    end)

    local orig_sync_stage_settings = ConnectionNetworkHandler.sync_stage_settings
    function ConnectionNetworkHandler:sync_stage_settings(level_id_index, ...)
        if self._ignore_stage_settings_once then
            self._ignore_stage_settings_once = nil
            return
        end
        return orig_sync_stage_settings(self, level_id_index, ...)
    end

    function ConnectionNetworkHandler:lobby_sync_update_level_id_ignore_once(...)
        self:lobby_sync_update_level_id(...)
        self._ignore_update_level_id_once = true
    end

    local orig_lobby_sync_update_level_id = ConnectionNetworkHandler.lobby_sync_update_level_id
    function ConnectionNetworkHandler:lobby_sync_update_level_id(level_id_index, ...)
        if self._ignore_update_level_id_once then
            self._ignore_update_level_id_once = nil
            return
        end
        return orig_lobby_sync_update_level_id(self, level_id_index, ...)
    end
elseif F == "elementinteraction" then
    --Checks if the interaction unit is loaded to avoid crashes
    --Checks if interaction tweak id exists
    core:import("CoreMissionScriptElement")
    ElementInteraction = ElementInteraction or class(CoreMissionScriptElement.MissionScriptElement)
    local orig_init = ElementInteraction.init
    local unit_ids = Idstring("unit")
    local norm_ids = Idstring("units/dev_tools/mission_elements/point_interaction/interaction_dummy")
    local nosync_ids = Idstring("units/dev_tools/mission_elements/point_interaction/interaction_dummy_nosync")
    function ElementInteraction:init(mission_script, data, ...)
        if not PackageManager:has(unit_ids, norm_ids) or not PackageManager:has(unit_ids, nosync_ids) then
            return ElementInteraction.super.init(self, mission_script, data, ...)
        end
        if data and data.values and not tweak_data.interaction[data.values.tweak_data_id] then
            return ElementInteraction.super.init(self, mission_script, data, ...)
        end
        return orig_init(self, mission_script, data, ...)
    end

    function MissionScriptElement:init(mission_script, data)
        self._mission_script = mission_script
        self._id = data.id
        self._editor_name = data.editor_name
        self._values = data.values
    end
elseif F == "elementvehiclespawner" then
    --Same as interaction element but checks the selected vehicle
    core:import("CoreMissionScriptElement")
    ElementVehicleSpawner = ElementVehicleSpawner or class(CoreMissionScriptElement.MissionScriptElement)
    local orig_on_executed = ElementVehicleSpawner.on_executed
    local unit_ids = Idstring("unit")
    function ElementVehicleSpawner:on_executed(...)
        if not PackageManager:has(unit_ids, Idstring(self._vehicles[self._values.vehicle] or "")) then
            return
        end
        return orig_on_executed(self, ...)
    end
elseif F == "coresoundenvironmentmanager" then
    --From what I remember, this fixes a crash, these are useless in public.
    function CoreSoundEnvironmentManager:emitter_events(path)
        return {""}
    end
    function CoreSoundEnvironmentManager:ambience_events()
        return {""}
    end
elseif F == "coreelementinstance" then
    core:module("CoreElementInstance")
    core:import("CoreMissionScriptElement")
    function ElementInstancePoint:client_on_executed(...)
        self:on_executed(...)
    end
elseif F == "coreelementshape"  or F == "coreelementarea" then
    Hooks:PostHook(F == "coreelementshape" and ElementShape or ElemetArea, "init", "BeardLibAddSphereShape", function(self)
        if self._values.shape_type == "sphere" then
            self:_add_shape(CoreShapeManager.ShapeSphere:new({
                position = self._values.position,
                rotation = self._values.rotation,
                height = self._values.height,
                radius = self._values.radius
            }))
        end
    end)
elseif F == "raycastweaponbase" then
    if RaycastWeaponBase._soundfix_should_play_normal then
        return --Don't run if fix installed.
    end

    function RaycastWeaponBase:use_soundfix()
        local sounds = tweak_data.weapon[self:get_name_id()].sounds
        return sounds and sounds.use_fix == true
    end

    --Based of https://modworkshop.net/mydownloads.php?action=view_down&did=20403
    local fire_sound = RaycastWeaponBase._fire_sound
    function RaycastWeaponBase:_fire_sound(...)
        if not self:use_soundfix() then
            return fire_sound(self, ...)
        end
    end

    local fire = RaycastWeaponBase.fire
    function RaycastWeaponBase:fire(...)
        local result = fire(self, ...)
        if self:use_soundfix() and result then
			self._bullets_fired = 0
            self:play_tweak_data_sound("fire_single", "fire")
        end
        return result
    end

    Hooks:PreHook(RaycastWeaponBase, "update_next_shooting_time", "BeardLibUpdateNextShootingTime", function(self)
        if self:use_soundfix() then
            self:_fire_sound()
        end
    end)

    Hooks:PreHook(RaycastWeaponBase, "trigger_held", "BeardLibTriggerHeld", function(self)
        if not self:start_shooting_allowed() and self:use_soundfix() then
            self:play_tweak_data_sound("stop_fire")
        end
    end)

    --Checks the name ID of the weapon to ensure it exists. If it doesn't exist, it searches for a factory that holds this unit
    --and then accesses its weapon_id parameter (because fuck going through shit upgradestweakdata). If that fails, it falls back to amcar.
    Hooks:PreHook(RaycastWeaponBase, "_create_use_setups", "BeardLibCheckWeaponExistence", function(self)
        if not tweak_data.weapon[self._name_id] then
            local unit_name = self._unit:name()
            for _, fac in pairs(tweak_data.weapon.factory) do
                self._name_id = nil
                if fac.weapon_id and fac.unit and fac.unit:id() == unit_name then
                    self._name_id = fac.weapon_id
                    break
                end
            end
            self._name_id = self._name_id or "amcar"
        end
    end)
elseif F == "playermovement" then
    --VR teleporation fix
    if _G.IS_VR then
        function PlayerMovement:trigger_teleport(data)
            if game_state_machine and game_state_machine:current_state() then
                self._vr_has_teleported = data
            end
        end

        function PlayerMovement:update(unit, t, dt)
            if _G.IS_VR then
                self:_update_vr(unit, t, dt)
            end

            self:_calculate_m_pose()

            if self:_check_out_of_world(t) then
                return
            end

            if self._vr_has_teleported then
                managers.player:warp_to(self._vr_has_teleported.position or Vector3(), self._vr_has_teleported.rotation or Rotation())
                self._vr_has_teleported = nil
                return
            end

            self:_upd_underdog_skill(t)

            if self._current_state then
                self._current_state:update(t, dt)
            end

            self:update_stamina(t, dt)
            self:update_teleport(t, dt)
        end
    else
        local trigger = PlayerMovement.trigger_teleport
        function PlayerMovement:trigger_teleport(data, ...)
            data.fade_in = data.fade_in or 0
            data.sustain = data.sustain or 0
            data.fade_out = data.fade_out or 0
            return trigger(self, data, ...)
        end
    end
elseif F == "dialogmanager" then
	Hooks:PreHook(DialogManager, "queue_dialog", "BeardLibQueueDialogFixIds", function(self, id)
		if id and not managers.dialog._dialog_list[id] then
			local sound = BeardLib.Managers.Sound:GetSound(id)
			if sound then
				managers.dialog._dialog_list[id] = {
					id = id,
					sound = id,
					priority = sound.priority and tonumber(sound.priority) or tweak_data.dialog.DEFAULT_PRIORITY
				}
			end
		end
    end)
elseif F == "networkpeer" then
    local tradable_item_verif = NetworkPeer.tradable_verify_outfit
    function NetworkPeer:tradable_verify_outfit(signature)
        local outfit = self:blackmarket_outfit()

        if outfit.primary and outfit.primary.cosmetics and tweak_data.blackmarket.weapon_skins[outfit.primary.cosmetics.id] then
            if tweak_data.blackmarket.weapon_skins[outfit.primary.cosmetics.id].is_a_unlockable  then
                return
            end
        else
            return
        end

        if outfit.secondary and outfit.secondary.cosmetics and tweak_data.blackmarket.weapon_skins[outfit.secondary.cosmetics.id] then
            if tweak_data.blackmarket.weapon_skins[outfit.secondary.cosmetics.id].is_a_unlockable  then
                return
            end
        else
            return
        end

        return tradable_item_verif(self, signature)
    end
elseif F == 'ingamewaitingforplayers' then
    --[[--Fixes custom weapon not appearing at first
    Hooks:PostHook(IngameWaitingForPlayersState, "_start_audio", "BeardLib.StartAudio", function()
        DelayedCalls:Add("PleaseShowCorrectWeaponBrokenPieceOf", 1, function()
            if managers.player:player_unit() then
                managers.player:player_unit():inventory():_send_equipped_weapon()
            end
        end)
    end)]]
elseif F == "playerdamage" then
    Hooks:PostHook(PlayerDamage, "init", "BeardLibPlyDmgInit", function(self)
        local level_tweak = tweak_data.levels[managers.job:current_level_id()]

        if level_tweak and level_tweak.player_invulnerable then
            self:set_mission_damage_blockers("damage_fall_disabled", true)
            self:set_mission_damage_blockers("invulnerable", true)
        end
    end)
elseif F == "dlcmanager" then
    --Fixes parts receiving global value doing a check here using global values and disregarding if the global value is not a DLC. https://github.com/simon-wh/PAYDAY-2-BeardLib/issues/237
    function GenericDLCManager:is_dlc_unlocked(dlc)
        if not tweak_data.dlc[dlc] then
            local global_value = tweak_data.lootdrop.global_values[dlc]
            if global_value and global_value.custom then
                return tweak_data.lootdrop.global_values[dlc].dlc == false
            end
        end
        return tweak_data.dlc[dlc] and tweak_data.dlc[dlc].free or self:has_dlc(dlc)
    end
elseif F == "playerhandstatemelee" then
    --Removes the need of having a thq material config for custom melee in VR.
    local mtr_cubemap = Idstring("mtr_cubemap")
    Hooks:PostHook(PlayerHandStateMelee, "_spawn_melee_unit", "VRBeardLibForceMeleeTHQ", function(self)
        if alive(self._melee_unit) then
            local tweak = tweak_data.blackmarket.melee_weapons[self._melee_entry]
            if tweak.custom then
                if tweak.auto_thq ~= false then
                    for _, material in ipairs(self._melee_unit:get_objects_by_type(Idstring("material"))) do
                        if material:name() == mtr_cubemap then
                            material:set_render_template(Idstring("generic:CUBE_ENVIRONMENT_MAPPING:DIFFUSE_TEXTURE:NORMALMAP"))
                        else
                            material:set_render_template(Idstring("generic:DIFFUSE_TEXTURE:NORMALMAP"))
                        end
                    end
                end
            end
        end
    end)
elseif F == "hudbelt" then
    local function scale_by_aspect(gui_obj, max_size)
        local w = gui_obj:texture_width()
        local h = gui_obj:texture_height()

        if h < w then
            gui_obj:set_size(max_size, max_size / w * h)
        else
            gui_obj:set_size(max_size / h * w, max_size)
        end
    end

    --Fixes melees in VR having no fallback and to make them use based_on when the files are missing.
    local tex_ids = Idstring("texture")
    Hooks:PostHook(HUDBeltInteraction, "update_icon", "BeardLibFixCustomMelee", function(self)
        if self._id == "melee" then
            local tweak = tweak_data.blackmarket.melee_weapons[managers.blackmarket:equipped_melee_weapon()]
            local id = tweak.based_on
            if id then
                if self._texture then
                    if not DB:has(tex_ids, self._texture) then
                        local prefix = "guis"
                        local texture = "/textures/pd2/blackmarket/icons/melee_weapons/outline/" .. id

                        if not DB:has(tex_ids, Idstring(prefix .. texture)) then
                            prefix = "guis/dlcs/" .. tweak_data.blackmarket.melee_weapons[id].texture_bundle_folder
                        end

                        if DB:has(tex_ids, Idstring(prefix .. texture)) then
                            self._texture = prefix .. texture
                        else
                            self._texture = "guis/textures/pd2/blackmarket/icons/melee_weapons/outline/weapon"
                        end

                        self._icon:set_image(self._texture)
                        scale_by_aspect(self._icon, math.min(self._w, self._h))
                        self._icon:set_center(self._panel:w() / 2, self._panel:h() / 2)
                    end
                end
            end
        end
    end)
elseif F == "coreworldinstancemanager" then
    --Fixes #252
    local prepare = CoreWorldInstanceManager.prepare_mission_data
    function CoreWorldInstanceManager:prepare_mission_data(instance, ...)
        local instance_data = prepare(self, instance, ...)
        for _, script_data in pairs(instance_data) do
            for _, element in ipairs(script_data.elements) do
                local vals = element.values
                if element.class == "ElementMoveUnit" then
                    if vals.start_pos then
                        vals.start_pos = instance.position + element.values.start_pos:rotate_with(instance.rotation)
                    end
                    if vals.end_pos then
                        vals.end_pos = instance.position + element.values.end_pos:rotate_with(instance.rotation)
                    end
                elseif element.class == "ElementRotateUnit" then
                    vals.end_rot = instance.rotation * vals.end_rot
                end
            end
        end
        return instance_data
    end
elseif F == "groupaitweakdata" then
    --Fixes a weird crash when exiting instance levels or in general the game not having a sanity check for having the level.
    local _read_mission_preset = GroupAITweakData._read_mission_preset

    function GroupAITweakData:_read_mission_preset(tweak_data, ...)
        if not Global.game_settings or not Global.game_settings.level_id or not tweak_data.levels[Global.game_settings.level_id] then
            return
        end
        return _read_mission_preset(self, tweak_data, ...)
    end
elseif F == "elementfilter" then
    --Overkill decided not to add a one down check alongside the difficulties, so here's one, because why not.

    Hooks:PostHook(ElementFilter, "_check_difficulty", "BeardLibFilterOneDownCheck", function(self)
        if self._values.one_down and Global.game_settings.one_down then
            return true
        end
    end)
elseif F == "blackmarketgui" then
    -- Universal icon backwards compatibility.
    Hooks:PostHook(BlackMarketGui, "populate_weapon_category_new", "BeardLibUniversalIconMiniIconFix", function(self, data)
        local category = data.category
        local crafted_category = managers.blackmarket:get_crafted_category(category) or {}

        for i, index in pairs(data.on_create_data) do
            local crafted = crafted_category[index]

            if crafted then
                local equipped_cosmetic_id = crafted and crafted.cosmetics and crafted.cosmetics.id
                local color_tweak = tweak_data.blackmarket.weapon_skins[equipped_cosmetic_id]

                if color_tweak and color_tweak.universal then
                    local guis_catalog = "guis/"
                    local bundle_folder = color_tweak.texture_bundle_folder
                    if bundle_folder then
                        guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
                    end

                    local mini_icons = data[i].mini_icons
                    mini_icons[#mini_icons].texture = guis_catalog .. "weapon_skins/" .. equipped_cosmetic_id
                end
            end
        end
    end)

    Hooks:PostHook(BlackMarketGui, "populate_weapon_cosmetics", "BeardLibUniversalIconMiniIconFix2", function(self, data)
        local crafted = managers.blackmarket:get_crafted_category(data.category)[data.prev_node_data and data.prev_node_data.slot]
        local equipped_cosmetic_id = crafted and crafted.cosmetics and crafted.cosmetics.id
        local color_tweak = tweak_data.blackmarket.weapon_skins[equipped_cosmetic_id]

        if color_tweak and color_tweak.universal then
            local guis_catalog = "guis/"
            local bundle_folder = color_tweak.texture_bundle_folder
            if bundle_folder then
                guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
            end

            data[1].bitmap_texture = guis_catalog .. "weapon_skins/" .. equipped_cosmetic_id
        end
    end)
elseif F == "menunodecustomizeweaponcolorgui" then
    -- Universal icon backwards compatibility.
    Hooks:PreHook(MenuCustomizeWeaponColorInitiator, "create_grid", "BeardLibUniversalIconGridFix", function(self, node, colors_data)
        for _, color_data in pairs(colors_data) do
            local color_tweak = tweak_data.blackmarket.weapon_skins[color_data.value]

            if color_tweak and color_tweak.universal then
                local guis_catalog = "guis/"
                local bundle_folder = color_tweak.texture_bundle_folder
                if bundle_folder then
                    guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
                end

                color_data.texture = guis_catalog .. "weapon_skins/" .. color_data.value
            end
        end
    end)
elseif F == "platformmanager" then
    core:module("PlatformManager")
    -- Fixes rich presence to work with custom heists by forcing raw status.
    Hooks:PostHook(WinPlatformManager, "set_rich_presence", "FixCustomHeistStatus", function(self)
        if not Global.game_settings.single_player and Global.game_settings.permission ~= "private" and name ~= "Idle" and managers.network and managers.network.matchmake.lobby_handler  then
            local job = managers.job:current_job_data()
            if job and job.custom and Steam then
                Steam:set_rich_presence("steam_display", "#raw_status")
            end
        end
    end)
end