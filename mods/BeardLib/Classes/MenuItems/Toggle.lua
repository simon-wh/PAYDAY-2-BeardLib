Toggle = Toggle or class(Item)
Toggle.type_name = "Toggle"
function Toggle:Init()    
	self.super.Init(self)
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

function Toggle:SetEnabled(enabled)
	self.super.SetEnabled(self, enabled)
	if self.toggle and self:alive() then
		self.toggle:set_alpha(enabled and 1 or 0.5)
	end
end

function Toggle:SetValue(value, run_callback)
	self.super.SetValue(self, value, run_callback)
	if alive(self.panel) then
		if managers.menu_component then
			managers.menu_component:post_event(value and "box_tick" or "box_untick")
		end
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
		self.super.MousePressed(self, button, x, y)
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
    self.super.DoHighlight(self, highlight) 
    self.toggle:set_color(self.title:color())
end