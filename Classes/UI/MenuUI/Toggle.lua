BeardLib.Items.Toggle = BeardLib.Items.Toggle or class(BeardLib.Items.Item)
local Toggle = BeardLib.Items.Toggle
Toggle.type_name = "Toggle"
function Toggle:Init()
	Toggle.super.Init(self)
	local s = self.size - 2
	local fgcolor = self:GetForeground()
    self.toggle = self.panel:bitmap({
		name = "toggle",
        w = s,
        h = s,
		color = fgcolor,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {3, 89, 36, 36},
		layer = 5,
	})
	local s = self.value and s or 0
	self.toggle_value = self.panel:bitmap({
        name = "toggle",
        w = s,
        h = s,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {41, 89, 36, 36},
		color = fgcolor,
		layer = 5,
	})
    self.toggle:set_center_y(self.panel:h() / 2)
    self.toggle:set_right(self.panel:w() - (self.text_offset[4] or self.text_offset[2]))
	self.toggle_value:set_center(self.toggle:center())
	self:UpdateToggle(true)
end

function Toggle:SetEnabled(enabled)
	Toggle.super.SetEnabled(self, enabled)
	if self:alive() then
		--toggle and toggle value alpha isn't the same as some cases.. :/
		self.toggle:set_alpha(self.enabled and 1 or 0.05)
	end
end

function Toggle:SetValue(value, run_callback)
	if Toggle.super.SetValue(self, value, run_callback) then
		self:UpdateToggle(true)
		return true
	else
		return false
	end
end

function Toggle:UpdateToggle(value_changed, highlight)
	local value = self.value
	if alive(self.panel) then
		local fgcolor = self:GetForeground(highlight)
		local s = value and self.size - 2 or 0
		if self.animate_colors then
			play_color(self.toggle, fgcolor)
		else
			self.toggle:set_color(fgcolor)
			self.toggle_value:set_color(fgcolor)
		end
		play_anim(self.toggle_value, {
			after = function()
				self.toggle_value:set_center(self.toggle:center())
			end,
			set = {w = s, h = s, color = self.animate_colors and fgcolor}
		})
	end
end

local enter = Idstring("enter")
function Toggle:MousePressed(b, x, y)
	local result, state = Toggle.super.MousePressed(self, b, x, y)
	if state == self.UNCLICKABLE or state == self.INTERRUPTED then
		return result, state
	end
	if state == self.CLICKABLE and b == self.click_btn then
		self:SetValue(not self.value, true)
		if managers.menu_component then
			managers.menu_component:post_event(self.value and "box_tick" or "box_untick")
		end
        return true
	end
	return result, state
end

function Toggle:KeyPressed(o, k)
	if k == enter then
		self:SetValue(not self.value, true)
		self:RunCallback()
	end
end

function Toggle:DoHighlight(highlight)
	Toggle.super.DoHighlight(self, highlight)
	self:UpdateToggle(false, highlight)
end