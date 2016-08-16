WeaponModModule = WeaponModModule or class(ItemModuleBase)

WeaponModModule.type_name = "WeaponMod"

function WeaponModModule:init(core_mod, config)
    if not self.super.init(self, core_mod, config) then
        return false
    end
    return true
end

function WeaponModModule:RegisterHook()
    self._config.default_amount = self._config.default_amount and tonumber(self._config.default_amount) or 1
    self._config.global_value = self._config.global_value or BeardLib.definitions.module_defaults.item.default_global_value
    self._config.drop = self._config.drop ~= nil and self._config.drop or true
    Hooks:Add("BeardLibCreateCustomWeaponMods", self._config.id .. "AddWeaponModTweakData", function(w_self)
        if w_self.parts[self._config.id] then
            BeardLib:log("[ERROR] Weapon mod with id '%s' already exists!", self._config.id)
            return
        end
        local data = table.merge(deep_clone(self._config.based_on and (w_self.parts[self._config.based_on] ~= nil and w_self.parts[self._config.based_on]) or {}), {
            name_id = self._config.name_id or "bm_wp_" .. self._config.id,
            unit = self._config.unit,
            third_unit = self._config.third_unit,
            a_obj = self._config.a_obj,
            dlc = self._config.drop and (self._config.dlc or BeardLib.definitions.module_defaults.item.default_dlc),
            texture_bundle_folder = self._config.texture_bundle_folder,
            pcs = self._config.pcs and BeardLib.Utils:RemoveNonNumberIndexes(self._config.pcs),
            stats = table.merge({value=0}, BeardLib.Utils:RemoveMetas(self._config.stats, true) or {}),
            type = self._config.type,
            animations = self._config.animations,
            is_a_unlockable = self._config.is_a_unlockable,
            custom = true
        })
        if self._config.merge_data then
            table.merge(data, self._config.merge_data)
        end
        w_self.parts[self._config.id] = data
        if self._config.drop and data.dlc == BeardLib.definitions.module_defaults.item.default_dlc then
            table.insert(BeardLib._mod_lootdrop_items, {
                type_items = "weapon_mods",
                item_entry = self._config.id,
                amount = self._config.default_amount,
                global_value = self._config.global_value ~= BeardLib.definitions.module_defaults.item.default_global_value and self._config.global_value or nil
            })

        end

        if self._config.weapons then
            for _, weap in ipairs(self._config.weapons) do
                if w_self[weap] and w_self[weap].uses_parts then
                    table.insert(w_self[weap].uses_parts, self._config.id)
                end
            end
        end
    end)
end

BeardLib:RegisterModule(WeaponModModule.type_name, WeaponModModule)
