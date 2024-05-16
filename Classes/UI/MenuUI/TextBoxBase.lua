
BeardLib.Items.TextBoxBase = BeardLib.Items.TextBoxBase or class()
local TextBoxBase = BeardLib.Items.TextBoxBase
local KB = BeardLib.Utils.Input
function TextBoxBase:init(parent, params)
    self.owner = parent
    self.parent = parent.parent
    self.menu = parent.menu
    self.size = params.size or parent.size
    self.fit_text = params.fit_text
    self.forbidden_chars = parent.forbidden_chars or {}
    self.text_align = params.text_align or parent.text_align or "left"
    self.font_size = parent.textbox_font_size or params.font_size or parent.font_size or parent.size
    self.text_vertical = params.text_vertical or parent.text_vertical
    self.textbox_max_h = parent.textbox_max_h
    self.no_magic_chars = NotNil(parent.no_magic_chars, true)
    self.panel = params.panel:panel({
        name = "text_panel",
        w = params.w,
        h = params.h or params.size,
        layer = params.layer or 5
    })
    self.panel:set_w(self.panel:w()-(parent.textbox_offset or 0))
    self.panel:set_right(params.panel:w()-(parent.textbox_offset or 0))
    self.line_color = params.line_color
    self.foreground = params.foreground
    self.foreground_highlight = params.foreground_highlight
    local color = self:GetForeground()
    local line = self.panel:rect({
        name = "line",
        halign = "grow",
        visible = params.line,
        h = 2,
        layer = -1,
        color = self.line_color or color,
    })
    line:set_bottom(self.panel:h())
    local value = params.value or ""
    if parent.filter == "number" then
        value = self:tonumber(value)
    end
    self._scroll = ScrollablePanelModified:new(self.panel, "text_panel", {
        layer = params.layer or 5,
        padding = 0,
        scroll_width = params.lines == 1 and 0 or parent.scroll_width,
        color = parent.textbox_scroll_color or line:color(),
        hide_shade = true,
        hide_scroll_background = true,
        scroll_speed = parent.scroll_speed
    })
    local canvas = self._scroll:canvas()
    self.text = canvas:text({
        name = "text",
        text = tostring(value),
        w = canvas:w() - 4 - (params.textbox_text_offset or 0),
        wrap = not params.lines or params.lines > 1,
        word_wrap = not params.lines or params.lines > 1,
        color = color,
        align = self.text_align,
        vertical = self.text_vertical or nil,
        selection_color = color:with_alpha(0.5), --I fucking wish there was something better..
        font = parent.font or tweak_data.menu.pd2_medium_font,
        font_size = self.font_size
    })
    if self.fit_text then
        self.text:set_vertical("center")
    end
    if self.owner.text_offset then
        self._text_offset = self.owner.text_offset[2]
        self._text_offset_b = (self.owner.text_offset[4] or self._text_offset)
    else
        self._text_offset = 2
        self._text_offset_b = 2
    end
    self._text_offset = math.max(self._text_offset - line:h(), 0)
    self.text:set_y(self._text_offset)
    local len = self:Value():len()
    self.text:set_selection(len, len)
    self.panel:rect({
        name = "caret",
        w = 1,
        visible = false,
        color = color:with_alpha(1),
        h = self.text:font_size() - (line:h() * 2),
        layer = 3,
    })

    self.focus_mode = NotNil(params.focus_mode, true)
    if self.focus_mode and not self.owner.menu:Typing() and params.auto_focus then
        self:set_active(true)
    end

    self.lines = params.lines
    self.btn = params.btn or "0"
    self.history = {params.value and self:Value()}
    self.text:enter_text(ClassClbk(self, "enter_text"))
    self.update_text = params.update_text or ClassClbk(self.owner, "TextBoxSetValue")
end

function TextBoxBase:PostInit()
    self:CheckText(self.text, true)
    self:update_caret()
end

function TextBoxBase:GetForeground(highlight)
    return NotNil(highlight and self.foreground or self.highlight_foreground, self.owner:GetForeground(highlight))
end

function TextBoxBase:DoHighlight(highlight)
    local color = self:GetForeground(highlight)
    local caret = self.panel:child("caret")
    if caret then
        if self.owner.animate_colors then
            play_color(caret, color:with_alpha(1))
            play_color(self.panel:child("line"), self.line_color or color)
            play_anim(self.text, {set = {color = color, selection_color = color:with_alpha(0.5)}})
        else
            caret:set_color(color:with_alpha(1))
            self.panel:child("line"):set_color(self.line_color or color)
            self.text:set_color(color)
            self.text:set_selection_color(color:with_alpha(0.5))
        end
    end
end

function TextBoxBase:Value()
    return self.text:text()
end

function TextBoxBase:Text()
    return self.text
end

function TextBoxBase:CheckText(text, no_clbk)
    if self.owner.filter == "number" then
        if self.owner.allow_expressions then
            local f = loadstring("return " .. self:Value())
            local val = f and f()
            if val and tonumber(val) ~= nil then
                self.update_text(self:tonumber(val), not no_clbk, true)
                return
            end
        end

        if tonumber(self:Value()) ~= nil then
            self.update_text(self:tonumber(self:Value()), not no_clbk, true)
        else
            self.update_text(self:tonumber(self:one_point_back()), not no_clbk, true)
        end
    else
        self.update_text(self:Value(), not no_clbk, true)
    end
end

function TextBoxBase:tonumber(text)
    text = text or 0
    if self.owner.floats then
        return tonumber(string.format("%." .. self.owner.floats .. "f", tonumber(text) or 0))
    else
        return tonumber(text)
    end
end

function TextBoxBase:remove_selected(delete_forward)
    local text = self.text
    local s, e = text:selection()
    if not (utf8.len(self:Value()) < 1) then
        if s == e and s > 0 then
            if delete_forward then
                text:set_selection(s, e + 1)
            else
                text:set_selection(s - 1, e)
            end
        end
        text:replace_text("")
        self:add_history_point(self:Value())
        if self:fixed_text(self:Value()) == self:Value() then
            self.update_text(self:Value(), true, false, true)
        end
    end
end

function TextBoxBase:key_hold(text, k)
    local first
    while alive(text) and self.cantype and self.menu._key_pressed == k and self.menu.active_textbox == self do
        local s, e = text:selection()
        local n = utf8.len(self:Value())
        local x = KB:Down("x")
        if ctrl() then
            if KB:Down("a") then
                text:set_selection(0, self:Value():len())
            elseif KB:Down("c") or x then
                Application:set_clipboard(tostring(text:selected_text()))
                if x and math.abs(s - e) > 0 then
                    self:remove_selected()
                end
            elseif KB:Down("v") then
                local copy = tostring(Application:get_clipboard())
                if (self.owner.filter == "number" and tonumber(copy) == nil) then
                    return
                end

                for _, c in pairs(self.forbidden_chars) do
                    if s:find(c) ~= nil then
                        return
                    end
                end

                text:replace_text(copy)
                self:add_history_point(self:Value())
                self.update_text(self:Value(), true, true, true)
            else
                local z = KB:Down("z")
                local y = KB:Down("y")
                if z or y then
                    local point = self.history_point or not y and #self.history
                    local new_point = point and point + (z and -1 or 1)
                    if new_point > 0 then
                        self.history_point = new_point < #self.history and new_point or nil
                        self.update_text(self.history[new_point], true, true, true)
                    end
                end
            end
        else
            local s, e = text:selection()
            if k == Idstring("backspace") or (s ~= e and k == Idstring("delete")) then
                self:remove_selected()
            elseif k == Idstring("delete") then
                self:remove_selected(true)
            elseif shift() then
                if KB:Down(Idstring("left")) then text:set_selection(s - 1, e)
                elseif KB:Down(Idstring("right")) then text:set_selection(s, e + 1) end
            elseif k == Idstring("left") then
                if s < e then
                    text:set_selection(s, s)
                elseif s > 0 then
                    text:set_selection(s - 1, s - 1)
                end
            elseif k == Idstring("right") then
                if s < e then
                    text:set_selection(e, e)
                elseif s < n then
                    text:set_selection(s + 1, s + 1)
                end
            else
                self.menu._key_pressed = nil
            end
        end
        self:update_caret()
        if not first then
            first = true
            wait(0.5)
        end
        wait(0.01)
    end
end

function TextBoxBase:one_point_back()
    return self.history[#self.history - 1]
end

function TextBoxBase:add_history_point(text)
    if self.history_point then
        local temp_history = clone(self.history)
        self.history = {}
        for point, point_text in pairs(temp_history) do
            if point <= self.history_point then
                table.insert(self.history, point_text)
            end
        end
        self.history_point = nil
    end
    table.insert(self.history, text)
end

function TextBoxBase:fixed_text(text)
    if self.owner.filter == "number" then
        local num = tonumber(text)
        if num then
            local clamp = math.clamp(num, self.owner.min or num, self.owner.max or num)
            if self.owner.floats then
                return string.format("%." .. self.owner.floats .."f", clamp)
            else
                return clamp
            end
        end
    else
        return text
    end
end

local allowed_number_text = {
    ["-"] = true,
    ["."] = true
}
local allowed_expression_text = {
    ["("] = true,
    [")"] = true,
    ["+"] = true,
    ["*"] = true,
    ["/"] = true
}
function TextBoxBase:enter_text(text, s)
    if not self.cantype or not self.menu:IsMouseActive() then
        return
    end
    local number = self.owner.filter == "number"
    if number and not tonumber(s) and not allowed_number_text[s] and (not self.owner.allow_expressions or not allowed_expression_text[s]) then
        return
    end
    for _, c in pairs(self.forbidden_chars) do
        if s:find(c) ~= nil then
            return
        end
    end
    if self.menu.active_textbox == self and self.cantype and not ctrl() then
        text:replace_text(s)
        self:add_history_point(number and (tonumber(self:Value()) or self:one_point_back()) or self:Value())
        self:update_caret()
        if self:fixed_text(self:Value()) == self:Value() then
            self.update_text(self:Value(), true, false, true)
        end
    end
end

function TextBoxBase:set_active(active)
    local cantype = self.cantype
    self.cantype = active

    local text = self:alive() and self.text or nil

    if self.cantype then
        self.menu.active_textbox = self
        TextBoxBase.active_textbox = self
    else
        if self.menu.active_textbox == self then
            self.menu.active_textbox = nil
            TextBoxBase.active_textbox = nil
        end
        if text and cantype then
            self:CheckText(text)
        end
    end
    self:update_caret()
end

function TextBoxBase:KeyPressed(o, k)
    if not alive(self.panel) then
        return
    end

    local text = self.text

    if k == Idstring("enter") or k == Idstring("esc") then
        self:set_active(false)
        text:stop()
         self:CheckText(text)
        return true
     end
    if self.cantype then
        text:stop()
        text:animate(ClassClbk(self, "key_hold"), k)
        return true
    end
    self:update_caret()
end

function TextBoxBase:update_caret()
    if not self.owner:alive() or not alive(self.panel) then
        return
    end
    local text = self.text
    local line = self.panel:child("line")
    local caret = self.panel:child("caret")

    if self.fit_text then
        text:set_font_size(self.font_size)
        local _,_,w,_ = text:text_rect()
        text:set_font_size(math.clamp(self.font_size * text:w() / w, 8, self.font_size))
        caret:set_h(text:font_size() - (line:h() * 2))
    end

    local _,_,w,h = text:text_rect()

    local lines = math.max(1, text:number_of_lines())
    h = math.max(h, text:font_size())
    local old_h = self.panel:h()
    if not self.owner.h and (not self.lines or (self.lines > 1 and self.lines ~= lines)) then
        self.panel:set_h(math.min(h + self._text_offset + self._text_offset_b + line:h(), self.textbox_max_h))
        text:set_h(h)
        self.owner:_SetText(self.owner.text)
        if not self.owner.SetScrollPanelSize then
            self.panel:set_h(self.panel:parent():h())
        end
        line:set_bottom(self.panel:h())
        text:set_h(math.max(self.panel:h() - self._text_offset - self._text_offset_b - line:h(), text:h()))
    else
        text:set_h(self.panel:h() - self._text_offset - self._text_offset_b - line:h(), text:h())
    end
    if self.parent and (self.cantype or self.parent.auto_align) then
        self.parent:AlignItems(true, nil, true)
    end
    local s, e = text:selection()
    local x, y = text:character_rect(self._select_neg and s or e)
    if s == 0 and e == 0 then
        x = text:world_x()
        y = text:world_y()
        if text:align() == "center" then
            x = x + text:w() / 2
        end
    end
    caret:set_world_position(x, y + 1)
    caret:set_visible(self.cantype)
    caret:set_color(text:color():with_alpha(1))
    self._scroll:set_size(self.panel:w(), self.panel:h()-line:h()*2)
    self._scroll:panel():set_bottom(self.panel:h()-line:h())
    self._scroll:update_canvas_size()
    self._scroll:force_scroll()
end

function TextBoxBase:MousePressed(button, x, y)
    if not self:alive() then
        return false
    end

    local text = self.text
    local active = text:inside(x,y) and button == Idstring(self.btn)

    if alive(self._scroll) then
        if button == Idstring("0") then
            if self._scroll:mouse_pressed(button, x, y) then
                self.menu._scroll_hold = self
                return true
            end
        elseif self._scroll:is_scrollable() then
            if button == Idstring("mouse wheel down") then
                if self._scroll:scroll(x, y, -1) then
                    return true
                end
            elseif button == Idstring("mouse wheel up") then
                if self._scroll:scroll(x, y, 1) then
                    return true
                end
            end
        end
    end

    self:set_active(active)

    if active then
        local i = text:point_to_index(x, y)
        self._start_select = i
        self._select_neg = nil
        text:set_selection(i, i)
        self:update_caret()
    end

    return self.cantype and cantype
end

function TextBoxBase:MouseMoved(x, y)
    if not self:alive() then
        return false
    end

    local text = self.text
    if self.cantype then
        local x,y = managers.mouse_pointer:world_position()
        if x ~= self._old_x or y ~= self._old_y then
            local active = self.menu.active_textbox
            self:set_active((self.focus_mode and (not active or active == self)) or self.panel:inside(x,y))
        end
        self:update_caret()
    end
    if self._start_select then
        local i = text:point_to_index(x, y)
        local s, e = text:selection()
        if self._select_neg == nil or (s == e) then
            self._select_neg = (x - self.menu._old_x) < 0
        end
        if self._select_neg then
            text:set_selection(i - 1, self._start_select)
        else
            text:set_selection(self._start_select, i + 1)
        end
        if self._scroll:is_scrollable() then
            if (self.panel:world_y() - y) > 0 then
                self._scroll:scroll(x, y, 1, true)
            elseif (y - self.panel:world_bottom()) > 0 then
                self._scroll:scroll(x, y, -1, true)
            end
        end
        --self:update_caret()
    end
    self._old_x = x
    self._old_y = y
    return self.cantype
end

function TextBoxBase:MouseReleased(button, x, y)
    self._start_select = nil
end

function TextBoxBase:alive()
    return alive(self.panel)
end

-- Stop BLT Keybinds from executing while we are typing in a BeardLib textbox
local o_update = BLTKeybindsManager.update
function BLTKeybindsManager:update(...)
    if not alive(TextBoxBase.active_textbox) then
        o_update(self, ...)
    end
end
