--ElementExecuteWithCode--
--Created by Luffy

core:import("CoreMissionScriptElement")
ElementExecuteWithCode = ElementExecuteWithCode or class(CoreMissionScriptElement.MissionScriptElement)

function ElementExecuteWithCode:on_script_activated()
    BeardLib:Err("The element ElementExecuteWithCode has been deprecated. Please use ElementExecuteCode instead. See issue #473 for details.")
    self._mission_script:add_save_state_cb(self._id)
end

function ElementExecuteWithCode:client_on_executed(...)
    self:on_executed(...)
end

function ElementExecuteWithCode:save(data)
    data.save_me = true
    data.enabled = self._values.enabled
end

function ElementExecuteWithCode:load(data)
    self:set_enabled(data.enabled)
end
