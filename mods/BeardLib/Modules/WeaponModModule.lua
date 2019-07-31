WeaponModModule = WeaponModModule or class(ItemModuleBase)
WeaponModModule.type_name = "WeaponMod"
function WeaponModModule:init(...)
    self.required_params = {}
    self.clean_table = table.add(clone(self.clean_table), {
        {param = "stats", action = "remove_metas"},
        {param = "stance_mod", action = function(tbl)
            for _, stance in pairs(tbl) do
                if stance.rotation then
                    stance.rotation = BeardLib.Utils:normalize_string_value(stance.rotation)
                end
            end
        end},
	})
	
    return WeaponModule.super.init(self, ...)
end

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
    local config = self._config

    config.default_amount = config.default_amount and tonumber(config.default_amount) or 1
    config.global_value =config.global_value or self.defaults.global_value
    local available = true
    if config.hidden then
        available = false
    end
    config.droppable = NotNil(config.droppable, available)
    if config.drop == false and config.is_a_unlockable == false then
        config.droppable = false
    end
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
        config.unit = config.unit or "units/mods/weapons/wpn_fps_"..id.."/wpn_fps_"..id
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
            is_a_unlockable = available,
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
        if config.droppable == false and config.is_a_unlockable == false then
            return
        end
        
        config.weapons = config.weapons or {}
        local based_on = self:GetBasedOn(f_self.parts)
        
        --Inheritance
        local inherit = config.inherit
        config.inherit_weapons = NotNil(config.inherit_weapons, inherit)
        config.inherit_adds = NotNil(config.inherit_adds, inherit)
        config.inherit_override = NotNil(config.inherit_override, inherit)
        config.inherit_parts_override = NotNil(config.inherit_parts_override, inherit)
        config.inherit_parts_forbids = NotNil(config.inherit_parts_forbids, inherit)
        if based_on then
            for _, weap in pairs(f_self) do
                if config.inherit_weapons and weap.uses_parts and table.contains(weap.uses_parts, based_on) and not table.contains(weap.uses_parts, id) then
                    table.insert(weap.uses_parts, id)
                end
                if config.inherit_adds and weap.adds and weap.adds[based_on] and not weap.adds[id] then
                    weap.adds[id] = deep_clone(weap.adds[based_on])
                end
                if config.inherit_override and weap.override and weap.override[based_on] and not weap.override[id] then
                    weap.override[id] = deep_clone(weap.override[based_on])
                end
            end
            if config.inherit_parts_override or config.inherit_parts_forbids then
                for _, part in pairs(f_self.parts) do
                    if config.inherit_parts_override and part.override and part.override[based_on] then
                        part.override[id] = deep_clone(part.override[based_on])
                    end
                    if config.inherit_parts_forbids and part.forbids and table.contains(part.forbids, based_on) then
                        table.insert(part.forbids, id)
                    end
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

        local function merge(tbl, what, tweak)
            if tbl then
                for wpn_or_prt_id, merge in ipairs(tbl) do
                    local weap = (tweak or f_self)[wpn_or_prt_id]
                    if weap then
                        weap[what] = weap[what] or {}
                        weap[what][id] = table.merge(weap[what][id], merge)
                    end
                end
            end
        end

        local function override(tbl, what, tweak)
            if tbl then
                for wpn_or_prt_id, override in ipairs(tbl) do
                    local weap = (tweak or f_self)[wpn_or_prt_id]
                    if weap then
                        weap[what] = weap[what] or {}
                        weap[what][id] = override
                    end
                end
            end
        end


        override(config.weapons_adds, "adds")
        override(config.weapons_override, "override")
        override(config.parts_override, "override", f_self.parts)

        merge(config.merge_weapons_adds, "adds")
        merge(config.merge_weapons_override, "override")
        merge(config.merge_parts_override, "override", f_self.parts)

        if config.parts_forbids then
            for _, part_id in ipairs(config.parts_forbids) do
                local part = f_self.parts[part_id]
                if part then
                    part.forbids = part.forbids or {}
                    if not table.contains(part.forbids, id) then
                        table.insert(part.forbids, id)
                    end
                else
                    self:log("[Warning] Mod with ID %s does not exist. Cannot add part to forbids")
                end
            end    
        end
	end)
end

BeardLib:RegisterModule(WeaponModModule.type_name, WeaponModModule)
