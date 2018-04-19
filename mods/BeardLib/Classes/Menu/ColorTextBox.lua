BeardLib.Items.ColorTextBox = BeardLib.Items.ColorTextBox or class(BeardLib.Items.TextBox)
local ColorTextBox = BeardLib.Items.ColorTextBox
ColorTextBox.type_name = "ColoredTextBox"

function ColorTextBox:Init(...)
    self.lines = 1
    self.value = self:HexValue() or "000000"
    ColorTextBox.super.Init(self, ...)
    local panel = self:Panel()
    panel:rect({name = "color_preview", w = self.size, h = self.size})
    self:UpdateColor()
end

function ColorTextBox:UpdateColor()
    local preview = self:Panel():child("color_preview")
    if preview then
        preview:set_color(self:Value())
        local s = self._textbox.panel:h()
        preview:set_size(s,s)
        preview:set_right(self._textbox.panel:right())
    end
end

function ColorTextBox:Value()
	local value = self.value
    if type_name(value) == "Color" then
        self.value = value:to_hex()
        return value
    else
        return Color:from_hex(value)
    end
end

function ColorTextBox:HexValue()
    local value = self.value
    if type_name(value) == "Color" then
        return value:to_hex()
    else
        return value
    end
end

function ColorTextBox:VectorValue()
	local v = self:Value()
	return Vector3(v.r, v.g, v.b)
end

function ColorTextBox:SetValue(value, ...)
	local t = type_name(value)
    if t == "Color" then
		value = value:to_hex()
	elseif t == "Vector3" then
		value = Color(value.x, value.y, value.z):to_hex()
    end
    return ColorTextBox.super.SetValue(self, value, ...)
end

function ColorTextBox:TextBoxSetValue(...)
    ColorTextBox.super.TextBoxSetValue(self, ...)
    self:UpdateColor()
end

local mouse_0 = Idstring("0")
function ColorTextBox:MousePressed(button, x, y)
    local result, bad = ColorTextBox.super.MousePressed(self, button, x, y)
    if result then
        return result
    elseif not bad and button == mouse_0 and self:Panel():inside(x,y) then
        if self.show_color_dialog then -- Old.
            self:RunCallback(self.show_color_dialog)
            return true
        elseif not self.no_color_dialog then
            BeardLib.managers.dialog:Color():Show({color = self:Value(), use_alpha = self.use_alpha, force = true, callback = function(color)
                self:SetValue(color, true)
            end})
            return true
        end
    end
    return result
end

function BeardLib.Items.Menu:ColorTextBox(params)
    return self:NewItem(BeardLib.Items.ColorTextBox:new(self:ConfigureItem(params)))
end