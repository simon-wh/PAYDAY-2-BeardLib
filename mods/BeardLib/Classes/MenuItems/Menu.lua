Menu = Menu or class(MenuUI)

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
    local w = menu._panel:w() - 12
    if params.w == "full" then
        params.w = menu._scroll_panel:w()
    elseif params.w == "half" then
        params.w = menu._scroll_panel:w() / 2
    end
    params.w = params.w or (w < 400 and w or 400)
    params.panel = menu._scroll_panel:panel({
        name = params.name .. "_panel",
        w = params.w,
        h = params.h,
        visible = params.visible == true,
        layer = 21,
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
    local bar_h = params.panel:top() - params.panel:bottom()
    local scroll_bar = params.panel:panel({
        name = "scroll_bar",
        halign = "center",
        w = 4,
        layer = 20,
    })
    scroll_bar:rect({
        name = "rect",
        color = Color.white,
        layer = 4,
        h = bar_h,
    })
    scroll_bar:set_right(params.panel:right())
    params.items_panel = params.panel:panel({
        name = "items_panel",
        layer = 1,
        w = params.w - (scroll_bar:w() * 2),
    })

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
    if type(params.position) == "table" then
        self:SetPosition(params.position[1], params.position[2])
    else
        self:SetPositionByString(params.position)
    end
end
function Menu:SetPositionByString(pos)
    if string.match(pos, "Center") then
       self.panel:set_world_center(self.menu._scroll_panel:world_center())
    end
    if string.match(pos, "Bottom") then
       self.panel:set_world_bottom(self.menu._scroll_panel:world_bottom())
    end
    if string.match(pos, "Top") then
        self.panel:set_world_top(self.menu._scroll_panel:world_top())
    end
    if string.match(pos, "Right") then
        self.panel:set_world_right(self.menu._scroll_panel:world_right())
    end
    if string.match(pos, "Left") then
        self.panel:set_world_left(self.menu._scroll_panel:world_left())
    end
    self:AlignScrollBar()
end
function Menu:AnimatePosition(pos, position_number)
    pos = pos:lower()
    local v = position_number or self.menu._scroll_panel["world_" .. pos](self.menu._scroll_panel)
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
    self:AlignScrollBar()
end
function Menu:Panel()
    return self.panel
end
function Menu:SetMaxRow(max)
    self.row_max = max
    self:AlignItems()
end
function Menu:MouseInside()
    return self.panel:inside(managers.mouse_pointer._mouse:world_position())
end
function Menu:SetSize(w,h)
    self.panel:set_size(w or self.w,h or self.h)
    self.panel:child("scroll_bar"):set_h(h or self.h)
    self.items_panel:set_size((w or self.w) - self.panel:child("scroll_bar"):w(),h or self.h)
    self.panel:child("scroll_bar"):set_right(self.panel:right())
    self.w = w or self.w
    self.h = h or self.h
    self:RecreateItems()
end
function Menu:MouseDoubleClick(button, x, y)
    local menu = self.menu
    if self.visible then
        if menu._highlighted and menu._highlighted.parent == self then
            if menu._highlighted.MouseDoubleClick and menu._highlighted:MouseDoubleClick( button, x, y ) then
                return true
            end
        end
    end
end
function Menu:MousePressed(button, x, y)
    local menu = self.menu
    if self.visible then
        if menu._highlighted and menu._highlighted.parent == self then
            if menu._highlighted:MousePressed( button, x, y ) then 
                return true
            end
        end
        if not self.menu._openlist and self.panel:inside(x,y) then
            if button == Idstring("mouse wheel down") then
                self:scroll_down()
                self:MouseMoved( x, y )
                return true
            elseif button == Idstring("mouse wheel up") then
                self:scroll_up()
                self:MouseMoved( x, y )
                return true
            end
        end
        if button == Idstring("0") then
            if self.panel:child("scroll_bar"):child("rect"):inside(x, y) then
                self.menu._grabbed_scroll_bar = self
                self.panel:child("scroll_bar"):child("rect"):set_color(Color(0.8, 0.8, 0.8))
                return true
            end
            if not self.menu._grabbed_scroll_bar and self.panel:child("scroll_bar"):inside(x, y) then
                self.menu._grabbed_scroll_bar = self
                self.panel:child("scroll_bar"):child("rect"):set_color(Color(0.8, 0.8, 0.8))
                local where = (y - self.panel:world_top()) / (self.panel:world_bottom() - self.panel:world_top())
                self:scroll(where * self.items_panel:h())
                return true
            end
        end
    end
end
function Menu:MouseMoved(x, y)
    if self.menu._openlist then
        self.menu._openlist:MouseMoved(x, y)
        return
    end
    if self.visible then
        if self.menu._grabbed_scroll_bar == self then
            local where = (y - self.panel:world_top()) / (self.panel:world_bottom() - self.panel:world_top())
            self:scroll(where * self.items_panel:h())
        end
        for _, item in ipairs(self._items) do
            item:MouseMoved(x, y)
        end
    end
end
function Menu:MouseReleased(button, x, y)
    self.panel:child("scroll_bar"):child("rect"):set_color(Color.white)
    if self:Visible() then
        if self.menu._highlighted:MouseReleased(button, x, y) then
            return true
        end
    end
end
function Menu:KeyPressed(o, k)
    if self:Visible() then
        if self.menu._highlighted:KeyPressed( o, k ) then
            return true
        end
    end
end
function Menu:Visible()
    return self.visible and self.menu._highlighted
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
    self.items_panel:set_h(self.row_max and self.row_max == 1 and self.panel:h() or h)
    if self.items_panel:h() <= self.panel:h() then
        self.items_panel:set_top(0)
    end
    if self.items_panel:h() > self.panel:h() and self.should_scroll_down and not self._grabbed_scroll_bar then
        self.items_panel:set_bottom(self.panel:h())
    end
    self:AlignScrollBar()
end
function Menu:AlignScrollBar()
    local scroll_bar = self.panel:child("scroll_bar")
    local scroll_bar_rect = scroll_bar:child("rect")
    local bar_h = self.panel:top() - self.panel:bottom()
    scroll_bar_rect:set_h(math.abs( self.panel:h() * (bar_h / self.items_panel:h())))
    scroll_bar_rect:set_y(-(self.items_panel:y()) * self.panel:h() / self.items_panel:h())
    scroll_bar:set_visible(self.items_panel:h() > self.panel:h())
end
function Menu:GetItem( name )
    for _, item in pairs(self._items) do
        if item.name == name then
            return item
        end
    end
    return nil
end
function Menu:scroll_up()
    if self.items_panel:h() > self.panel:h() then
        self.items_panel:set_top(math.min(0, self.items_panel:top() + 25))
        self:AlignScrollBar()
        return true
    end
end

function Menu:scroll_down()
    if self.items_panel:h() > self.panel:h() then
        self.items_panel:set_bottom(math.max(self.items_panel:bottom() - 25, self.panel:h()))
        self:AlignScrollBar()
        return true
    end
end
function Menu:scroll(y)
    if self.items_panel:h() > self.panel:h() then
        self.items_panel:set_y(math.clamp(-y, -self.items_panel:h() ,0))
        self.items_panel:set_bottom(math.max(self.items_panel:bottom(), self.panel:h()))
        self.items_panel:set_top(math.min(0, self.items_panel:top()))
        self:AlignScrollBar()
        return true
    end
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
    self:AlignItems()
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
    item.panel:parent():remove(item.panel)
    if item.list then
        item.list:parent():remove(item.list)
    end
    table.delete(self.items, item)
    table.delete(self._items, item)
    self:AlignItems()
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
function Menu:ContextMenu(params)
    self:ConfigureItem(params)
    return self:NewItem(ContextMenu:new(self, params))
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
        return {0,0}
    end
end
function Menu:ConfigureItem(item)
    item.parent = self
    item.menu = self.menu
    item.enabled = item.enabled or true
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
    self:AlignItems()
    return item
end
