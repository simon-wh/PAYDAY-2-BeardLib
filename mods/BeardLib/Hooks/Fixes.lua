local F = table.remove(RequiredScript:split("/"))
--Custom weapons crash fix based of Rokk's mod.
--I wish I could make a warning dialog for custom weapon crash fix but you'd need to pause the save manager or something..
if F == "weaponfactorymanager" then
    local orig_unpack = WeaponFactoryManager.unpack_blueprint_from_string
    function WeaponFactoryManager:unpack_blueprint_from_string(factory_id, ...)
        local factory = tweak_data.weapon.factory
        if not factory[factory_id] then
            BeardLib:log("Weapon with the factory ID %s does not exist, returning empty table.", tostring(factory_id))
            return {}
        end
        return orig_unpack(self, factory_id, ...)
    end
    local orig_has = WeaponFactoryManager.has_perk
    function WeaponFactoryManager:has_perk(perk_name, factory_id, blueprint, ...)
        for _, part_id in pairs(blueprint) do
            if not tweak_data.weapon.factory.parts[part_id] then
                BeardLib:log("[WARNING] Weapon mod with the ID '%s' was found in the save but was missing, the weapon mod will be deleted from the save", tostring(part_id))
                return false
            end
        end
        return orig_has(self, perk_name, factory_id, blueprint, ...)
    end
elseif F == "blackmarketmanager" then
    local orig_get = BlackMarketManager.get_silencer_concealment_modifiers
    function BlackMarketManager:get_silencer_concealment_modifiers(weapon, ...)
        local weapon_id = weapon.weapon_id or managers.weapon_factory:get_weapon_id_by_factory_id(weapon.factory_id)
        if tweak_data.weapon[weapon_id] then
            return orig_get(self, weapon, ...)
        else
            BeardLib:log("[WARNING] Weapon with the ID '%s' was found in the save but was missing, the weapon will be deleted from the save", tostring(weapon_id))		
            return 0
        end
    end
end