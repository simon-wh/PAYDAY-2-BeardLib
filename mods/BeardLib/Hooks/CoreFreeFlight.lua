core:module("CoreFreeFlight")
local SaveTable = _G.SaveTable
FreeFlight = FreeFlight or CoreFreeFlight.FreeFlight
local CoreUnit = _G.CoreUnit
local FF_ON, FF_OFF, FF_ON_NOCON = 0, 1, 2
local MOVEMENT_SPEED_BASE = 1000
local TURN_SPEED_BASE = 1
local FAR_RANGE_MAX = 250000
local PITCH_LIMIT_MIN = -80
local PITCH_LIMIT_MAX = 80
local TEXT_FADE_TIME = 0.3
local TEXT_ON_SCREEN_TIME = 2
local FREEFLIGHT_HEADER_TEXT = "FREEFLIGHT, PRESS 'F' OR 'C'"
local DESELECTED = Color(0.5, 0.5, 0.5)
local SELECTED = Color(1, 1, 1)

function FreeFlight:_setup_modifiers()
	local FFM = CoreFreeFlightModifier.FreeFlightModifier
	local IFFM = CoreFreeFlightModifier.InfiniteFreeFlightModifier
	local ms = FFM:new("MOVE SPEED", {
		0.02,
		0.05,
		0.1,
		0.2,
		0.3,
		0.4,
		0.5,
		1,
		2,
		3,
		4,
		5,
		8,
		11,
		14,
		18,
		25,
		30,
		40,
		50,
		60,
		70,
		80,
		100,
		120,
		140,
		160,
		180,
		200
	}, 9)
	local ts = FFM:new("TURN SPEED", {
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		9,
		10
	}, 5)
	local gt = FFM:new("GAME TIMER", {
		0.1,
		0.2,
		0.3,
		0.4,
		0.5,
		0.6,
		0.7,
		0.8,
		0.9,
		1,
		1.1,
		1.2,
		1.3,
		1.4,
		1.5,
		1.6,
		1.7,
		1.8,
		1.9,
		2,
		2.5,
		3,
		3.5,
		4,
		4.5,
		5,
		5.5,
		6,
		6.5,
		7,
		7.5,
		8,
		8.5,
		9,
		9.5,
		10
	}, 10, callback(self, self, "_set_game_timer"))
	local fov = FFM:new("FOV", {
		2,
		5,
		7,
		10,
		20,
		30,
		40,
		50,
		55,
		60,
		65,
		70,
		75,
		80,
		85,
		90
	}, 13, callback(self, self, "_set_fov"))
	local xposition = IFFM:new("POSITION X", 0, 5, callback(self, self, "_set_positionx"))
	local yposition = IFFM:new("POSITION Y", 0, 5, callback(self, self, "_set_positiony"))
	local zposition = IFFM:new("POSITION Z", 0, 5, callback(self, self, "_set_positionz"))
	
	local yawrotation = IFFM:new("ROTATION YAW", 0, 5, callback(self, self, "_set_rotationyaw"))
	local pitchrotation = IFFM:new("ROTATION PITCH", 0, 5, callback(self, self, "_set_rotationpitch"))
	local rollrotation = IFFM:new("ROTATION ROLL", 0, 5, callback(self, self, "_set_rotationroll"))
	
	self._modifiers = {
		ms,
		ts,
		gt,
		fov,
		xposition,
		yposition,
		zposition,
		yawrotation,
		pitchrotation,
		rollrotation
	}
	self._modifier_index = 1
	self._fov = fov
	self._move_speed = ms
	self._turn_speed = ts
	self._xposition_modifier = xposition
	self._yposition_modifier = yposition
	self._zposition_modifier = zposition
	self._yawrotation_modifier = yawrotation
	self._pitchrotation_modifier = pitchrotation
	self._rollrotation_modifier = rollrotation
	self._modded_units = {}
end

function FreeFlight:_setup_actions()
	local FFA = CoreFreeFlightAction.FreeFlightAction
	local FFAT = CoreFreeFlightAction.FreeFlightActionToggle
	local dp = FFA:new("DROP PLAYER", callback(self, self, "_drop_player"))
	local au = FFA:new("SELECT UNIT", callback(self, self, "_select_unit"))
	local pd = FFA:new("POSITION DEBUG", callback(self, self, "_position_debug"))
	local yc = FFA:new("YIELD CONTROL (F9 EXIT)", callback(self, self, "_yield_control"))
	local ef = FFA:new("EXIT FREEFLIGHT", callback(self, self, "_exit_freeflight"))
	local ps = FFAT:new("PAUSE", "UNPAUSE", callback(self, self, "_pause"), callback(self, self, "_unpause"))
	local unit_enable = FFAT:new("DISABLE UNIT", "ENABLE UNIT", callback(self, self, "_disable_unit"), callback(self, self, "_enable_unit"))
	--local ff = FFAT:new("FRUSTUM FREEZE", "FRUSTUM UNFREEZE", callback(self, self, "_frustum_freeze"), callback(self, self, "_frustum_unfreeze"))
	self._actions = {
		ps,
		dp,
		au,
		pd,
		yc,
		--ff,
		ef,
		unit_enable
	}
	self._action_index = 1
end

function FreeFlight:_select_unit()
	local cam = self._camera_object
	local ray = World:raycast("ray", cam:position(), cam:position() + cam:rotation():y() * 10000)
	if ray then
		log("ray hit " .. tostring(ray.unit:name()) .. " " .. ray.body:name())
		log(ray.unit:id() .. ":" .. ray.unit:editor_id())
		--[[if alive(self._attached_to_unit) and self._attached_to_unit == ray.unit then
			log("[FreeFlight] Detach")
			self:attach_to_unit(nil)
		else
			log("[FreeFlight] Attach")
			self:attach_to_unit(ray.unit)
		end]]--
		local current_unit
		if self._selected_unit == ray.unit then
			current_unit = true
		end
		
		if alive(self._selected_unit) then
			if self._selected_unit:contour() then
				log("is contour remove")
				self._selected_unit:contour():remove("taxman")
				self._selected_unit:contour()._added_test_contour = false
			end
			self._selected_unit = nil
		end
		
		if not current_unit then
			if ray.unit:contour() then
				log("is contour add")
				ray.unit:contour():add("taxman")
				ray.unit:contour()._added_test_contour = true
			end
			self._selected_unit = ray.unit
			self._selected_body = ray.body
			
			self._modded_units[ray.unit:editor_id()] = self._modded_units[ray.unit:editor_id()] or {}
			self._modded_units[ray.unit:editor_id()]._default_position = self._modded_units[ray.unit:editor_id()]._default_position or ray.unit:position()
			self._modded_units[ray.unit:editor_id()]._default_rotation = self._modded_units[ray.unit:editor_id()]._default_rotation or ray.unit:rotation()
			self._modded_units[self._selected_unit:editor_id()]._modded_offset_position = self._modded_units[self._selected_unit:editor_id()]._modded_offset_position or Vector3(0, 0, 0)
			self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation = self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation or Rotation(0, 0, 0)
			
			
			--SaveTable(ray, "RayIndex.txt")
		end
		if self._modded_units[ray.unit:editor_id()]._modded_offset_position then
			local modded_offset = self._selected_unit and self._modded_units[ray.unit:editor_id()]._modded_offset_position or Vector3(0, 0, 0)
			self._xposition_modifier:set_value(modded_offset.x)
			self._yposition_modifier:set_value(modded_offset.y)
			self._zposition_modifier:set_value(modded_offset.z)
			self._modifier_gui[5]:set_text(self._xposition_modifier:name_value())
			self._modifier_gui[6]:set_text(self._yposition_modifier:name_value())
			self._modifier_gui[7]:set_text(self._zposition_modifier:name_value())
		end
		
		if self._modded_units[ray.unit:editor_id()]._modded_offset_rotation then
			local modded_offset = self._selected_unit and self._modded_units[ray.unit:editor_id()]._modded_offset_rotation or Rotation(0, 0, 0)
			self._yawrotation_modifier:set_value(modded_offset:yaw())
			self._pitchrotation_modifier:set_value(modded_offset:pitch())
			self._rollrotation_modifier:set_value(modded_offset:roll())
			self._modifier_gui[8]:set_text(self._yawrotation_modifier:name_value())
			self._modifier_gui[9]:set_text(self._pitchrotation_modifier:name_value())
			self._modifier_gui[10]:set_text(self._rollrotation_modifier:name_value())
		end
	else
		log("no ray")
	end
end

function FreeFlight:_set_rotationyaw(value)
	if self._selected_unit then
		local modded_offset = self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation
		
		self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation = Rotation(value, modded_offset:pitch(), modded_offset:roll())
		
		self:set_position(self._selected_unit, self._selected_body, self._modded_units)
	end
end

function FreeFlight:_disable_unit()
	if self._selected_unit then
		self._selected_unit:set_enabled(false)
	end
end

function FreeFlight:_enable_unit()
	if self._selected_unit then
		self._selected_unit:set_enabled(true)
	end
end

function FreeFlight:_set_rotationpitch(value)
	if self._selected_unit then
		local modded_offset = self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation
		
		self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation = Rotation(modded_offset:yaw(), value, modded_offset:roll())
		
		self:set_position(self._selected_unit, self._selected_body, self._modded_units)
	end
end
function FreeFlight:_set_rotationroll(value)
	if self._selected_unit then
		local modded_offset = self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation
		
		self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation = Rotation(modded_offset:yaw(), modded_offset:pitch(), value)
		
		self:set_position(self._selected_unit, self._selected_body, self._modded_units)
	end
end

function FreeFlight:_set_positionx(value)
	if self._selected_unit then
		local modded_offset = self._modded_units[self._selected_unit:editor_id()]._modded_offset_position
		
		self._modded_units[self._selected_unit:editor_id()]._modded_offset_position = Vector3(value, modded_offset.y, modded_offset.z)
		
		self:set_position(self._selected_unit, self._selected_body, self._modded_units)
	end
end

function FreeFlight:_set_positiony(value)
	if self._selected_unit then
		local modded_offset = self._modded_units[self._selected_unit:editor_id()]._modded_offset_position
		
		self._modded_units[self._selected_unit:editor_id()]._modded_offset_position = Vector3(modded_offset.x, value, modded_offset.z)
		
		self:set_position(self._selected_unit, self._selected_body, self._modded_units)
	end
end

function FreeFlight:_set_positionz(value)
	if self._selected_unit then
		local modded_offset = self._modded_units[self._selected_unit:editor_id()]._modded_offset_position
		
		self._modded_units[self._selected_unit:editor_id()]._modded_offset_position = Vector3(modded_offset.x, modded_offset.y, value)
		
		self:set_position(self._selected_unit, self._selected_body, self._modded_units)
	end
end

function FreeFlight:_set_camera(pos, rot)
	if pos then
		self._camera_object:set_position((alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3()) + pos)
		self._camera_pos = pos
	end
	if rot then
		self._camera_object:set_rotation(rot)
		self._camera_rot = rot
	end
end

function FreeFlight:enable()
	if self._gsm:current_state():allow_freeflight() then
		local active_vp = self._vpm:first_active_viewport()
		if active_vp then
			self._start_cam = active_vp:camera()
			if self._start_cam then
				local pos = self._start_cam:position() - (alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3())
				self:_set_camera(pos, self._start_cam:rotation())
			end
		end
		self._state = FF_ON
		self._vp:set_active(true)
		self._con:enable()
		self._workspace:show()
		self:_draw_actions()
		self:_draw_modifiers()
		if managers.enemy then
			managers.enemy:set_gfx_lod_enabled(false)
		end
		managers.menu:open_menu("menu_editor")
	end
end

function FreeFlight:_update_camera(t, dt)
	local axis_move = self._con:get_input_axis("freeflight_axis_move")
	local axis_look = self._con:get_input_axis("freeflight_axis_look")
	local btn_move_up = self._con:get_input_float("freeflight_move_up")
	local btn_move_down = self._con:get_input_float("freeflight_move_down")
	local move_dir = self._camera_rot:x() * axis_move.x + self._camera_rot:y() * axis_move.y
	move_dir = move_dir + btn_move_up * Vector3(0, 0, 1) + btn_move_down * Vector3(0, 0, -1)
	local move_delta = move_dir * self._move_speed:value() * MOVEMENT_SPEED_BASE * dt
	local pos_new = self._camera_pos + move_delta
	local yaw_new = self._camera_rot:yaw() + axis_look.x * -1 * self._turn_speed:value() * TURN_SPEED_BASE
	local pitch_new = math.clamp(self._camera_rot:pitch() + axis_look.y * self._turn_speed:value() * TURN_SPEED_BASE, PITCH_LIMIT_MIN, PITCH_LIMIT_MAX)
	local rot_new 
	if self._keyboard:down(Idstring("left shift")) then
		rot_new = Rotation(yaw_new, pitch_new, 0)
	end
	if not CoreApp.arg_supplied("-vpslave") then
		self:_set_camera(pos_new, rot_new)
	end
end

function FreeFlight:set_position(unit, body, modded_units)
	unit:set_position(Vector3(modded_units[unit:editor_id()]._default_position.x + modded_units[unit:editor_id()]._modded_offset_position.x, modded_units[unit:editor_id()]._default_position.y + modded_units[unit:editor_id()]._modded_offset_position.y, modded_units[unit:editor_id()]._default_position.z + modded_units[unit:editor_id()]._modded_offset_position.z))
	unit:set_rotation(Rotation(modded_units[unit:editor_id()]._default_rotation:yaw() + modded_units[unit:editor_id()]._modded_offset_rotation:yaw(), modded_units[unit:editor_id()]._default_rotation:pitch() + modded_units[unit:editor_id()]._modded_offset_rotation:pitch(), modded_units[unit:editor_id()]._default_rotation:roll() + modded_units[unit:editor_id()]._modded_offset_rotation:roll()))
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

function FreeFlight:_position_debug()
	local p = self._camera_pos
	log("CAMERA POSITION: " .. tostring(p))
end