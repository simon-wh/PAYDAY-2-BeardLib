MenuUIManager = MenuUIManager or BeardLib:CreateManager("menu_ui")

function MenuUIManager:init()
    self._menus = {}
end

function MenuUIManager:AddMenu(menu)
    table.insert(self._menus, menu)
end

function MenuUIManager:RemoveMenu(menu)
    table.delete(self._menus, menu)
end

function MenuUIManager:Menus()
    return self._menus
end

function MenuUIManager:GetActiveMenu()
    local mc = managers.mouse_pointer._mouse_callbacks
    local last = mc[#mc]
    if last and last.menu_ui_object then
        return last.menu_ui_object
    end
    return nil
end

function MenuUIManager:DisableInput()
	self._input_disabled = true
end

function MenuUIManager:EnableInput()
    self._input_disabled = nil
	self._enable_input_t = nil
end

function MenuUIManager:EnableINput()
    return not self._input_disabled
end

function MenuUIManager:InputDisabled()
    return self._input_disabled
end

function MenuUIManager:InputAllowed(...)
    if self:input_disabled() then
        return false
    end
    local menu = self:get_active_menu()
    return not menu or menu.allow_full_input == true
end

function MenuUIManager:CloseMenuEvent()
	self:disable_input()
	self._enable_input_t = Application:time() + 0.01
end

function MenuUIManager:Update(t, dt)
	if self._input_disabled and self._enable_input_t and self._enable_input_t <= t then
        self:enable_input()
    end
end

--Part of making BeardLib a little more consistent. Function names are PascalCase.
MenuUIManager.add_menu = MenuUIManager.AddMenu
MenuUIManager.remove_menu = MenuUIManager.RemoveMenu
MenuUIManager.get_active_menu = MenuUIManager.GetActiveMenu
MenuUIManager.disable_input = MenuUIManager.DisableInput
MenuUIManager.enable_input = MenuUIManager.EnableINput
MenuUIManager.input_enabled = MenuUIManager.InputEnabled
MenuUIManager.input_disabled = MenuUIManager.InputDisabled
MenuUIManager.input_allowed = MenuUIManager.InputAllowed
MenuUIManager.close_menu_event = MenuUIManager.CloseMenuEvent