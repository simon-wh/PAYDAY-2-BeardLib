Hooks:Register("BeardLibCreateCustomNodesAndButtons")
Hooks:Register("BeardLibPreProcessScriptData")
Hooks:Register("BeardLibProcessScriptData")
Hooks:Register("BeardLibCreateCustomMenus")
Hooks:Register("GameSetupPauseUpdate")
Hooks:Register("SetupInitManagers")

if GameSetup then
    Hooks:PostHook(GameSetup, "paused_update", "GameSetupPausedUpdateBase", function(self, t, dt)
        Hooks:Call("GameSetupPauseUpdate", t, dt)
    end)
end

Hooks:Add("GameSetupPauseUpdate", "BeardLibGameSetupPausedUpdate", callback(BeardLib, BeardLib, "PausedUpdate"))
Hooks:Add("GameSetupUpdate", "BeardLibGameSetupUpdate", callback(BeardLib, BeardLib, "Update"))
Hooks:Add("MenuUpdate", "BeardLibMenuUpdate", callback(BeardLib, BeardLib, "Update"))

Hooks:Add("MenuManagerInitialize", "BeardLibCreateMenuHooks", function(menu_manager)
    managers.menu = managers.menu or menu_manager
    BeardLib.managers.dialog:Init()
    Hooks:Call("BeardLibCreateCustomMenus", menu_manager)
    Hooks:Call("BeardLibMenuHelperPlusInitMenus", menu_manager)
    Hooks:Call("BeardLibCreateCustomNodesAndButtons", menu_manager)
end)

if not BeardLib.Setup then
    BeardLib:Init()
    BeardLib.Setup = true
end