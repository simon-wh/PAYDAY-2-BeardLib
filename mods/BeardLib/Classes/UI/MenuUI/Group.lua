BeardLib.Items.Group = BeardLib.Items.Group or class(BeardLib.Items.Menu)
local Group = BeardLib.Items.Group
Group.type_name = "Group"
Group.GROUP = true
Group.HYBRID = true

function Group:Init(...)
    Group.super.Init(self, ...)
    self:InitBasicItem()
    self:GrowHeight()
end

function Group:InitBasicItem()
    Group.super.InitBasicItem(self)
    if not self.divider_type then
	    self.toggle = self.panel:bitmap({
	        name = "toggle",
	        w = self.title:h() * 0.78,
	        h = self.title:h() * 0.78,
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
            local s = self.title:font_size() * 0.78
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

function Group:UpdateGroup()
    if self.closed then
        self.panel:set_h(self:TextHeight())
    end
    if not self.divider_type then
        for i, item in pairs(self._my_items) do
            if item:ParentPanel() == self:ItemsPanel() and (item.visible or item._hidden_by_menu) then --handle only visible items.
                item:SetVisible(not self.closed)
                if self.closed then
                    item._hidden_by_menu = true
                end
            end
        end
        if alive(self.toggle) then
            self.toggle:set_texture_rect(self.closed and 42 or 2, self.closed and 2 or 0, 16, 16)
        end
        self:_SetSize()
    end
    if not self.divider_type or self.auto_align then
        self:_AlignItems()
    end
end

function Group:_SetSize(w, h)
	if self.closed then
		h = self:TextHeight()
	end
	return Group.super._SetSize(self, w, h)
end

function Group:ToggleGroup()
    self.closed = not self.closed
    self:UpdateGroup()
end

function Group:CloseGroup()
    self.closed = true
    self:UpdateGroup()
end

function Group:OpenGroup()
    self.closed = false
    self:UpdateGroup()
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

Group.MouseMoved = BeardLib.Items.Item.MouseMoved

function Group:GetToolbar()
    if not alive(self.tb) then
        self.tb = self:ToolBar({
            name = "Toolbar",
            label = "Toolbar",
            ignore_align = true,
            position = "RightTop",
            full_bg_color = false,
            align_method = "grid_from_right",
            h = self.highlight_bg:h(),
            auto_height = false,
            use_main_panel = true
        })
    end
    return self.tb
end

function Group:NewItem(item, ...)
	if self.closed then
		item:SetVisible(false)
		item._hidden_by_menu = true
	end
	return Group.super.NewItem(self, item, ...)
end