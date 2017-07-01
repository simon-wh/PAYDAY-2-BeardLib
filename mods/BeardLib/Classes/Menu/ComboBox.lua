ComboBox = ComboBox or class(Item)
ComboBox.type_name = "ComboBox"
function ComboBox:Init()
    self.size_by_text = false
    self.items = self.items or {}
    self.searchbox = self.searchbox == nil and true or self.searchbox
    self.super.Init(self)
    local text = self.items[self.value]
    if type(text) == "table" then
        text = text.text
    end
    local control_size = self.panel:w() / self.control_slice
    local bgcolor = self:Get2ndBackground()
    local combo_bg = self.panel:bitmap({
        name = "combo_bg",
        w = control_size,
        h = self.items_size,
        layer = 1,
        color = bgcolor,
    })
    local combo_selected = self.panel:text({
        name = "combo_selected",
        text = self.localized_items and text and managers.localization:text(tostring(text)) or type(text) ~= "nil" and tostring(text) or "",
        w = control_size - 10,
        h = self.items_size,
        valign = "center",
        align = "center",
        vertical = "center",
        layer = 2,
        color = bgcolor:contrast(),
        font = self.font,
        font_size = self.items_size - 2
    })
    combo_bg:set_right(self.panel:w())
    combo_selected:set_left(combo_bg:left() + 2)
    self.panel:bitmap({
        name = "combo_icon",
        w = self.items_size - 4,
        h = self.items_size - 4,
        texture = "guis/textures/menuicons",
        texture_rect = {4,0,16,16},
        color = bgcolor:contrast(),
        layer = 2,
    }):set_right(combo_bg:right() - 2.5)
    local h = math.max(1, #self.items) * 18
end

function ComboBox:SetEnabled(enabled)
    self.super.SetEnabled(self, enabled)
    if self:alive() and self.panel:child("combo_bg") then
        self.panel:child("combo_selected"):set_alpha(enabled and 1 or 0.5)
        self.panel:child("combo_bg"):set_alpha(enabled and 1 or 0.5)
        self.panel:child("combo_icon"):set_alpha(enabled and 1 or 0.5)
        if self._list then
            self._list:hide()
        end
    end
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
       self.panel:child("combo_selected"):set_text(self.localized_items and v and managers.localization:text(tostring(v)) or type(v) ~= "nil" and tostring(v) or "")
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
    if not self:MouseCheck(true) then
        return
    end
    if not self.menu._openlist and self.parent.panel:inside(x,y) and self.panel:inside(x,y) then
        if button == Idstring("0") then
            self._list:update_search()
            self._list:show()
            return true
        end
    end
end