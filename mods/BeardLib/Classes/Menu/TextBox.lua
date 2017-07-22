BeardLib.Items.TextBox = BeardLib.Items.TextBox or class(BeardLib.Items.Item)
local TextBox = BeardLib.Items.TextBox
TextBox.type_name = "TextBox"
function TextBox:Init()
	self.size_by_text = false
	TextBox.super.Init(self)	
    self.floats = self.floats or 2
    if self.filter == "number" then
    	self.value = tonumber(self.value) or 0
    end
	self._textbox = BeardLib.Items.TextBoxBase:new(self, {
        panel = self.panel,
        lines = self.lines,
        align = self.textbox_align,
        line_color = self.line_color or self.marker_highlight_color,
        w = self.panel:w() / (self.text == nil and 1 or self.control_slice),
        value = self.value,
    })
    self.value = self.value or ""
    self._textbox:PostInit()
end

function TextBox:_SetValue(value, run_callback, reset_selection)
	local text = self._textbox.panel:child("text")

	if self.filter == "number" then
		value = tonumber(value) or 0
		if self.max then
			value = math.min(self.max, value)
		end
		if self.min then
			value = math.max(self.min, value)
		end
	    local format = string.format("%." .. self.floats .. "f", value)
	    value = tonumber(format)    
	    text:set_text(format)
	else
		text:set_text(value)
	end
	if reset_selection then
		text:set_selection(text:text():len())
	end
	self._textbox:update_caret()	
	TextBox.super.SetValue(self, value, run_callback)
end

function TextBox:SetValue(value, ...)
	if self.value ~= value then
		self._textbox:add_history_point(value)
	end
	self:_SetValue(value, ...)
end

function TextBox:SetStep(step)
	self.step = step
end

function TextBox:MousePressed(button, x, y)
	if not self:MouseCheck(true) then
		return
	end
	if button == Idstring("1") and self.type_name == "NumberBox" and not self.no_slide and self._textbox.panel:inside(x,y) then
		self.menu._slider_hold = self
		return true
	end
	self._textbox:MousePressed(button, x, y)
	return self._textbox.cantype
end

function TextBox:MouseReleased(button, x, y)
	self._textbox:MouseReleased(button, x, y)
end

function TextBox:KeyPressed(o, k)
	TextBox.super.KeyPressed(self, o, k)
	self._textbox:KeyPressed(o, k)
end

function TextBox:MouseMoved(x, y)
    if not TextBox.super.MouseMoved(self, x, y) then
    	return 
    end
    self._textbox:MouseMoved(x, y)
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
        if managers.mouse_pointer._mouse:world_x() == self.menu._panel:w() then
            managers.mouse_pointer:set_mouse_world_position(1, managers.mouse_pointer._mouse:world_y())
            self.ignore_next = true
        elseif managers.mouse_pointer._mouse:world_x() == 0 then
            managers.mouse_pointer:set_mouse_world_position(self.menu._panel:w() - 1, managers.mouse_pointer._mouse:world_y())
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