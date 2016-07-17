function GamePlayCentralManager:add_move_unit(unit, start_pos, end_pos, speed, done_callback)
	self._move_units = self._move_units or {}
    for k, move_unit in pairs(self._move_units) do
        if move_unit.unit == unit then
			table.remove(self._move_units, k)
        end
    end

	if not alive(unit) then
        return
    end
	start_pos = start_pos or unit:position()
	speed = speed or 1
	local total_time = mvector3.distance(start_pos, end_pos) / speed

	table.insert(self._move_units, {unit = unit, start_pos = start_pos, end_pos = end_pos, speed = speed, done_callback = done_callback, t=0, total_time = total_time})
end
function GamePlayCentralManager:add_rotate_unit(unit, from, to, speed)

end
Hooks:PostHook(GamePlayCentralManager, "update", "BeardLibGamePlayCentralManagerpost_update", function(self, t, dt)
	for k, move_unit in pairs(self._move_units or {}) do
		if move_unit.t == move_unit.total_time then
			table.remove(self._move_units, k)
            move_unit.done_callback()
		else
			local pos = Vector3()
			move_unit.t = math.min(move_unit.t + dt, move_unit.total_time)
            mvector3.step(pos, move_unit.start_pos, move_unit.end_pos, move_unit.speed * move_unit.t)
            if not alive(move_unit.unit) then
				table.remove(self._move_units, k)
			else
				self:set_position(move_unit.unit, pos)
            end
		end
	end
end)

function GamePlayCentralManager:set_position(unit, position, rotation, offset)
    unit:set_position(position)
	local objects = unit:get_objects_by_type(Idstring("model"))
	for _, object in pairs(objects) do
		object:set_visibility(not object:visibility())
		object:set_visibility(not object:visibility())
	end
	local num = unit:num_bodies()
	for i = 0, num - 1 do
		local unit_body = unit:body(i)
		unit_body:set_enabled(not unit_body:enabled())
		unit_body:set_enabled(not unit_body:enabled())
	end
end
