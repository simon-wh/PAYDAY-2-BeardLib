ItemsGroup = ItemsGroup or class(Item)

function ItemsGroup:init(parent, params)    
    self.type_name = "ItemsGroup"
    params.items = params.items or {}
    params.panel = parent.items_panel:panel({ 
        name = params.name,
        y = 10, 
        h = math.max(#params.items, 1) * parent.items_size,
    }) 
    params.toggle = params.panel:bitmap({
        name = "toggle",
        w = parent.items_size - 4,
        h = parent.items_size - 4,
        texture = "guis/textures/menuicons",
        color = params.text_color or Color.black,
        y = 2,
        x = 4,
        texture_rect = {42,2,16,16},
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
        font = "fonts/font_large_mf",
        font_size = parent.items_size
    })
    local _,_,w,h = params.title:text_rect()
    params.panel:rect({
        name = "bg",
        h = h,
        color = params.marker_highlight_color,     
    })    
    params.title:set_w(w)
    params.option = params.option or params.name    
    table.merge(self, params)
    self.parent = parent
    self.menu = parent.menu
end

function ItemsGroup:MousePressed( button, x, y )
    if button == Idstring("0") and alive(self.panel) and self.panel:child("bg"):inside(x,y) then
        self:Toggle()
        return true
    end
end

function ItemsGroup:AddItem(item)
    table.insert(self.items, item)
    self:AlignItems()
end

function ItemsGroup:Toggle()
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

function ItemsGroup:AlignItems(text)
    local h = self.parent.items_size
    local rows = 1
    for i, item in ipairs(self.items) do
        local offset = item.offset
        item.panel:set_x(offset[1])            
        item.panel:set_y(self.parent.items_size + offset[2])
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
    self.panel:set_h(self.closed and self.parent.items_size or h)
    self.parent:AlignItems()
end

function ItemsGroup:SetText(text)
    self.panel:child("title"):set_text(text)
end

function Item:SetParam(param, value)
    self[param] = value
end

function ItemsGroup:SetCallback(callback)
    self.callback = callback
end

function ItemsGroup:MouseMoved(x, y, highlight)
    if not alive(self.panel) or not self.enabled then
        return
    end    
    if not self.menu._openlist and not self.menu._slider_hold then
        if self.panel:inside(x, y) then
            self.menu._highlighted = self 
            self.panel:child("bg"):show()  
        elseif self.closed then
            self.panel:child("bg"):hide()
        end 
        self.menu._highlighted = self.menu._highlighted and (alive(self.menu._highlighted.panel) and self.menu._highlighted.panel:inside(x,y)) and self.menu._highlighted or nil
    end   
end

 