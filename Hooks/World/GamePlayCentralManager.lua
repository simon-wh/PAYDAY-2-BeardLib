function GamePlayCentralManager:add_move_unit(unit, from, to, speed, done_callback)
	if alive(unit) then
		from = from or unit:position()
		speed = speed or 1
		local total_time = mvector3.distance(from, to) / speed
		self._move_units[unit:key()] = {unit = unit, from = from, to = to, speed = speed, done_callback = done_callback, t = 0, total_time = total_time}
    end
end

function GamePlayCentralManager:add_rotate_unit(unit, from, to, speed, done_callback)
	if alive(unit) then
		from = from or unit:rotation()
		speed = speed or 1
		local temp_rot = Rotation:rotation_difference(from, to)
		local total_time = math.abs((temp_rot:yaw() + temp_rot:pitch() + temp_rot:roll())) / speed
		self._rotate_units[unit:key()] = {unit = unit, to = to, from = from, speed = speed, done_callback = done_callback, t = 0, total_time = total_time}
    end
end

Hooks:PostHook(GamePlayCentralManager, "update", "BeardLibGamePlayCentralManagerpost_update", function(self, t, dt)
	if self._rotate_units then
		for unit_k, task in pairs(self._rotate_units) do
			if task.t == task.total_time then
				self._rotate_units[unit_k] = nil
				if task.done_callback then
					task.done_callback()
				end
			else
				local rot = Rotation()
				task.t = math.min(task.t + dt, task.total_time)
				mrotation.step(rot, task.from, task.to, task.speed * task.t)
				if not alive(task.unit) then
					self._rotate_units[unit_k] = nil
				else
					self:set_position(task.unit, nil, rot)
				end
			end
		end
	end

	if self._move_units then
		for unit_k, task in pairs(self._move_units) do
			if task.t == task.total_time then
				self._move_units[unit_k] = nil
				if task.done_callback then
					task.done_callback()
				end
			else
				local pos = Vector3()
				task.t = math.min(task.t + dt, task.total_time)
				mvector3.step(pos, task.from, task.to, task.speed * task.t)
				if not alive(task.unit) then
					self._move_units[unit_k] = nil
				else
					self:set_position(task.unit, pos)
				end
			end
		end
	end
end)

function GamePlayCentralManager:is_unit_moving(unit)
	return alive(unit) and (self._move_units and self._move_units[unit:key()] or self._rotate_units and self._rotate_units[unit:key()])
end

function GamePlayCentralManager:set_position(unit, position, rotation)
	if position then
		unit:set_position(position)
	end
	if rotation then
		unit:set_rotation(rotation)
	end
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
