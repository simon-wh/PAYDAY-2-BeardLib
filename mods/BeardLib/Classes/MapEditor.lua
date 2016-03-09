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
	self:create_menu()
	local keyboard = Input:keyboard()
	local key = Idstring("f10")
	if keyboard and keyboard:has_button(key) then
		self._show_con = Input:create_virtual_controller()
		self._show_con:connect(keyboard, key, Idstring("btn_toggle"))
		self._show_con:add_trigger(Idstring("btn_toggle"), callback(self, self, "show_key_pressed"))
	end	
end

function MapEditor:create_menu()
	self._menu = MenuUI:new({
		w = 300,
		create_items = callback(self, self, "create_items")
	})

end
function MapEditor:create_items(menu)
    menu:CreateItem({
        name = "unit_options",
        text = "Selected Unit",
        help = "",
        type = "menu"  
    })      
    menu:CreateItem({
        name = "units_browser",
        text = "Units",
        help = "",
        directory = "assets/extract/units",
        file_click = callback(self, self, "file_click"),
    --    folder_click = callback(self, self, "folder_click"),
        type = "browser"  
    })      
    menu:CreateItem({
        name = "missions_options",
        text = "Missions",
        help = "",
        type = "menu"  
    })            
    menu:CreateItem({
        name = "continents_options",
        text = "Continents",
        help = "",
        type = "menu"  
    })      
    menu:CreateItem({
        name = "game_options",
        text = "Game",
        help = "",
        type = "menu"  
    })        
    menu:CreateItem({
        name = "unit_name",
        text = "Name: ",
        value = "",
        help = "",
        parent = "unit_options",
        type = "textbox"  
    })    
    menu:CreateItem({
        name = "unit_id",
        text = "ID: ",
        value = "",
        help = "",
        parent = "unit_options",
        type = "textbox"  
    })         
    menu:CreateItem({
        name = "unit_path",
        text = "Unit path: ",
        value = "",
        help = "",
        parent = "unit_options",
        type = "textbox"  
    })      
    menu:CreateItem({
        name = "positionx",
        text = "Position x: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"), 
        parent = "unit_options",
        type = "slider"  
    })     
    menu:CreateItem({
        name = "positiony",
        text = "Position Y: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"), 
        parent = "unit_options",
        type = "slider"  
    })       
    menu:CreateItem({
        name = "positionz",
        text = "Position z: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"), 
        parent = "unit_options",
        type = "slider"  
    })       
    menu:CreateItem({
        name = "rotationyaw",
        text = "Rotation yaw: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"), 
        parent = "unit_options",
        type = "slider"  
    })     
    menu:CreateItem({
        name = "rotationpitch",
        text = "Rotation pitch: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"),       
        parent = "unit_options",
        type = "slider"  
    })       
    menu:CreateItem({
        name = "rotationroll",
        text = "Rotation roll: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"),
        parent = "unit_options",
        type = "slider"  
    })          
    menu:CreateItem({
        name = "unit_delete_btn",
        text = "Delete unit",
        help = "",
        callback = callback(self, self, "delete_unit"),
        parent = "unit_options",
        type = "button"  
    })      
    menu:CreateItem({
        name = "continents_savepath",
        text = "Save path: ",
        value = BeardLib.mod_path .. "save",
        help = "",
        parent = "continents_options",
        type = "textbox"  
    })       
    menu:CreateItem({
        name = "continents_filetype",
        text = "Type: ",
        value = 1,
        items = {"custom_xml", "generic_xml", "json"},
        help = "",
        parent = "continents_options",
        type = "combo"  
    })     
    menu:CreateItem({
        name = "continents_savebtn",
        text = "Save",
        help = "",
        callback = callback(self, self, "save_continents"),
        parent =  "continents_options",
        type = "button"  
    })  
    menu:CreateItem({
        name = "units_visibility",
        text = "Editor units visibility",
        help = "",
        value = false,
        callback = callback(self, self, "set_editor_units_visible"),
        parent = "continents_options",
        type = "toggle"  
    })      
    menu:CreateItem({
        name = "units_highlight",
        text = "Highlight all units",
        help = "",
        value = false,
        parent = "continents_options",
        type = "toggle"  
    })       
    menu:CreateItem({
        name = "show_elements",
        text = "Show elements",
        help = "",
        value = false,
        parent = "missions_options",
        type = "toggle"  
    })         
    menu:CreateItem({
        name = "teleport_player",
        text = "Teleport player",
        help = "",
        callback = callback(self, self, "drop_player"),
        parent = "game_options",
        type = "button"  
    })      
end
function MapEditor:delete_unit(menu, item)
	if alive(self._selected_unit) then
		setup._world_holder._definition:delete_unit(self._selected_unit)		
		World:delete_unit(self._selected_unit)
		self:set_unit(nil)			
	end
end
function MapEditor:set_editor_units_visible(menu, item)
	for _, unit in pairs(World:find_units_quick("all")) do
		if type(unit:unit_data()) == "table" and unit:unit_data().only_visible_in_editor then
			unit:set_visible( item.value )
		end
	end
end
function MapEditor:file_click(menu, item)
	local cam = managers.viewport:get_current_camera()
	local unit_path = menu._current_menu.current_dir:gsub("assets/extract/", "") .. "/" .. item.name:gsub(".unit", "")
	local unit_path = item.path
	local SpawnUnit = function()
		local unit
		if MassUnitManager:can_spawn_unit(Idstring(unit_path)) then
			unit = MassUnitManager:spawn_unit(Idstring(unit_path), cam:position() + cam:rotation():y(), Rotation(0,0,0))
		else
			unit = CoreUnit.safe_spawn_unit(unit_path,  cam:position() + cam:rotation():y(),  Rotation(0,0,0))
		end	
		unit:unit_data().name_id = "new_unit"
		unit:unit_data().unit_id = math.random(99999)
		unit:unit_data().name = unit_path
		unit:unit_data().position = unit:position()
		unit:unit_data().rotation = unit:rotation()
		setup._world_holder._definition:add_unit(unit)
	end
	if item.color == Color.red then
		QuickMenu:new( "Warning", "Unit is not loaded, load it?", 
		{[1] = {text = "Yes", callback = function()	
			managers.dyn_resource:load(Idstring("unit"), Idstring(unit_path), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)
			MenuUI:browse(menu._current_menu)
			SpawnUnit()			
  		end
  		},[2] = {text = "No", is_cancel_button = true}}, true)
	else
		SpawnUnit()
	end
end
function MapEditor:save_continents(menu)
	local item = menu:get_item("continents_filetype")
	local type = item.items[item.value]
	local path = menu:get_item("continents_savepath").value
	local world_def = setup._world_holder._definition
	if file.DirectoryExists( path ) then
		for continent_name, _ in pairs(world_def._continent_definitions) do
			if menu:get_item(continent_name).value then
				world_def:save_continent(continent_name, type, path)
			end
		end
	else
		log("Directory doesn't exists.")
	end
end
function MapEditor:set_unit_data(menu, item)
	if alive(self._selected_unit) then
		self:set_position(Vector3(menu:get_item("positionx").value, menu:get_item("positiony").value, menu:get_item("positionz").value), Rotation(menu:get_item("rotationyaw").value, menu:get_item("rotationpitch").value, menu:get_item("rotationroll").value))
		if self._selected_unit:editor_id() then
			setup._world_holder._definition:set_unit(self._selected_unit:editor_id(), {position = self._selected_unit:position(), rotation = self._selected_unit:rotation()})
		end
	end
end

function MapEditor:load_continents(continents)
    for continent_name, _ in pairs(continents) do
	    self._menu:CreateItem({
	        name = continent_name,
	        text = "Save continent: " .. continent_name,
	        help = "",
	        value = true,
	        parent = "continents_options",
	        type = "toggle"  
	    })     
    end
end
function MapEditor:set_unit(unit)
	self._selected_unit = unit
	self._menu:set_value(self._menu:get_item("unit_name"), unit and unit:unit_data().name_id or "")
	self._menu:set_value(self._menu:get_item("unit_path"), unit and unit:unit_data().name or "")
	self._menu:set_value(self._menu:get_item("unit_id"), unit and unit:unit_data().unit_id or "")	
	self._menu:set_value(self._menu:get_item("positionx"), unit and unit:position().x or 0)
	self._menu:set_value(self._menu:get_item("positiony"), unit and unit:position().y or 0)
	self._menu:set_value(self._menu:get_item("positionz"), unit and unit:position().z or 0)	
	self._menu:set_value(self._menu:get_item("rotationyaw"), unit and unit:rotation():yaw() or 0)
	self._menu:set_value(self._menu:get_item("rotationpitch"), unit and unit:rotation():pitch() or 0)
	self._menu:set_value(self._menu:get_item("rotationroll"), unit and unit:rotation():roll() or 0)
end
function MapEditor:show_key_pressed()
	if self._closed then
		self:enable()
		self._menu:enable()
	else 
		self:disable()
		self._menu:disable()
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
	if self._menu:get_item("units_visibility").value then
		ray = World:raycast("ray", cam:position(), cam:position() + cam:rotation():y() * 1000, "ray_type",  "body editor", "slot_mask",managers.slot:get_mask("all"))
	else
		ray = World:raycast("ray", cam:position(), cam:position() + cam:rotation():y() * 1000)
	end
	if ray then
		log("ray hit " .. tostring(ray.unit:unit_data().name_id).. " " .. ray.body:name())
		local current_unit
		if self._selected_unit == ray.unit then
			current_unit = true
		end
		if alive(self._selected_unit) then
			self:set_unit(nil)
		end
		if not current_unit then
			self:set_unit(ray.unit)
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
	if type(managers.enemy) == "table" then
		managers.enemy:set_gfx_lod_enabled(true)
	end
    
    --Unpause Game
    --Application:set_pause(false)
    
    --Show HUD
    managers.hud:set_enabled()
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
    
    --Pause Game
    --For some reason prevents camera movement
    --Application:set_pause(true)
    
    --Hide HUD
    managers.hud:set_disabled()
end
function MapEditor:update(t, dt)
	local main_t = TimerManager:main():time()
	local main_dt = TimerManager:main():delta_time()	

	local brush = Draw:brush(Color(0.5, 0.5, 0.85))
	if alive(self._selected_unit) and managers.viewport:get_current_camera() then
		Application:draw(self._selected_unit, 0.5, 0.5, 0.85)	
		local cam_up = managers.viewport:get_current_camera():rotation():z()
		local cam_right = managers.viewport:get_current_camera():rotation():x()		
		brush:set_font(Idstring("fonts/font_medium"), 32)
		brush:center_text(self._selected_unit:position() + Vector3(-10, -10, 200), self._selected_unit:unit_data().name_id .. "[ " .. self._selected_unit:editor_id() .. " ]", cam_right, -cam_up)
	end
	if self._menu:get_item("units_highlight").value then
		for _, unit in pairs(World:find_units_quick("all")) do
			if unit:editor_id() ~= -1 then
				Application:draw(unit, 1, 1,1)
			end					
		end
	end	
	if self:enabled() then
		self:update_camera(main_t, main_dt)
	end
end
function MapEditor:update_camera(t, dt)
	if self._menu._highlighted and not Input:keyboard():down(Idstring("left shift")) then
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