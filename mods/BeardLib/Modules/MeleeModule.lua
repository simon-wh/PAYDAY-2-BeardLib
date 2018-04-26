MeleeModule = MeleeModule or class(ItemModuleBase)
MeleeModule.type_name = "Melee"

local default_melee = "kabar"
function MeleeModule:GetBasedOn(melees, based_on)
    melees = melees or tweak_data.blackmarket.melee_weapons
    based_on = based_on or self._config.based_on
    if based_on and melees[based_on] then
        return based_on
    else
        return default_melee
    end
end

function MeleeModule:RegisterHook()
    local dlc
    self._config.unlock_level = self._config.unlock_level or 1
    Hooks:PostHook(BlackMarketTweakData, "_init_melee_weapons", self._config.id .. "AddMeleeData", function(bm_self)
        if bm_self.melee_weapons[self._config.id] then
            BeardLib:log("[ERROR] Melee weapon with id '%s' already exists!", self._config.id)
            return
        end
        local data = table.merge(deep_clone(bm_self.melee_weapons[self:GetBasedOn(bm_self.melee_weapons)]), table.merge({
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

    Hooks:PostHook(TweakDataVR , "init", self._config.id .. "AddVRMeleeTweakData", function(vrself)
        local config = self._config.vr or {}

        local id = self._config.id
        if config.locked then
            vrself.locked.melee_weapons[id] = true
            return
        end

        local tweak_offsets = vrself.melee_offsets
        local offsets = tweak_offsets[self:GetBasedOn(tweak_offsets, config.based_on)]

        tweak_offsets[id] = offsets and table.merge(offsets, config.offsets) or config.offsets or nil
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