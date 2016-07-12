MaskModule = MaskModule or class(ModuleBase)

MaskModule.type_name = "Mask"
MaskModule._loose = true
MaskModule._default_dlc = "pd2_clan"

function MaskModule:init(core_mod, config)
    self.super.init(self, core_mod, config)
end

function MaskModule:RegisterHook()
    self._config.max_amount = self._config.max_amount or 1
    Hooks:PostHook(BlackMarketTweakData, "_init_masks", self._config.id .. "AddMaskData", function(bm_self)
        bm_self.masks[self._config.id] = {
            name_id = self._config.name_id or "mask_" .. self._config.id .. "_title",
            desc_id = self._config.brief_id or "mask_" .. self._config.id .. "_desc",
            unit = self._config.unit,
            dlc = self._config.dlc or self._default_dlc, --Should change this to a 'mod' dlc
            texture_bundle_folder = self._config.texture_bundle_folder,
            pcs = self._config.pcs and BeardLib.Utils:RemoveNonNumberIndexes(self._config.pcs) or {},
            sort_number = self._config.sort_number,
            type = self._config.type,
            skip_mask_on_sequence = self._config.skip_mask_on_sequence,
            value = self._config.value or -1,
            infamous = self._config.infamous,
            custom = true
        }
        if self._config.merge_data then
            table.merge(narr_self.jobs[self._config.id], self._config.merge_data)
        end
    end)
    Hooks:Add("MenuManagerOnOpenMenu", self._config.id .. "AddMaskToPlayer", function( self_menu, menu, index )
        if menu == "menu_main" then
            local current_amount = (managers.blackmarket:get_item_amount(self._config.dlc or self._default_dlc, "masks", self._config.id, true) + managers.blackmarket:get_crafted_item_amount("masks", self._config.id))
            if current_amount < self._config.max_amount then
                while current_amount < self._config.max_amount do
                    log(string.format("added %s to the inventory", self._config.id))
        			managers.blackmarket:add_to_inventory(self._config.dlc or self._default_dlc, "masks", self._config.id, true)
                    current_amount = current_amount + 1
                end
            end
        end
    end)
end

BeardLib:RegisterModule(MaskModule.type_name, MaskModule)
