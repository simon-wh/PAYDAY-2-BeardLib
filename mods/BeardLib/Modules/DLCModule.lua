DLCModule = DLCModule or class(ModuleBase)

DLCModule.type_name = "DLC"

function DLCModule:init(core_mod, config)
    self.required_params = table.add(clone(self.required_params), {"id"})

    if not DLCModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()
    return true
end

function DLCModule:Load()
    TweakDataHelper:ModifyTweak(table.merge({
        free = true,
        content = {
            --loot_global_value = "mod",
            loot_drops = {},
            upgrades = {}
        }
    }, self._config), "dlc", self._config.id)
end

BeardLib:RegisterModule(DLCModule.type_name, DLCModule)
