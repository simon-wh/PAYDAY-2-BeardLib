BeardLib.Items.ComboBox = BeardLib.Items.ComboBox or class(BeardLib.Items.Item)
local ComboBox = BeardLib.Items.ComboBox
ComboBox.type_name = "ComboBox"
function ComboBox:Init()
    self.size_by_text = false
    self.items = self.items or {}
    self.searchbox = self.searchbox == nil and false or self.searchbox
    ComboBox.super.Init(self)
    local control_size = self.panel:w() * self.control_slice
    local combo_bg = self.panel:rect({
        name = "combo_bg",
        w = control_size,
        alpha = 0,
        h = self.size,
        layer = 1,
        color = self:GetForeground(),
    })
	self._textbox = BeardLib.Items.TextBoxBase:new(self, {
        panel = self.panel,
        lines = 1,
        fit_text = true,
        textbox_text_offset = 16,
        line_color = self.line_color or self.highlight_color,
        w = self.panel:w() * (self.text == nil and 1 or self.control_slice),
        value = self:GetValueText(),
    })
    self._textbox:PostInit()

    combo_bg:set_right(self.panel:w())
    self.icon = self.panel:bitmap({
        name = "icon_arrow",
        w = self.size - 4,
        h = self.size - 4,
        alpha = 0.5,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {0,0,32,32},
        color = self:GetForeground(),
        layer = 2,
    })
    self.icon:set_right(combo_bg:right() - 4)
    self.icon:set_center_y(self._textbox.panel:center_y() - 1)
    self:UpdateValueText()
end

function ComboBox:WorkParams(params)
    ComboBox.super.WorkParams(self, params)
	self.open_list_key = self.open_list_key or Idstring("0")
end

function ComboBox:TextBoxSetValue(value, run_clbk, ...)
    if self.free_typing then
        for i, item in pairs(self.items) do
            if type(item) == "table" and item.text == value or item == value then
                value = i
            end
        end
        self:SetValue(value, run_clbk, true)
    end
    self._list:update_search(true)
end

function ComboBox:ContextMenuCallback(item)
    self:SetSelectedItem(item, true)
end

function ComboBox:Clear()
    self.items = {}
    self:RefreshList()
end

function ComboBox:Append(item)
    table.insert(self.items, item)
    self:RefreshList()
end

function ComboBox:Prepend(item)
    table.insert(self.items, 1, item)
    self:RefreshList()
end

function ComboBox:SetItems(items)
    self.items = items or {}
    self:RefreshList()
end

function ComboBox:RefreshList()
    self._list:update_search()
    self._list._do_search = 0
end

function ComboBox:SetValue(value, run_callback, no_items_clbk)
    if not self:alive() then
		return false
    end

    local v = self.items[value]
    if run_callback and not no_items_clbk and v and type(v) == "table" and v.on_callback then
        self:RunCallback(v.on_callback)
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
        text = self.items_localized and text and managers.localization:text(text) or type(text) ~= "nil" and tostring(text) or ""
    elseif self.free_typing then
        text = self.value
	end

	local is_upper = self.items_uppercase
	local is_lower = self.items_lowercase
	local is_pretty = self.items_pretty
    return (is_upper and text:upper()) or (is_lower and text:lower()) or (is_pretty and text:pretty(true)) or text
end

function ComboBox:UpdateValueText()
    if alive(self.panel) then
        self._textbox:Text():set_text(self:GetValueText())
        self._textbox:update_caret()
    end
end

function ComboBox:SetSelectedItem(value, ...)
    self:SetValue(table.get_key(self.items, value) or (self.free_typing and value or nil), ...)
end

function ComboBox:SelectedItem()
    return self.items[self.value] or (self.free_typing and self.value or nil)
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