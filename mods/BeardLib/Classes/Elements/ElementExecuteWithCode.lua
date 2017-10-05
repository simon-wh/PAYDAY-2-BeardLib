--ElementExecuteWithCode--
--Created by Luffy

core:import("CoreMissionScriptElement")
ElementExecuteWithCode = ElementExecuteWithCode or class(CoreMissionScriptElement.MissionScriptElement)

function ElementExecuteWithCode:on_script_activated()
    self._mission_script:add_save_state_cb(self._id)
end
 
function ElementExecuteWithCode:client_on_executed(...)
    self:on_executed(...)
end
 
function ElementExecuteWithCode:on_executed(instigator)
    if not self._values.enabled then
        return
    end
    local execute = true

    if self._values.code then
        local ret, data = pcall(function()
            execute = loadstring(self._values.code)()
        end)
        if not ret then
            BeardLib:log("Error while executing ElementExecuteWithCode, Id %s Name %s", tostring(self._values.id), tostring(self._values.editor_name))
        end
    end
    if execute then
        ElementExecuteWithCode.super.on_executed(self, instigator)
    end
end

function ElementExecuteWithCode:save(data)
    data.save_me = true
    data.enabled = self._values.enabled
end

function ElementExecuteWithCode:load(data)
    self:set_enabled(data.enabled)
end
