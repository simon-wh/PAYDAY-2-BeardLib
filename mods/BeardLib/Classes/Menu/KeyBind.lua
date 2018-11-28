BeardLib.Items.KeyBindItem = BeardLib.Items.KeyBindItem or class(BeardLib.Items.Item)
local KeyBindItem = BeardLib.Items.KeyBindItem
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
        layer = 1,
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
    self.keybind_key:set_text(string.upper(self.value or "None"))
    local _,_,w,h = self.keybind_key:text_rect()
    self.keybind_key:set_size(w,h)
    self.keybind_key:set_righttop(self.panel:w() - self.text_offset[1], self.text_offset[2])
end

function KeyBindItem:SetCanEdit(CanEdit)
    self.CanEdit = CanEdit
    if not alive(self.panel) then
        return
    end
    self.keybind_key:set_alpha(CanEdit and 0.5 or 1)
    if CanEdit then
        BeardLib:AddUpdater("MenuUIKeyBindUpdate"..tostring(self), function()
            local function get(input)
                local key, additional_key
                for _,k in pairs(input:down_list()) do
                    local _key = input:button_name_str(input:button_name(k))
                    if not additional_key then
                        if key then
                            additional_key = _key
                        else
                            key = _key
                            if not self.supports_additional then
                                break
                            end
                        end
                    end
                end
                return key, additional_key
            end
            local key, additional_key = self.supports_keyboard and get(Input:keyboard())
            local is_mouse
            if not key and self.supports_mouse and not self._ignore_mouse then
                key = get(Input:mouse())
                is_mouse = true
            end
            if self._ignore_mouse then
                self._ignore_mouse = Input:mouse():down("0")
            end
            if key then
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
                for _, btn in pairs(forbidden_btns) do
                    if key == "backspace" then
                        self:SetValue(nil, true)
                        self:SetCanEdit(false)
                        return
                    elseif key == btn or additional_key == btn then
                        self:SetCanEdit(false)
                        return
                    end
                end
                if additional_key then
                    if additional_key:find("ctrl") or additional_key:find("alt") or additional_key:find("shift") then
                        local old_k = key
                        key = additional_key
                        additional_key = old_k
                    end
                    key = key .. "+" .. additional_key
                    self:SetCanEdit(false)
                elseif is_mouse then
                    self:SetCanEdit(false)
                end
                if is_mouse and not key:find("mouse") then
                    key = "mouse " .. key
                end
                self:SetValue(key, true)
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