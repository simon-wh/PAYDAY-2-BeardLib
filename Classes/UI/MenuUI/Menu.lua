BeardLib.Items.Menu = BeardLib.Items.Menu or class(BeardLib.Items.Item)
local Menu = BeardLib.Items.Menu
Menu.type_name = "Menu"
Menu.MENU = true
function Menu:Init(params)
    self:WorkParams(params)
    self.menu_type = true
    self:InitBasicMenu()
    self._scroll = ScrollablePanelModified:new(self.panel, "ItemsPanel", {
        layer = 4,
        padding = 0,
        scroll_width = self.scrollbar == false and 0 or self.scroll_width,
		hide_shade = true,
		debug = self.debug,
        color = self.scroll_color or self.highlight_color,
        hide_scroll_background = self.hide_scroll_background,
        scroll_speed = self.scroll_speed
    })
    self.items_panel = self._scroll:canvas()
    self._my_items = self._my_items or {}
    self._reachable_items = self._reachable_items or {}
    self._visible_items = {}
    self:Reposition()
    self:SetEnabled(self.enabled)
    self:SetVisible(self.visible)
end

function Menu:GrowHeight()
    if self.auto_align then
        self:_AlignItems()
    end
end

function Menu:SetScrollSpeed(speed)
    self.scroll_speed = speed
    if not managers.menu:is_pc_controller() then
        self.scroll_speed = self.scroll_speed * 0.5
    end
    self._scroll._scroll_speed = self.scroll_speed
end

function Menu:ReloadInterface() --Unused
    self.panel:child("background"):configure({
       --visible = self.background_color ~= nil and self.background_visible,
       --render_template = self.background_blur and "VertexColorTexturedBlur3D" or "VertexColorTextured",
       --texture = self.background_blur and "guis/textures/test_blur_df" or "units/white_df",
        color = self.background_color,
        alpha = self.background_alpha,
    })
    self._scroll:set_scroll_color(self.scroll_color or self.highlight_color)
    self:RecreateItems()
end

function Menu:WorkParams(params)
    Menu.super.WorkParams(self, params)
    params = params or {}
    self:WorkParam("scroll_width", 8)
    self.background_visible = NotNil(self.background_visible, self.type_name == "Menu" and true or false)
    self.private.background_color = NotNil(self.private.background_color, self.background_visible and self.background_color or nil)
    self.auto_height = NotNil(self.auto_height, self.h == nil or self.HYBRID and true or false)
    self.scrollbar = NotNil(self.scrollbar, self.auto_height ~= true or self.min_height ~= nil or self.max_height ~= nil)
end

function Menu:SetSize(w, h)
    self.orig_h = h
    self:_SetSize(w, h)
end

function Menu:_SetSize(w, h)
    if not self:alive() then
        return
	end

	w = w or self.w
	h = h or self.orig_h or self.h
	h = math.clamp(h, self.min_height or 0, self.max_height or h)

	self.panel:set_size(w, h)
	self:SetScrollPanelSize()
    self.w, self.h = self.panel:size()
    self:Reposition()
    self:MakeBorder()
end

function Menu:ScrollY()
    return self.items_panel:y()
end

function Menu:SetScrollY(y)
    self.items_panel:set_y(y)
    self:CheckItems()
    self._scroll:_check_scroll_indicator_states()
end

function Menu:SetScrollPanelSize()
    if not self:alive() or not self._scroll:alive() then
        return
    end
    self._scroll:set_size(self.panel:w(), self.panel:h() - self:TextHeight())
	self._scroll:panel():set_bottom(self.panel:h())
	self._scroll:force_scroll()
end

function Menu:UpdateCanvas(h)
    if not self:alive() then
        return
	end

	if not self.auto_height and h < self._scroll:scroll_panel():h() then
		h = self._scroll:scroll_panel():h()
	end

	self._scroll:set_canvas_size(nil, h)
	self:_SetSize(nil, self.auto_height and self.items_panel:h() + self:TextHeight() or nil)
end

Menu.MousePressed = Menu.MousePressedMenuEvent
Menu.MouseMoved = Menu.MouseMovedMenuEvent

function Menu:MouseReleased(b,x,y)
    self._scroll:mouse_released(b,x,y)
    return Menu.super.MouseReleased(self, b, x, y)
end

function Menu:ItemsPanel() return self.items_panel end