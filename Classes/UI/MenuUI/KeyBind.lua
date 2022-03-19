BeardLib.Items.KeyBindItem = BeardLib.Items.KeyBindItem or class(BeardLib.Items.Item)
local KeyBindItem = BeardLib.Items.KeyBindItem
local InputUtils = BeardLib.Utils.Input
KeyBindItem.type_name = "KeyBind"
function KeyBindItem:Init()
    self.size_by_text = false
    self:WorkParam("supports_keyboard", true)
    KeyBindItem.super.Init(self)
    self.keybind_key = self.panel:text({
        name = "keybind_key",
        h = self.size,
        align = "center",
        vertical = self.text_vertical,
        layer = 3,
        color = self:GetForeground(highlight),
        font = self.font,
        font_size = self.size
    })
    self:SetKeybindKey()
end

function KeyBindItem:SetValue(value, run_callback)
    if KeyBindItem.super.SetValue(self, value, run_callback) then
        self:SetKeybindKey()
        return true
    else
        return false
    end
end

function KeyBindItem:SetKeybindKey()
    if not self:alive() then
        return
    end
    local value = self.value
    self.keybind_key:set_text(string.upper((value and tostring(value):len() > 0 and value) or "None"))
    local _,_,w,h = self.keybind_key:text_rect()
    self.keybind_key:set_size(w,h)
    self.keybind_key:set_righttop(self.panel:w() - self.text_offset[1], self.text_offset[2])
end

function KeyBindItem:GetPressedKeys()
    local keys = {}
    local input_devices = InputUtils:GetInputDevices(not self.supports_keyboard, not self.supports_mouse or self._ignore_mouse)
    for device_name, device in pairs(input_devices) do
        local down_list = device:DownList()
        for _, key in pairs(down_list) do
            if not table.contains(keys, key) then
                table.insert(keys, key)
                if not self.supports_additional then
                    return keys
                elseif #keys >= 4 then
                    break
                end
            end
        end
    end
    local special_keys = {ctrl = 3, shift = 2, alt = 1}
    table.sort(keys, function(a,b)
        local actual_a = string.split(a, " ")[2] or ""
        local actual_b = string.split(b, " ")[2] or ""
        if special_keys[actual_a] and not special_keys[actual_b] then
            return true
        else
            return false
        end
    end)
    return keys
end

local forbidden_btns = {
    "esc",
    "tab",
    "enter",
    "num abnt c1",
    "num abnt c2",
    "@",
    "+",
    "ax",
    "convert",
    "left windows",
    "right windows",
    "kana",
    "kanji",
    "no convert",
    "oem 102",
    "stop",
    "unlabeled",
    "yen",
    "mouse 8",
    "mouse 9",
    ""
}

function KeyBindItem:SetCanEdit(CanEdit)
    self.CanEdit = CanEdit
    if not alive(self.panel) then
        return
    end
    self.keybind_key:set_alpha(CanEdit and 0.5 or 1)
    if CanEdit then
        local keys
        BeardLib:AddUpdater("MenuUIKeyBindUpdate"..tostring(self), function()
            if keys then
                local devices = InputUtils:GetInputDevices(not self.supports_keyboard, not self.supports_mouse or self._ignore_mouse)
                for _, key in pairs(keys) do
                    for device_name, device in pairs(devices) do
                        if device_name ~= "mouse" or key:find("mouse") then
                            if device:Down(key) then
                                break
                            else
                                self:SetCanEdit(false)
                                return    
                            end
                        end
                    end
                end
            end
            keys = self:GetPressedKeys()
            if self._ignore_mouse then
                self._ignore_mouse = Input:mouse():down("0")
            end
            if #keys > 0 then
                for _, btn in pairs(forbidden_btns) do
                    for _, key in pairs(keys) do
                        if key == "backspace" then
                            self:SetValue(nil, true) 
                            self:SetCanEdit(false)
                            return
                        elseif key == btn then
                            self:SetCanEdit(false)
                            return
                        end
                    end
                end
                self:SetValue(table.concat(keys, "+"), true)
                return
            end
        end, true)
    else
        BeardLib:RemoveUpdater("MenuUIKeyBindUpdate"..tostring(self))
    end
end

function KeyBindItem:KeyPressed(o, k)
    if k == Idstring("enter") then
        self:SetCanEdit(true)
        return true
    end
end

function KeyBindItem:MouseMoved(x, y)
    if self.menu._highlighted ~= self then
        self:SetCanEdit(false)
    end
    KeyBindItem.super.MouseMoved(self, x, y)
    if not alive(self.panel) then
        return
    end
    self.keybind_key:set_color(self.title:color())
end

function KeyBindItem:MousePressed(button, x, y)
	local result, state = KeyBindItem.super.MousePressed(self, button, x, y)
	if state == self.UNCLICKABLE or state == self.INTERRUPTED then
		return result, state
	end

    if state == self.CLICKABLE and button == self.click_btn and not self.CanEdit then
        self._ignore_mouse = true
		self:SetCanEdit(true)
		return true
	end

	return result, state
end

function KeyBindItem:GetKeyBind()
    return Idstring(item.value)
end