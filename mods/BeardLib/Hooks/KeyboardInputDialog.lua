core:module("SystemMenuManager")
require("lib/managers/dialogs/GenericDialog")
KeyboardInputDialog = class(GenericDialog)

function KeyboardInputDialog:init(manager, data, is_title_outside)
    Dialog.init(self, manager, data)
    
    self._data.button_list = {
        {
            text = "ENTER"
        }
    }
    
	if not self._data.focus_button then
		if #self._button_text_list > 0 then
			self._data.focus_button = #self._button_text_list
		else
			self._data.focus_button = 1
		end
	end
	self._ws = self._data.ws or manager:_get_ws()
	self._panel_script = _G.TextBoxGui:new(self._ws, self._data.title or "", self._data.text or "", self._data, {
		type = self._data.type or "system_menu",
		no_close_legend = true,
		use_indicator = data.indicator,
		is_title_outside = is_title_outside,
        forced_h = 100,
        bottom = true
	})
    
    self._caret = self._panel_script._panel:child("info_area"):child("scroll_panel"):rect({
		name = "caret",
		layer = 2,
		x = 0,
		y = 0,
		w = 0,
		h = 0,
		color = Color.white
	})
    local text = self._panel_script._panel:child("info_area"):child("scroll_panel"):child("text")
    local e = utf8.len(text:text())
	text:set_selection(e, e)
    
	self._panel_script:add_background()
	self._panel_script:set_layer(_G.tweak_data.gui.DIALOG_LAYER)
	self._panel_script:set_centered()
	self._panel_script:set_fade(0)
	self._controller = self._data.controller or manager:_get_controller()
	self._confirm_func = callback(self, self, "button_pressed_callback")
	self._cancel_func = callback(self, self, "dialog_cancel_callback")
	self._resolution_changed_callback = callback(self, self, "resolution_changed_callback")
	managers.viewport:add_resolution_changed_func(self._resolution_changed_callback)
	if data.counter then
		self._counter = data.counter
		self._counter_time = self._counter[1]
	end
    
    self._ws:connect_keyboard(Input:keyboard())
	self._panel_script._panel:enter_text(callback(self, self, "enter_text"))
	self._panel_script._panel:key_press(callback(self, self, "key_press"))
	self._panel_script._panel:key_release(callback(self, self, "key_release"))
    self._last_backspace_tick = 0
    self._backspace_pressed_num = 0
    
    self:update_caret()
end

function KeyboardInputDialog:blink(o)
	while true do
		o:set_color(Color(0, 1, 1, 1))
		wait(0.3)
		o:set_color(Color.white)
		wait(0.3)
	end
end
function KeyboardInputDialog:set_blinking(b)
	if b == self._blinking then
		return
	end
	if b then
		self._caret:animate(callback(self, self, "blink"))
	else
		self._caret:stop()
	end
	self._blinking = b
	if not self._blinking then
		self._caret:set_color(Color.white)
	end
end
function KeyboardInputDialog:update_caret()
	local text = self._panel_script._panel:child("info_area"):child("scroll_panel"):child("text")
	local s, e = text:selection()
	local x, y, w, h = text:selection_rect()
	if s == 0 and e == 0 then
		if text:align() == "center" then
			x = text:world_x() + text:w() / 2
		else
			x = text:world_x()
		end
		y = text:world_y()
	end
	h = text:h()
	if w < 3 then
		w = 3
	end
	self._caret:set_world_shape(x, y + 2, w, h - 4)
	self:set_blinking(true)
end

function KeyboardInputDialog:enter_text(o, s)
    if self:filter() == "number" and tonumber(s) == nil and s ~= "." then
        return
    end

    if #self._data.text == self:max_count() then
        return
    end
    
    local text = self._panel_script._panel:child("info_area"):child("scroll_panel"):child("text")
    text:replace_text(s)
    local lbs = text:line_breaks()
	if #lbs > 1 then
		local s = lbs[2]
		local e = utf8.len(text:text())
		text:set_selection(s, e)
		text:replace_text("")
	end
    self:update_caret()
end

function KeyboardInputDialog:key_press(o, k)
    local text = self._panel_script._panel:child("info_area"):child("scroll_panel"):child("text")
    local s, e = text:selection()
    local n = utf8.len(text:text())
    if k == Idstring("backspace") then
        self._backspace_pressed = true
    elseif k == Idstring("left") then
		if s < e then
			text:set_selection(s, s)
		elseif s > 0 then
			text:set_selection(s - 1, s - 1)
		end
	elseif k == Idstring("right") then
		if s < e then
			text:set_selection(e, e)
		elseif s < n then
			text:set_selection(s + 1, s + 1)
		end
    end
    self:update_caret()
end

function KeyboardInputDialog:key_release(o, k)
    if k == Idstring("backspace") then
        self._backspace_pressed = false
        self._backspace_pressed_num = 0
    end
end

function KeyboardInputDialog:update(t, dt)
    self.super.update(self, t, dt)
    if self._backspace_pressed and t - self._last_backspace_tick > (self._backspace_pressed_num == 0 and 0 or (0.7 / self._backspace_pressed_num)) then
        local text = self._panel_script._panel:child("info_area"):child("scroll_panel"):child("text")
        local s, e = text:selection()
        if s == e and s > 0 then
            text:set_selection(s - 1, e)
        end
        text:replace_text("")
        self._last_backspace_tick = t
        self._backspace_pressed_num = self._backspace_pressed_num + 1
        
        self:update_caret()
    end
end

function KeyboardInputDialog:set_text(text, no_upper)
	self._panel_script:set_text(text, no_upper)
end

function KeyboardInputDialog:title()
	return self._data.title or ""
end
function KeyboardInputDialog:text()
	return self._data.text or ""
end
function KeyboardInputDialog:input_text()
	return self._data.input_text
end
function KeyboardInputDialog:input_type()
	return self._data.input_type or "default"
end
function KeyboardInputDialog:max_count()
	return self._data.max_count
end
function KeyboardInputDialog:filter()
	return self._data.filter
end

function KeyboardInputDialog:button_pressed_callback()
	if self._data.no_buttons then
		return
	end
	self:remove_mouse()
	self:button_pressed(self._panel_script:get_focus_button(), true)
end

function KeyboardInputDialog:button_pressed(button_index, success)
	cat_print("dialog_manager", "[SystemMenuManager] Button index pressed: " .. tostring(button_index))
	local button_list = self._data.button_list
	self:fade_out_close()
	if button_list then
		local button = button_list[button_index]
		if button and button.callback_func then
			button.callback_func(button_index, button)
		end
	end
	local callback_func = self._data.callback_func
	if callback_func then
		callback_func(success, self:text())
	end
end

function KeyboardInputDialog:dialog_cancel_callback()
	if #self._data.button_list == 1 then
		self:remove_mouse()
		self:button_pressed(1, false)
	end
	for i, btn in ipairs(self._data.button_list) do
		if btn.cancel_button then
			self:remove_mouse()
			self:button_pressed(i, false)
			return
		end
	end
end

function KeyboardInputDialog:to_string()
	return string.format("%s, Title: %s, Text: %s, Input text: %s, Max count: %s, Filter: %s", tostring(BaseDialog.to_string(self)), tostring(self._data.title), tostring(self._data.text), tostring(self._data.input_text), tostring(self._data.max_count), tostring(self._data.filter))
end
