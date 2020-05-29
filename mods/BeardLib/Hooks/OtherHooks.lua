local F = table.remove(RequiredScript:split("/"))
local Hooks = Hooks

if F == "tweakdata" then
	TweakDataHelper:Apply()
	local function icon_and_unit_check(list, folder, friendly_name, uses_texture_val, only_check_units)
		for id, thing in pairs(list) do
			if thing.custom and not id:ends("_npc") and not id:ends("_crew") then
				if not only_check_units and not thing.hidden then
					if folder ~= "mods" or thing.pcs then
						local guis_catalog = "guis/"
						local bundle_folder = thing.texture_bundle_folder
						if bundle_folder then
							guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
						end

						guis_catalog = guis_catalog .. "textures/pd2/blackmarket/icons/"..folder.."/"
						local tex = uses_texture_val and thing.texture or guis_catalog .. id
						if not DB:has(Idstring("texture"), tex) then
							local mod = BeardLib.Utils:FindModWithPath(thing.mod_path) or BeardLib
							mod:Err("Icon for %s %s doesn't exist path: %s", tostring(friendly_name), tostring(id), tostring(tex))
						end
					end
				end
				if thing.unit then
					if not DB:has(Idstring("unit"), thing.unit) then
						local mod = BeardLib.Utils:FindModWithPath(thing.mod_path) or BeardLib
						mod:Err("Unit for %s %s doesn't exist path: %s", tostring(friendly_name), tostring(id), tostring(thing.unit))
					end
				end
			end
		end
	end
	icon_and_unit_check(tweak_data.weapon, "weapons", "weapon")
	icon_and_unit_check(tweak_data.weapon.factory, "weapons", "weapon", false, true)
	icon_and_unit_check(tweak_data.weapon.factory.parts, "mods", "weapon mod")
	icon_and_unit_check(tweak_data.blackmarket.melee_weapons, "melee_weapons", "melee weapon")
	icon_and_unit_check(tweak_data.blackmarket.textures, "textures", "mask pattern", true)
	icon_and_unit_check(tweak_data.blackmarket.materials, "materials", "mask material")
elseif F == "tweakdatapd2" then
	Hooks:PostHook(WeaponFactoryTweakData, "_init_content_unfinished", "CallWeaponFactoryAdditionHooks", function(self)
		Hooks:Call("BeardLibCreateCustomWeapons", self)
		Hooks:Call("BeardLibCreateCustomWeaponMods", self)
	end)

	Hooks:PostHook(BlackMarketTweakData, "init", "CallAddCustomWeaponModsToWeapons", function(self, tweak_data)
		Hooks:Call("BeardLibAddCustomWeaponModsToWeapons", tweak_data.weapon.factory, tweak_data)
		Hooks:Call("BeardLibCreateCustomProjectiles", self, tweak_data)
	end)

	--Big brain.
	Hooks:PostHook(BlackMarketTweakData, "_init_weapon_mods", "FixGlobalValueWeaponMods", function(self, tweak_data)
		local parts = tweak_data.weapon.factory.parts
		for id, mod in pairs(self.weapon_mods) do
			local gv = parts[id] and parts[id].global_value
			if gv then
				mod.global_value = gv
			end
		end
	end)

	Hooks:PreHook(WeaponTweakData, "init", "BeardLibWeaponTweakDataPreInit", function(self, tweak_data)
		_tweakdata = tweak_data
	end)

	Hooks:PostHook(WeaponTweakData, "init", "BeardLibWeaponTweakDataInit", function(self, tweak_data)
		Hooks:Call("BeardLibPostCreateCustomProjectiles", tweak_data)
	end)

	for _, framework in pairs(BeardLib.Frameworks) do framework:RegisterHooks() end
	--Makes sure that rect can be returned as a null if it's a custom icon
	local get_icon = HudIconsTweakData.get_icon_data
	function HudIconsTweakData:get_icon_data(id, rect, ...)
		local icon, texture_rect = get_icon(self, id, rect, ...)
		local data = self[id]
		if not rect and data and data.custom and not data.texture_rect then
			texture_rect = ni
		end
		return icon, texture_rect
	end

	Hooks:PostHook(BlackMarketTweakData, "_init_player_styles", "CallPlayerStyleAdditionHooks", function(self)
		Hooks:Call("BeardLibCreateCustomPlayerStyles", self.player_styles)
		Hooks:Call("BeardLibCreateCustomPlayerStyleVariants", self.player_styles)
	end)
elseif F == "gamesetup" then
	Hooks:PreHook(GameSetup, "paused_update", "GameSetupPausedUpdateBase", function(self, t, dt)
        Hooks:Call("GameSetupPrePausedUpdate", t, dt)
	end)
	Hooks:PostHook(GameSetup, "paused_update", "GameSetupPausedUpdateBase", function(self, t, dt)
        Hooks:Call("GameSetupPauseUpdate", t, dt)
	end)
elseif F == "setup" then
	Hooks:PreHook(Setup, "update", "BeardLibSetupPreUpdate", function(self, t, dt)
        Hooks:Call("SetupPreUpdate", t, dt)
	end)

	Hooks:PostHook(Setup, "init_managers", "BeardLibAddMissingDLCPackages", function(self)
		if managers.dlc.give_missing_package then
			managers.dlc:give_missing_package()
		end
		Hooks:Call("SetupInitManagers", self)
	end)

	Hooks:PostHook(Setup, "init_finalize", "BeardLibInitFinalize", function(self)
		BeardLib.Managers.Sound:Open()
		Hooks:Call("BeardLibSetupInitFinalize", self)
	end)

	Hooks:PostHook(Setup, "unload_packages", "BeardLibUnloadPackages", function(self)
		BeardLib.Managers.Sound:Close()
		BeardLib.Managers.Package:Unload()
		Hooks:Call("BeardLibSetupUnloadPackages", self)
	end)
elseif F == "missionmanager" then
	for _, name in ipairs(BeardLib.config.mission_elements) do
		dofile(Path:Combine(BeardLib.config.classes_dir, "Elements", "Element"..name..".lua"))
	end

	local add_script = MissionManager._add_script
	function MissionManager:_add_script(data, ...)
		if self._scripts[data.name] then
			return
		end
		return add_script(self, data, ...)
	end
end