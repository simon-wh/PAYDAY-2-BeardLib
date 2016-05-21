ComboBox = ComboBox or class(Item)

function ComboBox:init( menu, params )
    self.super.init( self, menu, params )
    if not params.items then
        BeardLib:log("No items for ComboBox with the name: " .. tostring(params.name))
        return
    end
    local combo_selected = params.panel:text({
        name = "combo_selected",
        text = params.items[params.value or 1],
        valign = "center",
        align = "center",
        vertical = "center",
        layer = 6,
        color = params.text_color or Color.black,
        font = "fonts/font_medium_mf",
        font_size = params.items_size - 2
    })
    local list_icon = params.panel:text({
        name = "list_icon",
        text = "^",
        rotation = 180,
        valign = "right",
        align = "right",
        vertical = "center",
        w = params.items_size - 4,
        h = params.items_size - 4,
        layer = 6,
        color = params.text_color or Color.black,
        font = "fonts/font_medium_mf",
        font_size = params.items_size - 2
    })
    local _,_,w,_ = list_icon:text_rect()
    list_icon:set_w(w)
    local combo_bg = params.panel:bitmap({
        name = "combo_bg",
        x = -2,
        w = params.panel:w() / 1.5,
        layer = 5,
        color = Color(0.6, 0.6, 0.6),
    })
    combo_bg:set_right(params.panel:w())
    combo_selected:set_center(combo_bg:center())
    local h = math.max(1, #params.items) * 18
    self.list = self.menu._fullscreen_ws_pnl:panel({
        name = params.name.."list",
        y = 0,
        w = params.panel:w() / 1.5,
        h = math.min(self.menu._fullscreen_ws_pnl:h() - self.panel:top(), h),
        layer = 1100,
        visible = false,
        halign = "left",
        align = "left"
    })
    self.list:rect({
        name = "bg",
        halign="grow",
        valign="grow",
        layer = -1
    })
    self.items_panel = self.list:panel({
        name = "items_panel",
        w = self.list:w() - 12,
        x = 12,
        h = h,
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
    list_icon:set_right(combo_bg:right())
    self:CreateItems()
end
function ComboBox:SetItems( items )
    self.items = items
    self:CreateItems()
end
function ComboBox:CreateItems()
    self.items_panel:clear()
    local h = math.max(1, #self.items) * 18
    self.list:set_h(math.min(self.menu._fullscreen_ws_pnl:h() - self.panel:top(), h))
    self._scroll_panel:set_h(self.list:h())
    self._scroll_panel:child("scroll_bar"):set_h(self.list:h())
    self.items_panel:set_h(h)
    self.items_panel:set_y(0)

    for k, text in pairs(self.items) do
        local combo_item = self.items_panel:text({
            name = "item"..k,
            text = tostring(text),
            align = "center",
            h = 18,
            y = 18 * (k - 1),
            layer = 6,
            color = self.text_color or Color.black,
            font = "fonts/font_medium_mf",
            font_size = 16
        })
        local combo_item_bg = self.items_panel:bitmap({
            name = "bg"..k,
            align = "center",
            h = 18,
            y = 18 * (k - 1),
            layer = 5,
        })
    end
    self:AlignScrollBar()
end
function ComboBox:SetValue(value)
    self.super.SetValue(self, value)
    if alive(self.panel) then
        self.panel:child("combo_selected"):set_text(self.localize_items and managers.localization:text(self.items[value]) or self.items[value])
    end
end

function ComboBox:SelectedItem()
    return self.items[self.value]
end

function ComboBox:mouse_pressed( button, x, y )
    if not self.menu._openlist and self.panel:inside(x,y) then
        if button == Idstring("0") then
            if alive(self.list) then
                self.list:set_lefttop(self.panel:child("combo_bg"):world_left(), self.panel:child("combo_bg"):world_bottom() + 4)
                self.list:show()
                self.menu._openlist = self
                return true
            end
        end
        local wheelup = (button == Idstring("mouse wheel up") and 1) or (button == Idstring("mouse wheel down") and 0) or -1
        if wheelup ~= -1 then
            if not self.menu._openlist then
                if self.value and ((self.value - 1) ~= 0) and ((self.value + 1) < (#self.items + 1))  then
                    self:SetValue(self.value + ((wheelup == 1) and -1 or 1))
                    if self.callback then
                        self.callback(self.menu, self)
                    end
                    return true
                end
            end
        end
    elseif self.menu._openlist == self and self.list:inside(x,y) then
        if button == Idstring("mouse wheel down") then
            self:scroll_down()
            self:mouse_moved( x, y )
        elseif button == Idstring("mouse wheel up") then
            self:scroll_up()
            self:mouse_moved( x, y )
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
                if self.items_panel:child("item"..k):inside(x,y) then
                    self:SetValue(k)
                    if self.callback then
                        self.callback(self.menu, self)
                    end
                    self.list:hide()
                    self.menu._openlist = nil
                    return true
                end
            end
        end
        return true
    elseif self.menu._openlist and button == Idstring("0") or button == Idstring("1")  then
        self.menu._openlist.list:hide()
        self.menu._openlist = nil
        return true
    end
end
function ComboBox:AlignScrollBar()
    local scroll_bar = self._scroll_panel:child("scroll_bar")
    local scroll_bar_rect = scroll_bar:child("rect")
    local bar_h = self._scroll_panel:top() - self._scroll_panel:bottom()
    scroll_bar_rect:set_h(math.abs(self._scroll_panel:h() * (bar_h / self.items_panel:h() )))
    scroll_bar_rect:set_y( -(self.items_panel:y()) * self._scroll_panel:h()  / self.items_panel:h())
    scroll_bar:set_left(self._scroll_panel:left())
    scroll_bar:set_visible(self.items_panel:h() > self._scroll_panel:h())
end
function ComboBox:scroll_up()
    if self.items_panel:h() > self._scroll_panel:h() then
        self.items_panel:set_top(math.min(0, self.items_panel:top() + 20))
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
        self.items_panel:set_y(math.clamp(-y, -self.items_panel:h() ,0))
        self.items_panel:set_bottom(math.max(self.items_panel:bottom(), self._scroll_panel:h()))
        self.items_panel:set_top(math.min(0, self.items_panel:top()))
        self:AlignScrollBar()
        return true
    end
end
function ComboBox:key_press( o, k )
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

function ComboBox:mouse_moved( x, y )
    self.super.mouse_moved(self, x, y)
    if self.menu._openlist == self then
        if self._grabbed_scroll_bar then
            local where = (y - self._scroll_panel:world_top()) / (self._scroll_panel:world_bottom() - self._scroll_panel:world_top())
            self:scroll(where * self.items_panel:h())
        end
        for k, v in pairs(self.items) do
            self.items_panel:child("bg"..k):set_color(self.items_panel:child("bg"..k):inside(x,y) and Color(0, 0.5, 1) or Color.white)
        end
    end
end

function ComboBox:mouse_released( button, x, y )
    self.super.mouse_released( button, x, y )
    self._grabbed_scroll_bar = false
end
