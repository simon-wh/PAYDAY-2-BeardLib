KeyBindItem = KeyBindItem or class(Item)

function KeyBindItem:init(parent, params)
    self.type_name = "KeyBind"
    self.size_by_text = false
    self.super.init(self, parent, params)
    self.panel:text({
        name = "keybind_key",
        text = string.upper(self.value or "None"),
        w = self.items_size * 3,
        h = self.items_size,
        align = "center",
        layer = 1,
        color = self.text_color or Color.black,
        font = "fonts/font_large_mf",
        font_size = self.items_size - 2
    }):set_right(self.panel:w())
end

function KeyBindItem:SetValue(value, run_callback)
    self.super.SetValue(self, value, run_callback)
    if not alive(self.panel) then
        return
    end
    self.panel:child("keybind_key"):set_text(string.upper(value or "None"))
end
function KeyBindItem:KeyPressed(o, k)
    local key = Input:keyboard():button_name_str(k)
    if self.CanEdit then
        local forbidden_btns = {
    		"esc",
    		"tab",
            "enter",
    		"num abnt c1",
    		"num abnt c2",
    		"@",
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
                return true
            elseif key == btn then
                self:SetCanEdit(false)
                return true
            end
        end
        self:SetCanEdit(false)
        self:SetValue(key, true)
        return true
    elseif key == "enter" then
        if self.panel:child("keybind_key"):inside(self.menu._old_x, self.menu._old_y) then
            self:SetCanEdit(true)
            return true
        end
    end
end

function KeyBindItem:MouseMoved(x, y)
    self.super.MouseMoved(self, x, y)
    if not alive(self.panel) then
        return
    end        
    self.panel:child("keybind_key"):set_color(self.panel:child("title"):color())    
    if self.menu._highlighted ~= self then
        self:SetCanEdit(false)
    end
end
function KeyBindItem:MousePressed(button, x, y)
    if not alive(self.panel) then
        return
    end    
    if self.menu._highlighted == self and button == Idstring("0") then
        if self.panel:child("keybind_key"):inside(x, y) then
            self:SetCanEdit(true)
        end
    end
end

function KeyBindItem:SetCanEdit(CanEdit)
    self.CanEdit = CanEdit
    if not alive(self.panel) then
        return
    end    
    self.panel:child("keybind_key"):set_alpha(CanEdit and 0.5 or 1)
end
function KeyBindItem:GetKeyBind()
    return Idstring(item.value)
end
