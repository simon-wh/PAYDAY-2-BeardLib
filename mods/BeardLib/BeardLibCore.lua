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
	self.AssetsDirectory = self.ModPath .. "Assets/"
    self.managers = {}
    self._replace_script_data = {}

    self.classes = {
        "ModCore.lua",
        "FrameworkBase.lua",
        "MapFramework.lua",
        "AddFramework.lua",
        "Definitions.lua",
        "MenuUI.lua",
        "MenuDialog.lua",
        "MenuItems/Menu.lua",
        "MenuItems/TextBoxBase.lua",
        "MenuItems/Item.lua",
		"MenuItems/KeyBind.lua",  
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
        ["lib/managers/killzonemanager"] = "Killzonemanager.lua",
        ["lib/managers/gameplaycentralmanager"] = "GamePlayCentralManager.lua",
        ["lib/managers/killzonemanager"] = "Killzonemanager.lua",
        ["lib/managers/trademanager"] = "TradeManager.lua",
        ["lib/managers/missionmanager"] = "MissionManager.lua",
        ["lib/managers/menumanager"] = "MenuManager.lua",
        ["lib/managers/weaponfactorymanager"] = "WeaponFactoryManager.lua",
        ["lib/managers/dialogs/keyboardinputdialog"] = "KeyboardInputDialog.lua",
        ["core/lib/utils/dev/editor/coreworlddefinition"] = "CoreWorldDefinition.lua",
        ["core/lib/system/coresystem"] = "CoreSystem.lua",
        ["lib/tweak_data/enveffecttweakdata"] = "TweakData.lua",
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

function BeardLib:LoadAsset(ext_ids, path_ids)
    if not managers.dyn_resource:has_resource(ext_ids, path_ids, managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
        self:log("loaded file %s.%s", path_ids:key(), ext_ids:key())
        managers.dyn_resource:load(ext_ids, path_ids, managers.dyn_resource.DYN_RESOURCES_PACKAGE)
    end
end

local add_file = "add.xml"

function BeardLib:LoadModOverrideFolder(directory)
    local add_file_path = BeardLib.Utils.Path:Combine(directory, add_file)
    if io.file_is_readable(add_file_path) then
        local file = io.open(add_file_path, "r")
        local config = ScriptSerializer:from_custom_xml(file:read("*all"))
        self:LoadAddConfig(directory, config)
    end
end

function BeardLib:LoadAddConfig(directory, config)
    for i, child in ipairs(config) do
        if type(child) == "table" then
            local typ = child._meta
            local path = child.path
            if typ and path then
                path = self.Utils.Path:Normalize(path)
                local ext_ids = Idstring(typ)
                local path_ids = Idstring(path)
                local file_path = BeardLib.Utils.Path:Combine(directory, path) ..".".. typ
                if SystemFS:exists(file_path) then
                    if (not DB:has(ext_ids, path_ids) or child.force) then
                        if typ == "unit" then
                            Global.added_units[tostring(path_ids:key())] = true
                        end
                        --[[if string.find(path, "husk") then
                            child.load = true
                        end]]

                        --self:log("Added file %s %s", path, typ)
                        DB:create_entry(ext_ids, path_ids, file_path)
                        if child.reload then
                            PackageManager:reload(ext_ids, path_ids)
                        end
                        if child.load then
                            table.insert(self._files_to_load, {ext_ids, path_ids})
                        end
                    end
                else
                    self:log("[ERROR] File does not exist! %s", file_path)
                end
            else
                self:log("[ERROR] Node in %s does not contain a definition for both type and path", add_file_path)
            end
        end
    end
    if managers.dyn_resource then
        while #BeardLib._files_to_load > 0 do
            local ext_ids, path_ids = unpack(table.remove(BeardLib._files_to_load))
            BeardLib:LoadAsset(ext_ids, path_ids)
        end
    end
end


function BeardLib:UnloadAddConfig(config)
    self:log("Unloading added files")
    for i, child in ipairs(config) do
        if type(child) == "table" then
            local typ = child._meta
            local path = child.path
            if typ and path then
                path = self.Utils.Path:Normalize(path)
                local ext_ids = Idstring(typ)
                local path_ids = Idstring(path)
                if DB:has(ext_ids, path_ids) then
                    if typ == "unit" then
                        Global.added_units[tostring(path_ids:key())] = nil
                    end
                    if child.unload ~= false then
                        if managers.dyn_resource:has_resource(ext_ids, path_ids, managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
                            managers.dyn_resource:unload(ext_ids, path_ids, managers.dyn_resource.DYN_RESOURCES_PACKAGE)
                        end
                    end
                    --self:log("Unloaded %s %s", path, typ)
                    DB:remove_entry(ext_ids, path_ids)
                end
            else
                self:log("[ERROR] Node in %s does not contain a definition for both type and path", add_file_path)
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

function BeardLib:log(str, ...)
    log("[BeardLib] " .. string.format(str, ...))
end

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
end

function BeardLib:ReplaceScriptData(replacement, replacement_type, target_path, target_ext, options)
    if options ~= nil and type(options) ~= "table" then
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
    table.insert(self._replace_script_data[target_ext:key()][target_path:key()], {path = replacement, load_type = replacement_type, options = options})
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
