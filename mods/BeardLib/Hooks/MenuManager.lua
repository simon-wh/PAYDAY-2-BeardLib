local o_toggle_menu_state = MenuManager.toggle_menu_state
function MenuManager:toggle_menu_state(...)
    if BeardLib.DialogOpened then
        BeardLib.DialogOpened:hide()
        BeardLib.DialogOpened = nil
        return
    else
        return o_toggle_menu_state(self, ...) 
    end
end