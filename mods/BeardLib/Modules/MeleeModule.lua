MeleeModule = MeleeModule or class(ItemModuleBase)

MeleeModule.type_name = "Melee"

function MeleeModule:init(core_mod, config)
    if not MeleeModule.super.init(self, core_mod, config) then
        return false
    end

    return true
end

function MeleeModule:RegisterHook()
    local dlc
    self._config.unlock_level = self._config.unlock_level or 1
    Hooks:PostHook(BlackMarketTweakData, "_init_melee_weapons", self._config.id .. "AddMeleeData", function(bm_self)
        if bm_self.melee_weapons[self._config.id] then
            BeardLib:log("[ERROR] Melee weapon with id '%s' already exists!", self._config.id)
            return
        end

        local data = table.merge(deep_clone(self._config.based_on and (bm_self.melee_weapons[self._config.based_on] ~= nil and bm_self.melee_weapons[self._config.based_on]) or bm_self.melee_weapons.kabar), table.merge({
            name_id = "bm_melee_" .. self._config.id,
            dlc = self.defaults.dlc,
            custom = true,
            free = not self._config.unlock_level
        }, self._config.item or self._config))
        dlc = data.dlc
        bm_self.melee_weapons[self._config.id] = data

        if dlc then
            TweakDataHelper:ModifyTweak({self._config.id}, "dlc", dlc, "content", "upgrades")
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
