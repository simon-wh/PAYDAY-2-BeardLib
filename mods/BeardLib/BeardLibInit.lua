Hooks:Register("BeardLibPreProcessScriptData")
Hooks:Register("BeardLibProcessScriptData")
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

if not BeardLib.setup then
    BeardLib:init()
    BeardLib.setup = true
end
