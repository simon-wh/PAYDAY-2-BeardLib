GlobalValueModule = GlobalValueModule or class(ModuleBase)

GlobalValueModule.type_name = "GlobalValue"
GlobalValueModule._loose = true

function GlobalValueModule:init(core_mod, config)
    self.super.init(self, core_mod, config)
end

function GlobalValueModule:RegisterHook()
    if not self._config.id then
        self._mod:log("[ERROR] Global Value does not contain a definition for id!")
        return
    end

    Hooks:PostHook(LootDropTweakData, "init", self._config.id .. "AddGlobalValueData", function(loot_self, tweak_data)
        if loot_self.global_values[self._config.id] and not self._config.overwrite then
            self._mod:log("[ERROR] Global value with key %s already exists! overwrite should be set to true if this is intentional.")
            return
        end

        loot_self.global_values[self._config.id] = {
            name_id = self._config.name_id or "bm_global_value_" .. self._config.id,
            desc_id = self._config.desc_id or "menu_l_global_value_" .. self._config.id,
            color = self._config.color and BeardLib.Utils:normalize_string_value(self._config.color) or Color.white,
            dlc = self._config.dlc ~= nil and self._config.dlc or false,
            chance = self._config.chance or 1,
            value_multiplier = self._config.value_multiplier or 1,
            drops = not not self._config.drops,
            track = self._config.track ~= nil and self._config.track or false,
            sort_number = self._config.sort_number or 0,
            category = not self._config.is_category and (self._config.category or "mod") or nil,
        }

        table.insert(loot_self.global_value_list_index, self._config.id)
        loot_self.global_value_list_map[self._config.id] = #loot_self.global_value_list_index
    end)
end

BeardLib:RegisterModule(GlobalValueModule.type_name, GlobalValueModule)
