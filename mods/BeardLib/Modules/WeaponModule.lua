WeaponModule = WeaponModule or class(ModuleBase)

WeaponModule.type_name = "Weapon"
WeaponModule._loose = true

function WeaponModule:init(core_mod, config)
    self.super.init(self, core_mod, config)
end

function WeaponModule:RegisterHook()
    local dlc = self._config.dlc or BeardLib.definitions.module_defaults.mask.default_dlc
    self._config.unlock_level = self._config.unlock_level or 1
    self._config.fac_id = self._config.fac_id or "wpn_fps_" .. self._config.id
    Hooks:PostHook(WeaponTweakData, "_init_new_weapons", self._config.id .. "AddWeaponTweakData", function(w_self, autohit_rifle_default, autohit_pistol_default, autohit_shotgun_default, autohit_lmg_default, autohit_snp_default, autohit_smg_default, autohit_minigun_default, damage_melee_default, damage_melee_effect_multiplier_default, aim_assist_rifle_default, aim_assist_pistol_default, aim_assist_shotgun_default, aim_assist_lmg_default, aim_assist_snp_default, aim_assist_smg_default, aim_assist_minigun_default)
        if w_self[self._config.id] then
            self._mod:log("[ERROR] Weapon with id '%s' already exists!", self._config.id)
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

        local data = table.merge(self._config.based_on and (w_self[self._config.based_on] ~= nil and w_self[self._config.based_on]) or w_self.glock_17, {
            name_id = self._config.name_id or "bm_w_" .. self._config.id,
            desc_id = self._config.desc_id or "bm_w_" .. self._config.id .. "_desc",
            description_id = self._config.description_id or "des_" .. self._config.id,
            muzzleflash = self._config.muzzleflash,
            shell_ejection = self._config.shell_ejection,
            use_data = self._config.use_data,
            DAMAGE = self._config.DAMAGE,
            damage_near = self._config.damage_near,
            damage_far = self._config.damage_far,

            kick = BeardLib.Utils:RemoveMetas(self._config.kick),
            crosshair = BeardLib.Utils:RemoveMetas(self._config.crosshair),
            shake = self._config.shake,
            autohit = self._config.autohit and (default_autohit[self._config.autohit] ~= nil and default_autohit[self._config.autohit] or self._config.autohit),
            aim_assist = self._config.aim_assist and (default_aim_assist[self._config.aim_assist] ~= nil and default_aim_assist[self._config.aim_assist] or self._config.aim_assist),
            weapon_hold = self._config.weapon_hold,
            animations = self._config.animations,
            texture_bundle_folder = self._config.texture_bundle_folder,
            panic_suppression_chance = self._config.panic_suppression_chance,
            stats = BeardLib.Utils:RemoveMetas(self._config.stats, true),

            rays = self._config.rays,
            CLIP_AMMO_MAX = self._config.CLIP_AMMO_MAX,
            NR_CLIPS_MAX = self._config.NR_CLIPS_MAX,
            FIRE_MODE = self._config.FIRE_MODE,
            fire_mode_data = self._config.fire_mode_data,
            single = self._config.single,
            spread = self._config.spread,

            damage_melee = self._config.damage_melee or damage_melee_default,
            damage_melee_effect_mul = self._config.damage_melee_effect_mul or damage_melee_effect_multiplier_default,
            category = self._config.category,
            sub_category = self._config.sub_category,
            sounds = self._config.sounds,
            timers = self._config.timers,
            global_value = self._config.global_value or BeardLib.definitions.module_defaults.mask.default_global_value,
            custom = true
        })
        data.AMMO_MAX = data.CLIP_AMMO_MAX * data.NR_CLIPS_MAX
        data.AMMO_PICKUP = w_self:_pickup_chance(data.AMMO_MAX, self._config.ammo_pickup or 1)

        if self._config.merge_data then
            table.merge(data, self._config.merge_data)
        end
        w_self[self._config.id] = data
    end)

    Hooks:Add("BeardLibCreateCustomWeapons", self._config.fac_id .. "AddWeaponFactoryTweakData", function(w_self)

        if w_self[self._config.fac_id] then
            self._mod:log("[ERROR] Weapon with factory id '%s' already exists!", self._config.id)
            return
        end

        local data = {
            unit = self._config.unit,
            default_blueprint = BeardLib.Utils:RemoveMetas(self._config.default_blueprint, true),
            uses_parts = BeardLib.Utils:RemoveMetas(self._config.uses_parts, true),
            optional_types = BeardLib.Utils:RemoveMetas(self._config.optional_types, true),
            animations = BeardLib.Utils:RemoveMetas(self._config.animations, true),
            adds = BeardLib.Utils:RemoveMetas(BeardLib.Utils:RemoveAllNumberIndexes(self._config.adds, true), true),
            custom = true
        }

        if self._config.fac_merge_data then
            table.merge(data, self._config.fac_merge_data)
        end

        w_self[self._config.fac_id] = data
        w_self[self._config.fac_id .. "_npc"] = data
    end)

    Hooks:PostHook(UpgradesTweakData, "init", self._config.id .. "AddWeaponUpgradesData", function(u_self)
        u_self.definitions[self._config.id] = {
            category = "weapon",
            weapon_id = self._config.id,
            factory_id = self._config.fac_id,
            dlc = dlc
        }
        if self._config.unlock_level then
            u_self.level_tree[self._config.unlock_level] = u_self.level_tree[self._config.unlock_level] or {upgrades={}, name_id="weapons"}
            table.insert(u_self.level_tree[self._config.unlock_level].upgrades, self._config.id)
        end
    end)

    Hooks:PostHook(PlayerTweakData, "_init_new_stances", self._config.id .. "AddWeaponStancesData", function(p_self)
        local stance_data = self._config.stance or {}
        local data = table.merge(stance_data.based_on and (p_self.stances[stance_data.based_on] ~= nil and p_self.stances[stance_data.based_on]) or self._config.based_on and (p_self.stances[self._config.based_on] ~= nil and p_self.stances[self._config.based_on]) or p_self.stances.glock_17, {
            standard = stance_data.standard,
            steelsight = stance_data.steelsight,
            crouched = stance_data.crouched,
        })

        if stance_data.merge_data then
            table.merge(data, stance_data.merge_data)
        end

        p_self.stances[self._config.id] = data
    end)
end

BeardLib:RegisterModule(WeaponModule.type_name, WeaponModule)
