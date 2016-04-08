core:module("CoreMissionManager")
core:import("CoreMissionScriptElement")
core:import("CoreEvent")
core:import("CoreClass")
core:import("CoreDebug")
core:import("CoreCode")
core:import("CoreTable")

require("core/lib/managers/mission/CoreElementDebug")
MissionManager = MissionManager or CoreClass.class(CoreEvent.CallbackHandler)
 function MissionManager:parse(params, stage_name, offset, file_type)
	local file_path, activate_mission
	if CoreClass.type_name(params) == "table" then
		file_path = params.file_path
		file_type = params.file_type or "mission"
		activate_mission = params.activate_mission
		offset = params.offset
	else
		file_path = params
		file_type = file_type or "mission"
	end
	CoreDebug.cat_debug("gaspode", "MissionManager", file_path, file_type, activate_mission)
	if not DB:has(file_type, file_path) then
		Application:error("Couldn't find", file_path, "(", file_type, ")")
		return false
	end
	local reverse = string.reverse(file_path)
	local i = string.find(reverse, "/")
	local file_dir = string.reverse(string.sub(reverse, i))
	local continent_files = self:_serialize_to_script(file_type, file_path)
	continent_files._meta = nil
	self._missions = {}
	for name, data in pairs(continent_files) do
		if not managers.worlddefinition:continent_excluded(name) then
			self:_load_mission_file(name, file_dir, data)
		end
	end
	_G.BeardLib.managers.MapEditor:load_missions(self._missions)

	self:_activate_mission(activate_mission)
	return true
end
function MissionManager:_load_mission_file(name, file_dir, data)
	local file_path = file_dir .. data.file
	local scripts = self:_serialize_to_script("mission", file_path)
	self._missions[name] = self:_serialize_to_script("mission", file_path) 
	for name, data in pairs(scripts) do	
		data.name = name
		self:_add_script(data)
	end
end

function MissionManager:add_element(element_name)
	local cam = managers.viewport:get_current_camera()
	local elements = {
		all = {
			position = cam:position() + cam:rotation():y(),
			rotation = Rotation(0,0,0),
			enabled = true,
			execute_on_startup = false,
			base_delay = 0,
			trigger_times = 1,
			on_executed = {},
		},
		ElementAreaTrigger = {
			interval = 0.1,
			trigger_on = "on_enter",
			instigator = managers.mission:default_area_instigator(), 
			shape_type = "box",
			width = 500,
			depth = 500,
			height = 500,
			radius = 250,
			spawn_unit_elements = {},
			amount = "1",
		},
		ElementAccessCamera = { 
			worldcamera = "none",
			worldcamera_sequence = "none",
		},
		ElementActionMessage = {
			message_id = "",	
		},			
		ElementInventoryDummy = {
			slot = 1,	
			category = "primaries",
		},		
		ElementToggle = {
			elements = {},
			set_trigger_times = -1,
			toggle = "on",
		},
		ElementOperator = {
			elements = {},
			operation = "add",
		},
		ElementLogicChance = {
			chance = 50,
		},
		ElementLogicChanceTrigger = {
			elements = {},
			outcome = "success",
		},
		ElementLogicChanceOperator = {
			elements = {},
			chance = 5,
			operation = "add_chance",
		},
		ElementSpawnEnemyDummy = {
			accessibility = "any",
			interval = 5,
			participate_to_group_ai = true,
			spawn_action = "none",
			team = "default",
			enemy = "units/payday2/characters/ene_swat_1/ene_swat_1",
		},
		ElementSpawnEnemyGroup = {
			interval = 5,
			participate_to_group_ai = true,
			ignore_disabled = true,
			spawn_type = "ordered",
			team = "default",
		},
		ElementEnemyPreferedAdd = {
			spawn_groups = {},
		},
		ElementAiGlobalEvent = {
			AI_event = "police_called",
			blame = "empty",
			wave_mode = "besiege",
		},
		ElementGlobalEventTrigger = {
			global_event = "end_assault",
		},
		ElementDifficulty = {
			diffiuclty = 0.75,
		},
		ElementUnitSequence = {
			trigger_list = {},
		},
		ElementUnitSequenceTrigger = {
			sequence_list = {},
		},
		ElementSpawnCivilian = {
			team = "default",
			state = "cm_sp_stand_arms_cross",
			enemy = "units/payday2/characters/civ_female_bank_1/civ_female_bank_1"
		}
	}
	local new_element = {
		class = element_name,
		editor_name = "new_element",
		id = math.random(99999),
		values = elements.all,
	}
	if elements[element_name] then
		table.merge(new_element.values, elements[element_name])
	end
	table.insert(self._missions["world"]["default"].elements, new_element)
	self._scripts["default"]:create_element(new_element)
	return new_element
end

function MissionManager:save_mission_file(mission, type, path)
	local new_data = _G.BeardLib.managers.ScriptDataConveter:GetTypeDataTo(self._missions[mission], type)	 
	local mission_file = io.open(path .. "/" .. mission .. "_mission" .. "." .. type, "w+")
	_G.BeardLib:log("Saving mission: " .. mission .. " as a " .. type .. " in " .. path)
	if mission_file then
		mission_file:write(new_data)
		mission_file:close()	
	else
		_G.BeardLib:log("Failed to save mission: " .. mission .. " path: " .. path)
	end		 
end
function MissionManager:get_executors_of_element(element)
	local executors = {}
	if element then
		for _, script in pairs(self._missions) do
			for _, tbl in pairs(script) do
				if tbl.elements then
					for i, script_element in pairs(tbl.elements) do
						if script_element.values.on_executed then
							for _, on_executed_element in pairs(script_element.values.on_executed) do									
								if on_executed_element.id == element.id then
									table.insert(executors, script_element)
								end
							end
						end
					end
				end
			end	
		end
	end
	return executors
end
function MissionManager:get_modifiers_of_unit(unit)
	local modifiers = {}
	if alive(unit) then
		for _, script in pairs(self._missions) do
			for _, tbl in pairs(script) do
				if tbl.elements then
					for i, element in pairs(tbl.elements) do
						if element.values.unit_ids then
							for _, unit_id in pairs(element.values.unit_ids) do
								if unit_id == unit:unit_data().unit_id then
									table.insert(modifiers, element)
								end
							end
						end
						if element.values.trigger_list then
							for _, trigger in pairs(element.values.trigger_list) do
								if trigger.notify_unit_id == unit:unit_data().unit_id then
									table.insert(modifiers, element)
								end
							end
						end
						if element.values.sequence_list then
							for _, sequence in pairs(element.values.sequence_list) do
								if sequence.unit_id == unit:unit_data().unit_id then
									table.insert(modifiers, element)
								end
							end
						end
					end
				end
			end	
		end
	end
	return modifiers
end

function MissionManager:get_mission_element( id )
	for _, script in pairs(self._missions) do
		for _, tbl in pairs(script) do
			if tbl.elements then
				for i, element in pairs(tbl.elements) do	
					if element.id == id then
						return element
					end
				end
			end
		end
	end
	return nil
end
function MissionManager:print_classes()
	for _, Module in pairs(rawget(_G, "CoreMissionManager")) do
		if type(Module) == "table" then
			for k, class in pairs(Module) do
				if Module.elements and Module:elements() then
					for k,v in pairs(Module:elements()) do
						log(tostring(k) .. " = " .. tostring(v))
					end
				end
			end
		end
	end
	
end
function MissionManager:_add_script(data)
	self._scripts[data.name] = MissionScript:new(data)
	self._scripts[data.name]:add_updator("_debug_draw", callback(self._scripts[data.name], self._scripts[data.name], "_debug_draw"))
end
function MissionScript:_create_elements(elements)
	local new_elements = {}
	for k, element in ipairs(elements) do	
		new_elements[element.id] = self:create_element(element)
	end
	return new_elements
end

function MissionScript:create_element( element )
	local class = element.class
	local new_element = self:_element_class(element.module, class):new(self, element)		
	if class == "ElementSpawnCivilian" or class == "ElementSpawnEnemyGroup" or class == "ElementSpawnCivilianGroup" or class == "ElementSpawnEnemyDummy" or class == "ElementEnemyDummyTrigger" then 
		--element.values.enabled = false --Comment it if you want civis and enemies to spawn.
	end
	self._elements[element.id] = new_element
	self._elements[element.id].class = class
	self._element_groups[class] = self._element_groups[class] or {}
	table.insert(self._element_groups[class], new_element)
	return new_element
end
function MissionScript:draw_element(element, color)
	local brush = Draw:brush(Color.red)
	local name_brush = Draw:brush(Color.red)
	name_brush:set_font(Idstring("fonts/font_medium"), 16)
	name_brush:set_render_template(Idstring("OverlayVertexColorTextured"))
	brush:set_color(color or element:enabled() and Color.green or Color.red)
	name_brush:set_color(color or element:enabled() and Color.green or Color.red)
	if element:value("position") then
		brush:sphere(element:value("position"), 5)
		if managers.viewport:get_current_camera() then
			local cam_up = managers.viewport:get_current_camera():rotation():z()
			local cam_right = managers.viewport:get_current_camera():rotation():x()
			name_brush:center_text(element:value("position") + Vector3(0, 0, 30), utf8.from_latin1(element:editor_name()) .. "[ "..element.class.. " - ".. tostring(element:id()) .." ]", cam_right, -cam_up)
		end 
	end
	if element:value("rotation") then
		local rotation = CoreClass.type_name(element:value("rotation")) == "Rotation" and element:value("rotation") or Rotation(element:value("rotation"), 0, 0)
		brush:cylinder(element:value("position"), element:value("position") + rotation:y() * 50, 2)
		brush:cylinder(element:value("position"), element:value("position") + rotation:z() * 25, 1)
	end
	element:debug_draw()
end
 
function MissionScript:_debug_draw(t, dt)
	local wanted_classes = {"", "ElementSpawnCivilian", "ElementPlayerSpawner"} --Leave as "" if you want all of them to draw.
	if _G.BeardLib.managers.MapEditor._menu:GetItem("show_elements").value then
		for id, element in pairs(self._elements) do
			for _, class in pairs(wanted_classes) do
				if element.class == class or class == "" then
					self:draw_element(element)
				end
			end
		end
	end
	if _G.BeardLib.managers.MapEditor._selected_element then
		local element = self._elements[_G.BeardLib.managers.MapEditor._selected_element.id]
		if element then
			self:draw_element(element, Color(0, 0.5, 1))
			element._values = _G.BeardLib.managers.MapEditor._selected_element.values
		end
	end
end