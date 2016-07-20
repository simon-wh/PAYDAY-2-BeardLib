MeleeModule = MeleeModule or class(ModuleBase)

MeleeModule.type_name = "Melee"
MeleeModule._loose = true

function MeleeModule:init(core_mod, config)
    self.super.init(self, core_mod, config)
end

function MeleeModule:RegisterHook()
    local dlc = self._config.dlc or BeardLib.definitions.module_defaults.mask.default_dlc
    self._config.unlock_level = self._config.unlock_level or 1
    Hooks:PostHook(BlackMarketTweakData, "_init_melee_weapons", self._config.id .. "AddMeleeData", function(bm_self)
        if bm_self.melee_weapons[self._config.id] then
            self._mod:log("[ERROR] Melee weapon with id '%s' already exists!", self._config.id)
            return
        end

        bm_self.melee_weapons[self._config.id] = table.merge(self._config.based_on and (bm_self.melee_weapons[self._config.based_on] ~= nil and clone(bm_self.melee_weapons[self._config.based_on])) or bm_self.melee_weapons.kabar, {
            name_id = self._config.name_id or "bm_melee_" .. self._config.id,
            unit = self._config.unit,
            third_unit = self._config.third_unit,
            dlc = dlc,
            texture_bundle_folder = self._config.texture_bundle_folder,
            animation = self._config.animation,
            stats = self._config.stats,
            sounds = self._config.sounds,
            anim_global_param = self._config.anim_global_param,
            anim_attack_vars = self._config.anim_attack_vars,
            repeat_expire_t = self._config.repeat_expire_t,
            expire_t = self._config.expire_t,
            melee_damage_delay = self._config.melee_damage_delay,
            custom = true,
            free = not self._config.unlock_level
        })
        if self._config.merge_data then
            table.merge(bm_self.melee_weapons[self._config.id], self._config.merge_data)
        end
    end)

    Hooks:PostHook(UpgradesTweakData, "init", self._config.id .. "AddMeleeUpgradesData", function(u_self)
        u_self.definitions[self._config.id] = {
            category = "melee_weapon",
            dlc = dlc
        }
        if self._config.unlock_level then
            u_self.level_tree[self._config.unlock_level] = u_self.level_tree[self._config.unlock_level] or {upgrades={}, name_id="weapons"}
            table.insert(u_self.level_tree[self._config.unlock_level].upgrades, self._config.id)
        end
    end)
end

BeardLib:RegisterModule(MeleeModule.type_name, MeleeModule)
