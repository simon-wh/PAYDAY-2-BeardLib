WeaponModuleNew = WeaponModuleNew or class(ItemModuleBase)

WeaponModuleNew.type_name = "WeaponNew"

function WeaponModuleNew:init(core_mod, config)
    self.required_params = {"weapon", "factory", "stance", "weapon.id", "factory.id"}
    self.clean_table = table.add(clone(self.clean_table), {
        {
            param = "weapon.kick",
            action = "remove_metas"
        },
        {
            param = "weapon.crosshair",
            action = "remove_metas"
        },
        {
            param = "weapon.stats",
            action = "remove_metas"
        },
        {
            param = "factory.default_blueprint",
            action = "remove_metas"
        },
        {
            param = "factory.uses_parts",
            action = "remove_metas"
        },
        {
            param = "factory.optional_types",
            action = "remove_metas"
        },
        {
            param = "factory.animations",
            action = "remove_metas"
        },
        {
            param = "factory.override",
            action = {"remove_metas", "no_number_indexes"}
        },
        {
            param = "factory.adds",
            action = {"remove_metas", "no_number_indexes"}
        }

    })
    if not self.super.init(self, core_mod, config) then
        return false
    end

    return true
end

function WeaponModuleNew:RegisterHook()
    local dlc = self._config.dlc or BeardLib.definitions.module_defaults.item.default_dlc
    self._config.unlock_level = self._config.unlock_level or 1
    Hooks:PostHook(WeaponTweakData, "_init_new_weapons", self._config.weapon.id .. "AddWeaponTweakData", function(w_self, autohit_rifle_default, autohit_pistol_default, autohit_shotgun_default, autohit_lmg_default, autohit_snp_default, autohit_smg_default, autohit_minigun_default, damage_melee_default, damage_melee_effect_multiplier_default, aim_assist_rifle_default, aim_assist_pistol_default, aim_assist_shotgun_default, aim_assist_lmg_default, aim_assist_snp_default, aim_assist_smg_default, aim_assist_minigun_default)
        local config = self._config.weapon

        if w_self[config.id] then
            self:log("[ERROR] Weapon with id '%s' already exists!", config.id)
            return
        end

        local default_autohit = {
            rifle = autohit_rifle_default,
            pistol = autohit_pistol_default,
            shotgun = autohit_shotgun_default,
            lmg = autohit_lmg_default,
            snp = autohit_snp_default,
            smg = autohit_smg_default,
            minigun = autohit_minigun_default,
        }

        local default_aim_assist = {
            rifle = aim_assist_rifle_default,
            pistol = aim_assist_pistol_default,
            shotgun = aim_assist_shotgun_default,
            lmg = aim_assist_lmg_default,
            snp = aim_assist_snp_default,
            smg = aim_assist_smg_default,
            minigun = aim_assist_minigun_default,
        }

        local data = table.merge(deep_clone(config.based_on and (w_self[config.based_on] ~= nil and w_self[config.based_on]) or w_self.glock_17), table.merge({
            name_id = "bm_w_" .. config.id,
            desc_id = "bm_w_" .. config.id .. "_desc",
            description_id = "des_" .. config.id,
            autohit = default_autohit[config.default_autohit],
            aim_assist = default_aim_assist[config.default_aim_assist],
            damage_melee = damage_melee_default,
            damage_melee_effect_mul = damage_melee_effect_multiplier_default,
            global_value = BeardLib.definitions.module_defaults.item.default_global_value,
            custom = true
        }, config))
        data.AMMO_MAX = data.CLIP_AMMO_MAX * data.NR_CLIPS_MAX
        data.AMMO_PICKUP = w_self:_pickup_chance(data.AMMO_MAX, config.ammo_pickup or 1)
        data.npc = nil
        data.override = nil

        if config.override then
            data = table.merge(data, config.override)
        end

        w_self[config.id] = data
    end)

    Hooks:Add("BeardLibCreateCustomWeapons", self._config.factory.id .. "AddWeaponFactoryTweakData", function(w_self)
        local config = self._config.factory
        if w_self[config.id] then
            self:log("[ERROR] Weapon with factory id '%s' already exists!", config.id)
            return
        end

        local data = table.merge({
            custom = true
        }, config)
        data.override = nil

        if config.override then
            data = table.merge(data, config.override)
        end

        w_self[config.id] = data
        w_self[config.id .. "_npc"] = table.merge(clone(data), {unit=config.unit .. "_npc"})
    end)

    Hooks:PostHook(UpgradesTweakData, "init", self._config.weapon.id .. "AddWeaponUpgradesData", function(u_self)
        u_self.definitions[self._config.weapon.id] = {
            category = "weapon",
            weapon_id = self._config.weapon.id,
            factory_id = self._config.factory.id,
            dlc = dlc
        }
        if self._config.unlock_level then
            u_self.level_tree[self._config.unlock_level] = u_self.level_tree[self._config.unlock_level] or {upgrades={}, name_id="weapons"}
            table.insert(u_self.level_tree[self._config.unlock_level].upgrades, self._config.weapon.id)
        end
    end)

    Hooks:PostHook(PlayerTweakData, "_init_new_stances", self._config.weapon.id .. "AddWeaponStancesData", function(p_self)
        local stance_data = self._config.stance
        p_self.stances[self._config.weapon.id] = table.merge(deep_clone(stance_data.based_on and (p_self.stances[stance_data.based_on] ~= nil and p_self.stances[stance_data.based_on]) or self._config.weapon.based_on and (p_self.stances[self._config.weapon.based_on] ~= nil and p_self.stances[self._config.weapon.based_on]) or p_self.stances.glock_17), stance_data)
    end)
end

BeardLib:RegisterModule(WeaponModuleNew.type_name, WeaponModuleNew)
