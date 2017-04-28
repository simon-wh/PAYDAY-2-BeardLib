MaskModule = MaskModule or class(ItemModuleBase)

MaskModule.type_name = "Mask"

function MaskModule:init(core_mod, config)
    self.clean_table = table.add(clone(self.clean_table), {
        {
            param ="pcs",
            action = "no_number_indexes"
        }
    })
    if not self.super.init(self, core_mod, config) then
        return false
    end

    return true
end

function MaskModule:RegisterHook()
    self._config.default_amount = self._config.default_amount and tonumber(self._config.default_amount) or 1
    Hooks:PostHook(BlackMarketTweakData, "_init_masks", self._config.id .. "AddMaskData", function(bm_self)
        if bm_self.masks[self._config.id] then
            BeardLib:log("[ERROR] Mask with id '%s' already exists!", self._config.id)
            return
        end
        local data = table.merge({
            name_id = "bm_msk_" .. self._config.id,
            desc_id = "bm_msk_" .. self._config.id .. "_desc",
            dlc = self.defaults.dlc,
            pcs = {},
            value = 0,
            global_value = self.defaults.global_value,
            custom = true
        }, self._config.item or self._config)
        bm_self.masks[self._config.id] = data
        if data.drop ~= false and data.dlc then
            TweakDataHelper:ModifyTweak({{
                type_items = "masks",
                item_entry = self._config.id,
                amount = self._config.default_amount,
                global_value = data.global_value
            }}, "dlc", data.dlc, "content", "loot_drops")
        end
    end)
end

BeardLib:RegisterModule(MaskModule.type_name, MaskModule)
