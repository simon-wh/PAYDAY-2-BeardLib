ComboBox = ComboBox or class(Item)

function ComboBox:init( parent, params )
    self.type = "ComboBox"
    self.size_by_text = false
    self.super.init( self, parent, params )
    self.items = self.items or {} 
    local text = self.items[self.value]
    local combo_selected = self.panel:text({
        name = "combo_selected",
        text = self.localized_items and text and managers.localization:text(text) or text or "",
        h = self.items_size,
        valign = "center",
        align = "center",
        vertical = "center",
        layer = 1,
        color = self.text_color or Color.black,
        font = "fonts/font_medium_mf",
        font_size = self.items_size - 2
    })
    local combo_bg = self.panel:bitmap({
        name = "combo_bg",
        x = self.padding / 2,
        w = self.panel:w() - self.padding,
        h = self.items_size,
        layer = 0,
        color = parent.background_color / 1.2,
    })     
    combo_bg:set_world_bottom(self.panel:world_bottom())   
    combo_selected:set_bottom(combo_bg:bottom())
    self.panel:bitmap({
        name = "combo_icon",
        w = self.items_size,
        h = self.items_size,
        texture = "guis/textures/menu_arrows",
        color = self.text_color or Color.black,
        rotation = -90,
        texture_rect = {24,0,24,24},
        layer = 1,
    }):set_right(combo_bg:right() - 2)
    local h = math.max(1, #self.items) * 18
    self.list = self.menu._fullscreen_ws_pnl:panel({
        name = self.name.."list",
        y = 0,
        w = self.panel:w(),
        h = math.min(self.menu._fullscreen_ws_pnl:h() - self.panel:top(), h),
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
    TextBoxBase.init(self, {
        panel = self.list,
        lines = 1,
        value = "",
        update_text = callback(self, self, "update_search"),
    })
    self.items_panel = self.list:panel({
        name = "items_panel",
        w = self.list:w() - self.padding,
        x = self.padding / 2,
        y = self.items_size,
    })
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
    self:update_search()
end
function ComboBox:SetItems( items )
    self.items = items or {}
    self:update_search()
end
function ComboBox:CreateItems()
    self.items_panel:clear()
    for k, text in pairs(self.found_items) do
        local combo_item = self.items_panel:text({
            name = "item"..k,
            text = self.localized_items and managers.localization:text(tostring(text)) or tostring(text),
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
    if self.menu._openlist == self then
        self:show()
    end
end
function ComboBox:SetValue(value, run_callback)
    self.super.SetValue(self, value, run_callback)
    if alive(self.panel) then
        local text = self.items[value]
        self.panel:child("combo_selected"):set_text(self.localized_items and text and managers.localization:text(text) or text or "")
    end
end

function ComboBox:SelectedItem()
    return self.items[self.value]
end

function ComboBox:hide()
    self.list:hide()
    self.menu._openlist = nil
end
function ComboBox:show()
    local bottom_h = (self.menu._scroll_panel:world_bottom() - self.panel:world_bottom()) - 4
    local top_h = (self.panel:world_top() - self.menu._scroll_panel:world_top()) - 4
    local items_h = (#self.found_items * 14) + self.items_size
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
        self.list:set_lefttop(self.panel:child("combo_bg"):world_left(), self.panel:child("combo_bg"):world_bottom())
    else       
        self.list:set_leftbottom(self.panel:child("combo_bg"):world_left(), self.panel:child("combo_bg"):world_top())        
    end    
    self.items_panel:set_y(self.items_size)        
    self.list:show()
    self.menu._openlist = self
    self:AlignScrollBar()
end
function ComboBox:MousePressed( button, x, y )
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
            for k, v in pairs(self.items) do
                if alive(self.items_panel:child("item"..k)) and self.items_panel:child("item"..k):inside(x,y) then
                    self:SetValue(k)
                    self:RunCallback()
                    self:hide()
                    return true
                end
            end
        end
        return true
    elseif self.menu._openlist and button == Idstring("0") or button == Idstring("1")  then
        self.menu._openlist:hide()
        return true
    end
end
function ComboBox:AlignScrollBar()
    local scroll_bar = self._scroll_panel:child("scroll_bar")
    local scroll_bar_rect = scroll_bar:child("rect")
    local bar_h = self._scroll_panel:top() - self._scroll_panel:bottom() - 14
    scroll_bar_rect:set_h(math.abs(self._scroll_panel:h() * (bar_h / self.items_panel:h() )))
    scroll_bar_rect:set_y(math.max(14, -(self.items_panel:y()) * self._scroll_panel:h()  / self.items_panel:h()))
    scroll_bar:set_left(self._scroll_panel:left())
    scroll_bar:set_visible(self.items_panel:h() > self._scroll_panel:h())
end
function ComboBox:scroll_up()
    if self.items_panel:h() > self._scroll_panel:h() then
        self.items_panel:set_top(math.min(self.items_size, self.items_panel:top() + 20))
        self:AlignScrollBar()
        return true
    end
end
function ComboBox:scroll_down()
    if self.items_panel:h() > self._scroll_panel:h() then
        self.items_panel:set_bottom(math.max(self.items_panel:bottom() - 20, self._scroll_panel:h()))
        self:AlignScrollBar()
        return true
    end
end
function ComboBox:scroll(y)
    if self.items_panel:h() > self._scroll_panel:h() then
        self.items_panel:set_y(math.clamp(-y, -self.items_panel:h(), self.items_size))
        self.items_panel:set_bottom(math.max(self.items_panel:bottom(), self._scroll_panel:h()))
        self.items_panel:set_top(math.min(self.items_size, self.items_panel:top()))
        self:AlignScrollBar()
        return true
    end
end
function ComboBox:KeyPressed( o, k )
    if not self.menu._openlist then
        if k == Idstring("enter") then
            self.list:set_lefttop(self.panel:child("combo_bg"):world_left(), self.panel:child("combo_bg"):world_bottom() + 4)
            self.list:show()
            self.menu._openlist = self
        end
    elseif k == Idstring("esc") then
        self.menu._openlist.list:hide()
        self.menu._openlist = nil
    end
end
function ComboBox:update_search()
    local text = self.list:child("text"):text()
    self.found_items = {}
    for _, v in pairs(self.items) do
        if tostring(v):match(tostring(text)) then
            if #self.found_items <= 200 then
                table.insert(self.found_items, v)
            else
                break
            end
        end
    end 
    self:CreateItems()
end
function ComboBox:MouseMoved( x, y )
    self.super.MouseMoved(self, x, y)
    if self.menu._openlist == self then
        if self._grabbed_scroll_bar then
            local where = (y - self._scroll_panel:world_top()) / (self._scroll_panel:world_bottom() - self._scroll_panel:world_top())
            self:scroll(where * self.items_panel:h())
        end
        for k, v in pairs(self.found_items) do
            self.items_panel:child("bg"..k):set_color(self.items_panel:child("bg"..k):inside(x,y) and self.parent.marker_highlight_color or self.parent.background_color)
        end
    end
end

function ComboBox:MouseReleased( button, x, y )
    self.super.MouseReleased( button, x, y )
    self._grabbed_scroll_bar = false
end
