BeardLib.Items.Group = BeardLib.Items.Group or class(BeardLib.Items.Menu)
local Group = BeardLib.Items.Group
Group.type_name = "Group"
function Group:Init()
    Group.super.Init(self)
    self:InitBasicItem()
    self:GrowHeight()
end

function Group:InitBasicItem()
    Group.super.InitBasicItem(self)
    if not self.divider_type then
	    self.toggle = self.panel:bitmap({
	        name = "toggle",
	        w = self.parent.items_size - 4,
	        h = self.parent.items_size - 4,
	        texture = "guis/textures/menu_ui_icons",
	        color = self:GetForeground(highlight),
	        y = 2,
	        texture_rect = {self.closed and 42 or 2, self.closed and 2 or 0, 16, 16},
	        layer = 3,
	    })
	    self:RePositionToggle()
	end
end

function Group:RePositionToggle()
    if self:title_alive() then
        local _,_,w,_ = self.title:text_rect()
        if self.toggle and alive(self.toggle) then
            self.toggle:set_left(w + 4)
        end
    end
end

function Group:SetText(...)
    if Group.super.SetText(self, ...) then
        self:SetScrollPanelSize()
    end
    self:RePositionToggle()
end

function Group:ToggleGroup()
    if self.closed then
        self.closed = false
    else
        self.closed = true
        self.panel:set_h(self.parent.items_size)
    end
    for i, item in pairs(self._my_items) do
        item:SetVisible(not self.closed)
    end
    self.toggle:set_texture_rect(self.closed and 42 or 2, self.closed and 2 or 0, 16, 16)
    self:AlignItems()
    self:SetSize(nil, nil, true)
end

function Group:MouseInside(x, y) 
    return self.highlight_bg:inside(x,y) 
end

function Group:MousePressed(button, x, y)
    if button == Idstring("0") and self:MouseCheck(true) then
        self:ToggleGroup()
        return true
    end
    return Group.super.MousePressed(self, button, x, y)
end

function Group:MouseMoved(x, y)
    if not Group.super.MouseMoved(self, x, y) then
        return BeardLib.Items.Item.MouseMoved(self, x, y)
    end
    return false
end