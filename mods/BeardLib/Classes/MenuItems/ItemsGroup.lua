ItemsGroup = ItemsGroup or class(Menu)

function ItemsGroup:init( parent, params )
    params.enabled = params.enabled or true
    params.text_color = params.text_color or parent.text_color
    params.items = params.items or {}
    params.panel = parent.items_panel:panel({ 
        name = params.name,
        y = 10, 
        x = 10,
        h = math.max(#params.items, 1) * parent.items_size,
        layer = 21,
    }) 
    params.panel:rect({
        x = 4,
        halign = "grow",
        valign = "grow",       
        alpha = 0.2,
    })
    params.toggle = params.panel:text({
        name = "toggle",
        text = "^",
        vertical = "center",
        align = "left",
        rotation = 180,
        x = 6,
        y = -4,
        w = parent.items_size,
        h = parent.items_size,
        layer = 6,
        color = params.text_color or Color.black,
        font = "fonts/font_large_mf",
        font_size = parent.items_size
    })    
    local _,_,w,h = params.toggle:text_rect()
    params.toggle:set_size(w,h)
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
    params.title:set_w(w)
    params.option = params.option or params.name    
    table.merge(self, params)
    self.parent = parent
    self.menu = parent.menu
end

function ItemsGroup:SetValue(value)
    self.value = value
end
function ItemsGroup:SetEnabled(enabled)
    self.enabled = enabled
end
function ItemsGroup:Index()
    return self.parent:GetIndex(self.name)
end
function ItemsGroup:key_press( o, k )

end
function ItemsGroup:mouse_pressed( button, x, y )
    if self.panel:inside(x,y) then
        self:Toggle()
    end
end
function ItemsGroup:AddItem( item )
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
    end
    self.toggle:set_rotation(self.closed and 90 or 180)
    self.toggle:set_y(self.closed and -2 or -4)
    self:AlignItems()
end
function ItemsGroup:AlignItems(text)
    local h = self.parent.items_size
    for i, item in ipairs(self.items) do
        if i == 1 then
            item.panel:set_top(self.parent.items_size)
        else
            item.panel:set_top(self.items[i - 1].panel:bottom() + 2)
        end
        h = h + item.panel:h() + 2
    end
    self.panel:set_h( self.closed and self.parent.items_size or h )
    self.parent:AlignItems()
end
function ItemsGroup:SetText(text)
    self.panel:child("title"):set_text(text)
end

function ItemsGroup:SetCallback( callback )
    self.callback = callback
end

function ItemsGroup:mouse_moved( x, y, highlight )
    if not self.enabled then
        return
    end    
    if not self.menu._openlist and not self.menu._slider_hold then
        if self.panel:inside(x, y) then
            self.menu:SetHelp(self.help)
            self.menu._highlighted = self   
        end 
        self.menu._highlighted = self.menu._highlighted and (alive(self.menu._highlighted.panel) and self.menu._highlighted.panel:inside(x,y)) and self.menu._highlighted or nil
    end   
end

function ItemsGroup:mouse_released( button, x, y )

end