MenuItemColorButton = MenuItemColorButton or class(MenuItemInput)
MenuItemColorButton.TYPE = "color_button"
MenuItemColorButton.trigger = CoreMenuItem.Item.trigger

function MenuItemColorButton:init(...)
    MenuItemColorButton.super.init(self, ...)
    self._type = "color_button"
    self._input_limit = 8 --AARRGGBB
end

function MenuItemColorButton:set_value(value)
    local t = type_name(value)
    if t == "Color" then
        value = value:to_hex()
    end
    t = type_name(value)
    if t == "string" then
        self:set_input_text(value)
    else
        self:set_input_text("ffffff")
    end
    self:update_color_preview()
    self:dirty()
end

function MenuItemColorButton:value(value)
    return Color:from_hex(self:input_text())
end

function MenuItemColorButton:setup_gui(node, row_item)
    MenuItemColorButton.super.setup_gui(self, node, row_item)
    self._color_preview = row_item.gui_panel:rect({name = "color_preview", layer = node.layers.items})
    self._panel = row_item.gui_panel
    self._text = row_item.gui_text
    self._caret = row_item.caret
    self._caret:set_blend_mode("normal")
    row_item.input_bg:hide()
    self:_update_caret()
    return true
end

function MenuItemColorButton:set_editing(set)
    self:_set_enabled(set)
end

function MenuItemColorButton:_set_enabled(enabled)
	if not self:enabled() then
		return
	end
    self._editing = enabled
    managers.menu:active_menu().input:set_back_enabled(not enabled)
    managers.menu:active_menu().input:accept_input(not enabled)
    if not enabled then
        managers.menu:active_menu().input._current_input_item = nil
    end
    if alive(self._text) then
        self._text:set_selection(self._text:text():len())
    end

    self:_update_caret()
end

function MenuItemColorButton:_layout(row_item)
    MenuItemColorButton.super._layout(self, row_item)
    if alive(self._color_preview) then
        local s = self._panel:h() - 4
        self._color_preview:set_size(s, s)
        self._color_preview:set_center_y(self._panel:h() / 2)
    end
    self:update_color_preview()
    return true
end

local KB = BeardLib.Utils.Input
function MenuItemColorButton:update_key_down(row_item, o, k)
    if not row_item or not alive(row_item.gui_text) then
		return
    end

    local first
    local text = row_item.gui_text
  	while self._key_pressed == k do
		local s, e = text:selection()
		local t = text:text()
		local n = utf8.len(t)
		if ctrl() then
	    	if KB:Down("a") then
	    		text:set_selection(0, text:text():len())
	    	elseif Input:keyboard():down(Idstring("c")) then
	    		Application:set_clipboard(tostring(text:selected_text()))
	    	elseif KB:Down("v") then
	    		if (self.filter == "number" and tonumber(Application:get_clipboard()) == nil) then
	    			return
				end
				self._before_text = t
                text:replace_text(tostring(Application:get_clipboard()))
                text:set_text(text:text():sub(1, self._input_limit))
                self:check_changed()
			elseif shift() then
                if KB:Down(Idstring("left")) then text:set_selection(s - 1, e)
                elseif KB:Down(Idstring("right")) then text:set_selection(s, e + 1) end
			elseif KB:Down("z") and self._before_text then
				local before_text = self._before_text
				self._before_text = t
                text:set_text(before_text)
                self:check_changed()
	    	end
	    elseif shift() then
	  	    if KB:Down("left") then
				text:set_selection(s - 1, e)
			elseif KB:Down("right") then
				text:set_selection(s, e + 1)
			end
	    elseif self._key_pressed == Idstring("backspace") or self._key_pressed == Idstring("delete") then
			if s == e and s > 0 then
				text:set_selection(s - 1, e)
			end

			if not (utf8.len(t) < 1) or type(self._esc_callback) ~= "number" then
                text:replace_text("")
                self:check_changed()
			end
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
		else
			self._key_pressed = nil
	    end
		self:_update_caret()
        if not first then
            first = true
            wait(0.5)
        end
	    wait(0.01)
  	end
end

function MenuItemColorButton:update_color_preview(row_item)
    if alive(self._color_preview) then
        self._color_preview:set_color(Color:from_hex(self._text:text()))
        self._text:set_x(self._color_preview:right() + 4)
    end
end

function MenuItemColorButton:_update_caret()
    if not alive(self._text) then
        return
    end
	local text = self._text
    local caret = self._caret
    self:update_color_preview()

    text:set_align("left")
    caret:set_size(2, text:font_size())

    local s, e = text:selection()
	local x, y = text:character_rect(self._select_neg and s or e)

    if s == 0 and e == 0 then
		caret:set_world_position(text:world_position())
	else
		caret:set_world_position(x, y)
	end
    caret:set_alpha(1)
    caret:set_visible(self._editing)
    caret:set_color(text:color():with_alpha(1))
end

function MenuItemColorButton:check_changed()
    if alive(self._text) and self._text:text() ~= self:input_text() then
        self:set_value(self._text:text())
        self:trigger()
    end
end

function MenuItemColorButton:enter_text(row_item, ...)
	if ctrl() then
		return
	end
    MenuItemColorButton.super.enter_text(self, row_item, ...)
    self:check_changed()
end

function MenuItemColorButton:key_press(row_item, o, k)
	if not row_item or not alive(row_item.gui_text) or not self._editing then
		return
	end

    local text = row_item.gui_text
	self._key_pressed = k

	text:stop()
	text:animate(ClassClbk(self, "update_key_down", row_item), k)

	if k == Idstring("insert") then
		local clipboard = Application:get_clipboard() or ""
		text:replace_text(clipboard)
		local lbs = text:line_breaks()
		if #lbs > 1 then
			local s = lbs[2]
			local e = utf8.len(text:text())
			text:set_selection(s, e)
			text:replace_text("")
		end
	elseif self._key_pressed == Idstring("end") then
		text:set_selection(n, n)
	elseif self._key_pressed == Idstring("home") then
		text:set_selection(0, 0)
	end

	self:_layout(row_item)
end

function MenuItemColorButton:mouse_moved(x,y)
    local text = self._text
    local ret = false
    if self._start_select and self._old_x then
        local i = text:point_to_index(x, y)
        local s, e = text:selection()
        local old = self._select_neg
        if self._select_neg == nil or (s == e) then
            self._select_neg = (x - self._old_x) < 0
        end
        if self._select_neg then
            text:set_selection(i - 1, self._start_select)
        else
            text:set_selection(self._start_select, i + 1)
        end
        self:_update_caret()
        ret = true
    elseif not self._panel:inside(x,y) then
        self:set_editing(false)
    end
    self._old_x = x
    return ret
end

function MenuItemColorButton:mouse_pressed(button, x, y)
    local text = self._text
    if self._editing then
        local i = text:point_to_index(x, y)
        self._start_select = i
        self._select_neg = nil
        text:set_selection(i, i)
        self:_update_caret()
        return true
    end
    return false
end

function MenuItemColorButton:mouse_released(button, x, y)
    self._start_select = nil
end