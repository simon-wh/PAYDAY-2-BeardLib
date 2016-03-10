Slider = Slider or class(Item)

function Slider:init( menu, params )
	self.super.init( self, menu, params )
	local slider_value = params.panel:text({
	    name = "slider_value",
	    text = tostring(string.format("%.2f", params.value)),
	    valign = "center",
	    align = "center",
	    vertical = "center",
	    x = 2,
	    layer = 8,
	    color = Color.black,
	    font = "fonts/font_large_mf",
	    font_size = 16
	}) 	
	local slider_bg = params.panel:bitmap({
        name = "slider_bg",
        y = 4,
        w = params.panel:w() / 1.5,
        h = 16,
        layer = 5,
        color = Color(0.6, 0.6, 0.6),
    })			
    slider_bg:set_world_right(params.panel:right() - 4)
    slider_value:set_center(slider_bg:center())
end

function Slider:SetValue(value)
	local slider_value = self.panel:child("slider_value")
	slider_value:set_text(string.format("%.2f", value))
	self.super.SetValue(self, value)
end

function Slider:mouse_pressed( o, button, x, y )
	self.super.mouse_pressed(self, o, button, x, y)    
	if self.panel:child("slider_bg"):inside(x,y) and button == Idstring("0") then
        self.menu._slider_hold = self                
    end    
end

function Slider:key_press( o, k )

end 

function Slider:mouse_moved(o, x, y )
	self.super.mouse_moved(self, o, x, y)
	if self.menu._slider_hold == self and self.menu._old_x then
		local slider_bg = self.panel:child("slider_bg")
      	self:SetValue(self.value + (x - self.menu._old_x))
    end	
end
