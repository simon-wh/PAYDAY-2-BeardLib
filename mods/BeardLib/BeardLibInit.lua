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

Hooks:Add("MenuManagerSetupCustomMenus", "Base_SetupBeardLibMenu", function(menu_manager, nodes)
    managers.menu = managers.menu or menu_manager
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
