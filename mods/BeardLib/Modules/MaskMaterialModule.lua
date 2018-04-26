MaskMaterialModule = MaskMaterialModule or class(ItemModuleBase)
MaskMaterialModule.type_name = "MaskMaterial"

function MaskMaterialModule:init(...)
    self.clean_table = table.add(clone(self.clean_table), {{param = "pcs", action = "no_number_indexes" }})
    self.required_params = table.add(clone(self.required_params), {"texture"})
    return MaskMaterialModule.super.init(self, ...)
end

function MaskMaterialModule:RegisterHook()
    self._config.default_amount = self._config.default_amount and tonumber(self._config.default_amount) or 1
    Hooks:PostHook(BlackMarketTweakData, "_init_materials", self._config.id .. "AddMaskMaterialData", function(bm_self)
        if bm_self.materials[self._config.id] then
            BeardLib:log("[ERROR] Mask Material with id '%s' already exists!", self._config.id)
            return
        end
        local data = table.merge({
            name_id = "material_" .. self._config.id .. "_title",
            dlc = self.defaults.dlc,
            value = 0,
            global_value = self.defaults.global_value,
            custom = true
        }, self._config.item or self._config)
        bm_self.materials[self._config.id] = data
        if data.dlc then
            TweakDataHelper:ModifyTweak({{
                type_items = "materials",
                item_entry = self._config.id,
                amount = self._config.default_amount,
                global_value = data.global_value
            }}, "dlc", data.dlc, "content", "loot_drops")
        end
    end)
end

BeardLib:RegisterModule(MaskMaterialModule.type_name, MaskMaterialModule)