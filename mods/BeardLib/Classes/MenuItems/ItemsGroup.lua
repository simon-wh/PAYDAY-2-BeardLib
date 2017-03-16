ItemsGroup = ItemsGroup or class(Item)
function ItemsGroup:init(parent, params)    
    self.type_name = "ItemsGroup"
    params.items = params.items or {}
    params.panel = params.parent_panel:panel({ 
        name = params.name,
        w = params.w,
        h = math.max(#params.items, 1) * parent.items_size,
    })
    if params.use_as_menu ~= true then
        params.toggle = params.panel:bitmap({
            name = "toggle",
            w = parent.items_size - 4,
            h = parent.items_size - 4,
            texture = "guis/textures/menuicons",
            color = params.text_color or Color.black,
            y = 2,
            x = 4,
            texture_rect = {params.closed and 42 or 2, params.closed and 2 or 0, 16, 16},
            layer = 6,
        })    
        params.title = params.panel:text({
            name = "title",
            text = params.text,
            vertical = "center",
            align = "left",
            x = 6 + parent.items_size,
            h = parent.items_size,
            layer = 6,
            color = params.text_color or Color.black,
            font = params.font,
            font_size = parent.items_size
        })
        local _,_,w,h = params.title:text_rect()
        params.panel:rect({
            name = "bg",
            h = h,
            visible = not params.closed,
            color = params.marker_highlight_color,     
        })    
        params.title:set_w(w)
    end
    table.merge(self, params)
    params.option = params.option or params.name    
    if params.group then
        if params.group.type_name == "ItemsGroup" then
            params.group:AddItem(self)
        else
            BeardLib:log(self.name .. " group is not a group item!")
        end
    end

    self.parent = parent
    self.menu = parent.menu
end

function ItemsGroup:MousePressed(button, x, y)
    if self.use_as_menu ~= true and button == Idstring("0") and alive(self.panel) and self.panel:child("bg"):inside(x,y) then
        self:Toggle()
        return true
    end
end

function ItemsGroup:SetEnabled(enabled) end

function ItemsGroup:AddItem(item)
    table.insert(self.items, item)
    self:AlignItems()
end

function ItemsGroup:Toggle()
    if self.use_as_menu == true then
        return
    end
    if self.closed then
        self.closed = false
    else
        self.closed = true
        self.panel:set_h(self.parent.items_size)
    end
    for i, item in ipairs(self.items) do
        item:SetEnabled(not self.closed)
        item.panel:set_visible(not self.closed)
    end
    self.toggle:set_texture_rect(self.closed and 42 or 2, self.closed and 2 or 0, 16, 16)
    self.panel:child("bg"):set_visible(not self.closed)
    self:AlignItems()
end

function ItemsGroup:AlignItems()
    if self.align_method == "grid" then
        self:AlignItemsGrid()
    else
        self:AlignItemsNormal()
    end
    if self.group then
        self.group:AlignItems()
    else
        self.parent:AlignItems()
    end   
end

function ItemsGroup:AlignItemsGrid()
    local base_h = self.parent.items_size
    local x
    local y = self.use_as_menu ~= true and base_h or 0
    for i, item in ipairs(self.items) do
        local offset = item.offset
        x = x or offset[1]
        item.panel:set_position(x,y + offset[2])
        x = x + item.panel:w() + offset[1]
        if x > self.panel:w() then
            x = offset[1]
            y = y + item.panel:h() + offset[2]
            item.panel:set_position(x,y)
            x = x + item.panel:w() + offset[1]
        end
    end
    self.panel:set_h(base_h + (self.closed and 0 or y))
end

function ItemsGroup:AlignItemsNormal()
    local base_h = self.use_as_menu ~= true and self.parent.items_size or 0
    local h = base_h
    local rows = 1
    for i, item in ipairs(self.items) do
        local offset = item.offset
        item.panel:set_x(offset[1])            
        item.panel:set_y(base_h + offset[2])
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
    self.panel:set_h(self.closed and base_h or h)
end

function ItemsGroup:SetText(text)
    if alive(self.title) then
        self.title:set_text(text)
    end
end

function Item:SetParam(param, value)
    self[param] = value
end

function ItemsGroup:SetCallback(callback)
    self.callback = callback
end

function ItemsGroup:Highlight()
    if not alive(self.panel) then 
        return
    end
    self.panel:child("bg"):show()
    self.highlight = true
    self.menu._highlighted = self
end

function ItemsGroup:UnHighlight()
    if not alive(self.panel) or not self.closed then
        return
    end
    self.panel:child("bg"):hide()
    if self.menu._highlighted == self then
        self.menu._highlighted = nil
    end
    self.highlight = false
end

function ItemsGroup:MouseMoved(x, y)
    if not alive(self.panel) or not self.enabled or self.use_as_menu == true then
        return false
    end    
    if not self.menu._openlist and not self.menu._slider_hold then
        if self.panel:inside(x, y) then
            self:Highlight()
        elseif self.closed then
            self:UnHighlight()
        end 
    end   
end

 