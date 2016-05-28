Slider = Slider or class(Item)

function Slider:init( menu, params )
    params.value = params.value or 1
	self.super.init( self, menu, params )
    self.type = "Slider"
    self.step = params.step or 1
    local item_width = params.panel:w() / 1.5
	local slider_bg = params.panel:bitmap({
        name = "slider_bg",
        w = item_width,
        h = params.items_size,
        layer = 5,
        color = Color(0.6, 0.6, 0.6),
    })	 
    local slider_value = params.panel:text({
        name = "slider_value",
        text = tostring(string.format("%.2f", params.value)),
        valign = "center",
        vertical = "center",
        w = item_width - 4,
        h = params.items_size - 2,
        layer = 8,
        color = params.text_color or Color.black,
        font = "fonts/font_medium_mf",
        font_size = 16
    })  
    slider_value:set_selection(slider_value:text():len())	
    self.filter = "number"
    local caret = params.panel:rect({
        name = "caret",
        w = 1,
        h = params.items_size,
        alpha = 0,
        layer = 20,
    })   
    slider_bg:set_right(params.panel:w())
    slider_value:set_center(slider_bg:center())      
    if params.max or params.min then
        params.max = params.max or 1
        params.min = params.min or 0
        local slider = params.panel:rect({
            name = "slider",
            w = item_width * (params.value / params.max),
            h = params.items_size,
            layer = 6,
            alpha = 0.5,
            color = Color(0.2, 0.5, 1),
        })              
        local slider_icon = params.panel:rect({
            name = "slider_icon",
            w = 4,
            layer = 7,
            color = Color(0.4, 0.4, 0.4)
        })  
        slider:set_left(slider_bg:left())
        slider_icon:set_right(slider:right())
    end       
    slider_value:enter_text(callback(self, TextBox, "enter_text")) 
    caret:animate(callback(self, TextBox, "blink"))    
    self._mouse_pos_x, self._mouse_pos_y = 0,0
end
function Slider:update_caret()     
    local text = self.panel:child("slider_value")

    local s, e = text:selection()
    local x, y, w, h = text:selection_rect()
    if s == 0 and e == 0 then
        x = text:world_x()
        y = text:world_y()
    end
    self.panel:child("caret"):set_world_position(x, y + 1)
    self.panel:child("caret"):set_visible(self.cantype)
end
function Slider:SetValue(value, reset_selection, no_format)
    value = tonumber(value) or 0
    local slider_value = self.panel:child("slider_value")
    local slider_icon = self.panel:child("slider_icon")
	local slider = self.panel:child("slider")

    if self.max or self.min then           
        local val = math.clamp(value, self.min, self.max)
        slider:set_w((self.panel:w() / 1.5) * ((val - self.min) / (self.max - self.min)))         
        slider_icon:set_right(slider:right())             
        slider_value:set_text(not no_format and string.format("%.2f", val) or val)
    else
        slider_value:set_text(not no_format and string.format("%.2f", value) or value)        
    end   
     if reset_selection then
        slider_value:set_selection(slider_value:text():len())  
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
 
function Slider:mouse_pressed( button, x, y )
	self.super.mouse_pressed(self, button, x, y)   
    if not self.enabled then
        return
    end      
    local inside 
    if self.max or self.min then
        inside = self.panel:child("slider_bg"):inside(x,y) or self.panel:child("slider"):inside(x,y)
    else
        inside = self.panel:child("slider_bg"):inside(x,y)
    end
	if inside and button == Idstring("0") then
        self.menu._slider_hold = self  
        if self.max or self.min then
            local slider_bg = self.panel:child("slider_bg")
            local where = (x - slider_bg:world_left()) / (slider_bg:world_right() - slider_bg:world_left())
            managers.menu_component:post_event("menu_enter")
            self:SetValueByPercentage(where)
            if self.callback then
                self.callback(self.menu, self)
            end    
        else
           -- managers.mouse_pointer._mouse:hide()    
          --  self._mouse_pos_x, self._mouse_pos_y = managers.mouse_pointer._mouse:world_position()     
        end
        return true              
    end  
    if button == Idstring("1") then
        self.cantype = self.panel:inside(x,y)
        self:update_caret() 
        return self.cantype   
    end 
end

function Slider:key_press( o, k )
    self.panel:child("slider_value"):animate(callback(self, TextBox, "key_hold"), k)
end 

function Slider:mouse_moved( x, y )
    self.super.mouse_moved(self, x, y)
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
                move = self.step or (x - self.menu._old_x)
                if self.step and x - self.menu._old_x <= 0 then
                    move = -move
                end                   
            end
            self:SetValue((type(self.value) == "number" and self.value or 0) + move, true)
        end
        if self.callback then
            self.callback(self.menu, self)
        end
    end        
    
    local cantype = self.cantype  
    self.cantype = self.panel:inside(x,y) and self.cantype or false     
    if cantype and not self.cantype then
        TextBox.CheckText(self, self.panel:child("slider_value"))
        self:SetValue(self.value, true)
    end     
	if self.cantype then
		self:update_caret()
	end
end
 

function Slider:mouse_released( button, x, y )
    self.super.mouse_released( self, button, x, y )
    --managers.mouse_pointer._mouse:show()
end