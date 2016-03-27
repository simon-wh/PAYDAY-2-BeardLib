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
        color = Color.black,
        font = "fonts/font_large_mf",
        font_size = 16
    })
    local list_icon = params.panel:text({
        name = "list_icon",
        text = "^",
        rotation = 180,
        valign = "right",
        align = "right",
        vertical = "center",
        w = 18,
        h = 18,
        layer = 6,
        color = Color.black,
        font = "fonts/font_large_mf",
        font_size = 16
    })
    local combo_bg = params.panel:bitmap({
        name = "combo_bg",
        y = 4,
        x = -2,
        w = params.panel:w() / 1.4,
        h = 16,
        layer = 5,
        color = Color(0.6, 0.6, 0.6),
    })
    combo_bg:set_right(params.panel:w() - 4)
    combo_selected:set_center(combo_bg:center())
    self.list = self.menu._fullscreen_ws_pnl:panel({
        name = params.name.."list",
        y = 0,
        w = 120,
        h =  math.max(1, #params.items) * 18,
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
    list_icon:set_left(combo_bg:right() - 12)
    for k, text in pairs(params.items) do
        local combo_item = self.list:text({
            name = "item"..k,
            text = text,
            align = "center",
            h = 18,
            y = 18 * (k - 1),
            layer = 6,
            color = Color.black,
            font = "fonts/font_large_mf",
            font_size = 16
        })
        local combo_item_bg = self.list:bitmap({
            name = "bg"..k,
            align = "center",
            h = 18,
            y = 18 * (k - 1),
            layer = 5,
        })
    end
end

function ComboBox:SetValue(value)
    self.super.SetValue(self, value)
    if alive(self.panel) then
        self.panel:child("combo_selected"):set_text(self.localize_items and managers.localization:text(self.items[value]) or self.items[value])
    end
end

function ComboBox:mouse_pressed( o, button, x, y )
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
                if ((self.value - 1) ~= 0) and ((self.value + 1) < (#self.items + 1))  then
                    self:SetValue(self.value + ((wheelup == 1) and -1 or 1))
                    if self.callback then
                        self.callback(self.menu, self)
                    end
                    return true
                end
            end
        end
    elseif self.menu._openlist == self and self.list:inside(x,y) then
        for k, v in pairs(self.items) do
            if self.list:child("item"..k):inside(x,y) then
                self:SetValue(k)
                if self.callback then
                    self.callback(self.menu, self)
                end                
                self.list:hide()
                self.menu._openlist = nil
                return true
            end
        end
    else
        self.menu._openlist.list:hide()
        self.menu._openlist = nil
    end
end

function ComboBox:key_press( o, k )
    if not self.menu._openlist then
        if k == Idstring("enter") then
            self.list:set_lefttop(self.panel:child("combo_bg"):world_left(), self.panel:child("combo_bg"):world_bottom() + 4)
            self.list:show()
            self.menu._openlist = self
        end
    else
        self.menu._openlist.list:hide()
        self.menu._openlist = nil
    end
end

function ComboBox:mouse_moved(o, x, y )
    self.super.mouse_moved(self, o, x, y)
    if self.menu._openlist == self then
        for k, v in pairs(self.items) do
            self.list:child("bg"..k):set_color(self.list:child("bg"..k):inside(x,y) and Color(0, 0.5, 1) or Color.white)
        end
    end
end
