MaskPatternModule = MaskPatternModule or class(ItemModuleBase)
MaskPatternModule.type_name = "MaskPattern"

function MaskPatternModule:init(...)
    self.clean_table = table.add(clone(self.clean_table), {{param = "pcs",action = "no_number_indexes"}})
    self.required_params = table.add(clone(self.required_params), {"texture"})
    return MaskPatternModule.super.init(self, ...)
end

function MaskPatternModule:RegisterHook()
    self._config.default_amount = self._config.default_amount ~= nil and tonumber(self._config.default_amount) or 1
    Hooks:PostHook(BlackMarketTweakData, "_init_textures", self._config.id .. "AddMaskPatternData", function(bm_self)
        if bm_self.textures[self._config.id] then
            BeardLib:log("[ERROR] Mask Pattern with id '%s' already exists!", self._config.id)
            return
        end
        local data = table.merge({
            name_id = "pattern_" .. self._config.id .. "_title",
            dlc = self.defaults.dlc,
            pcs = {},
			value = 0,
			texture_bundle_folder = "mods",
            global_value = self.defaults.global_value,
            custom = true
        }, self._config)
        bm_self.textures[self._config.id] = data
        if data.dlc then
            TweakDataHelper:ModifyTweak({{
                type_items = "textures",
                item_entry = self._config.id,
                amount = self._config.default_amount,
                global_value = data.global_value
            }}, "dlc", data.dlc, "content", "loot_drops")
        end
    end)
end

BeardLib:RegisterModule(MaskPatternModule.type_name, MaskPatternModule)