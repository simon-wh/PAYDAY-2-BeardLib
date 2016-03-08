core:module("CoreMissionManager")
core:import("CoreMissionScriptElement")
core:import("CoreEvent")
core:import("CoreClass")
core:import("CoreDebug")
core:import("CoreCode")
core:import("CoreTable")
require("core/lib/managers/mission/CoreElementDebug")
MissionManager = MissionManager or CoreClass.class(CoreEvent.CallbackHandler)

function MissionManager:_load_mission_file(file_dir, data)
	local file_path = file_dir .. data.file
	local scripts = self:_serialize_to_script("mission", file_path)
	scripts._meta = nil
	for name, data in pairs(scripts) do
		data.name = name
		self:_add_script(data)
	end
end

function MissionManager:find_elements_of_unit(unit)
	if not alive(unit) then
		return 
	end
	for _, script in pairs(self._scripts) do
		for id, element in pairs(script._elements) do
			if element:values().unit_ids then
				for _, unit_id in pairs(element:values().unit_ids) do
					if unit_id == unit:unit_data().unit_id then
						log(id .. " modifies this unit!")
					end
				end
			end
		end
	end
end
function MissionManager:try_finding_element(start_pos, end_pos)
	_G.editor.ui._menu_panel:animate(callback(self, self, "try_finding"), start_pos, end_pos)
end
function MissionManager:try_finding(o, start_pos, end_pos)

	for _, script in pairs(self._scripts) do	
		local TOTAL_T = 2
		local t = TOTAL_T
		for id, element in pairs(script._elements) do
			if element._is_inside then	
				while t > 0 do
					local dt = coroutine.yield()	
					t = t - dt	
					local cv = math.sin( t * 200 ) 
					local pos = mvector3.lerp(start_pos, end_pos, cv) 
					if element:_is_inside(pos) then
						log("Point!")
					end
				end
			end
		end
	end
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
	for _, element in ipairs(elements) do
		local class = element.class
		local new_element = self:_element_class(element.module, class):new(self, element)		

		if element.values.unit_idsA then
			log("unit ids for: " .. element.id .. "[" .. element.class .. "]")
			for k,v in pairs(element.values.unit_ids) do
				log(tostring(k) .. " = " .. tostring(v))
			end
			log("end")
		end
		self._elements[element.id] = new_element
		self._elements[element.id].class = class
		new_elements[element.id] = new_element
		self._element_groups[class] = self._element_groups[class] or {}
		table.insert(self._element_groups[class], new_element)
	end
	return new_elements
end
function MissionScript:_debug_draw(t, dt)
	local brush = Draw:brush(Color.red)
	local name_brush = Draw:brush(Color.red)
	name_brush:set_font(Idstring("fonts/font_medium"), 16)
	name_brush:set_render_template(Idstring("OverlayVertexColorTextured"))

	local wanted_classes = {"ElementAreaTrigger", "ElementSpawnCivilian", "ElementPlayerSpawner"} --Leave as "" if you want all of them to draw.
	if _G.BeardLib.MenuMapEditor:get_item("show_elements").value then
		for id, element in pairs(self._elements) do
			for _, class in pairs(wanted_classes) do
				if element.class == class or class == "" then
					brush:set_color(element:enabled() and Color.green or Color.red)
					name_brush:set_color(element:enabled() and Color.green or Color.red)
					if element:value("position") then
						brush:sphere(element:value("position"), 5)
						if managers.viewport:get_current_camera() then
							local cam_up = managers.viewport:get_current_camera():rotation():z()
							local cam_right = managers.viewport:get_current_camera():rotation():x()
							name_brush:center_text(element:value("position") + Vector3(0, 0, 30), utf8.from_latin1(element:editor_name()) .. "[ "..element.class.. " - ".. id .." ]", cam_right, -cam_up)
						end 
					end
					if element:value("rotation") then
						local rotation = CoreClass.type_name(element:value("rotation")) == "Rotation" and element:value("rotation") or Rotation(element:value("rotation"), 0, 0)
						brush:cylinder(element:value("position"), element:value("position") + rotation:y() * 50, 2)
						brush:cylinder(element:value("position"), element:value("position") + rotation:z() * 25, 1)
					end
					element:debug_draw(t, dt)
				end
			end
		end
	end
end