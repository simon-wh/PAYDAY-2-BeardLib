InteractionModule = InteractionModule or class(ItemModuleBase)
InteractionModule.type_name = "Interaction"

function InteractionModule:RegisterHook()
    Hooks:PostHook(InteractionTweakData, "init", self._config.id .. "AddInteractionData", function(i_self)
        if i_self[self._config.id] then
            BeardLib:log("[ERROR] Interaction with id '%s' already exists!", self._config.id)
            return
        end
        self._config.text_id = self._config.text_id or "hud_"..self._config.id
        i_self[self._config.id] = table.merge(deep_clone(self._config.based_on and i_self[self._config.based_on]) or {}, self._config.item or self._config)
    end)
end

BeardLib:RegisterModule(InteractionModule.type_name, InteractionModule)