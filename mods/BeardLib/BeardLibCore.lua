if not _G.BeardLib then
    _G.BeardLib = {}
    
    local self = BeardLib
    
    self.mod_path = ModPath
    self.save_path = SavePath
    self.sequence_mods = self.sequence_mods or {}
    self.MainMenu = "BeardLibMainMenu"
    self.MapsPath = "BeardLibMaps"
    self.CurrentViewportNo = 0
    self.ScriptExceptions = self.ScriptExceptions or {}
    self.EditorEnabled = true
    self.HooksDirectory = "Hooks/"
    self.ClassDirectory = "Classes/"
    self.ScriptData = {}
    self.managers = {}
    self._replace_script_data = {}
    
    self.DBPaths = {}
    self.DBEntries = {}
     
   
    --Make this true if io.popen doesn't tab you out of the game, false if it does
    --[[if false then
        local handle = io.popen("wmic logicaldisk get name")
        local path = handle:read("*l")
        while (path ~= nil) do
            path = handle:read("*l")
            if path ~= nil then
                local clean_path = (string.gsub(path,  " ", "") .. "/")
                if string.find(clean_path, ":") then
                    table.insert(self.script_data_paths, {path = clean_path, name = clean_path})
                end
            end
        end
        handle:close()
        
        for i, path_data in pairs(self.script_data_paths) do
            local handle = io.popen("echo " .. path_data.path)
            path_data.path = string.gsub(handle:read("*l"),  "\\", "/")
            if not string.ends(path_data.path, "/") then
                path_data.path = path_data.path .. "/"
            end
            handle:close()
        end
    else]]--
    
    --end    
    
    self.script_data_types = {
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
        "network_settings",
    }
    
    self.file_types = {
        "achievment",
        "action_message",
        "animation",
        "animation_def",
        "animation_state_machine",
        "animation_states",
        "animation_subset",
        "atom_batcher_settings",
        "banksinfo",
        "bmfc",
        "bnk",
        "bnkinfo",
        "camera_shakes",
        "cameras",
        "cgb",
        "comment",
        "continent",
        "continents",
        "controller_settings",
        "cooked_physics",
        "cover_data",
        "credits",
        "decals",
        "dialog",
        "dialog_index",
        "diesel_layers",
        "effect",
        "environment",
        "font",
        "gui",
        "hint",
        "idstring_lookup",
        "light_intensities",
        "lua",
        "massunit",
        "material_config",
        "menu",
        "merged_font", 
        "mission",
        "model",
        "movie",
        "nav_data",
        "network_settings",
        "object",
        "objective",
        "physic_effect",
        "physics_settings",
        "post_processor",
        "prefhud",
        "render_config",
        "render_template_database",
        "scene",
        "scenes",
        "sequence_manager",
        "sfap0",
        "shaders",
        "stream",
        "strings",
        "texture",
        "texture_channels",
        "tga",
        "unit",
        "world",
        "world_cameras",
        "world_setting",
        "world_sounds",
        "xbox_live",
        "xml"
    }
    
    self.script_data_formats = {
        "json",
        "xml",
        "generic_xml",
        "custom_xml",
        "binary",
    }
    
    self.classes = {
        "ScriptData/ScriptData.lua",
        "ScriptData/EnvironmentData.lua",
        "ScriptData/ContinentData.lua",
        "ScriptData/SequenceData.lua",
        "EnvironmentEditorManager.lua",
        "EnvironmentEditorHandler.lua",      
        "ScriptDataConverterManager.lua",      
        "MenuUI.lua",        
        "MenuDialog.lua",                
        "MenuItems/Menu.lua",   
        "MenuItems/Item.lua",
        "MenuItems/Toggle.lua",
        "MenuItems/ComboBox.lua",
        "MenuItems/Slider.lua",
        "MenuItems/TextBox.lua", 
        "MenuItems/Divider.lua", 
        "MenuItems/Table.lua",         
        "MapEditor.lua",
        "MenuHelperPlus.lua",
        "UnitPropertiesItem.lua",
        "json_utils.lua",
        "utils.lua"
    }

    self.hook_files = {
        ["core/lib/managers/coresequencemanager"] = "CoreSequenceManager.lua",
        ["lib/managers/menu/menuinput"] = "MenuInput.lua",
        ["lib/managers/menu/textboxgui"] = "TextBoxGUI.lua",
        ["lib/managers/systemmenumanager"] = "SystemMenuManager.lua",
        ["lib/managers/dialogs/keyboardinputdialog"] = "KeyboardInputDialog.lua",
        ["core/lib/managers/viewport/corescriptviewport"] = "CoreScriptViewport.lua",
        ["core/lib/utils/dev/freeflight/corefreeflightmodifier"] = "CoreFreeFlightModifier.lua",
        ["core/lib/utils/dev/freeflight/corefreeflight"] = "CoreFreeFlight.lua",
        ["core/lib/managers/mission/coremissionmanager"] = "Coremissionmanager.lua",
        ["core/lib/utils/dev/editor/coreworlddefinition"] = "Coreworlddefinition.lua",
        ["lib/setups/gamesetup"] = "Gamesetup.lua",
        ["core/lib/system/coresystem"] = "CoreSystem.lua",
        --["core/lib/managers/viewport/environment/coreenvironmentmanager"] = "CoreEnvironmentManager.lua"
    }
end

function BeardLib:init()
    if not file.GetFiles(self.MapsPath) then
        os.execute("mkdir " .. self.MapsPath)
    end
    
    --implement creation of script data class instances
    self.ScriptData.Sequence = SequenceData:new("BeardLibBaseSequenceDataProcessor")
    self.ScriptData.Environment = EnvironmentData:new("BeardLibBaseEnvironmentDataProcessor")
    self.ScriptData.Continent = ContinentData:new("BeardLibBaseContinentDataProcessor")
    self.managers.EnvironmentEditor = EnvironmentEditorManager:new()
    self.managers.ScriptDataConveter = ScriptDataConveterManager:new()
    
    --Load ScriptData mod_overrides
    self:LoadModOverridePlus()
    
    self:LoadHashlist()
end

function BeardLib:LoadModOverridePlus()
    local mods = file.GetDirectories("assets/mod_overrides/")
    if mods then
        for _, path in pairs(mods) do
            self:LoadModOverrideFolder("assets/mod_overrides/" .. path .. "/", "")
        end
    end
end

function BeardLib:LoadHashlist()
    local file = DB:open("idstring_lookup", "idstring_lookup")
    
    BeardLib:log("Loading Hashlist")
    
    local function AddPathEntry(line, typ)
        local path_split = string.split(line, "/")
        local curr_tbl = self.DBEntries
        
        local filename = table.remove(path_split, #path_split)
        
        for _, part in pairs(path_split) do
            curr_tbl[part] = curr_tbl[part] or {}
            curr_tbl = curr_tbl[part]
        end
        table.insert(curr_tbl, {
            path = line,
            name = filename,
            file_type = typ
        })
    end
    local types = clone(self.script_data_types)
    table.insert(types, "unit")
    if file ~= nil then
        --Iterate through each string which contains _ or /, which should include all the filepaths in the idstring_lookup
        for line in string.gmatch(file:read(), "[%w_/]+%z") do
            --Remove the Zero byte at the end of the path
            line = string.sub(line, 1, #line - 1)
            
            --[[if DB:has("unit", line) then
                self.DBPaths["unit"] = self.DBPaths["unit"] or {}
                table.insert(self.DBPaths["unit"], line)
                AddPathEntry(line, "unit")
            else]]--
                for _, typ in pairs(types) do
                    self.DBPaths[typ] = self.DBPaths[typ] or {}
                    if DB:has(typ, line) then
                        table.insert(self.DBPaths[typ], line)
                        AddPathEntry(line, typ)
                        --I wish I could break so we don't have to iterate more than needed, but some files exist with the same name but a different type
                        --break
                    end
                end
            --end
        end
        file:close()
    end
    
    for typ, filetbl in pairs(self.DBPaths) do
        BeardLib:log(typ .. " Count: " .. #filetbl)
    end
    
    --SaveTable(self.DBEntries, "DBEntries_index.txt")
    
    BeardLib:log("Hashlist Loaded")
end

function BeardLib:LoadModOverrideFolder(directory, currentFilePath)
    local subFolders = file.GetDirectories(directory)
    if subFolders then
        for _, sub_path in pairs(subFolders) do
            self:LoadModOverrideFolder(directory .. sub_path .. "/", currentFilePath .. (currentFilePath == "" and "" or "/") .. sub_path)
        end
    end
    
    local subFiles = file.GetFiles(directory)
    if subFiles then
        for _, sub_file in pairs(subFiles) do
            local file_name_split = string.split(sub_file, "%.")
            if table.contains(self.script_data_formats, file_name_split[2]) or table.contains(self.script_data_types, file_name_split[2]) then
                local fullFilepath = currentFilePath .. "/" .. file_name_split[1]
                self:ReplaceScriptData(directory .. sub_file, #file_name_split == 2 and "binary" or file_name_split[3], fullFilepath, file_name_split[2], true, false)
            end
        end
    end
end

function BeardLib:RefreshCurrentNode()
    local selected_node = managers.menu:active_menu().logic:selected_node()
    managers.menu:active_menu().renderer:refresh_node(selected_node)
    local selected_item = selected_node:selected_item()
    selected_node:select_item(selected_item and selected_item:name())
    managers.menu:active_menu().renderer:highlight_item(selected_item)
end

function BeardLib:LoadScriptDataModFromJson(path)
    local file = io.open(path, 'r')
    if not file then
        return
    end 
    local data = json.custom_decode(file:read("*all"))
    for i, tbl in pairs(data) do
        if BeardLib.ScriptData[i] then
            for no, mod_data in pairs(tbl) do
                BeardLib.ScriptData[i]:ParseJsonData(mod_data)
            end
        end
    end
end

if RequiredScript then
    local requiredScript = RequiredScript:lower()
    if BeardLib.hook_files[requiredScript] then
        dofile( BeardLib.mod_path .. BeardLib.HooksDirectory .. BeardLib.hook_files[requiredScript] )
    end
end

function BeardLib:log(str)
    log("[BeardLib] " .. str)
end

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
    if extension == Idstring("menu") then
        if MenuHelperPlus and MenuHelperPlus:GetMenuDataFromHashedFilepath(filepath:key()) then
            data = MenuHelperPlus:GetMenuDataFromHashedFilepath(filepath:key())
        end
    end
    
    if self._replace_script_data[filepath:key()] and self._replace_script_data[filepath:key()][extension:key()] then
        BeardLib:log("Replace: " .. tostring(filepath:key()))
        
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
                new_data = json.custom_decode(read_data)
            elseif fileType == "xml" then
                new_data = ScriptSerializer:from_xml(read_data)
            elseif fileType == "custom_xml" then
                new_data = ScriptSerializer:from_custom_xml(read_data)
            elseif fileType == "generic_xml" then
                new_data = ScriptSerializer:from_generic_xml(read_data)
            elseif fileType == "binary" then
                new_data = ScriptSerializer:from_binary(read_data)
            else
                new_data = json.custom_decode(read_data)
            end
            
            if extension == Idstring("nav_data") then
                self:RemoveMetas(new_data)
            end
            
            if new_data then
                if (replacementPathData.merge) then
                    table.merge(data, new_data)
                else
                    data = new_data
                end
            end
            file:close()
        end
       
    end
    
    Hooks:Call("BeardLibPreProcessScriptData", PackManager, filepath, extension, data)
    Hooks:Call("BeardLibProcessScriptData", PackManager, filepath, extension, data)
    
    return data
end

function BeardLib:ReplaceScriptData(replacementPath, typ, path, extension, prevent_get, merge)
    self._replace_script_data[path:key()] = self._replace_script_data[path:key()] or {}
    if self._replace_script_data[path:key()][extension:key()] then
        BeardLib:log("[ERROR] Filepath has already been replaced, continuing with overwrite")
    end
    log(replacementPath .. "|" .. path .. "|" .. extension)
    if not DB:has(extension, path) then
        prevent_get = true
    end
    
    if prevent_get then
        BeardLib.ScriptExceptions[path:key()] = BeardLib.ScriptExceptions[path:key()] or {}
        BeardLib.ScriptExceptions[path:key()][extension:key()] = true
    end
    
    self._replace_script_data[path:key()][extension:key()] = {path = replacementPath, load_type = typ, merge = merge}
end

function BeardLib:update(t, dt)
    for _, manager in pairs(self.managers) do
        if manager.update then
            manager:update(t, dt)
        end
    end
end

function BeardLib:paused_update(t, dt)
    for _, manager in pairs(self.managers) do
        if manager.paused_update then
            manager:paused_update(t, dt)
        end
    end
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

if Hooks then
    Hooks:Register("GameSetupPauseUpdate")
    if GameSetup then
        Hooks:PostHook(GameSetup, "paused_update", "GameSetupPausedUpdateBase", function(self, t, dt)
            Hooks:Call("GameSetupPauseUpdate", t, dt)
        end)
    end
    
    Hooks:Add("MenuUpdate", "BeardLibMenuUpdate", function( t, dt )
        BeardLib:update(t, dt)
    end)

    Hooks:Add("GameSetupUpdate", "BeardLibGameSetupUpdate", function( t, dt )
        BeardLib:update(t, dt)
    end)
    
    Hooks:Add("GameSetupPauseUpdate", "BeardLibGameSetupPausedUpdate", function(t, dt)
        BeardLib:paused_update(t, dt)
    end)
    
    Hooks:Add("LocalizationManagerPostInit", "BeardLibLocalization", function(loc)
        LocalizationManager:add_localized_strings({
            ["BeardLibEnvMenu"] = "Environment Mod Menu",
            ["BeardLibEnvMenuHelp"] = "Modify the params of the current Environment",
            ["BeardLibSaveEnvTable_title"] = "Save Current modifications",
            ["BeardLibResetEnv_title"] = "Reset Values",
            ["BeardLibScriptDataMenu_title"] = "ScriptData Converter",
            ["BeardLibMainMenu"] = "BeardLib Main Menu"
        })
    end)

    Hooks:Add("MenuManagerSetupCustomMenus", "Base_SetupBeardLibMenu", function( menu_manager, nodes )
        --I'm going to leave this here, but I really don't like it being here
        --Because of GUI manager 3:
        BeardLib.managers.MapEditor = MapEditor:new()
        BeardLib.managers.Dialog = MenuDialog:new()
    
        local main_node = MenuHelperPlus:NewNode(nil, {
            name = BeardLib.MainMenu,
            menu_components =  managers.menu._is_start_menu and "player_profile menuscene_info news game_installing" or nil
        })
        
        BeardLib.managers.EnvironmentEditor:BuildNode(main_node)
        
        BeardLib.managers.ScriptDataConveter:BuildNode(main_node)
        
        managers.menu:add_back_button(main_node)
        
        MenuHelperPlus:AddButton({
            id = "BeardLibMainMenu",
            title = "BeardLibMainMenu",
            node_name = "options",
            position = managers.menu._is_start_menu and 9 or 7,
            next_node = BeardLib.MainMenu,
        })
    end)
    
    --[[Hooks:Add("MenuManagerPopulateCustomMenus", "PopulateBeardLibMenus", function(menu_manager, nodes)
        
    end)]]--
    
    Hooks:Register("BeardLibCreateCustomMenus")
    Hooks:Register("BeardLibCreateCustomNodesAndButtons")
    
    Hooks:Add( "MenuManagerInitialize", "BeardLibCreateMenuHooks", function(menu_manager) 
        Hooks:Call("BeardLibCreateCustomMenus", menu_manager)
        Hooks:Call("BeardLibMenuHelperPlusInitMenus", menu_manager)
        Hooks:Call("BeardLibCreateCustomNodesAndButtons", menu_manager)
    end)
    
    --[[Hooks:Add( "BeardLibCreateCustomMenus", "BeardLibCreateEditorMenu", function(menu_manager) 
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
    end)]]--
end

if not BeardLib.setup then
    for _, class in pairs(BeardLib.classes) do
        dofile(BeardLib.mod_path .. BeardLib.ClassDirectory .. class)
    end
    BeardLib:init()
    BeardLib.setup = true
end
