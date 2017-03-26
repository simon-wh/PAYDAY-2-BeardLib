core:import("CoreMissionScriptElement")
ElementPushInstigator = ElementPushInstigator or class(CoreMissionScriptElement.MissionScriptElement)
function ElementPushInstigator:on_script_activated()
    self._mission_script:add_save_state_cb(self._id)
end
 
function ElementPushInstigator:client_on_executed(...)
    self:on_executed(...)
end
 
function ElementPushInstigator:on_executed(instigator)
    if not self._values.enabled then
        return
    end
    if alive(instigator) then
        local velocity = self._values.velocity
        local pos = self._values.forward and instigator:camera():forward() or velocity
        mvector3.multiply(pos, self._values.multiply or 1)
        instigator:push(self._values.mass, pos:with_z(self._values.no_z and 0 or pos.z))
    end
    self.super.on_executed(self, instigator)
end