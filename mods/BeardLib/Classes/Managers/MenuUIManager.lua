MenuUIManager = MenuUIManager or class()
local Manager = MenuUIManager

function Manager:init()
    self._menus = {}
end

function Manager:add_menu(menu)
    table.insert(self._menus, menu)
end

function Manager:remove_menu(menu)
    table.delete(self._menus, menu)
end

function Manager:get_active_menu()
    local mc = managers.mouse_pointer._mouse_callbacks
    local last = mc[#mc]
    if last and last.menu_ui_object then
        return last.menu_ui_object
    end
    return nil
end

function Manager:disable_input()
	self._input_disabled = true
end

function Manager:enable_input()
    self._input_disabled = nil
	self._enable_input_t = nil
end

function Manager:input_enabled()
    return not self._input_disabled
end

function Manager:input_disabled()
    return self._input_disabled
end

function Manager:input_allowed(...)
    if self:input_disabled() then
        return false
    end
    local menu = self:get_active_menu()
    return not menu or menu.allow_full_input == true
end

function Manager:close_menu_event()
	self:disable_input()
	self._enable_input_t = Application:time() + 0.01
end

function Manager:Update(t, dt)
	if self._input_disabled and self._enable_input_t and self._enable_input_t <= t then
        self:enable_input()
    end
end

BeardLib:RegisterManager("menu_ui", Manager)