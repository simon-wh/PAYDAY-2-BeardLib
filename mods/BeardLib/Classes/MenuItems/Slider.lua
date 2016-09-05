Slider = Slider or class(Item)

function Slider:init( parent, params )
    params.value = params.value or 1
    self.type = "Slider"
    self.size_by_text = false
	self.super.init( self, parent, params )
    self.step = self.step or 1
    self.value = tonumber(self.value) or 0
    self.floats = self.floats or 2
    self.filter = "number"
    self.min = self.min or 0
    self.max = self.max or self.min
    local item_width = params.panel:w() / 2
	local slider_bg = params.panel:bitmap({
        name = "slider_bg",
        w = item_width,
        layer = 5,
        color = ((parent.background_color or Color.white) / 1.2):with_alpha(1),
    })
    local text_panel = TextBoxBase.init(self, {
        text_color = not parent.background_color and Color.black,
        lines = 1,
        btn = "1",
        panel = self.panel,
        line = false,
        align = "center",
        w = item_width,
        value = self.value,
    })
    local slider = self.panel:rect({
        name = "slider",
        x = text_panel:x(),
        w = item_width * (self.value / self.max),
        h = slider_bg:h(),
        layer = 6,
        color = parent.marker_highlight_color / 1.4
    })
    slider_bg:set_x(text_panel:x())
    local slider_icon = self.panel:rect({
        color = (parent.background_color and self.text_color) or Color.black,
        name = "slider_icon",
        w = 2,
        h = slider_bg:h(),
        layer = 7,
    })
    slider_icon:set_rightbottom(slider:right(), slider:bottom())
    self._mouse_pos_x, self._mouse_pos_y = 0,0
end
function Slider:SetStep(step)
    self.step = step
end
function Slider:SetValue(value, run_callback, reset_selection, no_format)  
    value = tonumber(value) or 0 
    if self.max or self.min then
        value = math.clamp(value, self.min, self.max)    
    end      
    value = tonumber(not no_format and format or value)     
    local format = string.format("%." .. self.floats .. "f", value)
    local text = self.text_panel:child("text")
	local slider = self.panel:child("slider")
    slider:set_w(self.panel:child("slider_bg"):w() * ((value - self.min) / (self.max - self.min)))
    self.panel:child("slider_icon"):set_left(slider:right())
    if not no_format then
        text:set_text(format)
    end
     if reset_selection then
        text:set_selection(text:text():len())
    end
    self.super.SetValue(self, value, run_callback)
    self._before_text = self.value
end

function Slider:SetValueByPercentage( percent )
    self:SetValue(self.min + (self.max - self.min) * percent, false, true)
end

function Slider:MousePressed( button, x, y )
	self.super.MousePressed(self, button, x, y)
    if not self.enabled or not alive(self.panel) then
        return
    end
    local inside = self.panel:child("slider_bg"):inside(x,y) or self.panel:child("slider"):inside(x,y)
    if inside then
        local wheelup = (button == Idstring("mouse wheel up") and 0) or (button == Idstring("mouse wheel down") and 1) or -1
        if wheelup ~= -1 then
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
                self:RunCallback()
            end
            return true
        end
    end
end

function Slider:KeyPressed( o, k )

end

function Slider:MouseMoved( x, y )
    if not self.super.MouseMoved(self, x, y) then
        return 
    end
    if self.menu._slider_hold == self and self.menu._old_x then
        local slider_bg = self.panel:child("slider_bg")
        local where = (x - slider_bg:world_left()) / (slider_bg:world_right() - slider_bg:world_left())
        self:SetValueByPercentage(where)
        self:RunCallback()
    end
end

function Slider:MouseReleased( button, x, y )
    self.super.MouseReleased( self, button, x, y )
end
