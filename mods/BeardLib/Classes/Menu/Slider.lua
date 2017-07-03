Slider = Slider or class(Item)
Slider.type_name = "Slider"
function Slider:Init()
    self.value = self.value or 1
    self.size_by_text = false
	self.super.Init(self)
    self.step = self.step or 1
    self.value = tonumber(self.value) or 0
    self.floats = self.floats or 2
    self.filter = "number"
    self.min = self.min or 0
    self.max = self.max or self.min
    local item_width = self.panel:w() / self.control_slice
    local bgcolor = self:Get2ndBackground()
	local slider_bg = self.panel:rect({
        name = "slider_bg",
        w = item_width,
        layer = 2,
        color = bgcolor,
    })
    self._textbox = TextBoxBase:new(self, {
        text_color = bgcolor:contrast(),
        lines = 1,
        btn = "1",
        panel = self.panel,
        line = false,
        align = "center",
        w = item_width,
        value = self.value,
    })
    self.slider_color = NotNil(self.slider_color, self.inherit_from.slider_color, self.accent_color)
    local marker_color = (self.marker_color and self.marker_color.a > 0 and self.marker_color) or self.marker_highlight_color and self.marker_highlight_color.a > 0 and self.marker_highlight_color
    local slider = self.panel:rect({
        name = "slider",
        x = self._textbox.panel:x(),
        w = item_width * (self.value / self.max),
        layer = 3,
        color = (self.slider_color or marker_color or self:Get2ndBackground(bgcolor)):with_alpha(0.5)
    })
    slider_bg:set_x(self._textbox.panel:x())
    self._mouse_pos_x, self._mouse_pos_y = 0,0
    self._textbox:PostInit()
end

function Slider:SetEnabled(enabled)
    self.super.SetEnabled(self, enabled)
    if self._textbox and self:alive() then
        self.panel:child("slider_bg"):set_alpha(enabled and 1 or 0.5)
        self._textbox.panel:child("text"):set_alpha(enabled and 1 or 0.5)
    end
end

function Slider:SetStep(step)
    self.step = step
end

function Slider:_SetValue(value, run_callback, reset_selection, no_format)  
    value = tonumber(value) or 0 
    if self.max or self.min then
        value = math.clamp(value, self.min, self.max)    
    end      
    value = tonumber(not no_format and format or value)     
    local format = string.format("%." .. self.floats .. "f", value)
    local text = self._textbox.panel:child("text")
	local slider = self.panel:child("slider")
    slider:set_w(self.panel:child("slider_bg"):w() * ((value - self.min) / (self.max - self.min)))
    if not no_format then
        text:set_text(format)
    end
     if reset_selection then
        text:set_selection(text:text():len())
    end
    self._before_text = self.value
    self.super.SetValue(self, value, run_callback)
end

function Slider:SetValue(value, ...)
    if self.value ~= value then
        self._textbox:add_history_point(value)
    end
    self:_SetValue(value, ...)
end

function Slider:SetValueByPercentage(percent)
    self:SetValue(self.min + (self.max - self.min) * percent, true, true)
end

function Slider:MouseMoved(x, y)
    self.super.MouseMoved(self, x, y)
    self._textbox:MouseMoved(x, y)
end

function Slider:MouseReleased(button, x, y)
    self._textbox:MouseReleased(button, x, y)
end

function Slider:KeyPressed(o, k)
    self.super.KeyPressed(self, o, k)
    self._textbox:KeyPressed(o, k)
end

function Slider:MousePressed(button, x, y)
	self.super.MousePressed(self, button, x, y)
    self._textbox:MousePressed(button, x, y)
    if not self.enabled or not alive(self.panel) then
        return
    end
    local inside = self.panel:child("slider_bg"):inside(x,y) or self.panel:child("slider"):inside(x,y)
    if inside then
        local wheelup = (button == Idstring("mouse wheel up") and 0) or (button == Idstring("mouse wheel down") and 1) or -1
        if self.wheel_control and wheelup ~= -1 then
            self:SetValue(self.value + ((wheelup == 1) and -self.step or self.step), true, true)
            return true
        end
    	if button == Idstring("0") then
            self.menu._slider_hold = self
            if self.max or self.min then
                local slider_bg = self.panel:child("slider_bg")
                local where = (x - slider_bg:world_left()) / (slider_bg:world_right() - slider_bg:world_left())
                managers.menu_component:post_event("menu_enter")
                self:SetValueByPercentage(where)
            end
            return true
        end
    end
end

function Slider:SetValueByMouseXPos(x)
    if not alive(self.panel) then
        return
    end
    local slider_bg = self.panel:child("slider_bg")
    self:SetValueByPercentage((x - slider_bg:world_left()) / (slider_bg:world_right() - slider_bg:world_left()))
end