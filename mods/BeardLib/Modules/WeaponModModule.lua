WeaponModModule = WeaponModModule or class(ItemModuleBase)
WeaponModModule.type_name = "WeaponMod"

function WeaponModModule:RegisterHook()
    self._config.default_amount = self._config.default_amount and tonumber(self._config.default_amount) or 1
    self._config.global_value = self._config.global_value or self.defaults.global_value
    self._config.droppable = NotNil(self._config.droppable, true)
	local config = self._config

    Hooks:Add("BeardLibCreateCustomWeaponMods", self._config.id .. "AddWeaponModTweakData", function(w_self)
        if w_self.parts[config.id] then
            BeardLib:log("[ERROR] Weapon mod with id '%s' already exists!", config.id)
            return
        end
        if type(config.perks) == "string" then
            config.perks = {config.perks}
        end
        local data = table.merge(deep_clone(config.based_on and (w_self.parts[config.based_on] ~= nil and w_self.parts[config.based_on]) or {}), table.merge({
            name_id = config.name_id or "bm_wp_" .. config.id,
            unit = config.unit,
            third_unit = config.third_unit,
            a_obj = config.a_obj,
            dlc = config.droppable and (config.dlc or self.defaults.dlc),
            texture_bundle_folder = config.texture_bundle_folder,
            pcs = config.pcs and BeardLib.Utils:RemoveNonNumberIndexes(config.pcs),
            stats = table.merge({value=0}, BeardLib.Utils:RemoveMetas(config.stats, true) or {}),
            type = config.type,
            animations = config.animations,
            is_a_unlockable = config.is_a_unlockable,
            custom = true
        }, config))
        if config.merge_data then
            table.merge(data, config.merge_data)
        end
        w_self.parts[config.id] = data
        if data.droppable ~= false then
            TweakDataHelper:ModifyTweak({{
                type_items = "weapon_mods",
                item_entry = config.id,
                amount = config.default_amount,
                global_value = data.global_value
            }}, "dlc", data.dlc or self.defaults.dlc, "content", "loot_drops")
        end
	end)
	
	--Due to some parts getting inserted to uses_parts in blackmarket tweakdata I had to push this event to a different point.
	Hooks:Add("BeardLibAddCustomWeaponModsToWeapons", self._config.id .. "AddWeaponModToWeapons", function(w_self)
        if config.weapons then
            for _, weap in ipairs(config.weapons) do
                if w_self[weap] and w_self[weap].uses_parts then
                    table.insert(w_self[weap].uses_parts, config.id)
                end
                local npc_weapon = w_self[weap.."_npc"]
                if npc_weapon and npc_weapon.uses_parts then
                    table.insert(npc_weapon.uses_parts, config.id)
                end
            end
        end
	end)
end

BeardLib:RegisterModule(WeaponModModule.type_name, WeaponModModule)
