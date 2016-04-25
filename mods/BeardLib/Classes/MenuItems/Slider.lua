Slider = Slider or class(Item)

function Slider:init( menu, params )    
    params.value = params.value or 1
	self.super.init( self, menu, params )
    local item_width = params.panel:w() / 1.4
	local slider_bg = params.panel:bitmap({
        name = "slider_bg",
        y = 4,
        w = item_width,
        h = 16,
        layer = 5,
        color = Color(0.6, 0.6, 0.6),
    })	 
    local slider_value = params.panel:text({
        name = "slider_value",
        text = tostring(string.format("%.2f", params.value)),
        valign = "center",
      --  align = "center",        
        vertical = "center",
        w = item_width - 4,
        h = 16,
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
        h = 16,
        alpha = 0,
        layer = 20,
    })   
    slider_bg:set_right(params.panel:w() - 4)
    slider_value:set_center(slider_bg:center())      
    if params.max or params.min then
        params.max = params.max or 1
        params.min = params.min or 0
        local slider = params.panel:rect({
            name = "slider",
            y = 4,
            w = item_width * (params.value / params.max),
            h = 16,
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
function Slider:SetValue(value, reset_selection)
    value = tonumber(value) or 0
    local slider_value = self.panel:child("slider_value")
    local slider_icon = self.panel:child("slider_icon")
	local slider = self.panel:child("slider")
	slider_value:set_text(string.format("%.2f", value))
    if reset_selection then
        slider_value:set_selection(slider_value:text():len())  
    end
    if self.max or self.min then
        slider:set_w((self.panel:w() / 1.4) * (value / self.max))         
        slider_icon:set_right(slider:right())
    end
    self._before_text = self.value
	self.super.SetValue(self, value)
end

function Slider:mouse_pressed( button, x, y )
	self.super.mouse_pressed(self, button, x, y)    
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
            self:SetValue( tonumber(math.clamp(where * self.max, self.min, self.max)))
            if self.callback then
                self.callback(self.menu, self)
            end            
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
            self:SetValue(tonumber(math.clamp(where * self.max, self.min, self.max)))
        else
            local slider_bg = self.panel:child("slider_bg")
            local move = self.step or (x - self.menu._old_x)
            if self.step and x - self.menu._old_x <= 0 then
                move = -move
            end     
            self:SetValue((type(self.value) == "number" and self.value or 0) + move)
        end
        if self.callback then
            self.callback(self.menu, self)
        end
    end	        
    self.cantype = self.panel:inside(x,y) and self.cantype or false     
    self:update_caret()
end
function Slider:mouse_released( button, x, y )
    self.super.mouse_released( self, button, x, y )
end