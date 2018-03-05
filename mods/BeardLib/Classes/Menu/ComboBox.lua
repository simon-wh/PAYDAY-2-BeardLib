BeardLib.Items.ComboBox = BeardLib.Items.ComboBox or class(BeardLib.Items.Item)
local ComboBox = BeardLib.Items.ComboBox
ComboBox.type_name = "ComboBox"
function ComboBox:Init()
    self.size_by_text = false
    self.items = self.items or {}
    self.searchbox = false -- self.searchbox == nil and true or self.searchbox
    ComboBox.super.Init(self)
    local text = self.items[self.value]
    if type(text) == "table" then
        text = text.text
    end
    local control_size = self.panel:w() * self.control_slice
    local combo_bg = self.panel:rect({
        name = "combo_bg",
        w = control_size,
        alpha = 0,
        h = self.items_size,
        layer = 1,
        color = self:GetForeground(),
    })
	self._textbox = BeardLib.Items.TextBoxBase:new(self, {
        panel = self.panel,
        lines = 1,
        align = self.textbox_align,
        line_color = self.line_color or self.highlight_color,
        w = self.panel:w() * (self.text == nil and 1 or self.control_slice),
        value = self:GetValueText(),
    })
    self._textbox:PostInit()
    combo_bg:set_right(self.panel:w())
    self.icon = self.panel:bitmap({
        name = "icon_arrow",
        w = self.items_size - 6,
        h = self.items_size - 6,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {4,0,16,16},
        color = self:GetForeground(highlight),
        layer = 2,
    })
    self.icon:set_right(combo_bg:right() - 2)
    self.icon:set_center_y(self._textbox.panel:center_y() - 2)
    self:UpdateValueText()
end

function ComboBox:TextBoxSetValue(value, run_clbk, ...)
    if self.free_typing then
        self:SetValue(self._textbox:Value(), run_clbk, true)
    end
    self._list:update_search(true)
end

function ComboBox:ContextMenuCallback(item)
    self:SetSelectedItem(item, true)
end

function ComboBox:SetItems(items)
    self.items = items or {}
    self._list:update_search()
end

function ComboBox:SetValue(value, run_callback, no_items_clbk)
    if not self:alive() then
		return false
    end
    if type(value) == "number" then
        local v = self.items[value]
        if run_callback and type(v) == "table" and not no_items_clbk and v.callback then
            self:RunCallback(v.callback)
        end
    end
    ComboBox.super.SetValue(self, value, run_callback)
    self:UpdateValueText()
    return true
end

function ComboBox:GetValueText()
    local text
    if type(self.value) == "number" then
        text = self.items[self.value]
        text = type(text) == "table" and text.text or text
        text = self.localized_items and text and managers.localization:text(text) or type(text) ~= "nil" and tostring(text) or ""
    elseif self.free_typing then
        text = self.value
    end
    return text
end
    
function ComboBox:UpdateValueText()
    if alive(self.panel) then
       self._textbox:Text():set_text(self:GetValueText())
    end
end

function ComboBox:SetSelectedItem(value, ...)
    self:SetValue(table.get_key(self.items, value) or value, ...)
end

function ComboBox:SelectedItem()
    return tonumber(self.value) and self.items[self.value] or self.value
end

function ComboBox:DoHighlight(highlight)
    ComboBox.super.DoHighlight(self, highlight)
    self._textbox:DoHighlight(highlight)
    if self.icon then
        if self.animate_colors then
            play_color(self.icon, self:GetForeground(highlight))
        else
            self.icon:set_color(self:GetForeground(highlight))
        end
    end
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