BeardLib.Items.KeyBindItem = BeardLib.Items.KeyBindItem or class(BeardLib.Items.Item)
local KeyBindItem = BeardLib.Items.KeyBindItem
KeyBindItem.type_name = "KeyBind"
function KeyBindItem:Init()
    self.size_by_text = false
    KeyBindItem.super.Init(self)
    self.keybind_key = self.panel:text({
        name = "keybind_key",
        h = self.items_size,
        align = "center",
        vertical = self.text_vertical,
        layer = 1,
        color = self.text_color or Color.black,
        font = self.font,
        font_size = self.items_size - 2
    })
    self:SetKeybindKey()
end

function KeyBindItem:SetValue(value, run_callback)
    KeyBindItem.super.SetValue(self, value, run_callback)
    self:SetKeybindKey()
end

function KeyBindItem:SetKeybindKey()
    if not self:alive() then
        return
    end
    self.keybind_key:set_text(string.upper(self.value or "None"))
    local _,_,w,h = self.keybind_key:text_rect()
    self.keybind_key:set_size(w,h)
    self.keybind_key:set_right(self.panel:w() - self.text_offset)
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
            local key, additional_key = get(Input:keyboard())
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
                    if additional_key:match("ctrl") or additional_key:match("alt") or additional_key:match("shift") then
                        local old_k = key
                        key = additional_key
                        additional_key = old_k
                    end
                    key = key .. "+" .. additional_key
                    self:SetCanEdit(false)
                elseif is_mouse then
                    self:SetCanEdit(false)
                end
                if is_mouse and not key:match("mouse") then
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
    if not self:MouseCheck(true) then
        return
    end
    if button == Idstring("0") and not self.CanEdit then
        if self.panel:inside(x, y) then
            self._ignore_mouse = true
            self:SetCanEdit(true)
        end
    end
end

function KeyBindItem:GetKeyBind()
    return Idstring(item.value)
end