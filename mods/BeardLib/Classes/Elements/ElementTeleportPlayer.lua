core:import("CoreMissionScriptElement")
ElementTeleportPlayer = ElementTeleportPlayer or class(CoreMissionScriptElement.MissionScriptElement)

function ElementTeleportPlayer:on_script_activated()
    self._mission_script:add_save_state_cb(self._id)
end
 
function ElementTeleportPlayer:client_on_executed(...)
    self:on_executed(...)
end
 
function ElementTeleportPlayer:on_executed(instigator)
    if not self._values.enabled then
        return
    end
   
    if self._values.use_instigator then
        if instigator == managers.player:player_unit() then
            if alive(instigator) then
                managers.player:warp_to(self._values.position, self._values.rotation, managers.player:player_id(instigator))
            end
        end
    else
        for i, _ in pairs(managers.player._players) do
            managers.player:warp_to(self._values.position, self._values.rotation, i)
        end
    end
 
    ElementTeleportPlayer.super.on_executed(self, instigator)
end

function ElementTeleportPlayer:save(data)
    data.save_me = true
    data.enabled = self._values.enabled
end

function ElementTeleportPlayer:load(data)
    self:set_enabled(data.enabled)
end
