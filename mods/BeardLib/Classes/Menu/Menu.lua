Menu = Menu or class(Item)
Menu.type_name = "Menu"
function Menu:Init(params)
    self:WorkParams(params)
    self.menu_type = true
    self.panel = self.parent_panel:panel({
        name = self.name .. "_panel",
        w = self.w,
        h = self.h,
        visible = self.visible == true,
        layer = self.layer or 1,
    })
    self.panel:rect({
        name = "background",
        halign = "grow",
        valign = "grow",
        visible = self.background_color ~= nil and self.background_visible,
        render_template = self.background_blur and "VertexColorTexturedBlur3D",
        texture = self.background_blur and "guis/textures/test_blur_df",
        color = self.background_color,
        alpha = self.background_alpha,
        layer = 0
    })
    self._scroll = ScrollablePanelModified:new(self.panel, "ItemsPanel", {
        layer = 4, 
        padding = 0.0001, 
        scroll_width = self.scrollbar == false and 0 or self.scroll_width, 
        hide_shade = true, 
        color = self.scroll_color or self.marker_highlight_color,
        scroll_speed = 48
    })
    self.items_panel = self._scroll:canvas()
    self._my_items = self._my_items or {}
    self._all_items = self._all_items or {}
    self._reachable_items = self._reachable_items or {}
    self._visible_items = {}
    self:Reposition()
    if self.auto_align then
        self:AlignItems()
    end
    self:SetScrollPanelSize()
    self:SetEnabled(self.enabled)
    self:SetVisible(self.visible)
end

function Menu:ReloadInterface()
    self.panel:child("background"):configure({
       --visible = self.background_color ~= nil and self.background_visible,
       --render_template = self.background_blur and "VertexColorTexturedBlur3D" or "VertexColorTextured",
       --texture = self.background_blur and "guis/textures/test_blur_df" or "units/white_df",
        color = self.background_color,
        alpha = self.background_alpha,        
    })
    self._scroll:set_scroll_color(self.scroll_color or self.marker_highlight_color)
    self:RecreateItems()
end

function Menu:WorkParams(params)
    params = params or {}
    table.careful_merge(self, clone(params))
    self.name = self.name or ""
    self.text_color = self.text_color or self.menu.text_color or (self.background_color and self.background_color:contrast() or Color.white)
    self.text_highlight_color = self.text_highlight_color or self.menu.text_highlight_color
    self.items_size = self.items_size or self.menu.items_size or 16
    self.marker_color = self.marker_color or self.menu.marker_color or Color.white:with_alpha(0)
    self.marker_alpha = self.marker_alpha or self.menu.marker_alpha 
    self.align = self.align or self.menu.align
    self.background_visible = NotNil(self.background_visible, self.type_name == "Menu" and true or false)
    self.font = self.font or tweak_data.menu.pd2_large_font or tweak_data.menu.default_font
    self.offset = self.offset and self:ConvertOffset(self.offset) or self:ConvertOffset(self.menu.offset)
    self.private_offset = self.private_offset and self:ConvertOffset(self.private_offset)
    self.control_slice = self.control_slice or self.menu.control_slice or 2
    self.auto_align = NotNil(self.auto_align, true)
    self.text_offset = self.text_offset or self.menu.text_offset or 4
    self.scroll_width = self.scroll_width or 8
    self.auto_height = NotNil(self.auto_height, self.type_name == "Group" and true or false)
    self.accent_color = NotNil(self.accent_color, self.menu.accent_color)
    self.scroll_color = NotNil(self.scroll_color, self.menu.scroll_color, self.accent_color)
    self.slider_color = NotNil(self.slider_color, self.menu.slider_color, self.accent_color)
    self.scrollbar = NotNil(self.scrollbar, self.auto_height ~= true)
    self.visible = NotNil(self.visible, true)
    self.enabled = NotNil(self.enabled, true)
    self.disabled_alpha = NotNil(self.disabled_alpha, 0.5)
    self.should_render = true
    local w = self.menu._panel:w()
    if self.w == "full" then
        self.w = self.menu._panel:w()
    elseif self.w == "half" then
        self.w = self.menu._panel:w() / 2
    end
end

function Menu:SetLayer(layer)
    self.super.SetLayer(self, layer)
end

function Menu:SetSize(w, h, no_recreate)
    if not self:alive() then
        return
    end
    w = w or self.w
    h = self.closed and 0 or (h or self.orig_h or self.h)
    h = math.clamp(h, self.min_height or 0, self.max_height or h)
    self.orig_h = h
    if self:title_alive() then
        local _,_,_,th = self.title:text_rect()
        h = h + th
    end
    self.panel:set_size(w, h)
    self:SetScrollPanelSize()
    self.w = w
    self.h = h
    self:Reposition()
    if not no_recreate then
        self:RecreateItems()
    end
    self:MakeBorder()
end

function Menu:SetScrollPanelSize()
    if not self:alive() or not self._scroll:alive() then
        return
    end
    local has_title = self:title_alive()
    if has_title then
        local _,_,_,h = self.title:text_rect()
        self._scroll:set_size(self.panel:w(), self.panel:h() - h)
    else
        self._scroll:set_size(self.panel:size()) 
    end
    if has_title then
       local _,_,_,h = self.title:text_rect()
       self._scroll:panel():set_bottom(self:Height())
    end
end

function Menu:KeyPressed(o, k)
    if self:Enabled() and (self:MouseFocused(x, y) or self.reach_ignore_focus) then
        local dir = k == Idstring("down") and 1 or k == Idstring("up") and -1
        local h = self.menu._highlighted
        local next_item
        if dir then
            local next_index = (h and table.get_key(self._reachable_items, h) or (dir == 1 and 0 or #self._reachable_items)) + dir
            if next_index > #self._reachable_items then
                next_index = 1
            elseif next_index < 1 then
                next_index = #self._reachable_items
            end
            next_item = self._reachable_items[next_index]
        end
        if next_item then
            next_item:Highlight()
            return true
        end
    end
end

function Menu:MouseDoubleClick(button, x, y)
    local menu = self.menu
    if self:Enabled() then
        if menu._highlighted and menu._highlighted.parent == self then
            if menu._highlighted.MouseDoubleClick and menu._highlighted:MouseDoubleClick(button, x, y) then
                return true
            end
        end
    end
end

function Menu:MousePressed(button, x, y)
    local menu = self.menu
    if self:Enabled() then
        for _, item in ipairs(self._visible_items) do
            if item:MousePressed(button, x, y) then
                return true
            end
        end
        if button == Idstring("0") then
            if self._scroll:mouse_pressed(button, x, y) then
                menu._scroll_hold = true
                self:CheckItems()
                return true
            end     
        elseif button == Idstring("mouse wheel down") and self.scrollbar and self._scroll:is_scrollable() then
            if self._scroll:scroll(x, y, -1) then
                if menu._highlighted and menu._highlighted.parent == self then
                    menu._highlighted:MouseMoved(x,y)
                end 
                self:CheckItems()
                return true
            end
        elseif button == Idstring("mouse wheel up") and self.scrollbar and self._scroll:is_scrollable() then
            if self._scroll:scroll(x, y, 1) then
                if menu._highlighted and menu._highlighted.parent == self then
                    menu._highlighted:MouseMoved(x,y)
                end 
                self:CheckItems()
                return true
            end
        end
    end
end

function Menu:MouseMoved(x, y)
    if self:Enabled() and self:MouseFocused(x, y) then
        local _, pointer = self._scroll:mouse_moved(nil, x, y) 
        if pointer then
            self:CheckItems()
            if managers.mouse_pointer.set_pointer_image then
                managers.mouse_pointer:set_pointer_image(pointer)
            end
            return true
        else
            if managers.mouse_pointer.set_pointer_image then
                managers.mouse_pointer:set_pointer_image("arrow")
            end
        end
        for _, item in ipairs(self._visible_items) do
            if item:MouseMoved(x, y) then
                return true
            end
        end
    end
end

function Menu:CheckItems()
    self._visible_items = {}
    for _, item in ipairs(self._all_items) do
        if item:TryRendering() then
            table.insert(self._visible_items, item)
        end                
    end
end

function Menu:MouseReleased(button, x, y)
    self._scroll:mouse_released(button, x, y)
    managers.mouse_pointer:set_pointer_image("arrow")
    for _, item in ipairs(self._all_items) do
        if item:MouseReleased(button, x, y) then
            return true
        end
    end
end

function Menu:SetEnabled(enabled)
	Item.super.SetEnabled(self, enabled)
	self.panel:set_alpha(enabled and 1 or self.disabled_alpha)
	for _, v in pairs({"left", "top", "right", "bottom"}) do
		local side = self.panel:child(v)
		if alive(side) then
			side:set_alpha(enabled and 1 or self.disabled_alpha)
		end
	end
end

function Menu:SetVisible(visible, animate)
    local panel = self:Panel()
    if not alive(panel) then
        return
    end
    local was_visible = self.visible
    Item.super.SetVisible(self, visible, true)
    if animate and visible and not was_visible then
        panel:set_alpha(0)
        QuickAnim:Work(panel, "alpha", 1, "speed", 5)
    end
    self.menu:CheckOpenedList()
end

function Menu:AlignItemsGrid()
    if not self:alive() then
        return
    end
    local prev_item
    local max_h = 0
    local max_x = 0
    local max_y = 0
    for i, item in ipairs(self._my_items) do
        if not item.ignore_align and item:Visible() then
            local offset = item:Offset()
            local panel = item:Panel()
            if panel:w() + (max_x + offset[1]) > self:ItemsWidth() then
                max_y = max_h
                max_x = 0
            end
            panel:set_position(max_x + offset[1], max_y + offset[2])
            local repos = item:Reposition()
            if not repos or item.count_as_aligned then
                prev_item = item
                max_x = math.max(max_x, panel:right())
            end
            if (not repos or item.count_as_aligned or item.count_height) then
                max_h = math.max(max_h, panel:bottom())
            end
        end
    end    
    max_h = max_h + (prev_item and prev_item:Offset()[2] or 0)
    if self.auto_height and self.orig_h ~= max_h then
        self:SetSize(nil, max_h, true)
    end
    self:UpdateCanvas()
end

function Menu:AlignItems(menus)
    if self.align_method == "grid" then
        self:AlignItemsGrid()
    else
        self:AlignItemsNormal()
    end
    if self.parent.AlignItems then
        self.parent:AlignItems()
    end
    if menus then
        for _, item in ipairs(self._my_items) do
            if item.menu_type then
                item:AlignItems(true)
            end
        end
    end
end

function Menu:AlignItemsNormal()
    if not self:alive() then
        return
    end
    local max_h = 0
    local prev_item
    for i, item in ipairs(self._my_items) do
        if not item.ignore_align and item:Visible() then
            local offset = item:Offset()
            local panel = item:Panel()
            panel:set_x(offset[1])
            panel:set_y(offset[2])
            if alive(prev_item) then
                panel:set_world_y(prev_item:Panel():world_bottom() + offset[2])
            end
            local repos = item:Reposition()
            if not repos or item.count_as_aligned then
                prev_item = item
            end
            if not repos or item.count_as_aligned or item.count_height then
                max_h = math.max(max_h, panel:bottom())
            end
        end
    end
    max_h = max_h + (prev_item and prev_item:Offset()[2] or 0)
    if self.auto_height and self.orig_h ~= max_h then
        self:SetSize(nil, max_h, true)
    end
    self:UpdateCanvas()
end

function Menu:UpdateCanvas()
    if not self:alive() then
        return
    end
    if self.type_name == "Group" then
        self:SetScrollPanelSize()
    end
    self._scroll:update_canvas_size()
    self:CheckItems()
end

function Menu:GetMenu(name, shallow)
    for _, menu in pairs(self._all_items) do
        if menu.menu_type then
            if menu.name == name then
                return menu
            elseif not shallow then
                local item = menu:GetMenu(name)
                if item and item.name then
                    return item
                end
            end
        end
    end
    return false
end

function Menu:GetItem(name, shallow)
    for _, item in pairs(self._all_items) do
        if item.name == name then
            return item
        elseif item.menu_type and not shallow then
            local i = item:GetItem(name)
            if i then
                return i
            end
        end
    end
    return nil
end

function Menu:ClearItems(label)
    local temp = clone(self._all_items)
    self._all_items = {}
    self._my_items = {}
    self._reachable_items = {}
    for _, item in pairs(temp) do
        if not label or type(label) == "table" and item.override_parent == label or item.label == label then
            self:RemoveItem(item)
        else
            if item:alive() and not item.override_parent or alive(item.override_parent) then
                table.insert(self._all_items, item)
                if item.override_parent == nil then
                    table.insert(self._my_items, item)
                end
                if item.reachable then
                    table.insert(self._reachable_items, item)
                end
            end
        end
    end
    self.menu:CheckOpenedList()
    if self.auto_align then
        self:AlignItems(true)
    end
    self:UpdateCanvas()
end

function Menu:RecreateItems()
    for _, item in pairs(self._all_items) do
        self:RecreateItem(item)
    end
    if self.auto_align then
        self:AlignItems(true)
    end
end

function Menu:RecreateItem(item, align_items)
    if item.list then
        item.list:parent():remove(item.list)
    end
    local panel = item:Panel()
    if alive(panel) then
        panel:parent():remove(panel)
    end
    if item.override_parent then
        table.delete(item.override_parent._my_items, item)
    end
    item.parent_panel = (item.override_parent and item.override_parent:Panel()) or self.items_panel
    item:Init()
    if item.menu_type then
        item:RecreateItems()
    end
    if align_items then
        self:AlignItems(true)
    end
end

function Menu:RemoveItem(item)
    if not item then
        return
    end
    if item.menu_type then
        item:ClearItems()
    elseif item._my_items then
        for _, v in pairs(item._my_items) do
            v.override_parent = nil
            self:RemoveItem(v)
        end
    end

    if item.override_parent then
        table.delete(item.override_parent._my_items, item)
    end
    if item.list then
        item.list:parent():remove(item.list)
    end
    table.delete(self._reachable_items, item)
    table.delete(self._my_items, item)
    table.delete(self._all_items, item)
    local panel = item:Panel()
    if alive(panel) then
        panel:parent():remove(panel)
    end
    if self.auto_align then
        self:AlignItems()
    end
end

function Menu:ShouldClose()
    for _, item in pairs(self._all_items) do
        if item.menu_type and not item:ShouldClose() then
            return false
        end
        if (item._textbox and item._textbox.cantype) or item.CanEdit then
            return false
        end
    end
    return true
end

function Menu:ItemsWidth() return self.items_panel:w() end
function Menu:ItemsHeight() return self.items_panel:h() end

function Menu:ImageButton(params)
    local w = params.w or not params.icon_h and params.items_size
    local h = params.h or params.icon_h or params.items_size
    local _params = self:ConfigureItem(params)
    _params.w = w or _params.w
    _params.h = h or _params.h or _params.items_size
    return self:NewItem(ImageButton:new(_params))
end

function Menu:Group(params) return self:NewItem(Group:new(self:ConfigureItem(params, true))) end
function Menu:Menu(params) return self:NewItem(Menu:new(self:ConfigureItem(params, true))) end
function Menu:Button(params) return self:NewItem(Item:new(self:ConfigureItem(params))) end
function Menu:ComboBox(params) return self:NewItem(ComboBox:new(self:ConfigureItem(params))) end
function Menu:TextBox(params) return self:NewItem(TextBox:new(self:ConfigureItem(params))) end
function Menu:ComboBox(params) return self:NewItem(ComboBox:new(self:ConfigureItem(params))) end
function Menu:Slider(params) return self:NewItem(Slider:new(self:ConfigureItem(params))) end
function Menu:Table(params) return self:NewItem(Table:new(self:ConfigureItem(params)))end
function Menu:KeyBind(params) return self:NewItem(KeyBindItem:new(self:ConfigureItem(params))) end
function Menu:Toggle(params) return self:NewItem(Toggle:new(self:ConfigureItem(params))) end
function Menu:ItemsGroup(params) return self:Group(params) end --Deprecated--

function Menu:NumberBox(params)
    local _params = self:ConfigureItem(params)
    _params.type_name = "NumberBox"
    _params.filter = "number"
    return self:NewItem(TextBox:new(_params))
end

function Menu:Divider(params)
    local _params = self:ConfigureItem(params)
    _params.divider_type = true
    return self:NewItem(Item:new(_params))
end

function Menu:DivGroup(params)
    local _params = self:ConfigureItem(params)
    _params.divider_type = true
    return self:NewItem(Group:new(_params))
end

function Menu:GetIndex(name)
    for k, item in pairs(self._my_items) do
        if item.name == name then
            return k
        end
    end
    return 1
end

function Menu:ConvertOffset(offset)
    if offset then
        if type(offset) == "number" then
            return {offset, offset}
        else
            return offset
        end
    else
        return {6,2}
    end
end

function Menu:ConfigureItem(item, menu)
    item = clone(item)
    if type(item) ~= "table" then
        log(tostring(debug.traceback()))
        return
    end
    if item.override_parent == self then
        item.override_parent = nil
    end
    local inherit = NotNil(item.inherit_from, item.override_parent, self)
    item.inherit_from = inherit
    item.parent = self
    item.menu = self.menu
    item.enabled = NotNil(item.enabled, true)
    item.visible = NotNil(item.visible, true)
    item.text_color = item.text_color or (item.marker_color and item.marker_color.a > 0.5 and item.marker_color:contrast()) or inherit.text_color
    item.name = NotNil(item.name, item.text)
    item.text = item.text or item.text ~= false and item.name
    item.text_highlight_color = NotNil(item.text_highlight_color, item.marker_highlight_color and item.marker_highlight_color.a > 0.5 and item.marker_highlight_color:contrast(), inherit.text_highlight_color)
    item.items_size = item.items_size or inherit.items_size
    item.marker_highlight_color = NotNil(item.marker_highlight_color, inherit.marker_highlight_color)
    item.marker_color = item.marker_color or inherit.marker_color
    item.background_color = item.background_color or inherit.background_color
    item.background_alpha = item.background_alpha or inherit.background_alpha
    item.marker_alpha = item.marker_alpha or inherit.marker_alpha
    item.text_align = item.text_align or inherit.text_align or "left"
    item.text_vertical = item.text_vertical or inherit.text_vertical or "top"
    item.border_color = item.border_color or inherit.border_color
    item.size_by_text = NotNil(item.size_by_text, inherit.size_by_text)
    item.parent_panel = (item.override_parent and item.override_parent.panel) or self.items_panel
    item.offset = item.offset and self:ConvertOffset(item.offset) or self:ConvertOffset(inherit.offset)
    item.private_offset = item.private_offset and self:ConvertOffset(item.private_offset)
    item.w = (item.w or item.parent_panel:w()) - (item.size_by_text and 0 or item.offset[1] * 2)
    item.w = math.clamp(item.w, item.min_width or 0, item.max_width or item.w)
    item.control_slice = item.control_slice or inherit.control_slice
    item.font = item.font or inherit.font
    item.text_offset = item.text_offset or inherit.text_offset
    item.border_size = item.border_size or inherit.border_size or 2
    item.accent_color = item.accent_color or inherit.accent_color
    item.scroll_color = item.scroll_color or inherit.scroll_color or item.accent_color
    item.should_render = true
    item.disabled_alpha = NotNil(item.disabled_alpha, 0.5)
    if type(item.index) == "string" then
        local split = string.split(item.index, "|")
        local wanted_item = self:GetItem(split[2] or split[1]) 
        if wanted_item then
            item.index = wanted_item:Index() + (split[1] == "After" and 1 or split[1] == "Before" and -1 or 0)
        else
            BeardLib:log("Could not create index from string, %s, %s", tostring(item.index), tostring(item))
            item.index = nil
        end
    end
    item.indx = item.indx or item.index
    item.index = nil
    return item
end

function Menu:NewItem(item)
    local index
    if not item.override_parent and item.indx then
        table.insert(self._all_items, item.indx, item)
    else
        table.insert(self._all_items, item)
    end
    if item.override_parent == nil then
        if item.indx then
            table.insert(self._my_items, item.indx, item)
        else
            table.insert(self._my_items, item)
            index = #self._my_items
        end
    end
    if item.reachable then
        table.insert(self._reachable_items, item)
    end
    item.indx = item.indx or index
    item:SetEnabled(item.enabled)
    item:SetVisible(item.visible)
    if item.highlight then
        item:Highlight()
    end
    if self.auto_align then self:AlignItems() end
    return item
end