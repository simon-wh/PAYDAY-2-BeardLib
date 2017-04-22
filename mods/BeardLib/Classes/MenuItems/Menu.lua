Menu = Menu or class(Item)
Menu.type_name = "Menu"
function Menu:Init()
    self:WorkParams()
    self.menu_type = true
    self.panel = self.parent_panel:panel({
        name = self.name .. "_panel",
        w = self.w,
        h = self.h,
        visible = self.visible == true,
        layer = 1,
    })
    self.panel:rect({
        name = "background",
        halign="grow",
        valign="grow",
        visible = self.background_color ~= nil and self.background_visible,
        color = self.background_color,
        alpha = self.background_alpha,
        layer = 0
    })
    self._scroll = ScrollablePanelModified:new(self.panel, "ItemsPanel", {
        layer = 4, 
        padding = 0.0001, 
        scroll_width = self.scrollbar == false and 0 or self.scroll_width, 
        hide_shade = true, 
        scroll_color = self.marker_highlight_color,
        scroll_speed = 48
    })
    self.items_panel = self._scroll:canvas()
    self._my_items = {}
    self._all_items = {}
    self._visible_items = {}
    self:Reposition()
    self:AlignItems()
end

function Menu:WorkParams()
    local NotNilOr = function(a,b)
        if a == nil then
            return b
        end
        return a
    end
    self.text_color = self.text_color or self.menu.text_color or Color.white
    self.text_highlight_color = self.text_highlight_color or self.menu.text_highlight_color or Color.white
    self.items_size = self.items_size or self.menu.items_size or 16
    self.marker_highlight_color = self.marker_highlight_color or self.menu.marker_highlight_color or Color(0.2, 0.5, 1)
    self.marker_color = self.marker_color or self.menu.marker_color or Color.white:with_alpha(0)
    self.marker_alpha = self.marker_alpha or self.menu.marker_alpha 
    self.align = self.align or self.menu.align
    self.background_visible = NotNilOr(self.background_visible, self.type_name == "Menu" and true or false)
    self.position = self.position or "Left"
    self.font = self.font or tweak_data.menu.pd2_large_font or tweak_data.menu.default_font
    self.offset = self.offset and self:ConvertOffset(self.offset) or self:ConvertOffset(self.menu.offset) 
    self.override_size_limit = self.override_size_limit or self.menu.override_size_limit
    self.control_slice = self.control_slice or self.menu.control_slice or 2
    self.auto_align = NotNilOr(self.auto_align, true)
    self.text_offset = self.text_offset or self.menu.text_offset or 4
    self.scroll_width = self.scroll_width or 8
    self.automatic_height = NotNilOr(self.automatic_height, self.type_name == "Group" and true or false)
    self.scrollbar = NotNilOr(self.scrollbar, self.automatic_height ~= true)
    local w = self.menu._panel:w()
    if self.w == "full" then
        self.w = self.menu._panel:w()
    elseif self.w == "half" then
        self.w = self.menu._panel:w() / 2
    end
    self.w = self.w or (w < 400 and w or 400)
end

function Menu:SetMaxRow(max)
    self.row_max = max
    if self.auto_align then
        self:AlignItems()
    end
end

function Menu:SetSize(w, h, no_recreate, temp)
    if not self:alive() then
        return
    end
    self.panel:set_size(w or self.w, h or self.h)
    self._scroll:set_size(self.panel:size())
    if not temp then
        self.w = w or self.w
        self.h = h or self.h
    end
    self:Reposition()
    if not no_recreate then
        self:RecreateItems()
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

function Menu:Focused()
    return self:Visible() and self.menu._highlighted and self:MouseFocused(x, y)
end

function Menu:SetVisible(visible)
    self.panel:set_visible(visible)
    self.visible = visible
    if self.menu._openlist then
        self.menu._openlist:hide()
    end
end

function Menu:AlignItemsGrid()
    local max_h = self.items_size
    local base_h = self.items_size
    local max_offset = self.offset[2]
    local x
    local y = self.type_name == "Group" and base_h or 0
    for i, item in ipairs(self._my_items) do
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
    local h = y + max_h + max_offset
    local result_h = self.closed and base_h or h
    if self.automatic_height and self.h ~= result_h then
        self:SetSize(nil, result_h, true, self.type_name == "Group")
    end
    self._scroll:update_canvas_size()
    self:CheckItems()
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
    local base_h = self.type_name == "Group" and self.items_size or 0
    local h = base_h
    local rows = 1
    for i, item in ipairs(self._my_items) do
        local offset = item.offset
        item.panel:set_x(offset[1])
        item.panel:set_y(base_h + offset[2])
        if self.row_max and i == (self.row_max * rows) + 1 then
            if i > 1 then
                item.panel:set_x(self._my_items[self.row_max * rows].panel:right() + offset[1])
            end
            rows = rows + 1
        else
            if self.row_max and self._my_items[(self.row_max * (rows - 1)) + 1] then
                item.panel:set_x(self._my_items[(self.row_max * (rows - 1)) + 1].panel:x() + offset[1])
            end
            if i > 1 then
                item.panel:set_y(self._my_items[i - 1].panel:bottom() + offset[2])
            end
            if not self.row_max or i <= self.row_max then
                h = h + item.panel:h() + item.offset[2]
            end
        end
    end
    local result_h = self.closed and base_h or h
    if self.automatic_height and self.h ~= result_h then
        self:SetSize(nil, result_h, true, self.type_name == "Group")
    end
    self._scroll:update_canvas_size()
    self:CheckItems()
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
    self.items_panel:set_y(0)
    if self.auto_align then
        self:AlignItems()
    end
end

function Menu:RecreateItems()
    self._my_items = {}
    local temp = clone(self._all_items)     
    for k, item in pairs(temp) do
        self:RemoveItem(item)
        self[item.type_name](self, item)
    end
    self.items_panel:set_y(0)
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
    for _, item in pairs(menu._all_items) do
        if item.menu_type and not item:ShouldClose() then
            return false
        end
        if item.cantype or item.CanEdit then
            return false
        end
    end
    return true
end

function Menu:KeyBind(params)
    self:ConfigureItem(params)
    return self:NewItem(KeyBindItem:new(params))
end

function Menu:Toggle(params)
    self:ConfigureItem(params)
    return self:NewItem(Toggle:new(params))
end

function Menu:ItemsGroup(params) return self:Group(params) end --Deprecated--

function Menu:Group(params)
    self:ConfigureItem(params, true)
    return self:NewItem(Group:new(params))
end

function Menu:ImageButton(params)
    self:ConfigureItem(params)
    return self:NewItem(ImageButton:new(params))
end

function Menu:Button(params)
    self:ConfigureItem(params)
    return self:NewItem(Item:new(params))
end

function Menu:ComboBox(params)
    self:ConfigureItem(params)
    return self:NewItem(ComboBox:new(params))
end

function Menu:TextBox(params)
    self:ConfigureItem(params)
    return self:NewItem(TextBox:new(params))
end

function Menu:NumberBox(params)
    self:ConfigureItem(params)
    params.type_name = "NumberBox"
    params.filter = "number"
    return self:NewItem(TextBox:new(params))
end

function Menu:ComboBox(params)
    self:ConfigureItem(params)
    return self:NewItem(ComboBox:new(params))
end

function Menu:Slider(params)
    self:ConfigureItem(params)
    return self:NewItem(Slider:new(params))
end

function Menu:Divider(params)
    self:ConfigureItem(params)
    params.divider_type = true
    return self:NewItem(Item:new(params))
end

function Menu:DivGroup(params)
    self:ConfigureItem(params)
    params.divider_type = true
    return self:NewItem(Group:new(params))
end

function Menu:Menu(params)
    self:ConfigureItem(params, true)
    return self:NewItem(Menu:new(params))
end

function Menu:Table(params)
    self:ConfigureItem(params)
    return self:NewItem(Table:new(params))
end

function Menu:GetIndex(name)
    for k, item in pairs(self._all_items) do
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
    if type(item) ~= "table" then
        log(tostring(debug.traceback()))
        return
    end
    local NotNilOr = function(a,b)
        if a == nil then
            return b
        end
        return a
    end
    item.parent = self
    item.menu = self.menu
    item.enabled = NotNilOr(item.enabled, true)
    item.visible = NotNilOr(item.visible, true)
    item.text_color = item.text_color or self.text_color
    item.text = item.text or item.name
    item.text_highlight_color = item.text_highlight_color or self.text_highlight_color
    item.items_size = item.items_size or self.items_size
    item.marker_highlight_color = item.marker_highlight_color or self.marker_highlight_color
    item.marker_color = item.marker_color or self.marker_color
    item.background_color = item.background_color or self.background_color
    item.background_alpha = item.background_alpha or self.background_alpha
    item.marker_alpha = item.marker_alpha or self.marker_alpha
    item.text_align = item.text_align or self.text_align or "left"
    item.text_vertical = item.text_vertical or self.text_vertical or "top"
    item.size_by_text = NotNilOr(item.size_by_text, self.size_by_text)
    item.parent_panel = (item.override_parent and item.override_parent.panel) or self.items_panel
    item.offset = item.offset and self:ConvertOffset(item.offset) or self.offset
    item.override_size_limit = item.override_size_limit or self.override_size_limit
    item.w = (item.w or (item.parent_panel:w() > 300 and not item.override_size_limit and 300 or item.parent_panel:w())) - (item.size_by_text and 0 or item.offset[1] * 2)
    item.control_slice = item.control_slice or self.control_slice
    item.font = item.font or self.font
    item.text_offset = item.text_offset or self.text_offset
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
end

function Menu:NewItem(item)
    if not item.override_parent and item.index then
        table.insert(self._all_items, item.index, item)
    else
        table.insert(self._all_items, item)
    end
    if item.override_parent == nil then
        if item.index then
            table.insert(self._my_items, item.index, item)
        else
            table.insert(self._my_items, item)
        end
    end
    if self.auto_align then self:AlignItems() end
    item:SetEnabled(item.enabled)
    return item
end