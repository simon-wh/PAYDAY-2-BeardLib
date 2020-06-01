--ElementOverrideInstigator--
--Created by Luffy

core:import("CoreMissionScriptElement")
ElementOverrideInstigator = ElementOverrideInstigator or class(CoreMissionScriptElement.MissionScriptElement)

function ElementOverrideInstigator:on_script_activated()
    self._mission_script:add_save_state_cb(self._id)
end

function ElementOverrideInstigator:client_on_executed(...)
    self:on_executed(...)
end

function ElementOverrideInstigator:on_executed(instigator)
    if not self._values.enabled then
        return
    end

    local override = self._values.unit_id and managers.worlddefinition:get_unit(self._values.unit_id)
    instigator = override or instigator

    ElementOverrideInstigator.super.on_executed(self, instigator)
end

function ElementOverrideInstigator:save(data)
    data.save_me = true
    data.enabled = self._values.enabled
end

function ElementOverrideInstigator:load(data)
    self:set_enabled(data.enabled)
end