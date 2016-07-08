Slider = Slider or class(Item)

function Slider:init( menu, params )    
    params.value = params.value or 1    
    self.type = "Slider"
    self.size_by_text = false
	self.super.init( self, menu, params )
    self.step = self.step or 1
    self.floats = self.floats or 2
    self.filter = "number"
    local item_width = params.panel:w() - self.padding
	local slider_bg = params.panel:bitmap({
        name = "slider_bg",
        w = item_width,
        h = params.items_size / 1.5,
        layer = 5,
        color = menu.background_color / 1.2,
    })
    TextBoxBase.init(self, {
        lines = 1,
        panel = self.panel,
        align = "center",
        w = params.panel:w() / 3.5,
        value = self.value,
    })	 
    slider_bg:set_center(params.panel:center())
    slider_bg:set_world_bottom(params.panel:world_bottom() - 4)
    params.panel:child("textbg"):set_right(params.panel:right() - 4)     
    params.panel:child("text"):set_center(params.panel:child("textbg"):center()) 
    if params.max or params.min then
        params.max = params.max or 1
        params.min = params.min or 0
        local slider = params.panel:rect({
            name = "slider",
            w = item_width * (params.value / params.max),
            h = slider_bg:h(),
            layer = 6,
            color = menu.marker_highlight_color / 1.4
        })              
        local slider_icon = params.panel:rect({
            name = "slider_icon",
            w = 2,
            h = slider_bg:h(),
            layer = 7,
        })  
        slider:set_leftbottom(slider_bg:left(), slider_bg:bottom())
        slider_icon:set_rightbottom(slider:right(), slider:bottom())
    end       
    self._mouse_pos_x, self._mouse_pos_y = 0,0
end
function Slider:SetStep(step)  
    self.step = step
end
function Slider:SetValue(value, reset_selection, no_format)
    log(tostring(value))
    value = tonumber(value) or 0
    log(tostring(value))
    local text = self.panel:child("text")
    local slider_icon = self.panel:child("slider_icon")
	local slider = self.panel:child("slider")

    if self.max or self.min then           
        local val = math.clamp(value, self.min, self.max)
        slider:set_w((self.panel:w() - self.padding) * ((val - self.min) / (self.max - self.min)))         
        slider_icon:set_right(slider:right())             
        text:set_text(not no_format and string.format("%.2f", val) or val)
    else
        text:set_text(not no_format and string.format("%.2f", value) or value)        
    end   
     if reset_selection then
        text:set_selection(text:text():len())  
    end
    if self.max or self.min then
	   self.super.SetValue(self, math.clamp(value, self.min, self.max))
    else
        self.super.SetValue(self, value)
    end    
    self._before_text = self.value
end

function Slider:SetValueByPercentage( percent )
    self:SetValue(self.min + (self.max - self.min) * percent)
end
 
function Slider:MousePressed( button, x, y )
	self.super.MousePressed(self, button, x, y)   
    if not self.enabled then
        return
    end      
    local inside 
    if self.max or self.min then
        inside = alive(self.panel:child("slider_bg")) and self.panel:child("slider_bg"):inside(x,y) or self.panel:child("slider"):inside(x,y)
    else
        inside = alive(self.panel:child("slider_bg")) and self.panel:child("slider_bg"):inside(x,y)
    end
    if inside then
        local wheelup = (button == Idstring("mouse wheel up") and 0) or (button == Idstring("mouse wheel down") and 1) or -1
        if wheelup ~= -1 then
            self:SetValue(self.value + ((wheelup == 1) and -self.step or self.step))
            self:RunCallback()
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
    self.super.MouseMoved(self, x, y)
    if self.menu._slider_hold == self and self.menu._old_x then
        if self.max or self.min then
            local slider_bg = self.panel:child("slider_bg")
            local where = (x - slider_bg:world_left()) / (slider_bg:world_right() - slider_bg:world_left())
            self:SetValueByPercentage(where)
        else
            local move = 0
            local slider_bg = self.panel:child("slider_bg")
            if managers.mouse_pointer._mouse:world_x() == self.menu._fullscreen_ws_pnl:w() then
                managers.mouse_pointer:set_mouse_world_position(1, managers.mouse_pointer._mouse:world_y())
            elseif managers.mouse_pointer._mouse:world_x() == 0 then
                managers.mouse_pointer:set_mouse_world_position(self.menu._fullscreen_ws_pnl:w() - 1, managers.mouse_pointer._mouse:world_y())
            else
                move = ctrl() and 1 or self.step or (x - self.menu._old_x)
                if self.step and x - self.menu._old_x <= 0 then
                    move = -move
                end                   
            end
            self:SetValue((type(self.value) == "number" and self.value or 0) + move, true)
        end
        self:RunCallback()
    end        
end
 
function Slider:MouseReleased( button, x, y )
    self.super.MouseReleased( self, button, x, y )
end