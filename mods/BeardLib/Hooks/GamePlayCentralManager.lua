Hooks:PostHook(GamePlayCentralManager, "init", "post_init", function(self, t, dt)
	 self._move_units = {}
end)
  
function GamePlayCentralManager:add_move_unit(unit, to, speed, opt, done_callback)
    for k, move_unit in pairs(self._move_units) do
        if move_unit.unit == unit then
            table.remove(self._move_units, k)
        end
    end 
    if not alive(unit) then
        return
    end
    local from = unit:position()
    to = to:with_x(opt.x and to.x or from.x):with_y(opt.y and to.y or from.y):with_z(opt.z and to.z or from.z)
	table.insert(self._move_units, {unit = unit, from = unit:position(), to = to, speed = speed, done_callback = done_callback})
end
function GamePlayCentralManager:add_rotate_unit(unit, from, to, speed)
 
end
Hooks:PostHook(GamePlayCentralManager, "update", "post_update", function(self, t, dt)
	for k, move_unit in pairs(self._move_units) do
		if mvector3.equal(move_unit.from, move_unit.to) then
			table.remove(self._move_units, k)
            move_unit.done_callback()
		else 
            mvector3.step(move_unit.from, move_unit.from, move_unit.to, dt * (move_unit.speed * 100) )
            if not alive(move_unit.unit) then
                move_unit.from = move_unit.to
                return 
            end
            self:set_position(move_unit.unit, move_unit.from)
		end
	end 
end)
  
function GamePlayCentralManager:set_position(unit, position, rotation, offset)        
    if offset and unit:unit_data()._prev_pos and unit:unit_data()._prev_rot then
        local pos = mvector3.copy(unit:unit_data()._prev_pos)
        mvector3.add(pos, position)
        unit:set_position(pos)
        local prev_rot = unit:unit_data()._prev_rot
        local rot = Rotation(prev_rot:yaw(), prev_rot:pitch(), prev_rot:roll())
        rot:yaw_pitch_roll(rot:yaw() + rotation:yaw(), rot:pitch() + rotation:pitch(), rot:roll() + rotation:roll())
       -- unit:set_rotation(rot)
    else

    	unit:set_position(position)
    --	unit:set_rotation(rotation)
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