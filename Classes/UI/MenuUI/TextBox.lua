BeardLib.Items.TextBox = BeardLib.Items.TextBox or class(BeardLib.Items.Item)
local TextBox = BeardLib.Items.TextBox
TextBox.type_name = "TextBox"
function TextBox:Init()
	self.size_by_text = false
	TextBox.super.Init(self)
	self:WorkParam("floats", 3)
	if self.filter == "number" then
		self.value = tonumber(self.value) or 0
		self.allow_expressions = NotNil(self.allow_expressions, true)
	end
	self._textbox = BeardLib.Items.TextBoxBase:new(self, {
		panel = self.panel,
		fit_text = NotNil(self.fit_text, self.filter == "number"),
		lines = self.filter == "number" and 1 or nil,
		focus_mode = self.focus_mode,
		auto_focus = self.auto_focus,
		line_color = self.line_color or self.highlight_color,
		w = self.panel:w() * (not self.text and 1 or self.control_slice),
		value = self.value,
	})
	self.auto_focus = nil
	self.value = self.value or ""
	self._textbox:PostInit()
end

function TextBox:TextBoxSetValue(value, run_callback, reset_selection)
	local text = self._textbox.text

	if self.filter == "number" then
		value = tonumber(value) or 0
		if self.max then
			value = math.min(self.max, value)
		end
		if self.min then
			value = math.max(self.min, value)
		end
	    local final_number = self.floats and string.format("%." .. self.floats .. "f", value) or tostring(value)
	    value = tonumber(final_number)
	    text:set_text(final_number)
	else
		text:set_text(value)
	end
	if reset_selection then
		local len = text:text():len()
		text:set_selection(len, len)
	end
	self._textbox:update_caret()
	TextBox.super.SetValue(self, value, run_callback)
end

function TextBox:SetValue(value, ...)
	if not self:alive() then
		return false
	end
	if self.value ~= value then
		self._textbox:add_history_point(value)
	end
	self:TextBoxSetValue(value, ...)
	return true
end

function TextBox:SetStep(step)
	self.step = step
end

function TextBox:MousePressed(button, x, y)
	local result, state = TextBox.super.MousePressed(self, button, x, y)
	if state == self.UNCLICKABLE or state == self.INTERRUPTED then
		return result, state
	end

	if button == Idstring("1") and self.filter == "number" and not self.no_slide and self._textbox.panel:inside(x,y) then
		self.menu._slider_hold = self
		self._last_mouse_position = {managers.mouse_pointer._mouse:world_position()}
		return true
	end

	if self._textbox:MousePressed(button, x, y) then
		return true
	end

	return self._textbox.cantype, not self._textbox.cantype and state or nil
end

function TextBox:MouseReleased(b, x, y)
	self._textbox:MouseReleased(b, x, y)
	if self._last_mouse_position then
		managers.mouse_pointer:set_mouse_world_position(unpack(self._last_mouse_position))
		self._last_mouse_position = nil
	end
	managers.mouse_pointer._ws:show()
	return TextBox.super.MouseReleased(self, b,x,y)
end

function TextBox:DoHighlight(highlight)
    TextBox.super.DoHighlight(self, highlight)
    self._textbox:DoHighlight(highlight)
end

function TextBox:SetValueByMouseXPos(x)
    if not alive(self.panel) or self.ignore_next then
    	self.ignore_next = false
        return
    end
    if self.menu._old_x ~= x then
		local move = 0
		local pointer = managers.mouse_pointer
		pointer._ws:hide()
        if pointer._mouse:world_x() == self.menu._panel:w() then
            pointer:set_mouse_world_position(1, pointer._mouse:world_y())
            self.ignore_next = true
        elseif pointer._mouse:world_x() == 0 then
            pointer:set_mouse_world_position(self.menu._panel:w() - 1, pointer._mouse:world_y())
            self.ignore_next = true
        else
            move = ctrl() and 1 or self.step or (x - self.menu._old_x)
            if self.step and (x - self.menu._old_x) < 0 then
                move = -move
            end
        end
        self:SetValue(self.value + move, true, true)
	end
end
