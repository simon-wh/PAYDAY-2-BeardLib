local orig_WeaponFactoryManager_unpack_blueprint_from_string = WeaponFactoryManager.unpack_blueprint_from_string
function WeaponFactoryManager:unpack_blueprint_from_string(factory_id, ...)
	local factory = tweak_data.weapon.factory
    if not factory[factory_id] then
        log("Returning empty due to the weapon not existing")
        return {}
    end
    return orig_WeaponFactoryManager_unpack_blueprint_from_string(self, factory_id, ...)
end
