Toggle = Toggle or class(Item)

function Toggle:init( menu, params )
	self.super.init( self, menu, params )
    params.panel:bitmap({
        name = "toggle",
        x = 2,
        w = params.panel:h() -2,
        h = params.panel:h() -2,
        layer = 6,
        color = Color.black,
        texture = "guis/textures/menu_tickbox",
        texture_rect = params.value and {24,0,24,24} or {0,0,24,24},
    }):set_right(params.panel:w() - 4)
end

function Toggle:SetValue(value)
	self.super.SetValue(self, value)
	if value == true then
		managers.menu_component:post_event("box_tick")
		self.panel:child("toggle"):set_texture_rect(24,0,24,24)
	else
		managers.menu_component:post_event("box_untick")
		self.panel:child("toggle"):set_texture_rect(0,0,24,24)			
	end
end

function Toggle:mouse_pressed( o, button, x, y )
	if button == Idstring("0") then
		self:SetValue(not self.value)	
		self.super.mouse_pressed(self, o, button, x, y)
        return true
	end
end

function Toggle:key_press( o, k )
	if k == Idstring("enter") then
		self:SetValue(not self.value)
		if self.callback then
			self.callback(self.menu, self)
		end
	end
end

function Toggle:mouse_moved(o, x, y )
	self.super.mouse_moved(self, o, x, y)
end
