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
    self._my_items = {}
    self._all_items = {}
    self._visible_items = {}
    self:Reposition()
    self:AlignItems()
    self:SetScrollPanelSize()
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
    self.control_slice = self.control_slice or self.menu.control_slice or 2
    self.auto_align = NotNil(self.auto_align, true)
    self.text_offset = self.text_offset or self.menu.text_offset or 4
    self.scroll_width = self.scroll_width or 8
    self.automatic_height = NotNil(self.automatic_height, self.type_name == "Group" and true or false)
    self.accent_color = NotNil(self.accent_color, self.menu.accent_color)
    self.scroll_color = NotNil(self.scroll_color, self.menu.scroll_color, self.accent_color)
    self.slider_color = NotNil(self.slider_color, self.menu.slider_color, self.accent_color)
    self.scrollbar = NotNil(self.scrollbar, self.automatic_height ~= true)
    self.visible = NotNil(self.visible, true)
    self.should_render = true
    local w = self.menu._panel:w()
    if self.w == "full" then
        self.w = self.menu._panel:w()
    elseif self.w == "half" then
        self.w = self.menu._panel:w() / 2
    end
    self.w = self.w or (w < 400 and w or 400)
end

function Menu:SetSize(w, h, no_recreate)
    if not self:alive() then
        return
    end
    w = w or self.w
    h = h or self.h
    if self.title and CoreClass.type_name(self.title) == "Text" then
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
    local has_title = self.title and CoreClass.type_name(self.title) == "Text"
    if not self.automatic_height and has_title then
        local _,_,_,h = self.title:text_rect()
        self._scroll:set_size(self.panel:w(), self.panel:h() - (h * 2))
    else
        self._scroll:set_size(self.panel:size()) 
    end
    if has_title then
       self._scroll:set_pos(nil, self.title:h())
    end
end

function Menu:KeyPressed(o, k)
    if self.visible and self:MouseFocused(x, y) then
        local dir = k == Idstring("down") and 1 or k == Idstring("up") and -1
        local start_index = self.menu._highlighted and self.menu._highlighted:Index() or 1
        local next_item = dir and self._my_items[math.clamp(start_index + dir, 1, #self._my_items)]
        if next_item then
            next_item:Highlight()
            return true
        end
    end
end

function Menu:MouseDoubleClick(button, x, y)
    local menu = self.menu
    if self.visible then
        if menu._highlighted and menu._highlighted.parent == self then
            if menu._highlighted.MouseDoubleClick and menu._highlighted:MouseDoubleClick(button, x, y) then
                return true
            end
        end
    end
end

function Menu:MousePressed(button, x, y)
    local menu = self.menu
    if self.visible then
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
    if self.visible and self:MouseFocused(x, y) then
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
    for _, item in ipairs(self._my_items) do
        if item:TryRendering() then
            table.insert(self._visible_items, item)
        end                
    end
end

function Menu:MouseReleased(button, x, y)
    self._scroll:mouse_released(button, x, y)
    for _, item in ipairs(self._all_items) do
        if item:MouseReleased(button, x, y) then
            return true
        end
    end
end

function Menu:SetVisible(visible)
    self.panel:set_visible(visible)
    self.visible = visible
    if self.menu._openlist then
        self.menu._openlist:hide()
    end
end

function Menu:AlignItemsGrid()
    if not self:alive() then
        return
    end
    local max_h = self.items_size
    local max_offset = 0
    local x
    local y = 0
    for i, item in ipairs(self._my_items) do
        if not item.ignore_align and item:Visible() then
            local offset = item.offset
            x = x or offset[1]
            item.panel:set_position(x,y + offset[2])
            x = x + item.panel:w() + offset[1]
            if x > self.panel:w() then
                max_h = item.panel:h()
                max_offset = item.offset[2]
                x = offset[1]
                y = y + item.panel:h() + offset[2]
                item.panel:set_position(x,y)
                x = x + item.panel:w() + offset[1]
            else
                max_h = math.max(max_h, item.panel:h())
                max_offset = math.max(max_offset, item.offset[2])
            end
        end
    end    
    local h = y + max_h + max_offset
    local result_h = self.closed and 0 or h
    if self.automatic_height and self.h ~= result_h then
        self:SetSize(nil, result_h, true)
    end
    self:UpdateCanvas(max_offset)
end


function Menu:AlignItems()
    if self.align_method == "grid" then
        self:AlignItemsGrid()
    else
        self:AlignItemsNormal()
    end
    if self.parent.AlignItems then
        self.parent:AlignItems()
    end
end

function Menu:AlignItemsNormal()
    if not self:alive() then
        return
    end
    local h = 0
    local prev_item
    for i, item in ipairs(self._my_items) do
        if not item.ignore_align and item:Visible() then
            local offset = item.offset
            local panel = item:Panel()
            panel:set_x(offset[1])
            panel:set_y(offset[2])
            if alive(prev_item) then
                panel:set_y(prev_item:Panel():bottom() + offset[2])
            end
            local repos = item:Reposition()
            if not repos or item.count_as_aligned then
                prev_item = item
            end
            if not repos or item.count_as_aligned or item.count_height then
                h = h + panel:h() + item.offset[2]
            end
        end
    end
    local result_h = self.closed and 0 or h
    if self.automatic_height and self.h ~= result_h then
        self:SetSize(nil, result_h, true)
    end
    self:UpdateCanvas(0)
end

function Menu:UpdateCanvas(offset)
    if self.type_name == "Group" then
        self:SetScrollPanelSize()
    end
    self._scroll:update_canvas_size()
    if self._scroll:canvas():h() > self._scroll:scroll_panel():h() then
   --     self._scroll:set_canvas_size(nil, self._scroll:canvas():h() + offset)
    end
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
    for _, item in pairs(temp) do
        if item.menu_type then
            item:ClearItems(label)
        end
        if not label or type(label) == "table" and item.override_parent == label or item.label == label then
            self:RemoveItem(item)
        else
            if item:alive() and not item.override_parent or alive(item.override_parent) then
                table.insert(self._all_items, item)
                if item.override_parent == nil then
                    table.insert(self._my_items, item)
                end
            end
        end
    end    
    if self.menu._openlist then
        self.menu._openlist:hide()
    end
    if self.auto_align then
        self:AlignItems()
    end
    self:UpdateCanvas(0)
end

function Menu:RecreateItems()
    self._my_items = {}
    local temp = clone(self._all_items)     
    for _, item in pairs(temp) do
        self:RecreateItem(item)
    end
    self:UpdateCanvas(0)
end

function Menu:RecreateItem(item, save_index)
    item.indx = save_index and item:Index() or nil
    self:RemoveItem(item)
    self[item.type_name](self, item)
end

function Menu:RemoveItem(item)       
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
    table.delete(self._my_items, item)
    table.delete(self._all_items, item)
    if alive(item) then
        item.panel:parent():remove(item.panel)
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

function Menu:KeyBind(params)
    params = self:ConfigureItem(params)
    return self:NewItem(KeyBindItem:new(params))
end

function Menu:Toggle(params)
    params = self:ConfigureItem(params)
    return self:NewItem(Toggle:new(params))
end

function Menu:ItemsGroup(params) return self:Group(params) end --Deprecated--

function Menu:Group(params)
    params = self:ConfigureItem(params, true)
    return self:NewItem(Group:new(params))
end

function Menu:ImageButton(params)
    local w = params.w or not params.icon_h and params.items_size
    local h = params.h or params.icon_h or params.items_size
    params = self:ConfigureItem(params)
    params.w = w or params.w
    params.h = h or params.h or params.items_size
    return self:NewItem(ImageButton:new(params))
end

function Menu:Button(params)
    params = self:ConfigureItem(params)
    return self:NewItem(Item:new(params))
end

function Menu:ComboBox(params)
    params = self:ConfigureItem(params)
    return self:NewItem(ComboBox:new(params))
end

function Menu:TextBox(params)
    params = self:ConfigureItem(params)
    return self:NewItem(TextBox:new(params))
end

function Menu:NumberBox(params)
    params = self:ConfigureItem(params)
    params.type_name = "NumberBox"
    params.filter = "number"
    return self:NewItem(TextBox:new(params))
end

function Menu:ComboBox(params)
    params = self:ConfigureItem(params)
    return self:NewItem(ComboBox:new(params))
end

function Menu:Slider(params)
    params = self:ConfigureItem(params)
    return self:NewItem(Slider:new(params))
end

function Menu:Divider(params)
    params = self:ConfigureItem(params)
    params.divider_type = true
    return self:NewItem(Item:new(params))
end

function Menu:DivGroup(params)
    params = self:ConfigureItem(params)
    params.divider_type = true
    return self:NewItem(Group:new(params))
end

function Menu:Menu(params)
    params = self:ConfigureItem(params, true)
    return self:NewItem(Menu:new(params))
end

function Menu:Table(params)
    params = self:ConfigureItem(params)
    return self:NewItem(Table:new(params))
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
    item.w = (item.w or item.parent_panel:w()) - (item.size_by_text and 0 or item.offset[1] * 2)
    item.control_slice = item.control_slice or inherit.control_slice
    item.font = item.font or inherit.font
    item.text_offset = item.text_offset or inherit.text_offset
    item.border_size = item.border_size or inherit.border_size or 2
    item.accent_color = item.accent_color or inherit.accent_color
    item.scroll_color = item.scroll_color or inherit.scroll_color or item.accent_color
    item.should_render = true
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
    item.indx = item.indx or index
    item:SetEnabled(item.enabled)
    item:SetVisible(item.visible)
    if self.auto_align then self:AlignItems() end
    return item
end