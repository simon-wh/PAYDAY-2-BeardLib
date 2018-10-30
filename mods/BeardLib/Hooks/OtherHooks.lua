local F = table.remove(RequiredScript:split("/"))
local Hooks = Hooks

if F == "tweakdata" then
	TweakDataHelper:Apply(tweak_data)
elseif F == "tweakdatapd2" then
	Hooks:PostHook(WeaponFactoryTweakData, "_init_content_unfinished", "CallWeaponFactoryAdditionHooks", function(self)
		Hooks:Call("BeardLibCreateCustomWeapons", self)
		Hooks:Call("BeardLibCreateCustomWeaponMods", self)
	end)
	
	Hooks:PostHook(BlackMarketTweakData, "init", "CallAddCustomWeaponModsToWeapons", function(self, tweak_data)
		Hooks:Call("BeardLibAddCustomWeaponModsToWeapons", tweak_data.weapon.factory, tweak_data)
		Hooks:Call("BeardLibCreateCustomProjectiles", self, tweak_data)
	end)
	
	Hooks:PostHook(TweakData, "init", "BeardLibTweakDataInit", function(self)
		Hooks:Call("BeardLibPostCreateCustomProjectiles", self, tweak_data)
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
elseif F == "gamesetup" then
	Hooks:PostHook(GameSetup, "paused_update", "GameSetupPausedUpdateBase", function(self, t, dt)
        Hooks:Call("GameSetupPauseUpdate", t, dt)
	end)
elseif F == "setup" then
	Hooks:PostHook(Setup, "init_managers", "BeardLibAddMissingDLCPackages", function(self)
		if managers.dlc.give_missing_package then
			managers.dlc:give_missing_package()
		end
		Hooks:Call("SetupInitManagers")
	end)
	
	Hooks:PostHook(Setup, "init_finalize", "BeardLibInitFinalize", function(self)
		CustomSoundManager:Open()
		Hooks:Call("BeardLibSetupInitFinalize", self)
	end)
	
	Hooks:PostHook(Setup, "unload_packages", "BeardLibUnloadPackages", function(self)
		CustomSoundManager:Close()
		CustomPackageManager:Unload()
		Hooks:Call("BeardLibSetupUnloadPackages", self)
	end)
elseif F == "missionmanager" then
	for _, name in ipairs(BeardLib.config.mission_elements) do 
		dofile(BeardLib.config.classes_dir .. "Elements/Element" .. name .. ".lua") 
	end
	
	local add_script = MissionManager._add_script
	function MissionManager:_add_script(data, ...)
		if self._scripts[data.name] then
			return
		end
		return add_script(self, data, ...)
	end
end