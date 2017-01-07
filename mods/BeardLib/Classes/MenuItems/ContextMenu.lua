ContextMenu = ContextMenu or class(Item)

function ContextMenu:init( parent, params )
    self.type_name = "ContextMenu"
    self.super.init( self, parent, params )
    params.items = params.items or {} 
    self.list = self.menu._fullscreen_ws_pnl:panel({
        name = params.name.."list",
        y = 0,
        w = 128,
        layer = 1100,
        visible = false,
        halign = "left",
        align = "left"
    })
    self.list:rect({
        name = "bg",
        color = parent.background_color,
        halign="grow",
        valign="grow",
        layer = -1
    })
    self.items_panel = self.list:panel({name = "items_panel"})
    self._scroll_panel = self.list:panel({
        name = "scroll_panel",
        halign = "center",
        align = "center",
    })
    local bar_h = self._scroll_panel:top() - self._scroll_panel:bottom()
    self._scroll_panel:panel({
        name = "scroll_bar",
        halign = "center",
        align = "center",
        w = 4,
    }):rect({
        name = "rect",
        color = Color.black,
        layer = 4,
        alpha = 0.5,
        h = bar_h,
    })
end

function ContextMenu:SetItems( items )
    self.items = items or {}
end

function ContextMenu:SetValue(value)
    self.super.SetValue(self, value)
    if alive(self.panel) then
        self.panel:child("combo_selected"):set_text(self.localize_items and managers.localization:text(self.items[value]) or self.items[value])
    end
end

function ContextMenu:SelectedItem()
    return self.items[self.value]
end

function ContextMenu:hide()
    self.list:hide()
    self.menu._openlist = nil
    self.cantype = false
end

function ContextMenu:show()
    self.items_panel:clear()
    for k, item in pairs(self.items) do
        local combo_item = self.items_panel:text({
            name = "item"..k,
            text = tostring(item.text),
            align = "center",
            h = 12,
            y = (k - 1) * 14,
            layer = 6,
            color = self.text_color or self.parent.text_color,
            font = "fonts/font_medium_mf",
            font_size = 12
        })
        local combo_item_bg = self.items_panel:bitmap({
            name = "bg"..k,
            align = "center",
            h = 12,
            color = self.background_color or self.parent.background_color,
            y = (k - 1) * 14,
            layer = 5,
        })
    end

    local bottom_h = (self.menu._scroll_panel:world_bottom() - self.panel:world_bottom()) - 4
    local top_h = (self.panel:world_top() - self.menu._scroll_panel:world_top()) - 4
    local items_h = (#self.items) * 14
    local normal_pos = items_h <= bottom_h or bottom_h >= top_h
    if (normal_pos and items_h > bottom_h) or (not normal_pos and items_h > top_h) then
        self.list:set_h(math.min(bottom_h, top_h))
    else
        self.list:set_h(items_h)
    end        
    self._scroll_panel:set_h(self.list:h())
    self._scroll_panel:child("scroll_bar"):set_h(self.list:h())
    self.items_panel:set_h(items_h)      
    if normal_pos then 
        self.list:set_lefttop(self.panel:world_left(), self.panel:world_bottom() + 2)
    else       
        self.list:set_leftbottom(self.panel:world_left(), self.panel:world_top() - 2)        
    end    
    self.items_panel:set_y(0)        
    self.list:show()
    self.menu._openlist = self
    self:AlignScrollBar()
end
function ContextMenu:MousePressed( button, x, y )
    if not self.menu._openlist and self.panel:inside(x,y) then
        if button == Idstring("0") then
            if alive(self.list) then
                self:show()
                return true
            end
        end
    elseif self.menu._openlist == self and self.list:inside(x,y) then
        if button == Idstring("mouse wheel down") then
            self:scroll_down()
            self:MouseMoved( x, y )
        elseif button == Idstring("mouse wheel up") then
            self:scroll_up()
            self:MouseMoved( x, y )
        end
        if button == Idstring("0") then
            if self.cantype then
                return true
            end                 
            if self._scroll_panel:child("scroll_bar"):child("rect"):inside(x, y) then
                self._grabbed_scroll_bar = true
                return true
            end
            if self._scroll_panel:child("scroll_bar"):inside(x, y) then
                self._grabbed_scroll_bar = true
                local where = (y - self._scroll_panel:world_top()) / (self._scroll_panel:world_bottom() - self._scroll_panel:world_top())
                self:scroll(where * self.items_panel:h())
                return true
            end
            for k, item in pairs(self.items) do
                if alive(self.items_panel:child("item"..k)) and self.items_panel:child("item"..k):inside(x,y) then
                    self:RunCallback(item.callback, item)
                    self:hide()
                    return true
                end
            end
        end
        return true
    elseif self.menu._openlist and (button == Idstring("0") or button == Idstring("1")) then
        self.menu._openlist:hide()
        return true
    end
end
function ContextMenu:AlignScrollBar()
    local scroll_bar = self._scroll_panel:child("scroll_bar")
    local scroll_bar_rect = scroll_bar:child("rect")
    local bar_h = self._scroll_panel:top() - self._scroll_panel:bottom() - 14
    scroll_bar_rect:set_h(math.abs(self._scroll_panel:h() * (bar_h / self.items_panel:h() )))
    scroll_bar_rect:set_y(math.max(14, -(self.items_panel:y()) * self._scroll_panel:h()  / self.items_panel:h()))
    scroll_bar:set_left(self._scroll_panel:left())
    scroll_bar:set_visible(self.items_panel:h() > self._scroll_panel:h())
end
function ContextMenu:scroll_up()
    if self.items_panel:h() > self._scroll_panel:h() then
        self.items_panel:set_top(math.min(self.items_size, self.items_panel:top() + 20))
        self:AlignScrollBar()
        return true
    end
end
function ContextMenu:scroll_down()
    if self.items_panel:h() > self._scroll_panel:h() then
        self.items_panel:set_bottom(math.max(self.items_panel:bottom() - 20, self._scroll_panel:h()))
        self:AlignScrollBar()
        return true
    end
end
function ContextMenu:scroll(y)
    if self.items_panel:h() > self._scroll_panel:h() then
        self.items_panel:set_y(math.clamp(-y, -self.items_panel:h(), self.items_size))
        self.items_panel:set_bottom(math.max(self.items_panel:bottom(), self._scroll_panel:h()))
        self.items_panel:set_top(math.min(self.items_size, self.items_panel:top()))
        self:AlignScrollBar()
        return true
    end
end
function ContextMenu:KeyPressed( o, k )
    if self.menu._openlist and k == Idstring("esc") then
        self.menu._openlist.list:hide()
        self.menu._openlist = nil    
    end
end

function ContextMenu:MouseMoved( x, y )
    self.super.MouseMoved(self, x, y)
    if self.menu._openlist == self then
        if self._grabbed_scroll_bar then
            local where = (y - self._scroll_panel:world_top()) / (self._scroll_panel:world_bottom() - self._scroll_panel:world_top())
            self:scroll(where * self.items_panel:h())
        end
        for k, v in pairs(self.items) do
            if alive( self.items_panel:child("bg"..k)) then
                self.items_panel:child("bg"..k):set_color(self.items_panel:child("bg"..k):inside(x,y) and self.marker_highlight_color or self.parent.background_color)  
            end
        end
    end
end

function ContextMenu:MouseReleased( button, x, y )
    self._grabbed_scroll_bar = false
end
