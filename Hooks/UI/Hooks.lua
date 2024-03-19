local F = table.remove(RequiredScript:split("/"))
local Hooks = Hooks

if F == "menumanager" then
    dofile(Path:Combine(BeardLib.config.classes_dir, "UI/MenuItemColorButton.lua"))
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
----------------------------------------------------------------
elseif F == "systemmenumanager" then
    core:module("SystemMenuManager")
    GenericSystemMenuManager = GenericSystemMenuManager or SystemMenuManager.GenericSystemMenuManager

    function GenericSystemMenuManager:show_custom(data)
        if _G.setup and _G.setup:has_queued_exec() then
            return
        end
        local success = self:_show_class(data, BeardLibGenericDialog, BeardLibGenericDialog, data.force)
        self:_show_result(success, data)
    end

    BeardLibGenericDialog = BeardLibGenericDialog or class(GenericDialog)
    function BeardLibGenericDialog:init(manager, data, is_title_outside)
        Dialog.init(self, manager, data)
        if not self._data.focus_button then
            if #self._button_text_list > 0 then
                self._data.focus_button = #self._button_text_list
            else
                self._data.focus_button = 1
            end
        end
        self._ws = self._data.ws or manager:_get_ws()
        self._panel_script = _G[self.PANEL_SCRIPT_CLASS]:new(self._ws, self._data.title or "", self._data.text or "", self._data, {
            type = self._data.type or "system_menu",
            no_close_legend = true,
            use_indicator = data.indicator or data.no_buttons,
            is_title_outside = is_title_outside
        })
        self._panel_script:set_layer(_G.tweak_data.gui.DIALOG_LAYER)
        self._panel_script:set_centered()
        if data.position_func then
            data.position_func(self._panel_script._panel, self._panel_script._ws:panel())
        end
        if not data.no_background then
            self._panel_script:add_background()
        end
        self._panel_script:set_fade(0)
        self._controller = self._data.controller or manager:_get_controller()
        local ClassClbk = _G.ClassClbk
        self._confirm_func = ClassClbk(self, "button_pressed_callback")
        self._cancel_func = ClassClbk(self, "dialog_cancel_callback")
        self._resolution_changed_callback = ClassClbk(self, "resolution_changed_callback")
        managers.viewport:add_resolution_changed_func(self._resolution_changed_callback)
        if data.counter then
            self._counter = data.counter
            self._counter_time = self._counter[1]
        end
    end
----------------------------------------------------------------
end