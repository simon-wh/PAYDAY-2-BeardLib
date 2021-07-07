LootBagsModule = LootBagsModule or BeardLib:ModuleClass("LootBags", ItemModuleBase)
LootBagsModule.required_params = {}
function LootBagsModule:AddLootbagsDataToTweak(c_self)
    for _, data in ipairs(self._config) do
        if data._meta == "carry" then
            if c_self[data.id] then
                self:Err("Carry data with id '%s' already exists!", data.id)
            else
                data.name_id = data.name_id or ("hud_"..data.id)
                c_self[data.id] = table.merge(data.based_on and deep_clone(c_self[data.based_on] or {}) or {}, data.item or data)
            end
        end
    end
end
function LootBagsModule:RegisterHook()
    local first = BeardLib.Utils.XML:GetNode(self._config, "carry")
    if first then
        if tweak_data and tweak_data.carry then
            self:AddLootbagsDataToTweak(tweak_data.carry)
        else
            Hooks:PostHook(CarryTweakData, "init", self._mod.Name..'/'..first.id .. "AddCarryData", ClassClbk(self, "AddLootbagsDataToTweak"))
        end
    end
end