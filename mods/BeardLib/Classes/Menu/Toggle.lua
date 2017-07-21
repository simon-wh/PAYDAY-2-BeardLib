Toggle = Toggle or class(Item)
Toggle.type_name = "Toggle"
function Toggle:Init()    
	Toggle.super.Init(self)
    self.toggle = self.panel:bitmap({
        name = "toggle",
        w = self.items_size,
        h = self.items_size,
        layer = 6,
        color = self.text_color or Color.black,
        texture = "guis/textures/menu_tickbox",
        texture_rect = self.value and {24,0,24,24} or {0,0,24,24},
    })
    self.toggle:set_right(self.panel:w())
end

function Toggle:SetValue(value, run_callback)
	Toggle.super.SetValue(self, value, run_callback)
	if alive(self.panel) then
		local rect = value == true and {24,0,24,24} or {0,0,24,24}
		self.toggle:set_texture_rect(unpack(rect))
	end
end

function Toggle:MousePressed(button, x, y)
	if not self:MouseCheck(true) then
		return
	end
	if button == Idstring("0") then
		self:SetValue(not self.value)
		if managers.menu_component then
			managers.menu_component:post_event(self.value and "box_tick" or "box_untick")
		end
		Toggle.super.MousePressed(self, button, x, y)
        return true
	end
end

function Toggle:KeyPressed(o, k)
	if k == Idstring("enter") then
		self:SetValue(not self.value)
		self:RunCallback()
	end
end

function Toggle:DoHighlight(highlight)
    Toggle.super.DoHighlight(self, highlight) 
    self.toggle:set_color(self.title:color())
end