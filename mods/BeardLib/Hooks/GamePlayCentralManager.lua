function GamePlayCentralManager:add_move_unit(unit, from, to, speed, done_callback)
	self._move_units = self._move_units or {}
    for k, move_unit in pairs(self._move_units) do
        if move_unit.unit == unit then
			table.remove(self._move_units, k)
        end
    end

	if not alive(unit) then
        return
    end
	from = from or unit:position()
	speed = speed or 1
	local total_time = mvector3.distance(from, to) / speed

	table.insert(self._move_units, {unit = unit, from = from, to = to, speed = speed, done_callback = done_callback, t = 0, total_time = total_time})
end

function GamePlayCentralManager:add_rotate_unit(unit, from, to, speed, done_callback)
	self._rotate_units = self._rotate_units or {}
    for k, move_unit in pairs(self._rotate_units) do
        if move_unit.unit == unit then
			table.remove(self._rotate_units, k)
        end
    end

	if not alive(unit) then
        return
    end
	from = from or unit:rotation()
	speed = speed or 1

	local temp_rot = Rotation()

	mrotation.rotation_difference(temp_rot, from, to)

	local total_time = math.abs((temp_rot:yaw() + temp_rot:pitch() + temp_rot:roll())) / speed

	table.insert(self._rotate_units, {unit = unit, to = to, from = from, speed = speed, done_callback = done_callback, t = 0, total_time = total_time})
end

Hooks:PostHook(GamePlayCentralManager, "update", "BeardLibGamePlayCentralManagerpost_update", function(self, t, dt)
	if self._rotate_units then
		for k, task in pairs(self._rotate_units) do
			if task.t == task.total_time then
				table.remove(self._rotate_units, k)
				if task.done_callback then
					task.done_callback()
				end
			else
				local rot = Rotation()
				task.t = math.min(task.t + dt, task.total_time)
				mrotation.step(rot, task.from, task.to, task.speed * task.t)
				if not alive(task.unit) then
					table.remove(self._rotate_units, k)
				else
					self:set_position(task.unit, nil, rot)
				end
			end
		end
	end

	if self._move_units then
		for k, task in pairs(self._move_units) do
			if task.t == task.total_time then
				table.remove(self._move_units, k)
				if task.done_callback then
					task.done_callback()
				end
			else
				local pos = Vector3()
				task.t = math.min(task.t + dt, task.total_time)
				mvector3.step(pos, task.from, task.to, task.speed * task.t)
				if not alive(task.unit) then
					table.remove(self._move_units, k)
				else
					self:set_position(task.unit, pos)
				end
			end
		end
	end
end)

function GamePlayCentralManager:is_unit_moving(unit)
	if self._move_units then
		for k, task in pairs(self._move_units) do
			if task.unit == unit then
				return
			end
		end
	end
	if self._rotate_units then
		for k, task in pairs(self._rotate_units) do
			if task.unit == unit then
				return
			end
		end
	end
end

function GamePlayCentralManager:set_position(unit, position, rotation, offset)
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