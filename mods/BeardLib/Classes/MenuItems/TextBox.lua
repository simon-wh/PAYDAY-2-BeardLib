TextBox = TextBox or class(Item)

function TextBox:init(parent, params)
	params.value = params.value or ""
	self.size_by_text = false
	self.super.init(self, parent, params)	
	self.type_name = self.type_name or "TextBox"
    self.floats = self.floats or 2
    if self.filter == "number" then
    	self.value = tonumber(self.value) or 0
    end
	self._textbox = TextBoxBase:new(self, {
        panel = self.panel,
        w = params.panel:w() / (self.text == nil and 1 or self.control_slice),
        value = self.value,
    })
end

function TextBox:SetEnabled(enabled)
	self.super.SetEnabled(self, enabled)
	self._textbox.panel:child("line"):set_alpha(enabled and 1 or 0.5)
	self._textbox.panel:child("text"):set_alpha(enabled and 1 or 0.5)
end

function TextBox:SetValue(value, run_callback, reset_selection)
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
	self.super.SetValue(self, value, run_callback)
end

function TextBox:SetStep(step)
	self.step = step
end

function TextBox:MousePressed(button, x, y)
	if not alive(self.panel) then
		return
	end
	if not self.cantype then
		self:SetValue(self._textbox.panel:child("text"):text(), true, true)
	end
	if button == Idstring("1") and self.type_name == "NumberBox" and not self.no_slide and self._textbox.panel:inside(x,y) then
		self.menu._slider_hold = self
		return true
	end
	self._textbox:MousePressed(button, x, y)
	return self.cantype
end

function TextBox:MouseReleased(button, x, y)
	self._textbox:MouseReleased(button, x, y)
end

function TextBox:KeyPressed(o, k)
	self.super.KeyPressed(self, o, k)
	self._textbox:KeyPressed(o, k)
end

function TextBox:MouseMoved(x, y)
    if not self.super.MouseMoved(self, x, y) then
    	return 
    end
    if self.cantype then
        self:SetValue(self._textbox.panel:child("text"):text())
    end    
    self._textbox:MouseMoved(x, y)
end

function TextBox:SetValueByMouseXPos(x)
    if not alive(self.panel) then
        return
    end
    if self.menu._old_x ~= x then
        local move = 0
        if managers.mouse_pointer._mouse:world_x() == self.menu._fullscreen_ws_pnl:w() then
            managers.mouse_pointer:set_mouse_world_position(1, managers.mouse_pointer._mouse:world_y())
        elseif managers.mouse_pointer._mouse:world_x() == 0 then
            managers.mouse_pointer:set_mouse_world_position(self.menu._fullscreen_ws_pnl:w() - 1, managers.mouse_pointer._mouse:world_y())
        else
            move = ctrl() and 1 or self.step or (x - self.menu._old_x)
            if self.step and (x - self.menu._old_x) < 0 then
                move = -move
            end
        end
        self:SetValue(self.value + move, true, true)
	end      
end
 