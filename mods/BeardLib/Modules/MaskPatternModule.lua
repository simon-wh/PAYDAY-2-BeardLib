MaskPatternModule = MaskPatternModule or class(ModuleBase)

MaskPatternModule.type_name = "MaskPattern"
MaskPatternModule._loose = true

function MaskPatternModule:init(core_mod, config)
    self.super.init(self, core_mod, config)
end

function MaskPatternModule:RegisterHook()
    self._config.default_amount = self._config.default_amount and tonumber(self._config.default_amount) or 1
    Hooks:PostHook(BlackMarketTweakData, "_init_materials", self._config.id .. "AddMaskPatternData", function(bm_self)
        if bm_self.textures[self._config.id] then
            self._mod:log("[ERROR] Mask Pattern with id '%s' already exists!", self._config.id)
            return
        end
        local data = {
            name_id = self._config.name_id or "pattern_" .. self._config.id .. "_title",
            texture = self._config.texture,
            dlc = self._config.dlc or BeardLib.definitions.module_defaults.mask.default_dlc,
            texture_bundle_folder = self._config.texture_bundle_folder,
            pcs = self._config.pcs and BeardLib.Utils:RemoveNonNumberIndexes(self._config.pcs) or {},
            pc = self._config.pc,
            value = self._config.value or 0,
            infamous = self._config.infamous,
            global_value = self._config.global_value or BeardLib.definitions.module_defaults.mask.default_global_value,
            custom = true
        }
        if self._config.merge_data then
            table.merge(data, self._config.merge_data)
        end
        bm_self.textures[self._config.id] = data
        if data.dlc == BeardLib.definitions.module_defaults.mask.default_dlc then
            table.insert(BeardLib._mod_lootdrop_items, {
                type_items = "textures",
                item_entry = self._config.id,
                amount = self._config.default_amount,
                global_value = data.global_value ~= BeardLib.definitions.module_defaults.mask.default_global_value and data.global_value or nil
            })

        end
    end)
end

BeardLib:RegisterModule(MaskPatternModule.type_name, MaskPatternModule)
