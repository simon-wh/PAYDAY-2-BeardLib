ComboBox = ComboBox or class(Item)

function ComboBox:init(parent, params)
    self.type_name = "ComboBox"
    self.size_by_text = false
    self.items = self.items or {}
    self.searchbox = self.searchbox == nil and true or self.searchbox
    self.super.init(self, parent, params)
    local text = self.items[self.value]
    if type(text) == "table" then
        text = text.text
    end
    local control_size = self.panel:w() / self.control_slice
    local combo_selected = self.panel:text({
        name = "combo_selected",
        text = self.localized_items and text and managers.localization:text(text) or text or "",
        w = control_size - 10,
        h = self.items_size,
        valign = "center",
        align = "center",
        vertical = "center",
        layer = 2,
        color = self.parent.background_color and self.text_color or Color.black,
        font = self.font,
        font_size = self.items_size - 2
    })
    local combo_bg = self.panel:bitmap({
        name = "combo_bg",
        w = control_size,
        h = self.items_size,
        layer = 1,
        color = ((parent.background_color or Color.white) / 1.2):with_alpha(1),
    })
    combo_bg:set_right(self.panel:w())
    combo_selected:set_left(combo_bg:left() + 2)
    self.panel:bitmap({
        name = "combo_icon",
        w = self.items_size - 4,
        h = self.items_size - 4,
        texture = "guis/textures/menuicons",
        texture_rect = {4,0,16,16},
        color = not parent.background_color and Color.black,
        layer = 2,
    }):set_right(combo_bg:right() - 2.5)
    local h = math.max(1, #self.items) * 18
end

function ComboBox:SetEnabled(enabled)
    self.super.SetEnabled(self, enabled)
    self.panel:child("combo_selected"):set_alpha(enabled and 1 or 0.5)
    self.panel:child("combo_bg"):set_alpha(enabled and 1 or 0.5)
    self.panel:child("combo_icon"):set_alpha(enabled and 1 or 0.5)
    self._list:hide()
end

function ComboBox:ContextMenuCallback(item)
    self:SetSelectedItem(item, true)
end

function ComboBox:SetItems(items)
    self.items = items or {}
    self._list:update_search()
end

function ComboBox:SetValue(value, run_callback, no_items_clbk)    
    local v = self.items[value]
    if run_callback and type(v) == "table" and not no_items_clbk and v.callback then
        self:RunCallback(v.callback)
    end
    if type(v) == "table" then
        v = v.text
    end
    if alive(self.panel) then
       self.panel:child("combo_selected"):set_text(self.localized_items and v and managers.localization:text(tostring(v)) or tostring(v) or "")
    end    
    self.super.SetValue(self, value, run_callback)
end

function ComboBox:SetSelectedItem(value, ...)    
    self:SetValue(table.get_key(self.items, value), ...)
end

function ComboBox:SelectedItem()
    return self.items[self.value]
end

function ComboBox:MousePressed(button, x, y)
    if not self.menu._openlist and self.parent.panel:inside(x,y) and self.panel:inside(x,y) then
        if button == Idstring("0") then
            self._list:update_search()
            self._list:show()
            return true
        end
    end
end
