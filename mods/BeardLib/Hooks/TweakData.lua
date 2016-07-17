BeardLib.managers.MapFramework:RegisterHooks()
BeardLib.managers.AddFramework:RegisterHooks()

Hooks:PostHook(LootDropTweakData, "init", "BeardLibLootDropTweakDataInit", function(self, tweak_data)
    self.global_values.mod = {
        name_id = "bm_global_value_mod",
    	desc_id = "menu_l_global_value_mod",
    	color = Color(255, 59, 174, 254) / 255,
    	dlc = false,
    	chance = 1,
    	value_multiplier = tweak_data:get_value("money_manager", "global_value_multipliers", "exceptional"),
    	durability_multiplier = 1,
    	--drops = false,
    	track = false,
    	sort_number = -10,
    	--category = "mod"
    }

    table.insert(self.global_value_list_index, "mod")
end)

Hooks:PostHook(DLCTweakData, "init", "BeardLibDLCTweakDataInit", function(self, tweak_data)
    self.mod = {
        free = true,
        content = {
            --loot_global_value = "mod",
            loot_drops = BeardLib._mod_lootdrop_items
        }
    }
end)
