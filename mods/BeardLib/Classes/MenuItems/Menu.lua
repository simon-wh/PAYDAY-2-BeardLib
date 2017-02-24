Menu = Menu or class()
function Menu:init(menu, params)
    params.text_color = params.text_color or menu.text_color or Color.white
    params.text_highlight_color = params.text_highlight_color or menu.text_highlight_color or Color.white
    params.items_size = params.items_size or menu.items_size or 16
    params.background_color = params.background_color
    params.marker_highlight_color = params.marker_highlight_color or menu.marker_highlight_color or Color(0.2, 0.5, 1)
    params.marker_color = params.marker_color or menu.marker_color or Color.white:with_alpha(0)
    params.marker_alpha = params.marker_alpha or menu.marker_alpha 
    params.align = params.align or menu.align
    params.position = params.position or "Left"
    params.offset = params.offset and self:ConvertOffset(params.offset) or self:ConvertOffset(menu.offset) 
    params.override_size_limit = params.override_size_limit or menu.override_size_limit
    params.control_slice = params.control_slice or menu.control_slice or 2
    params.auto_align = params.auto_align == nil and true or params.auto_align
    local w = menu._panel:w()  
    if params.w == "full" then
        params.w = menu._panel:w()
    elseif params.w == "half" then
        params.w = menu._panel:w() / 2
    end
    params.w = params.w or (w < 400 and w or 400)
    params.panel = menu._panel:panel({
        name = params.name .. "_panel",
        w = params.w,
        h = params.h,
        visible = params.visible == true,
        layer = 1,
    })
    params.panel:rect({
        name = "bg",
        halign="grow",
        valign="grow",
        visible = params.background_color ~= nil,
        color = params.background_color,
        alpha = params.background_alpha,
        layer = 0
    })
    self._scroll = ScrollablePanel:new(params.panel, "ItemsPanel", {layer = 4, padding = 0.0001, scroll_width = params.scrollbar == false and 0 or 8, hide_shade = true})
    params.items_panel = self._scroll:canvas()

    if not menu._first_parent then
        self.visible = self.visible or true
        menu._first_parent = self
        menu._current_menu = self
    else
        self.visible = self.visible or false
    end
    table.merge(self, params)
    self.menu = menu
    self.items = {}
    self._items = {}
    self._visible_items = {}
    self:Reposition()
    self:AlignItems()
end

function Menu:Reposition()
    local t = type(self.position)
    if t == "table" then
        self:SetPosition(unpack(self.position))
    elseif t == "function" then
        self:position(self)
    elseif t == "string" then
        self:SetPositionByString(self.position)
    end
end

function Menu:SetPositionByString(pos)
    local pos_panel = self.menu._panel
    for _, p in pairs({"center", "bottom", "top", "right", "left"}) do
        if pos:lower():match(p) then
            self.panel["set_world_"..p](self.panel, pos_panel["world_"..p](pos_panel))
        end
    end
end

function Menu:AnimatePosition(pos, position_number)
    pos = pos:lower()
    local v = position_number or self.menu._panel["world_" .. pos](self.menu._panel)
    local o_v = self.panel["world_" .. pos](self.panel)
    self.panel:animate(function(o)
        local t = 0
        while t < 0.25 do
            t = t + coroutine.yield()
            local n = 1 - math.sin(t * 360)
            o["set_world_" .. pos](o, math.lerp(v, o_v, n))
        end
        o["set_world_" .. pos](o, v)
    end)
end

function Menu:SetPosition(x,y)
    self.panel:set_position(x,y)
end

function Menu:Panel()
    return self.panel
end

function Menu:SetMaxRow(max)
    self.row_max = max
    if self.auto_align then
        self:AlignItems()
    end
end

function Menu:MouseInside()
    return self.panel:inside(managers.mouse_pointer._mouse:world_position())
end

function Menu:SetSize(w,h)
    self.panel:set_size(w or self.w,h or self.h)
    self._scroll:set_size(self.panel:size())
    self.w = w or self.w
    self.h = h or self.h
    self:Reposition()
    self:RecreateItems()
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
        if button == Idstring("0") then
            if self._scroll:mouse_pressed(button, x, y) then
                self:CheckItems()
                return true
            end     
        elseif button == Idstring("mouse wheel down") then
            if self._scroll:scroll(x, y, -1) then
                if menu._highlighted and menu._highlighted.parent == self then
                    menu._highlighted:MouseMoved(x,y)
                end 
                self:CheckItems()
                return true
            end
        elseif button == Idstring("mouse wheel up") then
            if self._scroll:scroll(x, y, 1) then
                if menu._highlighted and menu._highlighted.parent == self then
                    menu._highlighted:MouseMoved(x,y)
                end 
                self:CheckItems()
                return true
            end
        end
        if menu._highlighted and menu._highlighted.parent == self then
            if menu._highlighted:MousePressed(button, x, y) then 
                return true
            end
        end
    end
end

function Menu:MouseMoved(x, y)
    if self.visible and self.panel:inside(x,y) then
        local _, pointer = self._scroll:mouse_moved(nil, x, y) 
        if pointer then
            self:CheckItems()
            managers.mouse_pointer:set_pointer_image(pointer)
            return true
        else
            managers.mouse_pointer:set_pointer_image("arrow")
        end
        for _, item in ipairs(self._visible_items) do
            item:MouseMoved(x, y) 
        end
    end
end

function Menu:CheckItems()
    self._visible_items = {}
    for _, item in ipairs(self._items) do
        if item:TryRendering() then
            table.insert(self._visible_items, item)
        end                
    end
end

function Menu:MouseReleased(button, x, y)
    self._scroll:mouse_released(button, x, y)
end

function Menu:Focused()
    return self:Visible() and self.menu._highlighted
end

function Menu:Visible()
    return self.visible 
end

function Menu:SetVisible(visible)
    self.panel:set_visible(visible)
    self.visible = visible
    if self.menu._openlist then
        self.menu._openlist:hide()
    end
end

function Menu:AlignItems()
    local h = 0
    local rows = 1
    for i, item in ipairs(self.items) do
        local offset = item.offset
        item.panel:set_x(offset[1])            
        item.panel:set_y(offset[2])
        if self.row_max and i == (self.row_max * rows) + 1 then
            if i > 1 then
                item.panel:set_x(self.items[self.row_max * rows].panel:right() + offset[1])
            end
            rows = rows + 1
        else
            if self.row_max and self.items[(self.row_max * (rows - 1)) + 1] then
                item.panel:set_x(self.items[(self.row_max * (rows - 1)) + 1].panel:x() + offset[1])
            end
            if i > 1 then
                item.panel:set_y(self.items[i - 1].panel:bottom() + offset[2])
            end
            if not self.row_max or i <= self.row_max then
                h = h + item.panel:h() + offset[2]
            end
        end
    end
    self._scroll:update_canvas_size()
    self:CheckItems()
end

function Menu:GetItem(name)
    for _, item in pairs(self._items) do
        if item.name == name then
            return item
        end
    end
    return nil
end

function Menu:ClearItems(label)
    local temp = clone(self._items)
    self._items = {}
    self.items = {}
    for k, item in pairs(temp) do
        if not label or item.label == label then
            if alive(item.panel) then
                if item.group then
                    table.delete(item.group.items, item)
                    item.group:AlignItems()
                end
                if item.override_parent then
                    table.delete(item.group._items, item)
                end
                item.panel:parent():remove(item.panel)
            end
        else
            table.insert(self._items, item)
            if not item.group and item.override_parent == nil then
                table.insert(self.items, item)
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
    self.items = {}
    local temp = clone(self._items)     
    for k, item in pairs(temp) do
        self:RemoveItem(item)
        self[item.type_name](self, item)
    end
    self.items_panel:set_y(0)
end

function Menu:RemoveItem(item)       
    if alive(item.panel) then
        item.panel:parent():remove(item.panel)
    end
    if item.type_name == "ItemsGroup" and item.items then
        item.items = {}
    end
    if item.list then
        item.list:parent():remove(item.list)
    end
    table.delete(self.items, item)
    table.delete(self._items, item)
    if self.auto_align then
        self:AlignItems()
    end
end

function Menu:UpdateParams(params)
    params = params or {}
    self.text_color = params.text_color or self.menu.text_color
    self.items_size = params.items_size or self.menu.items_size or 16
    self.background_color = params.background_color
    self.marker_highlight_color = params.marker_highlight_color or self.menu.marker_highlight_color or Color(0.2, 0.5, 1)
    self.marker_color = params.marker_color or Color.white:with_alpha(0) 
    self.position = params.position or self.position
    self.panel:child("bg"):configure({
        visible = self.background_color ~= nil,
        color = self.background_color,
        alpha = self.background_alpha,        
    })
    self:SetSize(params.w, params.h)
    if params.visible then
        self:SetVisible(params.visible)
    end
    if type(self.position) == "table" then
        self:SetPosition(self.position[1], self.position[2])
    else
        self:SetPositionByString(self.position)
    end    
    for k, item in pairs(self._items) do
        item.text_color = item.text_color or self.text_color
        item.items_size = item.items_size or self.items_size
        item.marker_highlight_color = item.marker_highlight_color or self.marker_highlight_color
        item.marker_color = item.marker_color or self.marker_color
        item.w = item.w or (self.items_panel:w() > 300 and not item.override_size_limit and 300 or self.items_panel:w())
    end        
    self:RecreateItems()
end

function Menu:KeyBind(params)
    self:ConfigureItem(params)
    return self:NewItem(KeyBindItem:new(self, params))
end

function Menu:Toggle(params)
    self:ConfigureItem(params)
    return self:NewItem(Toggle:new(self, params))
end

function Menu:ItemsGroup(params)
    self:ConfigureItem(params)
    return self:NewItem(ItemsGroup:new(self, params))
end

function Menu:ImageButton(params)
    self:ConfigureItem(params)
    return self:NewItem(ImageButton:new(self, params))
end

function Menu:Button(params)
    self:ConfigureItem(params)
    return self:NewItem(Item:new(self, params))
end

function Menu:ComboBox(params)
    self:ConfigureItem(params)
    return self:NewItem(ComboBox:new(self, params))
end

function Menu:TextBox(params)
    self:ConfigureItem(params)
    return self:NewItem(TextBox:new(self, params))
end

function Menu:NumberBox(params)
    self:ConfigureItem(params)
    params.type_name = "NumberBox"
    params.filter = "number"
    return self:NewItem(TextBox:new(self, params))
end

function Menu:ComboBox(params)
    self:ConfigureItem(params)
    return self:NewItem(ComboBox:new(self, params))
end

function Menu:Slider(params)
    self:ConfigureItem(params)
    return self:NewItem(Slider:new(self, params))
end

function Menu:Divider(params)
    self:ConfigureItem(params)
    params.type_name = "Divider"
    return self:NewItem(Item:new(self, params))
end

function Menu:Table(params)
    self:ConfigureItem(params)
    return self:NewItem(Table:new(self, params))
end

function Menu:GetIndex(name)
    for k, item in pairs(self._items) do
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
        return {2,1}
    end
end

function Menu:ConfigureItem(item)
    if type(item) ~= "table" then
        log(tostring(debug.traceback()))
        return
    end
    item.parent = self
    item.menu = self.menu
    item.enabled = item.enabled == nil and true or item.enabled
    item.text_color = item.text_color or self.text_color
    item.text_highlight_color = item.text_highlight_color or self.text_highlight_color
    item.items_size = item.items_size or self.items_size
    item.marker_highlight_color = item.marker_highlight_color or self.marker_highlight_color
    item.marker_color = item.marker_color or self.marker_color
    item.marker_alpha = item.marker_alpha or self.marker_alpha
    item.align = item.align or self.align or "left"
    item.size_by_text = item.size_by_text or self.size_by_text
    item.parent_panel = (item.group and item.group.panel) or (item.override_parent and item.override_parent.panel) or self.items_panel
    item.offset = item.offset and self:ConvertOffset(item.offset) or self.offset
    item.override_size_limit = item.override_size_limit or self.override_size_limit
    item.w = (item.w or (item.parent_panel:w() > 300 and not item.override_size_limit and 300 or item.parent_panel:w())) - (item.size_by_text and 0 or item.offset[1])
    item.control_slice = item.control_slice or self.control_slice
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
    if item.index then
        table.insert(self._items, item.index, item)
    else
        table.insert(self._items, item)
    end
    if not item.group and item.override_parent == nil then
        if item.index then
            table.insert(self.items, item.index, item)
        else
            table.insert(self.items, item)
        end
    end
    if self.auto_align then
        self:AlignItems()
    end
    return item
end
