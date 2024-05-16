BeardLib.Items.Holder = BeardLib.Items.Holder or class(BeardLib.Items.Item)
local Holder = BeardLib.Items.Holder
Holder.type_name = "Holder"
Holder.HOLDER = true
Holder.MENU = true

function Holder:Init(params)
    self:WorkParams(params)
    self:InitBasicMenu()
    self:Menuify()
    self:PostInit()
    self:Reposition()
end

function Holder:WorkParams(params)
    Holder.super.WorkParams(self, params)
    params = params or {}
    self.background_visible = NotNil(self.background_visible, true)
    self.private.background_color = NotNil(self.private.background_color, self.background_visible and self.background_color or nil)
    self.auto_height = NotNil(self.auto_height, self.h == nil)
end

Holder.SetSize = BeardLib.Items.Menu.SetSize
Holder.MousePressed = Holder.MousePressedMenuEvent
Holder.MouseMoved = Holder.MouseMovedMenuEvent


function Holder:_SetSize(w, h)
    if not self:alive() then
        return
	end

	w = w or self.w
	h = h or self.orig_h or self.h
	h = math.clamp(h, self.min_height or 0, self.max_height or h)

	self.panel:set_size(w, h)
    self.w, self.h = self.panel:size()
    self:Reposition()
    self:MakeBorder()
end

function Holder:UpdateCanvas(h)
    if self:alive() and self.auto_height then
        self:_SetSize(nil, h)
    end
end