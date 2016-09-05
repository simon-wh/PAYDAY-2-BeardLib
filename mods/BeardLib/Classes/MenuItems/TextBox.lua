TextBox = TextBox or class(Item)

function TextBox:init( parent, params )
	params.value = params.value or ""
	self.size_by_text = false
	self.super.init(self, parent, params)	
	self.type = self.type or "TextBox"
    self.floats = self.floats or 2
    if self.filter == "number" then
    	self.value = tonumber(self.value) or 0
    end
	TextBoxBase.init(self, {
        panel = self.panel,
        w = params.panel:w() / 2,
        value = self.value,
    })
end

function TextBox:SetValue(value, run_callback, reset_selection)
	local text = self.text_panel:child("text")
	if self.filter == "number" then
		value = tonumber(value) or 0
	    if self.max or self.min then
	        value = math.clamp(value, self.min, self.max)    
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
	self:update_caret()
	self.super.SetValue(self, value, run_callback)
end

function TextBox:MousePressed(button, x, y)
	if not alive(self.panel) then
		return
	end
	if not self.cantype then
		self:SetValue(self.text_panel:child("text"):text(), true, true)
	end
	if button == Idstring("1") and self.type == "NumberBox" and not self.no_slide and self.text_panel:inside(x,y) then
		self.menu._slider_hold = self
		return true
	end
	return self.cantype
end
function TextBox:KeyPressed(o, k)
end

function TextBox:MouseMoved(x, y)
    if not self.super.MouseMoved(self, x, y) then
    	return 
    end
    if self.cantype then
        self:SetValue(self.text_panel:child("text"):text())
    end
    if self.menu._slider_hold == self and self.menu._old_x then
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

function TextBox:MouseReleased( button, x, y )
    self.super.MouseReleased( self, button, x, y )
end
