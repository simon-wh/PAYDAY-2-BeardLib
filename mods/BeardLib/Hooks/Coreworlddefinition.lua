core:module("CoreWorldDefinition")
WorldDefinition = WorldDefinition or class()
function WorldDefinition:init(params)
	managers.worlddefinition = self
	self._world_dir = params.world_dir
	self._cube_lights_path = params.cube_lights_path
	PackageManager:set_resource_loaded_clbk(Idstring("unit"), nil)
	self:_load_world_package()
	self._definition = self:_serialize_to_script(params.file_type, params.file_path)
	self._continent_definitions = {}
	self._continents = {}
	self._portal_slot_mask = World:make_slot_mask(1)
	self._massunit_replace_names = {}
	self._replace_names = {}
	self._replace_units_path = "assets/lib/utils/dev/editor/xml/replace_units"
	self:_parse_replace_unit()
	self._ignore_spawn_list = {}
	self._excluded_continents = {}
	self:_parse_world_setting(params.world_setting)
	self:parse_continents()
	managers.sequence:preload()
	PackageManager:set_resource_loaded_clbk(Idstring("unit"), callback(managers.sequence, managers.sequence, "clbk_pkg_manager_unit_loaded"))
	self._all_units = {}
	self._trigger_units = {}
	self._use_unit_callbacks = {}
	self._mission_element_units = {}
	self._termination_counter = 0
	self:create("ai")
end

 
function WorldDefinition:save_continent(continent, type, path)
	local new_data = _G.BeardLib.managers.ScriptDataConveter:GetTypeDataTo(self._continent_definitions[continent], type)	 	
	local continent_file = io.open(path .. "/" .. continent .. "." .. type, "w+")
	_G.BeardLib:log("Saving continent: " .. continent .. " as a " .. type .. " in " .. path)
	if continent_file then
	   	continent_file:write(new_data)
	    continent_file:close()	
	else
		_G.BeardLib:log("Failed to save continent: " .. continent .. " path: " .. path)
	end
end

function WorldDefinition:set_unit(unit_id, config)
	for continent_name, continent in pairs(self._continent_definitions) do
		for _,static in pairs(continent.statics) do
			if type(static) == "table" then
				for _,unit_data in pairs(static) do
					if unit_data.unit_id == unit_id then 
						for k,v in pairs(config) do
							unit_data[k] = v
						end
					end
				end
			end
		end
	end
end
function WorldDefinition:get_unit_number(name)
	local i = 1
	for continent_name, continent in pairs(self._continent_definitions) do
		for _,static in pairs(continent.statics) do
			if type(static) == "table" then
				for _,unit_data in pairs(static) do
					if unit_data.name == name then 
						i = i + 1
					end
				end
			end
		end
	end
	return i
end
function WorldDefinition:_continent_editor_only(data)
	return false
end
function WorldDefinition:init_done()
	if self._continent_init_packages then
		for _, package in ipairs(self._continent_init_packages) do
			self:_unload_package(package)
		end
	end
	_G.BeardLib.managers.MapEditor:load_continents(self._continent_definitions)
	self:_unload_package(self._current_world_init_package)
end

function WorldDefinition:delete_unit(unit)
	for continent_name, continent in pairs(self._continent_definitions) do
		if unit:unit_data().unit_id ~= 1 then
			for k, static in pairs(continent.statics) do
				if static.unit_data and (static.unit_data.unit_id == unit:unit_data().unit_id or static.unit_data.name_id == unit:unit_data().name_id) then
					table.remove(continent.statics, k)
					log("Removing.. " .. unit:unit_data().name_id .. "[" ..unit:unit_data().unit_id.. "]")
				end
			end
		end
	end
end
function WorldDefinition:add_unit(unit)
	table.insert(self._continent_definitions["world"].statics, { unit_data = unit:unit_data()})
end
function WorldDefinition:assign_unit_data(unit, data)
	if not unit:unit_data() then
		Application:error("The unit " .. unit:name():s() .. " (" .. unit:author() .. ") does not have the required extension unit_data (ScriptUnitData)")
	end
	--[[if unit:unit_data().only_exists_in_editor then
		self._ignore_spawn_list[unit:name():key()] = true
		unit:set_slot(0)
		return
	end]]
	_G.BeardLib.managers.MapEditor:set_editor_units_visible()
	unit:unit_data().instance = data.instance
	unit:unit_data().name_id = data.name_id
	unit:unit_data().unit_id = data.unit_id
	unit:unit_data().name = data.name

	self:_setup_unit_id(unit, data)
	self:_setup_editor_unit_data(unit, data)
	if unit:unit_data().helper_type and unit:unit_data().helper_type ~= "none" then
		managers.helper_unit:add_unit(unit, unit:unit_data().helper_type)
	end
	self:_setup_lights(unit, data)
	self:_setup_variations(unit, data)
	self:_setup_editable_gui(unit, data)
	self:add_trigger_sequence(unit, data.triggers)
	self:_set_only_visible_in_editor(unit, data)
	self:_setup_cutscene_actor(unit, data)
	self:_setup_disable_shadow(unit, data)
	self:_setup_hide_on_projection_light(unit, data)
	self:_setup_disable_on_ai_graph(unit, data)
	self:_add_to_portal(unit, data)
	self:_setup_projection_light(unit, data)
	self:_setup_ladder(unit, data)
	self:_setup_zipline(unit, data)
	self:_project_assign_unit_data(unit, data)
end

 local is_editor = Application:editor()
function WorldDefinition:make_unit(data, offset)

	local name = data.name
	if self._ignore_spawn_list[Idstring(name):key()] then		
		return nil
	end
	if table.has(self._replace_names, name) then
		name = self._replace_names[name]
	end
	if not name then
		return nil
	end
	if not is_editor and not Network:is_server() then
		local network_sync = PackageManager:unit_data(name:id()):network_sync()
		if network_sync ~= "none" and network_sync ~= "client" then
			return
		end
	end
	local unit
	if MassUnitManager:can_spawn_unit(Idstring(name)) and not is_editor then
		unit = MassUnitManager:spawn_unit(Idstring(name), data.position + offset, data.rotation)
	else
		unit = CoreUnit.safe_spawn_unit(name, data.position, data.rotation)
	end
	if unit then
		self:assign_unit_data(unit, data)
	elseif is_editor then
		local s = "Failed creating unit " .. tostring(name)
		Application:throw_exception(s)
	end
	if self._termination_counter == 0 then
		Application:check_termination()
	end
	self._termination_counter = (self._termination_counter + 1) % 100	
 
	return unit
end