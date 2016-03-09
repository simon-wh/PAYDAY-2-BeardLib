core:module("CoreWorldDefinition")
WorldDefinition = WorldDefinition or class()

function WorldDefinition:save_continent(continent, type, path)
	local new_data = _G.BeardLib:GetTypeDataTo(self._continent_definitions[continent], type)	 	
	local continent_file = io.open(path .. "/" .. continent .. "." .. type, "w+")
	log("Saving continent: " .. continent .. " as a " .. type .. " in " .. path)
   	continent_file:write(new_data)
    continent_file:close()	
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

function WorldDefinition:init_done()
	if self._continent_init_packages then
		for _, package in ipairs(self._continent_init_packages) do
			self:_unload_package(package)
		end
	end
	_G.BeardLib.MapEditor:load_continents(self._continent_definitions)
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
	if unit:unit_data().only_exists_in_editor then
		self._ignore_spawn_list[unit:name():key()] = true
		unit:set_slot(0)
		return
	end
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
