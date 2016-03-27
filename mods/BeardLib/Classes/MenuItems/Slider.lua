Slider = Slider or class(Item)

function Slider:init( menu, params )    
    params.value = params.value or 1
	self.super.init( self, menu, params )

	local slider_bg = params.panel:bitmap({
        name = "slider_bg",
        y = 4,
        w = params.panel:w() / 1.4,
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
        w = slider_bg:w() - 4,
        h = 16,
        layer = 8,
        color = Color.black,
        font = "fonts/font_large_mf",
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
    slider_value:enter_text(callback(self, TextBox, "enter_text")) 
    caret:animate(callback(self, TextBox, "blink"))    	
    slider_bg:set_right(params.panel:w() - 4)
    slider_value:set_center(slider_bg:center())
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
function Slider:SetValue(value)
    value = tonumber(value) or 0
	local slider_value = self.panel:child("slider_value")
	slider_value:set_text(string.format("%.2f", value))
    slider_value:set_selection(slider_value:text():len())   
    self._before_text = self.value
	self.super.SetValue(self, value)
end

function Slider:mouse_pressed( o, button, x, y )
	self.super.mouse_pressed(self, o, button, x, y)    
	if self.panel:child("slider_bg"):inside(x,y) and button == Idstring("0") then
        self.menu._slider_hold = self  
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

function Slider:mouse_moved(o, x, y )
	self.super.mouse_moved(self, o, x, y)
	if self.menu._slider_hold == self and self.menu._old_x then
		local slider_bg = self.panel:child("slider_bg")
        local move = self.step or (x - self.menu._old_x)
        if self.step and x - self.menu._old_x <= 0 then
            move = -move
        end
      	self:SetValue((type(self.value) == "number" and self.value or 0) + move)
        if self.callback then
            self.callback(self.menu, self)
        end
    end	        
    self.cantype = self.panel:inside(x,y) and self.cantype or false     
    self:update_caret()
end
