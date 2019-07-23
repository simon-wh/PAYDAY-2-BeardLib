WeaponModModule = WeaponModModule or class(ItemModuleBase)
WeaponModModule.type_name = "WeaponMod"

function WeaponModModule:GetBasedOn(f_self, based_on)
    f_self = f_self or tweak_data.weapon.factory.parts
    based_on = based_on or self._config.based_on
    if based_on and f_self[based_on] then
        return based_on
    else
        return nil
    end
end

function WeaponModModule:RegisterHook()
    self._config.default_amount = self._config.default_amount and tonumber(self._config.default_amount) or 1
    self._config.global_value = self._config.global_value or self.defaults.global_value
    self._config.droppable = NotNil(self._config.droppable, true)
    local config = self._config
    local id = config.id

    Hooks:Add("BeardLibCreateCustomWeaponMods", id .. "AddWeaponModTweakData", function(f_self)
        if f_self.parts[id] then
            BeardLib:log("[ERROR] Weapon mod with id '%s' already exists!", id)
            return
        end
        if type(config.perks) == "string" then
            config.perks = {config.perks}
        end
        local based_on = self:GetBasedOn(f_self.parts)
        local data = table.merge(deep_clone(based_on and f_self.parts[based_on] or {}), table.merge({
            name_id = config.name_id or "bm_wp_" .. id,
            unit = config.unit,
            stance_mod = config.stance_mod or {},
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
        f_self.parts[id] = data
        if data.droppable ~= false then
            TweakDataHelper:ModifyTweak({{
                type_items = "weapon_mods",
                item_entry = id,
                amount = config.default_amount,
                global_value = data.global_value
            }}, "dlc", data.dlc or self.defaults.dlc, "content", "loot_drops")
        end
	end)
	
	--Due to some parts getting inserted to uses_parts in blackmarket tweakdata I had to push this event to a different point.
    Hooks:Add("BeardLibAddCustomWeaponModsToWeapons", id .. "AddWeaponModToWeapons", function(f_self)
        config.weapons = config.weapons or {}
        local based_on = self:GetBasedOn(f_self)

        --Inheritance
        if based_on then
            for id, weap in pairs(f_self) do
                if weap.uses_parts and table.contains(weap.uses_parts, based_on) and not table.contains(config.weapon, weap.id) then
                    table.insert(weap.uses_parts, weap.id)
                end
                if weap.adds and weap.adds[based_on] and not weap.adds[id] then
                    weap.adds[id] = deep_clone(weap.adds[based_on])
                end
                if weap.override and weap.override[based_on] and not weap.override[id] then
                    weap.override[id] = deep_clone(weap.override[based_on])
                end
            end
            for _, part in pairs(f_self.parts) do
                if part.override[based_on] then
                    part.override[id] = deep_clone(part.override[based_on])
                end
                if not table.contains(part.forbids, based_on) then
                    table.insert(part.forbids, id)
                end
            end
        end

        --Adding
        for _, weap_id in ipairs(config.weapons) do
            local weap = f_self[weap_id]
            if weap then
                if weap.uses_parts and not table.contains(weap.uses_parts, id) then
                    table.insert(weap.uses_parts, id)
                end
                local npc_weapon = f_self[weap_id.."_npc"]
                if npc_weapon and npc_weapon.uses_parts and not table.contains(npc_weapon.uses_parts, id) then
                    table.insert(npc_weapon.uses_parts, id)
                end
            else
                self:log("[ERROR] Weapon %s does not exist. Cannot add part %s to it.", tostring(weap_id), tostring(id))
            end
        end

        if config.weapons_override then
            for weapon_id, override in pairs(config.weapons_override) do
                local weap = f_self[weapon_id]
                if weap then
                    weap.override = weap.override or {}
                    weap.override[id] = override
                end
            end
        end
        
        if config.weapons_adds then
            for weapon_id, adds in pairs(config.weapons_adds) do
                local weap = f_self[weapon_id]
                if weap then
                    weap.adds = weap.adds or {}
                    weap.adds[id] = adds
                end
            end
        end

        if config.parts_override then
            for part_id, override in pairs(config.parts_override) do
                local part = f_self.parts[part_id]
                if part then
                    part.override = part.override or {}
                    part.override[id] = override
                end
            end
        end

        if config.parts_forbids then
            for _, part_id in pairs(config.parts_forbids) do
                local part = f_self.parts[part_id]
                if not table.contains(part.forbids, id) then
                    table.insert(part.forbids, id)
                end
            end    
        end
	end)
end

BeardLib:RegisterModule(WeaponModModule.type_name, WeaponModModule)
