if not _G.BeardLib then
	_G.BeardLib = {}
	BeardLib.mod_path = ModPath
	BeardLib.save_path = SavePath
	BeardLib.sequence_mods = BeardLib.sequence_mods or {}
	BeardLib.EnvMods = BeardLib.EnvMods or {} 
	BeardLib.EnvMenu = "BeardLibEnvMenu"
	BeardLib.ModdedData = {}
	BeardLib.EnvCreatedMenus = {}
	BeardLib.JsonPathName = "BeardLibJsonMods"
	BeardLib.JsonPath = BeardLib.JsonPathName .. "/"
	BeardLib.CurrentViewportNo = 0
	BeardLib.ScriptExceptions = BeardLib.ScriptExceptions or {}
    BeardLib.EditorEnabled = true
    BeardLib.hooks_directory = "Hooks/"
    BeardLib.class_directory = "Classes/"
    BeardLib.ScriptData = {}
    
end

BeardLib.classes = {
    "ScriptData.lua",
	"EnvironmentData.lua",
	"SequenceData.lua",
	"MenuHelperPlus.lua",
	"UnitPropertiesItem.lua",
    "utils.lua"
}

BeardLib.hook_files = {
	["core/lib/managers/coresequencemanager"] = "CoreSequenceManager.lua",
	["lib/managers/menu/menuinput"] = "MenuInput.lua",
	["core/lib/managers/viewport/corescriptviewport"] = "CoreScriptViewport.lua",
	["core/lib/setups/coresetup"] = "CoreSetup.lua",
	["core/lib/utils/dev/freeflight/corefreeflightmodifier"] = "CoreFreeFlightModifier.lua",
	["core/lib/utils/dev/freeflight/corefreeflight"] = "CoreFreeFlight.lua",
	["core/lib/system/coresystem"] = "CoreSystem.lua",
	--["core/lib/managers/viewport/environment/coreenvironmentmanager"] = "CoreEnvironmentManager.lua"
}

function BeardLib:init()
    if not file.GetFiles(BeardLib.JsonPath) then
		log("Create Folder")
		os.execute("mkdir " .. BeardLib.JsonPathName)
	end
    
    --implement creation of script data class instances
    BeardLib.ScriptData.Sequence = SequenceData:new("BeardLibBaseSequenceDataProcessor")
    BeardLib.ScriptData.Environment = EnvironmentData:new("BeardLibBaseEnvironmentDataProcessor")
end

function BeardLib:LoadJsonMods()
    if file.GetFiles(BeardLib.JsonPath) then
		for _, path in pairs(file.GetFiles(BeardLib.JsonPath)) do
			--BeardLib:LoadScriptDataModFromJson(BeardLib.JsonPath .. path)
		end
	end
end

if not BeardLib.setup then
	for _, class in pairs(BeardLib.classes) do
		dofile(BeardLib.mod_path .. BeardLib.class_directory .. class)
	end
	--BeardLib:Load_options()
	--dofile(ModPath .. BeardLib.writeoptions)
    BeardLib:init()
	BeardLib.setup = true
	--log(tostring(file.DirectoryExists( BeardLib.JsonPathName )))
end

if RequiredScript then
	local requiredScript = RequiredScript:lower()
    log(requiredScript)
	if BeardLib.hook_files[requiredScript] then
		dofile( BeardLib.mod_path .. BeardLib.hooks_directory .. BeardLib.hook_files[requiredScript] )
	end
end

function BeardLib:log(string)
	log("BeardLib: " .. string)
end

--[[if not BeardLib.hook_setup then
	Hooks:Register("BeardLibSequencePostInit")
	Hooks:Register("BeardLibSequenceScriptData")
	BeardLib.hook_setup = true
end]]--

BeardLib.KeyMinMax = {
	["ambient_scale"] = {min = -0.99, max = 0.99},
	["ambient_color_scale"] = {min = -50, max = 50},
	["sun_range"] = {min = 1, max = 150000},
	["fog_min_range"] = {min = -500, max = 1000},
	["fog_max_range"] = {min = -500, max = 4000},
	["ambient_falloff_scale"] = {min = -20, max = 20},
	["sky_bottom_color_scale"] = {min = -50, max = 50},
	["sky_top_color_scale"] = {min = -50, max = 50},
	["sun_ray_color_scale"] = {min = -100, max = 100},
	["color2_scale"] = {min = -15, max = 15},
	["color0_scale"] = {min = -15, max = 15},
	["color1_scale"] = {min = -15, max = 15}
}

function BeardLib:ShouldGetScriptData(filepath, extension)
    if (BeardLib and BeardLib.ScriptExceptions and BeardLib.ScriptExceptions[filepath:key()]) then
        return false
    end
    
    return true
end

Hooks:Register("BeardLibPreProcessScriptData")
Hooks:Register("BeardLibProcessScriptData")
function BeardLib:ProcessScriptData(PackManager, filepath, extension, data)
    if extension == Idstring("environment") then
		BeardLib.CurrentEnvKey = filepath:key()
	elseif extension == Idstring("menu") then
		if MenuHelperPlus and MenuHelperPlus:GetMenuDataFromHashedFilepath(filepath:key()) then
			log("Give NewData")
			data = MenuHelperPlus:GetMenuDataFromHashedFilepath(filepath:key())
		end
	end
    
    Hooks:Call("BeardLibPreProcessScriptData", PackManager, filepath, extension, data)
    Hooks:Call("BeardLibProcessScriptData", PackManager, filepath, extension, data)
    
    return data
end

function BeardLib:PopulateMenuNode(Key, Params, MenuID)
	local node = BeardLib.EnvNode
	local new_display_name = string.split(Params.display_name, "/")
	if type(Params.value) == "number" then
		MenuHelper:AddSlider({
			min = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].min or -300,
			max = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].max or 300,
			step = 0.01,
			show_value = true,
			id = Params.path,
			title = new_display_name[2],
			desc = "",
			callback = "BeardLibEnvCallback",
			--disabled_color = ,
			localized = false,
			menu_id = MenuID,
			value = Params.value
			--priority = 
		})
	elseif Params.value.x then
		MenuHelper:AddSlider({
			min = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].min or -1,
			max = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].max or 1,
			step = 0.01,
			show_value = true,
			id = Params.path .. "-x",
			title = new_display_name[2] .. "-x",
			desc = "",
			callback = "BeardLibEnvVectorxCallback",
			--disabled_color = ,
			localized = false,
			menu_id = MenuID,
			value = Params.value.x
			--priority = 
		})
		MenuHelper:AddSlider({
			min = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].min or -1,
			max = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].max or 1,
			step = 0.01,
			show_value = true,
			id = Params.path .. "-y",
			title = new_display_name[2] .. "-y",
			desc = "",
			callback = "BeardLibEnvVectoryCallback",
			--disabled_color = ,
			localized = false,
			menu_id = MenuID,
			value = Params.value.y
			--priority = 
		})
		MenuHelper:AddSlider({
			min = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].min or -1,
			max = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].max or 1,
			step = 0.01,
			show_value = true,
			id = Params.path .. "-z",
			title = new_display_name[2] .. "-z",
			desc = "",
			callback = "BeardLibEnvVectorzCallback",
			--disabled_color = ,
			localized = false,
			menu_id = MenuID,
			value = Params.value.z
			--priority = 
		})
	else
		MenuHelper:AddButton({
			id = Params.path,
			title = new_display_name[2] .. "-" .. Params.value,
			--desc = "pdth_hud_active_challenges_hint",
			callback = "BeardLibEnvStringClbk",
			--back_callback = ,
			--next_node = pdth_hud.active_challenges_menu,
			menu_id = MenuID,
			localized = false,
			priority = 1
		})
	end
end

function BeardLib:EnvUpdate(handler, viewport, scene, script_viewport)
	if BeardLib.NewEnvData then
		for key, data in pairs(BeardLib.NewEnvData) do
			if handler:get_value(key) ~= data.value then
				local parts = string.split(data.path, "-")
				local val_to_save
				if type(data.value) == "number" then
					handler:editor_set_value(key, data.value)
					val_to_save = data.value
				elseif type(data.value) == "string" then
					if managers.dyn_resource then
						if parts[1] == "underlay" then
							if not managers.dyn_resource:has_resource(Idstring("scene"), Idstring(data.value), managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
								log("not loaded")
								managers.dyn_resource:load(Idstring("scene"), Idstring(data.value), managers.dyn_resource.DYN_RESOURCES_PACKAGE, nil)
							end
						end
					end
					handler:editor_set_value(key, data.value)
					val_to_save = data.value
				else
					local value = handler:get_value(key)
					--log(key)
					local val1, val2, val3 = (data.value.x ~= 100000 and data.value.x) or (value and value.x) or 0, (data.value.y ~= 100000 and data.value.y) or (value and value.y) or 0, (data.value.z ~= 100000 and data.value.z) or (value and value.z) or 0
					local new_value = Vector3(val1, val2, val3)
					--log(value.x .. " " .. value.y .. " " .. value.z)
					--log(new_value.x .. " " .. new_value.y .. " " .. new_value.z)
					handler:editor_set_value(key, new_value)
					val_to_save = {val1, val2, val3}
				end
				
				if not data.skip_save then
					BeardLib.ModdedData = BeardLib.ModdedData or {}
					local path_parts = string.split(data.key, "/")
					local prev_meta = path_parts[#path_parts - 1]
					BeardLib.ModdedData[prev_meta] = BeardLib.ModdedData[prev_meta] or {}
					BeardLib.ModdedData[prev_meta][parts[1]] = val_to_save
				end
			end
		end
		--BeardLib.NewEnvData = nil
	end
end

function BeardLib:update(t, dt)
	if managers.viewport and managers.viewport:viewports() and (not BeardLib.AddedCallback or BeardLib.CurrentViewports ~= #managers.viewport:viewports()) then
		for _, viewport in pairs(managers.viewport:viewports()) do
			viewport:set_environment_editor_callback(callback(BeardLib, BeardLib, "EnvUpdate"))
		end
		BeardLib.AddedCallback = true
		BeardLib.CurrentViewports = #managers.viewport:viewports()
		log("Viewports updated")
	end
	BeardLib.CurrentHeistTime = BeardLib.CurrentHeistTime or 0
	if managers.game_play_central and managers.game_play_central._heist_timer and managers.game_play_central._heist_timer.running then
		BeardLib.AddedCallback = BeardLib.CurrentHeistTime ~= 0 and true or false
		BeardLib.CurrentHeistTime = Application:time() - managers.game_play_central._heist_timer.start_time + managers.game_play_central._heist_timer.offset_time
		
		--[[BeardLib.NewEnvData = BeardLib.NewEnvData or {}
		BeardLib.NewEnvData["3c084f67b1da34be"] = {value = 10 * BeardLib.CurrentHeistTime, skip_save = true, path = "sky_orientation/rotation"}
		local t = os.date ("*t")]]--
		--log(t.hour .. ":" .. t.min .. ":" .. t.sec)
		
	end

end

function BeardLib:SetupWorkspace()
	log("setup workspace")
	self._ws = Overlay:gui():create_screen_workspace()
	self._fullscreen_ws = managers.gui_data:create_fullscreen_16_9_workspace()
	managers.gui_data:layout_workspace(self._ws)
	self._panel = self._ws:panel():panel({layer = 40})
	self._fullscreen_panel = self._fullscreen_ws:panel():panel({layer = 40})
	self._setup_workspace = true
end

function BeardLib:LoadScriptDataModFromJson(Path)
	local file = io.open(Path, 'r')
	if file ~= nil then
		local file_contents = file:read("*all")
		local data = json.decode(file_contents)
		file:close()
		if data.name then
			local ModID = data.name
			if data.Environment then
				for _, mod in pairs(data.Environment) do
					local clbkparts 
					local callback
					if mod.useCallback then
						clbkparts = string.split(mod.useCallback, ":")
						if clbkparts[1] == "self" then
							clbkparts[1] = "BeardLib"
						end
						callback = loadstring("return callback(" .. clbkparts[1] .. ", " .. clbkparts[1] .. ", '" .. clbkparts[2] .. "')")
					end
					BeardLib:CreateEnvMod(mod.file or mod.hashed_file, ModID, {use_callback = callback and callback() or nil, priority = data.priority or 0 }, mod.hashed_file and true or false)
					if mod.ParamMods then
						for ParamModName, ParamModGroup in pairs(mod.ParamMods) do
							local new_table = {}
							for ParamName, ParamValue in pairs(ParamModGroup) do
								if type(ParamValue) == "table" then
									log("is table")
									log(ParamName)
									new_table[ParamName] = Vector3(ParamValue[1], ParamValue[2], ParamValue[3])
								end
							end
							table.merge(ParamModGroup, new_table)
							BeardLib:AddEnvParamMods(mod.file or mod.hashed_file, ModID, ParamModName, ParamModGroup, mod.hashed_file and true or false)
						end
					end
					if mod.NewParams then
						for ParamNewGroup, NewParams in pairs(mod.NewParams) do
							for NewParamName, NewParamValue in pairs(NewParams) do
								local ParamVal = NewParamValue
								if type(NewParamValue) == "table" then
									ParamVal = Vector3(NewParamValue[1], NewParamValue[2], NewParamValue[3])
								end
								BeardLib:AddEnvNewParam(mod.file or mod.hashed_file, ModID, ParamNewGroup, NewParamName, ParamVal, mod.hashed_file and true or false)
							end
						end
					end
					if mod.NewGroups then
						for GroupForNewGroup, NewGroups in pairs(mod.NewGroups) do
							for i, NewGroup in pairs(NewGroups) do
								BeardLib:AddEnvNewGroup(mod.file or mod.hashed_file, ModID, GroupForNewGroup, NewGroup, mod.hashed_file and true or false)
							end
						end
					end
				end
			end
			if data.Sequence then 
				--Implement reading of sequence data
				
			end
		end
	end
end

function BeardLib:SavingBackCallback()
	BeardLib.CurrentlySaving = false
end

function BeardLib:FilenameEnteredCallback()
	BeardLib.current_filename = self._input_text
	BeardLib:CreateInputPanel({value = "GeneratedMod", title = "Environment Mod ID", callback = callback(BeardLib, BeardLib, "MODIDEnteredCallback"), back_callback = callback(BeardLib, BeardLib, "SavingBackCallback")})
	
end

function BeardLib:MODIDEnteredCallback()
	local JsonData = {
		name = self._input_text,
		Environment = {
			{
				hashed_file = BeardLib.CurrentEnvKey,
				ParamMods = BeardLib.ModdedData
			}
		}
	}
	local fileName = BeardLib.current_filename
	local file = io.open(fileName, "w+")
	file:write(json.encode(JsonData))
	file:close()
end

if Hooks then
	if MenuSceneManager then
		Hooks:PostHook(MenuSceneManager, "_setup_gui", "BeardLibCreateWorkspace", function(ply)
			BeardLib:SetupWorkspace()
		end)
	end
	
	Hooks:Add("MenuUpdate", "BeardLibMenuUpdate", function( t, dt )
		BeardLib:update(t, dt)
	end)

	Hooks:Add("GameSetupUpdate", "BeardLibGameSetupUpdate", function( t, dt )
		BeardLib:update(t, dt)
	end)
		
	Hooks:Add("LocalizationManagerPostInit", "BeardLibLocalization", function(loc)
		LocalizationManager:add_localized_strings({
			["BeardLibEnvMenu"] = "BeardLib Environment Mod Menu",
			["BeardLibEnvMenuHelp"] = "Modify the params of the current Environment",
			["BeardLibSaveEnvTable_title"] = "Save Current modifications"
		})
	end)

	Hooks:Add("MenuManagerSetupCustomMenus", "Base_SetupBeardLibMenu", function( menu_manager, nodes )
        if BeardLib.EditorEnabled then
            MenuHelper:NewMenu( BeardLib.EnvMenu )
        end
		BeardLib.nodes = nodes
	end)
	
	--Hooks:Add("MenuManagerPopulateCustomMenus", "Base_PopulateBeardLibMenu", function( menu_manager, nodes )
	function BeardLib:PopulateEnvMenu()
		MenuCallbackHandler.BeardLibEnvCallback = function(this, item)
			BeardLib.NewEnvData = BeardLib.NewEnvData or {}
			BeardLib.NewEnvData[Idstring(item:name()):key()] = {value = item:value(), path = item._parameters.text_id, key = item:name()}
			BeardLib.CurrentlySaving = false
			
		end
		
		MenuCallbackHandler.BeardLibEnvVectorxCallback = function(this, item)
			BeardLib.NewEnvData = BeardLib.NewEnvData or {}
			local parts = string.split(item:name(), "-")
			BeardLib.NewEnvData[Idstring(parts[1]):key()] = {value = Vector3(item:value(), 100000, 100000), path = item._parameters.text_id, key = parts[1]}
			BeardLib.CurrentlySaving = false
		end
		
		MenuCallbackHandler.BeardLibEnvVectoryCallback = function(this, item)
			BeardLib.NewEnvData = BeardLib.NewEnvData or {}
			local parts = string.split(item:name(), "-")
			BeardLib.NewEnvData[Idstring(parts[1]):key()] = {value = Vector3(100000, item:value(), 100000), path = item._parameters.text_id, key = parts[1]}
			BeardLib.CurrentlySaving = false
		end
		
		MenuCallbackHandler.BeardLibEnvVectorzCallback = function(this, item)
			BeardLib.NewEnvData = BeardLib.NewEnvData or {}
			local parts = string.split(item:name(), "-")
			BeardLib.NewEnvData[Idstring(parts[1]):key()] = {value = Vector3(100000, 100000, item:value()), path = item._parameters.text_id, key = parts[1]}
			BeardLib.CurrentlySaving = false
		end
		
		MenuCallbackHandler.BeardLibEnvStringClbk = function(this, item)
			BeardLib.NewEnvData = BeardLib.NewEnvData or {}
			local parts = string.split(item._parameters.text_id, "-")
			BeardLib.NewEnvData[Idstring(item:name()):key()] = {value = parts[2], path = parts[1], key = item:name()}
			BeardLib.CurrentlySaving = false
		end
		
		if BeardLib.env_data then
			
			for key, params in pairs(BeardLib.env_data) do
				local parts = string.split(params.display_name, "/")
				local menu_id = "BeardLib_" .. parts[1]
				
				if not BeardLib.EnvCreatedMenus[menu_id] then
					MenuHelper:NewMenu(menu_id)
					BeardLib.EnvCreatedMenus[menu_id] = true
					MenuHelper:AddButton({
						id = menu_id .. "button",
						title = parts[1],
						--desc = "pdth_hud_active_challenges_hint",
						--callback = "SaveEnvtable",
						next_node = menu_id,
						menu_id = BeardLib.EnvMenu,
						localized = false
					})
				end
				BeardLib:PopulateMenuNode(key, params, menu_id)
			end
		end
		MenuCallbackHandler.SaveEnvtable = function(this, item)
			--SaveTable(BeardLib.ModdedData, "EnvModification" .. BeardLib.current_env .. ".txt")
			if not BeardLib.CurrentlySaving then
				BeardLib.CurrentlySaving = true
				BeardLib:CreateInputPanel({value = "EnvModification" .. BeardLib.current_env .. ".txt", title = "Environment Mod Filename", callback = callback(BeardLib, BeardLib, "FilenameEnteredCallback")})
			end
			
		end
		MenuHelper:AddButton({
			id = "BeardLibSaveEnvTable",
			title = "BeardLibSaveEnvTable_title",
			--desc = "pdth_hud_active_challenges_hint",
			callback = "SaveEnvtable",
			menu_id = BeardLib.EnvMenu,
			priority = 1
		})
		
		self:BuildEnvMenu(BeardLib.nodes)
	end
		
	--end)
	
	--Hooks:Add("MenuManagerBuildCustomMenus", "Base_BuildBeardLibMenu", function( menu_manager, nodes )
	function BeardLib:BuildEnvMenu(nodes)
		nodes[BeardLib.EnvMenu] = MenuHelper:BuildMenu(BeardLib.EnvMenu, {area_bg = "half"})
		nodes[BeardLib.EnvMenu]._parameters.hide_bg = true
		if nodes.main then
			nodes[BeardLib.EnvMenu]._parameters.menu_components = {"player_profile", "menuscene_info", "news", "game_installing"}
		end
		if not BeardLib.EnvButtonAdded then
			MenuHelper:AddMenuItem( MenuHelper.menus.lua_mod_options_menu, BeardLib.EnvMenu, "BeardLibEnvMenu", "BeardLibEnvMenuHelp")
			BeardLib.EnvButtonAdded = true
		end
		BeardLib.EnvNode = nodes[BeardLib.EnvMenu]
		for name, made in pairs(BeardLib.EnvCreatedMenus) do
			if made then
				nodes[name] = MenuHelper:BuildMenu(name, {area_bg = "half"})
				nodes[name]._parameters.menu_components = {}
				nodes[name]._parameters.hide_bg = true
			end
		end
		--[[if BeardLib.env_data then
			local node = BeardLib.EnvNode
			for key, params in pairs(BeardLib.env_data) do
				BeardLib:PopulateMenuNode(key, params)
			end
		end]]--
	end
	Hooks:Add("MenuManagerBuildCustomMenus", "Base_BuildBeardLibMenu", function( menu_manager, nodes )
		if BeardLib.EditorEnabled then
            BeardLib:PopulateEnvMenu()
        end
	end)
	
	Hooks:Register("BeardLibCreateCustomMenus")
	Hooks:Register("BeardLibCreateCustomNodesAndButtons")
	
	Hooks:Add( "MenuManagerInitialize", "BeardLibCreateMenuHooks", function(menu_manager) 
		Hooks:Call("BeardLibCreateCustomMenus", menu_manager)
		Hooks:Call("BeardLibMenuHelperPlusInitMenus", menu_manager)
		Hooks:Call("BeardLibCreateCustomNodesAndButtons", menu_manager)
	end)
	
	Hooks:Add( "BeardLibCreateCustomMenus", "BeardLibCreateEditorMenu", function(menu_manager) 
		MenuHelperPlus:NewMenu({
			InitNode = {
				Name = "editor_main",
				AlignLine = 0.75,
				BackCallback = nil,
				GuiClass = "MenuNodeMainGui",
				MenuComponents = "",
				Modifier = "PauseMenu",
				Refresh = nil,
				TopicId = "menu_ingame_menu",
				MergeData = nil
			},
			Name = "menu_editor",
			Id = "editor_menu",
			FakePath = "gamedata/menus/editor_menu",
			CallbackHandler = "MenuCallbackHandler",
			Input = "MenuInput",
			Renderer = "MenuRenderer",
			MergeData = nil
		})
	end)
	
	Hooks:Add( "BeardLibCreateCustomNodesAndButtons", "BeardLibCreateEditorMenuData", function(menu_manager)
		MenuCallbackHandler.Editor_Exit = function(this, item)
			managers.menu:close_menu("menu_editor")
			setup:freeflight():disable()
		end
		MenuHelperPlus:AddButton({
			Menu = "menu_editor",
			Node = "editor_main",
			Id = "BeardLibTestButton",
			Title = "Exit Editor",
			Desc = "Exit the current instance of the editor",
			Callback = "Editor_Exit",
			Localize = false
		})
	end)
end
