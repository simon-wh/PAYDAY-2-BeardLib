InteractionModule = InteractionModule or class(ItemModuleBase)
InteractionModule.type_name = "Interactions"

function InteractionModule:RegisterHook()
    Hooks:PostHook(InteractionTweakData, "init", self._config.id .. "AddInteractionData", function(i_self)
        for _, data in ipairs(self._config) do
            if data._meta == "interaction" then
                if i_self[data.id] then
                    BeardLib:log("[ERROR] Interaction with id '%s' already exists!", data.id)
                else
                    data.text_id = data.text_id or "hud_"..data.id
                    i_self[data.id] = table.merge(deep_clone(data.based_on and i_self[data.based_on]) or {}, data.item or data)
                end
            end
        end
    end)
end

BeardLib:RegisterModule(InteractionModule.type_name, InteractionModule)