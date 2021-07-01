dofile(Path:Combine(BeardLib.config.classes_dir, "UI/MenuItemColorButton.lua"))
local orig_MenuCallbackHandler_start_job = MenuCallbackHandler.start_job

local sync_game_settings_id = "BeardLib_sync_game_settings"
local SyncUtils = BeardLib.Utils.Sync
local MenuUIManager = BeardLib.Managers.MenuUI
local DialogManager = BeardLib.Managers.Dialog

local o_toggle_menu_state = MenuManager.toggle_menu_state
function MenuManager:toggle_menu_state(...)
    if DialogManager:DialogOpened() then
        DialogManager:CloseLastDialog()
        return
    end
    if not MenuUIManager:InputAllowed() then
        return
    end
    return o_toggle_menu_state(self, ...)
end

local o_refresh = MenuManager.refresh_level_select
function MenuManager.refresh_level_select(...)
    if Global.game_settings.level_id then
        return o_refresh(...)
    else
        BeardLib:log("[Warning] Refresh level select was called while level id was nil!")
    end
end

local o_resume_game = MenuCallbackHandler.resume_game
function MenuCallbackHandler:resume_game(...)
    if not DialogManager:DialogOpened() then
        return o_resume_game(self, ...)
    end
end

core:import("SystemMenuManager")
Hooks:PostHook(SystemMenuManager.GenericSystemMenuManager, "event_dialog_shown", "BeardLibEventDialogShown", function(self)
    if DialogManager:DialogOpened() then
        BeardLib.IgnoreDialogOnce = true
    end
end)
Hooks:PostHook(SystemMenuManager.GenericSystemMenuManager, "event_dialog_closed", "BeardLibEventDialogClosed", function(self)
    BeardLib.IgnoreDialogOnce = false
end)

function MenuCallbackHandler:start_job(job_data)
    if not managers.job:activate_job(job_data.job_id) then
        return
    end

    if managers.job:current_level_data().custom or managers.job:current_job_data().custom then
    	Global.game_settings.level_id = managers.job:current_level_id()
    	Global.game_settings.mission = managers.job:current_mission()
    	Global.game_settings.world_setting = managers.job:current_world_setting()
    	Global.game_settings.difficulty = job_data.difficulty
        Global.game_settings.one_down = job_data.one_down
    	local matchmake_attributes = self:get_matchmake_attributes()
    	if Network:is_server() then
            SyncUtils:SyncGameSettings()
    		managers.network.matchmake:set_server_attributes(matchmake_attributes)
    		managers.menu_component:on_job_updated()
    		managers.menu:active_menu().logic:navigate_back(true)
    		managers.menu:active_menu().logic:refresh_node("lobby", true)
    	else
    		managers.network.matchmake:create_lobby(matchmake_attributes)
    	end
    else
        orig_MenuCallbackHandler_start_job(self, job_data)
    end
end

Hooks:Add("NetworkReceivedData", sync_game_settings_id, function(sender, id, data)
    if id == sync_game_settings_id then
        local split_data = string.split(data, "|")

        managers.network._handlers.connection:sync_game_settings(tweak_data.narrative:get_index_from_job_id(split_data[1]),
        tweak_data.levels:get_index_from_level_id(split_data[2]),
        tweak_data:difficulty_to_index(split_data[3]),
        Global.game_settings.one_down,
        managers.network:session():peer(sender):rpc())
    end
end)

Hooks:Add("BaseNetworkSessionOnPeerEnteredLobby", "BaseNetworkSessionOnPeerEnteredLobby_sync_game_settings", function(peer, peer_id)
    SyncUtils:SyncGameSettings(peer_id)
end)

Hooks:Add("NetworkManagerOnPeerAdded", "NetworkManagerOnPeerAdded_sync_game_settings", function(peer, peer_id)
    SyncUtils:SyncGameSettings(peer_id)
end)

QuickMenuPlus = QuickMenuPlus or class(QuickMenu)
QuickMenuPlus._menu_id_key = "quick_menu_p_id_"
QuickMenuPlus._menu_id_index = 0
function QuickMenuPlus:new( ... )
    return self:init( ... )
end

function QuickMenuPlus:init(title, text, options, dialog_merge)
    options = options or {}
    for _, opt in pairs(options) do
        if not opt.callback then
            opt.is_cancel_button = true
        end
    end
    QuickMenuPlus.super.init(self, title, text, options)
    if dialog_merge then
        table.merge(self.dialog_data, dialog_merge)
    end
    self.show = nil
    self.Show = nil
    self.visible = true
    managers.system_menu:show_custom(self.dialog_data)
    return self
end

Hooks:PostHook(MenuManager, "setup_local_lobby_character", "BeardLibExtraOutfitSetupLocalLobby", function(self)
    local local_peer = managers.network:session():local_peer()
    local_peer:set_extra_outfit_string_beardlib(SyncUtils:ExtraOutfitString())
end)

Hooks:PostHook(MenuCallbackHandler, "_update_outfit_information", "BeardLibExtraOutfitUpdateLocalOutfit", function(self)
    if managers.network:session() then
        local local_peer = managers.network:session():local_peer()
        local_peer:set_extra_outfit_string_beardlib(SyncUtils:ExtraOutfitString())
    end
end)