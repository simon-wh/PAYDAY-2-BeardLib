MapEditor = MapEditor or class()

local MOVEMENT_SPEED_BASE = 1000
local FAR_RANGE_MAX = 250000
local TURN_SPEED_BASE = 1
local PITCH_LIMIT_MIN = -80
local PITCH_LIMIT_MAX = 80
function MapEditor:init()
	self._camera_object = World:create_camera()
	self._camera_object:set_far_range(FAR_RANGE_MAX)
	self._camera_object:set_fov(75)
	self._vp = managers.viewport:new_vp(0, 0, 1, 1, "MapEditor", 10)
	self._vp:set_camera(self._camera_object)
	self._camera_pos = self._camera_object:position()
	self._camera_rot = self._camera_object:rotation()	
	self._closed = true
	self._con =  managers.controller:create_controller("MapEditor", nil, true, 10)
	self._modded_units = {}

	self._turn_speed = 5
	self._move_speed = 2

	local keyboard = Input:keyboard()
	if keyboard and keyboard:has_button(Idstring("f10")) then
		self._f9_con = Input:create_virtual_controller()
		self._f9_con:connect(keyboard, Idstring("f10"), Idstring("btn_toggle"))
		self._f9_con:add_trigger(Idstring("btn_toggle"), callback(self, self, "f10_pressed"))
	end	
end

function MapEditor:f10_pressed()
	if self._closed then
		self:enable()
		BeardLib.MenuMapEditor:enable()
	else 
		self:disable()
		BeardLib.MenuMapEditor:disable()
	end
	self._closed = not self._closed
end
function MapEditor:drop_player()
	local rot_new = Rotation(self._camera_rot:yaw(), 0, 0)
	game_state_machine:current_state():freeflight_drop_player(self._camera_pos, rot_new)
end
function MapEditor:select_unit()
	local cam = self._camera_object
	local ray
	if BeardLib.MenuMapEditor:get_item("units_visibility").value then
		ray = World:raycast("ray", cam:position(), cam:position() + cam:rotation():y() * 1000, "ray_type",  "body editor", "slot_mask",managers.slot:get_mask("all"))
	else
		ray = World:raycast("ray", cam:position(), cam:position() + cam:rotation():y() * 1000)
	end
	if ray then
		log("ray hit " .. tostring(ray.unit:unit_data().name_id) .. " " .. ray.body:name())
		local current_unit
		if self._selected_unit == ray.unit then
			current_unit = true
		end
		if alive(self._selected_unit) then
			self._selected_unit = nil
		end
		if not current_unit then
			self._selected_unit = ray.unit
			self._selected_body = ray.body
			self._modded_units[ray.unit:editor_id()] = self._modded_units[ray.unit:editor_id()] or {}
			self._modded_units[ray.unit:editor_id()]._default_position = self._modded_units[ray.unit:editor_id()]._default_position or ray.unit:position()
			self._modded_units[ray.unit:editor_id()]._default_rotation = self._modded_units[ray.unit:editor_id()]._default_rotation or ray.unit:rotation()
			self._modded_units[self._selected_unit:editor_id()]._modded_offset_position = self._modded_units[self._selected_unit:editor_id()]._modded_offset_position or Vector3(0, 0, 0)
			self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation = self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation or Rotation(0, 0, 0)
		end
		if self._modded_units[ray.unit:editor_id()]._modded_offset_position then
			local modded_offset = self._selected_unit and self._modded_units[ray.unit:editor_id()]._modded_offset_position or Vector3(0, 0, 0)
		end
		if self._modded_units[ray.unit:editor_id()]._modded_offset_rotation then
			local modded_offset = self._selected_unit and self._modded_units[ray.unit:editor_id()]._modded_offset_rotation or Rotation(0, 0, 0)
		end
		BeardLib.MenuMapEditor:set_unit(self._selected_unit)
		managers.mission:find_elements_of_unit(self._selected_unit)
	else
		log("no ray")
	end
end


function MapEditor:set_unit_enabled(enabled)
	if self._selected_unit then
		self._selected_unit:set_enabled(enabled)
	end
end

function MapEditor:set_camera(pos, rot)
	if pos then
		self._camera_object:set_position((alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3()) + pos)
		self._camera_pos = pos
	end
	if rot then
		self._camera_object:set_rotation(rot)
		self._camera_rot = rot
	end
end
function MapEditor:disable()
	self._closed = false
	self._con:disable()
	self._vp:set_active(false)
	if managers.enemy then
		managers.enemy:set_gfx_lod_enabled(true)
	end
end
function MapEditor:enable()
	local active_vp = managers.viewport:first_active_viewport()
	if active_vp then
		self._start_cam = active_vp:camera()
		if self._start_cam then
			local pos = self._start_cam:position() - (alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3())
			self:set_camera(pos, self._start_cam:rotation())
		end
	end
	self._closed = true
	self._vp:set_active(true)
	self._con:enable()
	if managers.enemy then
		managers.enemy:set_gfx_lod_enabled(false)
	end
end
function MapEditor:update(t, dt)
	local main_t = TimerManager:main():time()
	local main_dt = TimerManager:main():delta_time()
	if self:enabled() then
		self:update_camera(main_t, main_dt)
	end
end
function MapEditor:update_camera(t, dt)
	if BeardLib.MenuMapEditor._highlighted and not Input:keyboard():down(Idstring("left shift")) then
		return
	end
	local axis_move = self._con:get_input_axis("freeflight_axis_move")
	local axis_look = self._con:get_input_axis("freeflight_axis_look")
	local btn_move_up = self._con:get_input_float("freeflight_move_up")
	local btn_move_down = self._con:get_input_float("freeflight_move_down")
	local move_dir = self._camera_rot:x() * axis_move.x + self._camera_rot:y() * axis_move.y
	move_dir = move_dir + btn_move_up * Vector3(0, 0, 1) + btn_move_down * Vector3(0, 0, -1)
	local move_delta = move_dir * self._move_speed * MOVEMENT_SPEED_BASE * dt
	local pos_new = self._camera_pos + move_delta
	local yaw_new = self._camera_rot:yaw() + axis_look.x * -1 * self._turn_speed * TURN_SPEED_BASE
	local pitch_new = math.clamp(self._camera_rot:pitch() + axis_look.y * self._turn_speed * TURN_SPEED_BASE, PITCH_LIMIT_MIN, PITCH_LIMIT_MAX)
	local rot_new 
	if Input:keyboard():down(Idstring("left shift")) then
		rot_new = Rotation(yaw_new, pitch_new, 0)
	end
	if not CoreApp.arg_supplied("-vpslave") then
		self:set_camera(pos_new, rot_new)
	end
end

function MapEditor:set_position(position, rotation)
	local unit = self._selected_unit
	unit:set_position(position)
	unit:set_rotation(rotation)
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
function MapEditor:enabled()
	return not self._closed
end
function MapEditor:position_debug()
	local p = self._camera_pos
	log("Camera Pos: " .. tostring(p))
    if self._selected_unit then
        log("Selected Unit[" .. self._selected_unit:unit_data().name_id .. "] Pos: " .. tostring(self._selected_unit:position()))
        log("Selected Unit[" .. self._selected_unit:unit_data().name_id .. "] Rot: " .. tostring(self._selected_unit:rotation()))
    end
end