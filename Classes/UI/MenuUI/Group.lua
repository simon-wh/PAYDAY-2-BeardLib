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
    self.toggle = self.panel:bitmap({
        name = "toggle",
        visible = not self.divider_type,
        w = self.size * 0.78,
        h = self.size * 0.78,
        texture = "guis/textures/menu_ui_icons",
        color = self:GetForeground(),
        y = 2,
        texture_rect = {self.closed and 67 or 0, self.closed and 32 or 0, 32, 32},
        layer = 3,
    })
    self:RePositionToggle()
end

function Group:RePositionToggle()
    if self:title_alive() then
        local _,_,w,_ = self.title:text_rect()
        if alive(self.toggle) then
            local s = self.size * 0.78
            self.toggle:set_size(s, s)
            self.toggle:set_x(w + self.text_offset[1] + 4)
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

    local function fix_texts(o)
        for _, child in pairs(o:children()) do
            local t = type_name(child)
            if t == "Text" then
                local t = child:text()
                child:set_text("")
                child:set_text(t)
            elseif t == "Panel" then
                fix_texts(child)
            end
        end
    end

    if not self.divider_type then
        for _, item in pairs(self._my_items) do
            if item:ParentPanel() == self:ItemsPanel() then
                item._hidden_by_menu = self.closed
                item:TryRendering()
                -- Weird glitch that makes the title invisible. Changing its 'x' position solves it.
                fix_texts(self:Panel())
            end
        end
        self:CheckItems()
        if alive(self.toggle) then
            self.toggle:set_texture_rect(self.closed and 67 or 0, self.closed and 32 or 1, 32, 32)
        end
        self:_SetSize()
        self:AlignItems(true, nil, true)
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
    if self.on_group_toggled then
        self.on_group_toggled(self)
    end
end

function Group:CloseGroup()
    self.closed = true
    self:UpdateGroup()
    if self.on_group_toggled then
        self.on_group_toggled(self)
    end
end

function Group:OpenGroup()
    self.closed = false
    self:UpdateGroup()
    if self.on_group_toggled then
        self.on_group_toggled(self)
    end
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

function Group:GetToolbar(opt)
    if not alive(self.tb) then
        self.tb = self:ToolBar(table.merge({
            name = "Toolbar",
            label = "Toolbar",
            inherit_values = {
                foreground = self.foreground,
            },
            inherit = self,
            ignore_align = true,
            position = "Right",
            full_bg_color = false,
            align_method = "grid_from_right",
            h = self.highlight_bg:h(),
            auto_height = false,
            use_main_panel = true
        }, opt or {}))
    end
    return self.tb
end

function Group:NewItem(item, ...)
	if self.closed and not item.use_main_panel then
		item._hidden_by_menu = true
	end
	return Group.super.NewItem(self, item, ...)
end