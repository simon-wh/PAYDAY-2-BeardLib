BeardLib.definitions.module_defaults.mask = {
    default_global_value = "mod",
    default_dlc = "mod"
}

MaskModule = MaskModule or class(ModuleBase)

MaskModule.type_name = "Mask"
MaskModule._loose = true

function MaskModule:init(core_mod, config)
    self.super.init(self, core_mod, config)
end

function MaskModule:RegisterHook()
    self._config.default_amount = self._config.default_amount and tonumber(self._config.default_amount) or 1
    Hooks:PostHook(BlackMarketTweakData, "_init_masks", self._config.id .. "AddMaskData", function(bm_self)
        if bm_self.masks[self._config.id] then
            self._mod:log("[ERROR] Mask with id '%s' already exists!", self._config.id)
            return
        end
        local data = {
            name_id = self._config.name_id or "bm_msk_" .. self._config.id,
            desc_id = self._config.brief_id or "bm_msk_" .. self._config.id .. "_desc",
            unit = self._config.unit,
            dlc = self._config.dlc or BeardLib.definitions.module_defaults.mask.default_dlc,
            texture_bundle_folder = self._config.texture_bundle_folder,
            pcs = self._config.pcs and BeardLib.Utils:RemoveNonNumberIndexes(self._config.pcs) or {},
            pc = self._config.pc,
            sort_number = self._config.sort_number,
            type = self._config.type,
            skip_mask_on_sequence = self._config.skip_mask_on_sequence,
            value = self._config.value or 0,
            infamous = self._config.infamous,
            global_value = self._config.global_value or BeardLib.definitions.module_defaults.mask.default_global_value,
            custom = true
        }
        if self._config.merge_data then
            table.merge(data, self._config.merge_data)
        end
        bm_self.masks[self._config.id] = data
        if data.dlc == BeardLib.definitions.module_defaults.mask.default_dlc then
            table.insert(BeardLib._mod_lootdrop_items, {
                type_items = "masks",
                item_entry = self._config.id,
                amount = self._config.default_amount,
                global_value = data.global_value ~= BeardLib.definitions.module_defaults.mask.default_global_value and data.global_value or nil
            })

        end
    end)
    --[[Hooks:Add("MenuManagerOnOpenMenu", self._config.id .. "AddMaskToPlayer", function( self_menu, menu, index )
        if menu == "menu_main" then
            local global_value = self._config.global_value or self._default_global_value
            local current_amount = (managers.blackmarket:get_item_amount(global_value, "masks", self._config.id, true) + managers.blackmarket:get_crafted_item_amount("masks", self._config.id))
            if current_amount < self._config.max_amount then
                while current_amount < self._config.max_amount do
                    log(string.format("added %s to the inventory", self._config.id))
        			managers.blackmarket:add_to_inventory(global_value, "masks", self._config.id, false)
                    current_amount = current_amount + 1
                end
            elseif current_amount > self._config.max_amount then
                while current_amount > self._config.max_amount do
                    log(string.format("removed %s from the inventory", self._config.id))
                    managers.blackmarket:remove_item(global_value, "masks", self._config.id)
                    current_amount = current_amount - 1
                end
            end
        end
    end)]]--
end

BeardLib:RegisterModule(MaskModule.type_name, MaskModule)
