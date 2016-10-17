if not _G.BeardLib then
    _G.BeardLib = {}

    local self = BeardLib
    self.Name = "BeardLib"
    self.ModPath = ModPath
    self.SavePath = SavePath
    self.sequence_mods = self.sequence_mods or {}
    self.MainMenu = "BeardLibMainMenu"
    self.MapsPath = "Maps"
    self.ScriptExceptions = self.ScriptExceptions or {}
    self.HooksDirectory = self.ModPath .. "Hooks/"
    self.ModulesDirectory = self.ModPath .. "Modules/"
    self.ClassDirectory = self.ModPath .. "Classes/"
    self.managers = {}
    self._replace_script_data = {}

    self.classes = {
        "ModCore.lua",
        "CustomPackageManager.lua",
        --"CustomDLCManager.lua",
        "CustomAchievementManager.lua",
        "TweakDataHelper.lua",
        "ModManager.lua",
        "FileManager.lua",
        "FrameworkBase.lua",
        "MapFramework.lua",
        "AddFramework.lua",
        "Definitions.lua",
        "MenuUI.lua",
        "MenuDialog.lua",
        "MenuItems/Menu.lua",
        "MenuItems/TextBoxBase.lua",
        "MenuItems/Item.lua",
        "MenuItems/ItemsGroup.lua",
        "MenuItems/ImageButton.lua",
        "MenuItems/Toggle.lua",
        "MenuItems/ComboBox.lua",
        "MenuItems/Slider.lua",
        "MenuItems/TextBox.lua",
        "MenuItems/ContextMenu.lua",
        "MenuHelperPlus.lua",
        "json_utils.lua",
        "utils.lua",
        "ModAssetUpdateManager.lua",
        "ModuleBase.lua"
    }

    self.hook_files = {
        ["core/lib/managers/coresequencemanager"] = "CoreSequenceManager.lua",
        ["lib/managers/menu/menuinput"] = "MenuInput.lua",
        ["lib/managers/menu/textboxgui"] = "TextBoxGUI.lua",
        ["lib/managers/systemmenumanager"] = "SystemMenuManager.lua",
        ["lib/managers/achievmentmanager"] = "AchievementManager.lua",
        ["lib/managers/killzonemanager"] = "KillzoneManager.lua",
        ["lib/managers/gameplaycentralmanager"] = "GamePlayCentralManager.lua",
        ["lib/managers/trademanager"] = "TradeManager.lua",
        ["lib/managers/missionmanager"] = "MissionManager.lua",
        ["lib/managers/menumanager"] = "MenuManager.lua",
        ["lib/managers/weaponfactorymanager"] = "WeaponFactoryManager.lua",
        ["lib/managers/dialogs/keyboardinputdialog"] = "KeyboardInputDialog.lua",
        ["core/lib/utils/dev/editor/coreworlddefinition"] = "CoreWorldDefinition.lua",
        ["core/lib/system/coresystem"] = "CoreSystem.lua",
        ["lib/tweak_data/enveffecttweakdata"] = "PreTweakData.lua",
        ["lib/tweak_data/tweakdata"] = "TweakData.lua",
        ["lib/network/matchmaking/networkmatchmakingsteam"] = "NetworkMatchmakingSteam.lua",
        ["lib/network/base/networkpeer"] = "NetworkPeer.lua",
        ["lib/network/base/clientnetworksession"] = "ClientNetworkSession.lua",
        ["lib/units/beings/player/playermovement"] = "PlayerMovement.lua",
        ["lib/units/beings/player/huskplayermovement"] = "HuskPlayerMovement.lua",
        ["lib/units/beings/player/playerinventory"] = "PlayerInventory.lua",
        ["lib/setups/setup"] = "Setup.lua"
        --["core/lib/managers/viewport/environment/coreenvironmentmanager"] = "CoreEnvironmentManager.lua"
    }
    self.custom_mission_elements = {
        "MoveUnit",
        "TeleportPlayer",
        "Environment"
    }
    self.modules = {}
    self._mod_lootdrop_items = {}
    self._mod_upgrade_items = {}
    Global.added_units = Global.added_units or {}
    self._files_to_load = {}
    self._custom_packages = {}
    self._updaters = {}
    self._paused_updaters = {}
    Global.custom_loaded_packages = Global.custom_loaded_packages or {}
end

function BeardLib:init()
    self:LoadClasses()
    self:LoadModules()

    if not file.DirectoryExists(self.MapsPath) then
        os.execute("mkdir " .. self.MapsPath)
    end

    LocalizationModule:new(self, {
        directory = "Localization",
        {
            _meta = "localization",
            file = "english.txt",
            language = "english"
        }
    })
    self.managers.asset_update = ModAssetUpdateManager:new()
    self.managers.MapFramework = MapFramework:new()
    self.managers.AddFramework = AddFramework:new()
    self.managers.File = FileManager
    --Load mod_overrides adds
    self:LoadModOverridePlus()
end

function BeardLib:AddUpadter(id, clbk, pasued)
    self._updaters[id] = clbk 
    if paused then
        self._paused_updaters[id] = clbk 
    end
end

function BeardLib:RemoveUpadter(id)
    self._updaters[id] = nil
    self._paused_updaters[id] = nil
end

function BeardLib:LoadClasses()
    for _, clss in pairs(self.classes) do
        dofile(self.ClassDirectory .. clss)
    end
end

function BeardLib:RegisterModule(key, module)
    if not self.modules[key] then
        self:log("Registered module with key %s", key)
        self.modules[key] = module
    else
        self:log("[ERROR] Module with key %s already exists", key or "")
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
    if not SystemFS then
        return
    end

    local mods = file.GetDirectories(self.definitions.mod_override)
    if mods then
        for _, path in pairs(mods) do
            self:LoadModOverrideFolder(BeardLib.Utils.Path:Combine(self.definitions.mod_override, path))
        end
    end
end

local add_file = "add.xml"

function BeardLib:LoadModOverrideFolder(directory)
    local add_file_path = BeardLib.Utils.Path:Combine(directory, add_file)
    if io.file_is_readable(add_file_path) then
        local file = io.open(add_file_path, "r")
        local config = ScriptSerializer:from_custom_xml(file:read("*all"))
        CustomPackageManager:LoadPackageConfig(directory, config)
    end
end


if RequiredScript then
    local requiredScript = RequiredScript:lower()
    if BeardLib.hook_files[requiredScript] then
        dofile( BeardLib.HooksDirectory .. BeardLib.hook_files[requiredScript] )
    end
end

function BeardLib:log(str, ...)
    log("[BeardLib] " .. string.format(str, ...))
end

--[[Hooks:Register("BeardLibPreProcessScriptData")
Hooks:Register("BeardLibProcessScriptData")
function BeardLib:ProcessScriptData(PackManager, path, ext, data)
    if ext == Idstring("menu") then
        if MenuHelperPlus and MenuHelperPlus:GetMenuDataFromHashedFilepath(path:key()) then
            data = MenuHelperPlus:GetMenuDataFromHashedFilepath(path:key())
        end
    end

    if self._replace_script_data[ext:key()] and self._replace_script_data[ext:key()][path:key()] then
        for _, replacement in pairs(self._replace_script_data[ext:key()][path:key()]) do

            if not replacement.options.use_clbk or replacement.options.use_clbk() then
                --self:log("Replace: " .. tostring(path:key()))

                local fileType = replacement.load_type
                local file = io.open(replacement.path, fileType == "binary" and "rb" or 'r')

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

                    if ext == Idstring("nav_data") then
                        self.Utils:RemoveMetas(new_data)
                    elseif (ext == Idstring("continents") or ext == Idstring("mission")) and fileType=="custom_xml" then
                        self.Utils:RemoveAllNumberIndexes(new_data, true)
                    end

                    if new_data then
                        if replacement.options.merge_mode then
                            if replacement.options.merge_mode == "merge" then
                                table.merge(data, new_data)
                            elseif replacement.options.merge_mode == "script_merge" then
                                table.script_merge(data, new_data)
                            elseif replacement.options.merge_mode == "add" then
                                table.add(data, new_data)
                            end
                        else
                            data = new_data
                        end
                    end
                    file:close()
                end
            end
        end
    end

    Hooks:Call("BeardLibPreProcessScriptData", PackManager, path, ext, data)
    Hooks:Call("BeardLibProcessScriptData", PackManager, path, ext, data)

    return data
end]]

function BeardLib:ReplaceScriptData(replacement, replacement_type, target_path, target_ext, options)
    options = options or {}
    FileManager:ScriptReplaceFile(target_ext, target_path, replacement, table.merge(options, { type = replacement_type, mode = options.merge_mode }))
    --[[if options ~= nil and type(options) ~= "table" then
        self:log("[ERROR] %s:ReplaceScriptData parameter 5, expected table, got %s", self.Name, tostring(type(extra_data)))
        return
    end
    if not io.file_is_readable(replacement) then
        self:log("[ERROR] Lua state is unable to read file '%s'!", replacement)
        return
    end

    options = options or {}
    self._replace_script_data[target_ext:key()] = self._replace_script_data[target_ext:key()] or {}
    self._replace_script_data[target_ext:key()][target_path:key()] = self._replace_script_data[target_ext:key()][target_path:key()] or {}
    table.insert(self._replace_script_data[target_ext:key()][target_path:key()], {path = replacement, load_type = replacement_type, options = options})]]--
end

function BeardLib:update(t, dt)
    for _, manager in pairs(self.managers) do
        if manager.update then
            manager:update(t, dt)
        end
    end
    for _, clbk in pairs(self._updaters) do
        clbk()
    end
end

function BeardLib:paused_update(t, dt)
    for _, manager in pairs(self.managers) do
        if manager.paused_update then
            manager:paused_update(t, dt)
        end
    end
    for _, clbk in pairs(self._paused_updaters) do
        clbk()
    end
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
