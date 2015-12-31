if not _G.BeardLib then
	_G.BeardLib = {}
	BeardLib.mod_path = ModPath
	BeardLib.save_path = SavePath
	BeardLib.sequence_mods = BeardLib.sequence_mods or {}
	BeardLib.EnvMods = BeardLib.EnvMods or {} 
	BeardLib.EnvMenu = "BeardLibEnvMenu"
	BeardLib.ScriptDataMenu = "BeardLibScriptDataMenu"
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
    BeardLib._replace_script_data = {}
    
    BeardLib.script_data_paths = {
        {path = "%userprofile%", name = "User Folder"},
        {path = "%userprofile%/Documents/", name = "Documents"},
        {path = "%userprofile%/Desktop/", name = "Desktop"},
        {path = "./", name = "PAYDAY 2"}
    }
    local handle = io.popen("wmic logicaldisk get name")
    local path = handle:read("*l")
    while (path ~= nil) do
        path = handle:read("*l")
        if path ~= nil then
            local clean_path = (string.gsub(path,  " ", "") .. "/")
            if string.find(clean_path, ":") then
                table.insert(BeardLib.script_data_paths, {path = clean_path, name = clean_path})
            end
        end
    end
    
    
    for i, path_data in pairs(BeardLib.script_data_paths) do
        local handle = io.popen("echo " .. path_data.path)
        path_data.path = string.gsub(handle:read("*l"),  "\\", "/")
        if not string.ends(path_data.path, "/") then
            path_data.path = path_data.path .. "/"
        end
        handle:close()
    end
    
    BeardLib.script_file_extensions = {
        "json",
        "xml",
        "generic_xml",
        "custom_xml",
        "sequence_manager",
        "environment",
        "menu",
        "continent",
        "continents",
        "mission",
        "nav_data",
        "cover_data",
        "world",
        "world_cameras",
        "prefhud",
        "objective",
        "credits",
        "hint",
        "comment",
        "dialog",
        "dialog_index",
        "timeline",
        "action_message",
        "achievment",
        "controller_settings",
        "binary",
    }
    
    BeardLib.script_file_from_types = {
        [1] = {name = "binary", func = "ScriptSerializer:from_binary", open_type = "rb"},
        [2] = {name = "json", func = "json.decode_script_data"},
        [3] = {name = "xml", func = "ScriptSerializer:from_xml"},
        [4] = {name = "generic_xml", func = "ScriptSerializer:from_generic_xml"},
        [5] = {name = "custom_xml", func = "ScriptSerializer:from_custom_xml"},
    }
    
    BeardLib.script_file_to_types = {
        [1] = {name = "binary", open_type = "wb"},
        [2] = {name = "json"},
        [3] = {name = "generic_xml"},
        [4] = {name = "custom_xml"},
    }
    
    BeardLib.classes = {
        "ScriptData.lua",
        "EnvironmentData.lua",
        "ContinentData.lua",
        "SequenceData.lua",
        "MenuHelperPlus.lua",
        "UnitPropertiesItem.lua",
        "json_utils.lua",
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
end

function BeardLib:init()
    if not file.GetFiles(BeardLib.JsonPath) then
		os.execute("mkdir " .. BeardLib.JsonPathName)
	end
    
    --implement creation of script data class instances
    BeardLib.ScriptData.Sequence = SequenceData:new("BeardLibBaseSequenceDataProcessor")
    BeardLib.ScriptData.Environment = EnvironmentData:new("BeardLibBaseEnvironmentDataProcessor")
    BeardLib.ScriptData.Continent = ContinentData:new("BeardLibBaseContinentDataProcessor")
    
    self:LoadJsonMods()
end

function BeardLib:LoadJsonMods()
    if file.GetFiles(BeardLib.JsonPath) then
		for _, path in pairs(file.GetFiles(BeardLib.JsonPath)) do
			BeardLib:LoadScriptDataModFromJson(BeardLib.JsonPath .. path)
		end
	end
end

function BeardLib:LoadScriptDataModFromJson(path)
    local file = io.open(path, 'r')
    if not file then
        return
    end 
    local data = json.decode_script_data(file:read("*all"))
    for i, tbl in pairs(data) do
        if BeardLib.ScriptData[i] then
            for no, mod_data in pairs(tbl) do
                BeardLib.ScriptData[i]:ParseJsonData(mod_data)
            end
        end
    end
end

if not BeardLib.setup then
	for _, class in pairs(BeardLib.classes) do
		dofile(BeardLib.mod_path .. BeardLib.class_directory .. class)
	end
    BeardLib:init()
	BeardLib.setup = true
end

if RequiredScript then
	local requiredScript = RequiredScript:lower()
    log(requiredScript)
	if BeardLib.hook_files[requiredScript] then
		dofile( BeardLib.mod_path .. BeardLib.hooks_directory .. BeardLib.hook_files[requiredScript] )
	end
end

function BeardLib:log(str)
	log("[BeardLib] " .. str)
end

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
    if (BeardLib and BeardLib.ScriptExceptions and BeardLib.ScriptExceptions[filepath:key()] and BeardLib.ScriptExceptions[filepath:key()][extension:key()]) then
        return false
    end
    
    return true
end

function BeardLib:RemoveMetas(tbl)
    for i, data in pairs(tbl) do
        if type(data) == "table" then
            self:RemoveMetas(data)
        elseif i == "_meta" then
            tbl[i] = nil
        end
    end
end

Hooks:Register("BeardLibPreProcessScriptData")
Hooks:Register("BeardLibProcessScriptData")
function BeardLib:ProcessScriptData(PackManager, filepath, extension, data)
    if extension == Idstring("environment") then
		BeardLib.CurrentEnvKey = filepath:key()
	elseif extension == Idstring("menu") then
		if MenuHelperPlus and MenuHelperPlus:GetMenuDataFromHashedFilepath(filepath:key()) then
			data = MenuHelperPlus:GetMenuDataFromHashedFilepath(filepath:key())
		end
	end
    
    if self._replace_script_data[filepath:key()] and self._replace_script_data[filepath:key()][extension:key()] then
        log("Replace: " .. tostring(filepath:key()))
        
        local replacementPathData = self._replace_script_data[filepath:key()][extension:key()]
        local fileType = replacementPathData.load_type
        local file
        if fileType == "binary" then
            file = io.open(replacementPathData.path, "rb")
        else
            file = io.open(replacementPathData.path, 'r')
        end
        
        if file then
            local read_data = file:read("*all")
            
            local new_data
            if fileType == "json" then
                new_data = json.decode_script_data(read_data)
            elseif fileType == "xml" then
                new_data = ScriptSerializer:from_xml(read_data)
            elseif fileType == "custom_xml" then
                new_data = ScriptSerializer:from_custom_xml(read_data)
            elseif fileType == "generic_xml" then
                new_data = ScriptSerializer:from_generic_xml(read_data)
            elseif fileType == "binary" then
                new_data = ScriptSerializer:from_binary(read_data)
            else
                new_data = json.decode_script_data(read_data)
            end
            
            if extension == Idstring("nav_data") then
                self:RemoveMetas(new_data)
            end
            
            if new_data then
                data = new_data
            end
            file:close()
        end
       
    end
    
    Hooks:Call("BeardLibPreProcessScriptData", PackManager, filepath, extension, data)
    Hooks:Call("BeardLibProcessScriptData", PackManager, filepath, extension, data)
    
    return data
end

function BeardLib:ReplaceScriptData(replacementPath, typ, path, extension, prevent_get)
    self._replace_script_data[path:key()] = self._replace_script_data[path:key()] or {}
    if self._replace_script_data[path:key()][extension:key()] then
        BeardLib:log("[ERROR] Filepath has already been replaced, continuing with overwrite")
    end
    
    if prevent_get then
        BeardLib.ScriptExceptions[path:key()] = BeardLib.ScriptExceptions[path:key()] or {}
        BeardLib.ScriptExceptions[path:key()][extension:key()] = true
    end
    
    self._replace_script_data[path:key()][extension:key()] = {path = replacementPath, load_type = typ}
end

function BeardLib:PopulateMenuNode(Key, Params, value, node)
	local new_display_name = string.split(Params.display_name, "/")
	if type(Params.value) == "number" then
		MenuHelperPlus:AddSlider({
			min = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].min or -300,
			max = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].max or 300,
			step = 0.01,
			show_value = true,
			id = Params.path,
			title = new_display_name[2],
			desc = "",
			callback = "BeardLibEnvCallback",
			localized = false,
			node = node,
			value = value,
            merge_data = {
                path = Params.display_name,
                path_key = Key
            }
		})
	elseif Params.value.x then
		MenuHelperPlus:AddSlider({
			min = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].min or -1,
			max = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].max or 1,
			step = 0.01,
			show_value = true,
			id = Params.path .. "-x",
			title = new_display_name[2] .. "-X",
			desc = "",
			callback = "BeardLibEnvVectorxCallback",
			localized = false,
			node = node,
			value = value.x,
            merge_data = {
                path = Params.display_name,
                path_key = Key
            }
		})
		MenuHelperPlus:AddSlider({
			min = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].min or -1,
			max = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].max or 1,
			step = 0.01,
			show_value = true,
			id = Params.path .. "-y",
			title = new_display_name[2] .. "-Y",
			desc = "",
			callback = "BeardLibEnvVectoryCallback",
			localized = false,
			node = node,
			value = value.y,
            merge_data = {
                path = Params.display_name,
                path_key = Key
            }
		})
		MenuHelperPlus:AddSlider({
			min = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].min or -1,
			max = BeardLib.KeyMinMax[new_display_name[2]] and BeardLib.KeyMinMax[new_display_name[2]].max or 1,
			step = 0.01,
			show_value = true,
			id = Params.path .. "-z",
			title = new_display_name[2] .. "-Z",
			desc = "",
			callback = "BeardLibEnvVectorzCallback",
			localized = false,
			node = node,
			value = value.z,
            merge_data = {
                path = Params.display_name,
                path_key = Key
            }
		})
	else
		MenuHelperPlus:AddButton({
			id = Params.path,
			title = new_display_name[2],
			desc = value,
			callback = "BeardLibEnvStringClbk",
			node = node,
			localized = false,
			localized_help = false,
			priority = 1,
            merge_data = {
                string_value = value,
                path = Params.display_name,
                path_key = Key,
                input = true
            }
		})
	end
end

function BeardLib:update(t, dt)
    if managers.viewport and managers.viewport:viewports() and self.NewEnvData then
        for key, data in pairs(self.NewEnvData) do
            for _, viewport in pairs(managers.viewport:viewports()) do
                local handler = viewport._env_handler
                local value = viewport:get_environment_value(key)
                local val_to_save = data.value
                
                if CoreClass.type_name(value) == "Vector3" then
                    local new_value = Vector3(data.value.x or value.x, data.value.y or value.y, data.value.z or value.z)
                    handler:editor_set_value(key, new_value)
                    val_to_save = new_value
                else
                    handler:editor_set_value(key, data.value)
                end
                
                if not data.skip_save then
                    self.ModdedData = self.ModdedData or {}
                    self.ModdedData[data.path] = self.ModdedData[data.path] or {}
                    self.ModdedData[data.path] = tostring(val_to_save)
                end                
            end
            self.NewEnvData[key] = nil
        end
	end
end

function BeardLib:SavingBackCallback()
	BeardLib.CurrentlySaving = false
end

function BeardLib:FilenameEnteredCallback(value)
	BeardLib.current_filename = value
	BeardLib:CreateInputPanel({value = "GeneratedMod", title = "Environment Mod ID", callback = callback(BeardLib, BeardLib, "MODIDEnteredCallback"), back_callback = callback(BeardLib, BeardLib, "SavingBackCallback")})
	
end

function BeardLib:MODIDEnteredCallback(value)
	local JsonData = {
		name = value,
		Environment = {
			{
				file_key = BeardLib.CurrentEnvKey,
				ParamMods = BeardLib.ModdedData
			}
		}
	}
	local fileName = BeardLib.current_filename
	local file = io.open(fileName, "w+")
	file:write(json.encode_script_data(JsonData))
	file:close()
    BeardLib.CurrentlySaving = false
end

function BeardLib:GetSubValues(tbl, key)
    local new_tbl = {}
    for i, vals in pairs(tbl) do
        if vals[key] then
            new_tbl[i] = vals[key]
        end
    end
    
    return new_tbl
end

function BeardLib:GetTypeDataFrom(file, typ)
    local read_data = file:read("*all")
    
    local new_data
    if typ == "json" then
        new_data = json.decode_script_data(read_data)
    elseif typ == "xml" then
        new_data = ScriptSerializer:from_xml(read_data)
    elseif typ == "custom_xml" then
        new_data = ScriptSerializer:from_custom_xml(read_data)
    elseif typ == "generic_xml" then
        new_data = ScriptSerializer:from_generic_xml(read_data)
    elseif typ == "binary" then
        new_data = ScriptSerializer:from_binary(read_data)
    end
    
    return new_data
end

function BeardLib:GetTypeDataTo(data, typ)
    local new_data
    if typ == "json" then
        new_data = json.encode_script_data(data)
    elseif typ == "custom_xml" then
        new_data = ScriptSerializer:to_custom_xml(data)
    elseif typ == "generic_xml" then
        new_data = ScriptSerializer:to_generic_xml(data)
    elseif typ == "binary" then
        new_data = ScriptSerializer:to_binary(data)
    end
    
    return new_data
end

function BeardLib:ConvertFile(file, from_i, to_i, filename_dialog)
    local from_data = self.script_file_from_types[from_i]
    local to_data = self.script_file_to_types[to_i]
    
    local from_file = io.open(file, from_data.open_type or 'r')
    local convert_data = self:GetTypeDataFrom(from_file, from_data.name)
    from_file:close()
    
    local new_path = file .. "." .. to_data.name
    
    if filename_dialog then
        BeardLib:CreateInputPanel({value = new_path, title = "File name", callback = callback(self, self, "SaveConvertedData"), callback_params = {from_data = from_data, to_data = to_data, convert_data = convert_data, current_file = file}})
    else
        BeardLib:SaveConvertedData(new_path, {from_data = from_data, to_data = to_data, convert_data = convert_data, current_file = file})
    end
    
    
end

function BeardLib:SaveConvertedData(value, params)
    local to_file = io.open(value, params.to_data.open_type or "w+")
    local new_data = self:GetTypeDataTo(params.convert_data, params.to_data.name)
    to_file:write(new_data)
    to_file:close()
    
    BeardLib:RefreshFilesAndFolders()
end

if Hooks then
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
			["BeardLibSaveEnvTable_title"] = "Save Current modifications",
			["BeardLibScriptDataMenu_title"] = "BeardLib ScriptData Converter"
		})
	end)

	Hooks:Add("MenuManagerSetupCustomMenus", "Base_SetupBeardLibMenu", function( menu_manager, nodes )
        MenuCallbackHandler.BeardLibScriptDataMenuBack = function(this, item)
            BeardLib:CreateRootItems()
            BeardLib.current_script_path = ""
        end
        
        local node = MenuHelperPlus:NewNode(nil, {
            name = BeardLib.ScriptDataMenu,
            back_callback = "BeardLibScriptDataMenuBack"
        })
        if BeardLib.EditorEnabled then
            MenuHelperPlus:NewNode(nil, {
                name = BeardLib.EnvMenu,
                menu_components = managers.menu._is_start_menu and "player_profile menuscene_info news game_installing" or nil,
                merge_data = {
                    area_bg = "half",
                    hide_bg = true
                }
            })
        end
	end)
	
	function BeardLib:PopulateEnvMenu(feeder_list)
        local node = MenuHelperPlus:GetNode(nil, BeardLib.EnvMenu)
        if node then
            node:clean_items()
            
            MenuCallbackHandler.SaveEnvtable = function(this, item)
                if not BeardLib.CurrentlySaving then
                    BeardLib.CurrentlySaving = true
                    BeardLib:CreateInputPanel({value = "EnvModification" .. BeardLib.current_env .. ".txt", title = "Environment Mod Filename", callback = callback(BeardLib, BeardLib, "FilenameEnteredCallback")})
                end
                
            end
            MenuHelperPlus:AddButton({
                id = "BeardLibSaveEnvTable",
                title = "BeardLibSaveEnvTable_title",
                callback = "SaveEnvtable",
                node = node,
                priority = 1
            })
            
            MenuCallbackHandler.BeardLibEnvCallback = function(this, item)
                BeardLib.NewEnvData = BeardLib.NewEnvData or {}
                BeardLib.NewEnvData[tostring(item._parameters.path_key)] = {value = item:value(), path = item._parameters.path}
                BeardLib.CurrentlySaving = false
                
            end
            
            MenuCallbackHandler.BeardLibEnvVectorxCallback = function(this, item)
                BeardLib.NewEnvData = BeardLib.NewEnvData or {}
                BeardLib.NewEnvData[tostring(item._parameters.path_key)] = {value = Vector3(item:value(), nil, nil), path = item._parameters.path}
                BeardLib.CurrentlySaving = false
            end
            
            MenuCallbackHandler.BeardLibEnvVectoryCallback = function(this, item)
                BeardLib.NewEnvData = BeardLib.NewEnvData or {}
                BeardLib.NewEnvData[tostring(item._parameters.path_key)] = {value = Vector3(nil, item:value(), nil), path = item._parameters.path}
                BeardLib.CurrentlySaving = false
            end
            
            MenuCallbackHandler.BeardLibEnvVectorzCallback = function(this, item)
                BeardLib.NewEnvData = BeardLib.NewEnvData or {}
                BeardLib.NewEnvData[tostring(item._parameters.path_key)] = {value = Vector3(nil, nil, item:value()), path = item._parameters.path}
                BeardLib.CurrentlySaving = false
            end
            
            MenuCallbackHandler.BeardLibEnvStringClbk = function(this, item)
                BeardLib.NewEnvData = BeardLib.NewEnvData or {}
                local split = string.split(item._parameters.path, "/")
                if split[#split] == "underlay" then
                    if not managers.dyn_resource:has_resource(Idstring("scene"), Idstring(item._parameters.help_id), managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
                        managers.dyn_resource:load(Idstring("scene"), Idstring(item._parameters.help_id), managers.dyn_resource.DYN_RESOURCES_PACKAGE, nil)
                    end
                end
                
                BeardLib.NewEnvData[item._parameters.path_key] = {value = item._parameters.help_id, path = item._parameters.path, key = item:name()}
                BeardLib.CurrentlySaving = false
            end
            
            local viewport = managers.viewport:first_active_viewport()
            
            if feeder_list and feeder_list[viewport._env_handler:get_path():key()] then
                for key, params in pairs(feeder_list[viewport._env_handler:get_path():key()]) do
                    local value = viewport:get_environment_value(key) or params.value
                    local parts = string.split(params.path, "/")
                    local menu_id = "BeardLib_" .. parts[#parts - 1]
                    local new_node = MenuHelperPlus:GetNode(nil, menu_id)
                    if not new_node then
                        new_node = MenuHelperPlus:NewNode(nil, {
                            name = menu_id,
                            merge_data = {
                                hide_bg = true
                            }
                        })
                        managers.menu:add_back_button(new_node)
                        MenuHelperPlus:AddButton({
                            id = menu_id .. "button",
                            title = parts[#parts - 1],
                            next_node = menu_id,
                            node = node,
                            localized = false
                        })
                    end
                    if value then
                        BeardLib:PopulateMenuNode(key, params, value, new_node)
                    end
                end
            end
            
            managers.menu:add_back_button(node)
        end
	end
    
    function BeardLib:RefreshFilesAndFolders()
        local node = MenuHelperPlus:GetNode(nil, BeardLib.ScriptDataMenu)
        node:clean_items()
        
        local gui_class = managers.menu:active_menu().renderer:active_node_gui()
        
        local path_text = gui_class.safe_rect_panel:child("BeardLibPathText") or gui_class.safe_rect_panel:text({
            name = "BeardLibPathText",
            text = "",
            font =  tweak_data.menu.pd2_medium_font, 
            font_size = 25,
            layer = 20,
            color = Color.yellow
        })
        path_text:set_text(self.current_script_path)
        local x, y, w, h = path_text:text_rect()
        path_text:set_size(w, h)
        path_text:set_position(0, 0)
        
        MenuHelperPlus:AddButton({
            id = "BackToStart",
            title = "Back to the future",
            callback = "BeardLibScriptStart",
            node = node,
            localized = false
        })

        MenuHelperPlus:AddButton({
            id = "OpenFolderInExplorer",
            title = "Open In Explorer",
            callback = "BeardLibOpenInExplorer",
            node = node,
            localized = false
        })
        
        local up_level = string.split(self.current_script_path, "/")
        if #up_level > 1 then
            table.remove(up_level, #up_level)
            MenuHelperPlus:AddButton({
                id = "UpLevel",
                title = "UP A DIRECTORY...",
                callback = "BeardLibFolderClick",
                node = node,
                localized = false,
                merge_data = {
                    base_path = table.concat(up_level, "/") .. "/"
                }
            })
        end
        MenuHelperPlus:AddDivider({
            id = "fileDivider",
            node = node,
            size = 15
        })
        
        log(self.current_script_path)
        local folders = file.GetDirectories(self.current_script_path)
        local files = file.GetFiles(self.current_script_path)
        
        if folders then
            for i, folder in pairs(folders) do
                MenuHelperPlus:AddButton({
                    id = "BeardLibPath" .. folder,
                    title = folder,
                    callback = "BeardLibFolderClick",
                    node = node,
                    localized = false,
                    merge_data = {
                        base_path = self.current_script_path .. folder .. "/",
                        row_item_color = Color.yellow,
                        hightlight_color = Color.yellow,
                        to_upper = false
                    }
                })
            end
        end
        
        if files then
            for i, file in pairs(files) do
                local file_parts = string.split(file, "%.")
                local extension = file_parts[#file_parts]
                if table.contains(self.script_file_extensions, extension) then
                    MenuHelperPlus:AddButton({
                        id = "BeardLibPath" .. file,
                        title = file,
                        callback = "BeardLibFileClick",
                        node = node,
                        localized = false,
                        merge_data = {
                            base_path = self.current_script_path .. file,
                            row_item_color = Color.white,
                            hightlight_color = Color.white,
                            to_upper = false
                        }
                    })
                end
            end
        end
        
        managers.menu:add_back_button(node)
        
        local selected_node = managers.menu:active_menu().logic:selected_node()
        managers.menu:active_menu().renderer:refresh_node(selected_node)
        local selected_item = selected_node:selected_item()
        selected_node:select_item(selected_item and selected_item:name())
        managers.menu:active_menu().renderer:highlight_item(selected_item)
        
    end
    
     function BeardLib:CreateScriptDataFileOption()
        local node = MenuHelperPlus:GetNode(nil, BeardLib.ScriptDataMenu)
        node:clean_items()
        
        MenuHelperPlus:AddButton({
            id = "BackToStart",
            title = "Back to the future",
            callback = "BeardLibScriptStart",
            node = node,
            localized = false
        })
        
        MenuHelperPlus:AddButton({
            id = "Cancel",
            title = "Cancel",
            callback = "BeardLibFolderClick",
            node = node,
            localized = false,
            merge_data = {
                base_path = self.current_script_path
            }
        })
        
        MenuHelperPlus:AddDivider({
            id = "fileDivider",
            node = node,
            size = 15
        })
        
        log(self.current_selected_file_path)
        
        local gui_class = managers.menu:active_menu().renderer:active_node_gui()
        local path_text = gui_class.safe_rect_panel:child("BeardLibPathText")
        
        if path_text then
            path_text:set_text(self.current_selected_file_path)
            local x, y, w, h = path_text:text_rect()
            path_text:set_size(w, h)
            path_text:set_position(0, 0)
        end
        
        local file_parts = string.split(self.current_selected_file, "%.")
        local extension = file_parts[#file_parts]
        local selected_from = 1
        for i, typ in pairs(self.script_file_from_types) do
            if typ.name == extension then
                selected_from = i
                break
            end
        end
        
        MenuHelperPlus:AddMultipleChoice({
			id = "convertfrom",
			title = "from",
			node = node,
			value = selected_from,
			items = self:GetSubValues(self.script_file_from_types, "name"),
            localized = false,
            localized_items = false
		})
        
        MenuHelperPlus:AddMultipleChoice({
			id = "convertto",
			title = "to",
			node = node,
			items = self:GetSubValues(self.script_file_to_types, "name"),
            localized = false,
            localized_items = false
		})
        
        MenuHelperPlus:AddButton({
            id = "convert",
            title = "convert",
            callback = "BeardLibConvertClick",
            node = node,
            localized = false
        })
        
        managers.menu:add_back_button(node)
        
        local selected_node = managers.menu:active_menu().logic:selected_node()
        managers.menu:active_menu().renderer:refresh_node(selected_node)
        local selected_item = selected_node:selected_item()
        selected_node:select_item(selected_item and selected_item:name())
        managers.menu:active_menu().renderer:highlight_item(selected_item)
        
    end
    
    Hooks:Add("MenuManagerPopulateCustomMenus", "PopulateBeardLibMenus", function(menu_manager, nodes)
        MenuCallbackHandler.BeardLibFolderClick = function(this, item)
            BeardLib.current_script_path = item._parameters.base_path
            
            BeardLib:RefreshFilesAndFolders()
        end
        
        MenuCallbackHandler.BeardLibFileClick = function(this, item)
            BeardLib.current_selected_file = item._parameters.text_id
            BeardLib.current_selected_file_path = item._parameters.base_path
            
            BeardLib:CreateScriptDataFileOption()
        end
        
        MenuCallbackHandler.BeardLibScriptStart = function(this, item)
            local gui_class = managers.menu:active_menu().renderer:active_node_gui()
            local path_text = gui_class.safe_rect_panel:child("BeardLibPathText")
            
            if path_text then
                gui_class.safe_rect_panel:remove(path_text)
            end
            
            local node = MenuHelperPlus:GetNode(nil, BeardLib.ScriptDataMenu)
            node:clean_items()
        
            BeardLib.current_script_path = ""
            BeardLib:CreateRootItems()
        
            local selected_node = managers.menu:active_menu().logic:selected_node()
            managers.menu:active_menu().renderer:refresh_node(selected_node)
            local selected_item = selected_node:selected_item()
            selected_node:select_item(selected_item and selected_item:name())
            managers.menu:active_menu().renderer:highlight_item(selected_item)
        end
        
        MenuCallbackHandler.BeardLibConvertClick = function(this, item)
            local node = MenuHelperPlus:GetNode(nil, BeardLib.ScriptDataMenu)
            
            local convertfrom_item = node:item("convertfrom")
            local convertto_item = node:item("convertto")
            
            if convertfrom_item and convertto_item then
                BeardLib:ConvertFile(BeardLib.current_selected_file_path, convertfrom_item:value(), convertto_item:value(), true)
            end
        end
        
        MenuCallbackHandler.BeardLibOpenInExplorer = function(this, item)
            local open_path = string.gsub(BeardLib.current_script_path, "%./", "")
            open_path = string.gsub(BeardLib.current_script_path, "/", "\\")
            
            os.execute("start \"\" \"" .. open_path .. "\"")
        end
        
        BeardLib:CreateRootItems()
    end)
    
    function BeardLib:CreateRootItems()
        local node = MenuHelperPlus:GetNode(nil, BeardLib.ScriptDataMenu)
        node:clean_items()
        
        for i, path_data in pairs(BeardLib.script_data_paths) do
            MenuHelperPlus:AddButton({
                id = "BeardLibPath" .. path_data.name,
                title = path_data.name,
                callback = "BeardLibFolderClick",
                node = node,
                localized = false,
                merge_data = {
                    base_path = path_data.path
                }
            })
        end
        
        managers.menu:add_back_button(node)
    end
    
	Hooks:Add("MenuManagerBuildCustomMenus", "Base_BuildBeardLibMenu", function( menu_manager, nodes )
        MenuHelperPlus:AddButton({
            id = "BeardLibScriptDataMenu",
            title = "BeardLibScriptDataMenu_title",
            node_name = "lua_mod_options_menu",
            next_node = BeardLib.ScriptDataMenu,
        })
        
        if BeardLib.EditorEnabled then
            MenuCallbackHandler.BeardLibOpenEnvMenu = function(this, item)
                if BeardLib.env_data then
                    BeardLib:PopulateEnvMenu(BeardLib.env_data)
                end
            end
            
            MenuHelperPlus:AddButton({
                id = "BeardLibEnvMenu",
                title = "BeardLibEnvMenu",
                callback = "BeardLibOpenEnvMenu",
                node_name = "lua_mod_options_menu",
                next_node = BeardLib.EnvMenu,
            })
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
			init_node = {
				name = "editor_main",
				align_node = 0.75,
				back_callback = nil,
				gui_class = "MenuNodeMainGui",
				menu_components = "",
				modifier = "PauseMenu",
				refresh = nil,
				topic_id = "menu_ingame_menu",
				merge_data = nil
			},
			name = "menu_editor",
			id = "editor_menu",
			fake_path = "gamedata/menus/editor_menu",
			callback_handler = "MenuCallbackHandler",
			input = "MenuInput",
			renderer = "MenuRenderer",
			merge_data = nil
		})
	end)
	
	Hooks:Add( "BeardLibCreateCustomNodesAndButtons", "BeardLibCreateEditorMenuData", function(menu_manager)
		MenuCallbackHandler.Editor_Exit = function(this, item)
			managers.menu:close_menu("menu_editor")
			setup:freeflight():disable()
		end
		MenuHelperPlus:AddButton({
			menu = "menu_editor",
			node_name = "editor_main",
			id = "BeardLibTestButton",
			title = "Exit Editor",
			desc = "Exit the current instance of the editor",
			callback = "Editor_Exit",
			localized = false
		})
	end)
end
