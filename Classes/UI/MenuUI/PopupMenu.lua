BeardLib.Items.PopupMenu = BeardLib.Items.PopupMenu or class(BeardLib.Items.Item)
local PopupMenu = BeardLib.Items.PopupMenu
PopupMenu.type_name = "PopupMenu"
PopupMenu.MENU = true
function PopupMenu:InitBasicItem()
    PopupMenu.super.InitBasicItem(self)

    self._scroll = ScrollablePanelModified:new(self.menu._panel, "ItemsPanel", {
        layer = self.parent._popup_menu and self.parent._popup_menu:layer() + 100 or 100,
        padding = 0,
        scroll_width = self.scrollbar == false and 0 or self.scroll_width,
		hide_shade = true,
        debug = self.debug,
        change_width = true,
        color = self.scroll_color or self.highlight_color,
        hide_scroll_background = self.hide_scroll_background,
        scroll_speed = self.scroll_speed
    })
    self._popup_menu = self._scroll:panel()
    self._popup_menu:set_visible(false)
    self._popup_menu:bitmap({
        name = "background",
        halign = "grow",
        valign = "grow",
        visible = self.context_background_visible,
        render_template = self.context_background_blur and "VertexColorTexturedBlur3D",
        texture = self.context_background_blur and "guis/textures/test_blur_df",
        color = self.context_background_color,
        alpha = self.context_background_alpha
    })
    self.items_panel = self._scroll:canvas()
 end

function PopupMenu:WorkParams(params)
    self.auto_height = NotNil(self.auto_height, true)
    self:WorkParam("offset", 0)
    self:WorkParam("keep_menu_open", false)
    self:WorkParam("size_by_text", true)
    self.inherit_values = self.inherit_values or {}
    self.inherit_values.size_by_text = NotNil(self.inherit_values.size_by_text, true)

    PopupMenu.super.WorkParams(self, params)
end

function PopupMenu:RepositionPopupMenu()
	local size = (self.font_size or self.size)
	local offset_y = self.context_screen_offset_y or 32
    local bottom_h = (self.menu._panel:world_bottom() - self.panel:world_bottom()) - offset_y
    local top_h = (self.menu._panel:world_y() - self.panel:world_y()) - offset_y

    self:AlignItems()
	local items_h = self.items_panel:h()
	local normal_pos
	local best_h = items_h

    if items_h < bottom_h then
		normal_pos = true
	elseif items_h < top_h then
		normal_pos = false
	elseif bottom_h >= top_h then
		normal_pos = true
		best_h = bottom_h
	else
		normal_pos = false
		best_h = top_h
	end

    self._scroll:set_size(self._popup_menu:w(), best_h)

    local x_pos = self.panel:world_x()
    if (x_pos + self._popup_menu:w()) < self.menu._panel:w() then
        self._popup_menu:set_world_x(x_pos)
    else
        self._popup_menu:set_world_right(self.panel:world_right())
    end

    if normal_pos then
        self._popup_menu:set_world_y(self.panel:world_bottom())
    else
        self._popup_menu:set_world_bottom(self.panel:world_y())
	end
end

function PopupMenu:UpdateCanvas(h)
    if not self:alive() then
        return
	end

	if not self.auto_height and h < self._scroll:scroll_panel():h() then
		h = self._scroll:scroll_panel():h()
    end

    local max_w = 0
    for i, panel in pairs(self.items_panel:children()) do
		local item = panel:script().menuui_item
		if (item and item.visible) or panel:visible() then
			local w = panel:right()
			if max_w < w then
				max_w = w
			end
		end
    end

    self._scroll:set_size(max_w + self._scroll._scroll_bar:w(), self._popup_menu:h())
	self._scroll:set_canvas_size(nil, h)
end

function PopupMenu:MousePressed(b, x, y)
	if self.menu_type and self.opened and self:MousePressedMenuEvent(b, x, y) then
		return true
	else
		return self:MousePressedSelfEvent(b, x, y)
	end
end

function PopupMenu:Open()
    if not self.menu._popupmenu then
        self.menu._popupmenu = self
    end
    self._popup_menu:show()
    self.opened = true
    self:RepositionPopupMenu()
end

function PopupMenu:Close()
    if self.opened then
        if self.menu._popupmenu == self then
            self.menu._popupmenu = nil
        end
        self.opened = false
        self._popup_menu:hide()
    end
end

function PopupMenu:MousePressedMenuEvent(...)
    local ret, item = PopupMenu.super.MousePressedMenuEvent(self, ...)
    if not self.keep_menu_open and ret and item.type_name == "Button" then
        self:Close()
    end
    return ret, item
end

function PopupMenu:MousePressedSelfEvent(button, x, y)
    if self.opened and self._popup_menu:inside(x,y) then
        return true
    end

    if not self:MouseCheck(true) then
        self:Close()
        return false, self.UNCLICKABLE
    end

	if self:MouseInside(x,y) then
        if self.on_click then
			if self.on_click(self, button, x, y) == false then
				return false, self.INTERRUPTED
			end
		end
        if button == self.click_btn then
            if self.opened then
                self:Close()
            else
                self:Open()
            end
            return true
        end
        self:Close()
		return false, self.CLICKABLE
    else
        self:Close()
		return false
    end
end

function PopupMenu:MouseFocused(x, y)
    if not x and not y then
        x,y = managers.mouse_pointer._mouse:world_position()
    end
    return self:alive() and ((self.opened and self._popup_menu:inside(x,y)) or self.panel:inside(x,y)) and self:Visible()
end

function PopupMenu:MouseMoved(x,y)
	return (self.menu_type and self.opened and self:MouseMovedMenuEvent(x,y)) or self:MouseMovedSelfEvent(x,y)
end

function PopupMenu:ItemsPanel() return self.items_panel end