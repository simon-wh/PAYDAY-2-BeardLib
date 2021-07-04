BeardLib.Items.ColorTextBox = BeardLib.Items.ColorTextBox or class(BeardLib.Items.TextBox)
local ColorTextBox = BeardLib.Items.ColorTextBox
ColorTextBox.type_name = "ColoredTextBox"

function ColorTextBox:Init(...)
    self.lines = 1
    self.value = self:HexValue() or self.allow_empty and "" or "000000"
    ColorTextBox.super.Init(self, ...)
    local panel = self:Panel()
    panel:rect({name = "color_preview", w = self.size, h = self.size, layer = 10})
    self:UpdateColor()
end

function ColorTextBox:UpdateColor()
    local preview = self:Panel():child("color_preview")
	if preview then
        preview:set_color(self:ColorValue() or Color.transparent)
        local s = self._textbox.panel:h()
        preview:set_size(s,s)
        preview:set_right(self._textbox.panel:right())
    end
end

function ColorTextBox:Value()
    if self.return_hex then
        return self:HexValue()
    else
        return self:ColorValue()
    end
end

function ColorTextBox:ColorValue()
	local value = self.value
	local t = type_name(value)
    if t == "Color" then
        self.value = value:to_hex()
		return value
	elseif t == "Vector3" then
		local col = value:color()
		self.value = col:to_hex()
		return col
    elseif self.allow_empty and value == "" then
        return nil
    else
        return Color:from_hex(value)
    end
end

function ColorTextBox:HexValue()
    local value = self.value
	local t = type_name(value)
    if t == "Color" then
        return value:to_hex()
	elseif t == "Vector3" then
		return value:color():to_hex()
	else
        return value
    end
end

function ColorTextBox:VectorValue()
	return self:Value():vector()
end

function ColorTextBox:SetValue(value, ...)
	local t = type_name(value)
    if t == "Color" then
		value = value:to_hex()
	elseif t == "Vector3" then
		value = value:color():to_hex()
    end
    return ColorTextBox.super.SetValue(self, value, ...)
end

function ColorTextBox:TextBoxSetValue(...)
    ColorTextBox.super.TextBoxSetValue(self, ...)
    self:UpdateColor()
end

function ColorTextBox:MousePressed(button, x, y)
	local result, state = ColorTextBox.super.MousePressed(self, button, x, y)
	if state == self.UNCLICKABLE or state == self.INTERRUPTED then
		return result, state
	end

    if state == self.CLICKABLE and button == self.click_btn then
        if self.show_color_dialog then -- Old.
            self:RunCallback(self.show_color_dialog)
            return true
        elseif not self.no_color_dialog then
            BeardLib.Managers.Dialog:Color():Show({color = self:ColorValue(), use_alpha = self.use_alpha, force = true, callback = function(color)
                self:SetValue(color, true)
            end})
            return true
        end
    end
    return result, state
end

function BeardLib.Items.Menu:ColorTextBox(params)
    return self:NewItem(BeardLib.Items.ColorTextBox:new(self:ConfigureItem(params)))
end