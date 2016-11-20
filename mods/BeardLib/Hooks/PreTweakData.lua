local c_weap_hook = "BeardLibCreateCustomWeapons"
local c_weap_mods_hook = "BeardLibCreateCustomWeaponMods"

Hooks:Register(c_weap_hook)
Hooks:Register(c_weap_mods_hook)

Hooks:PostHook(WeaponFactoryTweakData, "_init_content_unfinished", "CallWeaponFactoryAdditionHooks", function(self)
    Hooks:Call(c_weap_hook, self)
    Hooks:Call(c_weap_mods_hook, self)
end)

BeardLib.managers.MapFramework:RegisterHooks()
BeardLib.managers.AddFramework:RegisterHooks()
