InteractionsModule = InteractionsModule or BeardLib:ModuleClass("Interactions", ItemModuleBase)
InteractionsModule.required_params = {}
function InteractionsModule:AddInteractionsDataToTweak(i_self)
    for _, data in ipairs(self._config) do
        if data._meta == "interaction" then
            if i_self[data.id] then
                self:Err("Interaction with id '%s' already exists!", data.id)
            else
                data.text_id = data.text_id or ("hud_"..data.id)
                i_self[data.id] = table.merge(data.based_on and deep_clone(i_self[data.based_on] or {}) or {}, data.item or data)
            end
        end
    end
end
function InteractionsModule:RegisterHook()
    local first = BeardLib.Utils.XML:GetNode(self._config, "interaction")
    if first then
        if tweak_data and tweak_data.interaction then
            self:AddInteractionsDataToTweak(tweak_data.interaction)
        else
            Hooks:PostHook(InteractionTweakData, "init", self._mod.Name..'/'..first.id .. "AddInteractionData", ClassClbk(self, "AddInteractionsDataToTweak"))
        end
    end
end