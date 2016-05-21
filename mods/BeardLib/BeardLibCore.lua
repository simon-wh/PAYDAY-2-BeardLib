if not _G.BeardLib then
    _G.BeardLib = {}

    local self = BeardLib

    self.ModPath = ModPath
    self.SavePath = SavePath
    self.sequence_mods = self.sequence_mods or {}
    self.MainMenu = "BeardLibMainMenu"
    self.MapsPath = "BeardLibMaps"
    self.CurrentViewportNo = 0
    self.ScriptExceptions = self.ScriptExceptions or {}
    self.HooksDirectory = self.ModPath .. "Hooks/"
    self.ModulesDirectory = self.ModPath .. "Modules/"
    self.ClassDirectory = self.ModPath .. "Classes/"
    self.managers = {}
    self._replace_script_data = {}

    self.classes = {
        "Definitions.lua",
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
        "MenuItems/ItemsGroup.lua",
        "MenuHelperPlus.lua",
        "UnitPropertiesItem.lua",
        "json_utils.lua",
        "utils.lua",
        "ModCore.lua",
        "ModuleBase.lua"
    }

    self.hook_files = {
        ["core/lib/managers/coresequencemanager"] = "CoreSequenceManager.lua",
        ["lib/managers/menu/menuinput"] = "MenuInput.lua",
        ["lib/managers/menu/textboxgui"] = "TextBoxGUI.lua",
        ["lib/managers/systemmenumanager"] = "SystemMenuManager.lua",
        ["lib/managers/dialogs/keyboardinputdialog"] = "KeyboardInputDialog.lua",
        ["core/lib/managers/viewport/corescriptviewport"] = "CoreScriptViewport.lua",
        ["core/lib/system/coresystem"] = "CoreSystem.lua"
        --["core/lib/managers/viewport/environment/coreenvironmentmanager"] = "CoreEnvironmentManager.lua"
    }
end

function BeardLib:init()
    self:LoadClasses()
    self:LoadModules()

    if not file.DirectoryExists(self.MapsPath) then
        os.execute("mkdir " .. self.MapsPath)
    end

    --Load ScriptData mod_overrides
    self:LoadModOverridePlus()
end

function BeardLib:LoadClasses()
    for _, clss in pairs(self.classes) do
        dofile(self.ClassDirectory .. clss)
    end
end

function BeardLib:LoadModules()
    local modules = file.GetFiles(self.ModulesDirectory)
    if modules then
        for _, mdle in pairs(modules) do
            dofile(self.ModulesDirectory .. mdle)
        end
    end
end

function BeardLib:LoadModOverridePlus()
    local mods = file.GetDirectories("assets/mod_overrides/")
    if mods then
        for _, path in pairs(mods) do
            self:LoadModOverrideFolder("assets/mod_overrides/" .. path .. "/", "")
        end
    end
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

if RequiredScript then
    local requiredScript = RequiredScript:lower()
    if BeardLib.hook_files[requiredScript] then
        dofile( BeardLib.HooksDirectory .. BeardLib.hook_files[requiredScript] )
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
        self:log("Replace: " .. tostring(filepath:key()))

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
            ["BeardLibMainMenu"] = "BeardLib Main Menu"
        })
    end)

    Hooks:Add("MenuManagerSetupCustomMenus", "Base_SetupBeardLibMenu", function( menu_manager, nodes )
        local main_node = MenuHelperPlus:NewNode(nil, {
            name = BeardLib.MainMenu,
            menu_components =  managers.menu._is_start_menu and "player_profile menuscene_info news game_installing" or nil
        })

        managers.menu:add_back_button(main_node)

        MenuHelperPlus:AddButton({
            id = "BeardLibMainMenu",
            title = "BeardLibMainMenu",
            node_name = "options",
            position = managers.menu._is_start_menu and 9 or 7,
            next_node = BeardLib.MainMenu,
        })
    end)

    Hooks:Register("BeardLibCreateCustomMenus")
    Hooks:Register("BeardLibCreateCustomNodesAndButtons")

    Hooks:Add( "MenuManagerInitialize", "BeardLibCreateMenuHooks", function(menu_manager)
        Hooks:Call("BeardLibCreateCustomMenus", menu_manager)
        Hooks:Call("BeardLibMenuHelperPlusInitMenus", menu_manager)
        Hooks:Call("BeardLibCreateCustomNodesAndButtons", menu_manager)
    end)
end

if not BeardLib.setup then
    BeardLib:init()
    BeardLib.setup = true
end
