Group = Group or class(Menu)
Group.type_name = "Group"
function Group:Init()
    self.super.Init(self)
    self:InitBasicItem()
end

function Group:InitBasicItem()
    self.super.InitBasicItem(self)
    if not self.divider_type then
	    self.toggle = self.panel:bitmap({
	        name = "toggle",
	        w = self.parent.items_size - 4,
	        h = self.parent.items_size - 4,
	        texture = "guis/textures/menuicons",
	        color = self.text_color or Color.black,
	        y = 2,
	        texture_rect = {self.closed and 42 or 2, self.closed and 2 or 0, 16, 16},
	        layer = 3,
	    })
	    self:RePositionToggle()
	end
end

function Group:RePositionToggle()
    local _,_,w,_ = self.title:text_rect()
    if self.toggle then
        self.toggle:set_left(w + 4)
    end
end

function Group:SetText(...)
    self.super.SetText(self, ...)
    self:RePositionToggle()
end

function Group:ToggleGroup()
    if self.closed then
        self.closed = false
    else
        self.closed = true
        self.panel:set_h(self.parent.items_size)
    end
    for i, item in ipairs(self._my_items) do
        item:SetEnabled(not self.closed)
        item.panel:set_visible(not self.closed)
    end
    self.toggle:set_texture_rect(self.closed and 42 or 2, self.closed and 2 or 0, 16, 16)
    self:AlignItems()
end

function Group:MouseInside(x, y) 
    return self.bg:inside(x,y) 
end

function Group:MousePressed(button, x, y)
    if button == Idstring("0") and self:MouseCheck(true) then
        self:ToggleGroup()
        return true
    end
    return self.super.MousePressed(self, button, x, y)
end

function Group:MouseMoved(x, y)
    if Item.MouseMoved(self, x, y) then
        return true
    end
    return self.super.MouseMoved(self, x, y)
end