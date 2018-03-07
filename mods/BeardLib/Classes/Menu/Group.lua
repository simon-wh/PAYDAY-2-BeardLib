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
	        w = self.title:h() - 4,
	        h = self.title:h() - 4,
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
        if alive(self.toggle) then
            local s = self.title:h() - 4
            self.toggle:set_size(s, s)
            self.toggle:set_x(w + 4)
            self.toggle:set_center_y(self.title:center_y())
        end
        if alive(self.bg) and alive(self.highlight_bg) then
            self.bg:set_h(self:TextHeight())
            self.highlight_bg:set_h(self:TextHeight())
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
        self.panel:set_h(self:TextHeight())
    end
    for i, item in pairs(self._my_items) do
        if item:ParentPanel() == self:ItemsPanel() then
            item:SetVisible(not self.closed)
        end
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