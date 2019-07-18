--Based of ElementMoveUnit

core:import("CoreMissionScriptElement")
ElementRotateUnit = ElementRotateUnit or class(ElementMoveUnit)

function ElementRotateUnit:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if not self._values.end_rot then
		BeardLib:log("[ERROR] Rotateunit must have an end rotation defined!")
		return
	end

	--Sync before beginning the move
	if Network:is_server() then
		if instigator and alive(instigator) and instigator:id() ~= -1 then
			managers.network:session():send_to_peers_synched("run_mission_element", self._id, instigator, self._last_orientation_index or 0)
		else
			managers.network:session():send_to_peers_synched("run_mission_element_no_instigator", self._id, self._last_orientation_index or 0)
		end
	end

	if #self._units == 0 and alive(instigator) then
		self:register(instigator)
	else
		for _, unit in pairs(self._units) do
			self:register(unit)
		end
	end
end

function ElementRotateUnit:register(unit)
	if self._values.remember_unit_rot then
		unit:unit_data().orig_rot = unit:unit_data().orig_rot or mrotation.copy(unit:rotation())
	end

	local start_rot = self._values.use_unit_rot and unit:unit_data().orig_rot or unit:rotation() or self._values.rotation
	local end_rot = self._values.end_rot
	--[[
	broken :/
	if not end_rot and self._values.offset then
		end_rot = mrotation.copy(start_rot)
		mrotation.multiply(end_rot, self._values.offset)
		end_rot = end_rot:inverse()
	end
	]]
	managers.game_play_central:add_rotate_unit(unit, start_rot, end_rot, self._values.speed, ClassClbk(self, "done_callback", unit))
end