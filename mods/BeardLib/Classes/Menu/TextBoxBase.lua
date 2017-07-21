TextBoxBase = TextBoxBase or class()
local KB = BeardLib.Utils.Input
function TextBoxBase:init(parent, params)
    self._parent = parent
    self.parent = parent.parent
    self.menu = parent.menu
    self.items_size = params.items_size or parent.items_size
    self._forbidden = {'%', '(', ")", "[", "]"}
    if self._parent.forbidden_chars then
        table.merge(self._forbidden, self._parent.forbidden_chars)
    end
	self.panel = params.panel:panel({
		name = "text_panel",
		w = params.w,
		h = params.h or params.items_size,
        layer = 4
	})
	self.panel:set_right(params.panel:w())
    self.line_color = params.line_color
    self.text_color =  NotNil(params.text_color, parent.text_color, self.parent.text_color)
    self.text_highlight_color = NotNil(params.text_highlight_color, parent.text_highlight_color, self.parent.text_highlight_color)
	local line = self.panel:rect({
        name = "line",
		halign = "grow",
		visible = params.line,
        h = 1,
        layer = 2,
        color = self.line_color or self.text_color,
    })
    line:set_bottom(self.panel:h())
    self.text = self.panel:text({
        name = "text",
        text = params.value and (parent.filter == "number" and string.format("%." .. parent.floats .. "f", tonumber(params.value)) or tostring(params.value)) or "",
        align = params.align,
        wrap = not params.lines or params.lines > 1,
        word_wrap = not params.lines or params.lines > 1,
        color = self.text_color,
        selection_color = self.text_color:with_alpha(0.5), --I fucking wish there was something better..
		font = parent.font or "fonts/font_medium_mf",
		font_size = self.items_size
    })
    self.text:set_selection(self.text:text():len())
    local caret = self.panel:rect({
        name = "caret",
        w = 2,
        visible = false,
        color = self.text:color():with_alpha(1),
        h = self.text:font_size() - (line:h() * 2),
        layer = 3,
    })
	self.lines = params.lines
	self.btn = params.btn or "0"
    self.history = {params.value and self.text:text()}
 	self.text:enter_text(callback(self, TextBoxBase, "enter_text"))
 	self.update_text = params.update_text or function(self, ...) self._parent:_SetValue(...) end
end

function TextBoxBase:PostInit()
    self:CheckText(self.panel:child("text"), true)
    self:update_caret()
end

function TextBoxBase:DoHighlight(highlight)
    local color = highlight and self.text_highlight_color or self.text_color or Color.white
    local line = self.panel:child("line")
    local text = self.panel:child("text")
    line:set_color(self.line_color or color)
    text:set_color(color)
    text:set_selection_color(color:with_alpha(0.5))
    self.panel:child("caret"):set_color(text:color():with_alpha(1))
end

function TextBoxBase:Value()
    return self.text:text()
end

function TextBoxBase:Text()
    return self.text
end

function TextBoxBase:CheckText(text, no_clbk)
    if self.filter == "number" then
        if tonumber(text:text()) ~= nil then
            self:update_text(self:tonumber(text:text()), not no_clbk, true)
        else
            self:update_text(self:tonumber(self:one_point_back()), not no_clbk, true)
        end
    else
        self:update_text(text:text(), not no_clbk, true)
    end
end
 
function TextBoxBase:tonumber(text)
    return tonumber(string.format("%." .. self._parent.floats .. "f", (text or 0)))
end

function TextBoxBase:key_hold(text, k)
    local first
    while self.cantype and self.menu._key_pressed == k and (self.menu._highlighted == self._parent or self.menu._openlist == self._parent) do
        local s, e = text:selection()
        local n = utf8.len(text:text())
        if ctrl() then
            if KB:Down("a") then
                text:set_selection(0, text:text():len())
            elseif KB:Down("c") then
                Application:set_clipboard(tostring(text:selected_text()))
            elseif KB:Down("v") then
                if (self.filter == "number" and tonumber(Application:get_clipboard()) == nil) then
                    return
                end
                text:replace_text(tostring(Application:get_clipboard()))
                self:add_history_point(text:text())
                self:update_text(text:text(), true, true, true)
            elseif shift() then
                if KB:Down(Idstring("left")) then text:set_selection(s - 1, e)
                elseif KB:Down(Idstring("right")) then text:set_selection(s, e + 1) end
            else
                local z = KB:Down("z") 
                local y = KB:Down("y")
                if z or y then
                    local point = self.history_point or not y and #self.history
                    local new_point = point and point + (z and -1 or 1)
                    if new_point > 0 then
                        self.history_point = new_point < #self.history and new_point or nil
                        self:update_text(self.history[new_point], true, true, true)
                    end
                end
            end
        else
            if k == Idstring("backspace") or k == Idstring("delete") then
                if not (utf8.len(text:text()) < 1) then
                    if s == e and s > 0 then
                        text:set_selection(s - 1, e)
                    end
                    text:replace_text("")
                    self:add_history_point(text:text())
                    if (self._parent.filter ~= "number") or (text:text() ~= "" and self:fixed_text(text:text()) == text:text()) then
                        self:update_text(text:text(), true, false, true)
                    end
                end
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

function TextBoxBase:one_point_back(text)
    return self.history[#self.history - 1]
end

function TextBoxBase:add_history_point(text)
    if self.history_point then
        local temp_history = clone(self.history)
        self.history = {}
        for point, text in ipairs(temp_history) do
            if point <= self.history_point then
                table.insert(self.history, text)
            end
        end
        self.history_point = nil
    end
    table.insert(self.history, text)
end

function TextBoxBase:fixed_text(text)
	if self._parent.filter == "number" then
		local num = tonumber(text) 
        if num then
		    return string.format("%." .. self._parent.floats .."f", math.clamp(num, self._parent.min or num, self._parent.max or num))
        end
	else
		return text
	end
end

function TextBoxBase:enter_text(text, s)
    local number = self._parent.filter == "number"
    if not self.menu:Enabled() or number and (tonumber(s) == nil and s ~= "-" and s ~= ".") then
        return
    end
    for _, c in pairs(self._forbidden) do
        if s == c then
            return
        end
    end
    if (self.menu._highlighted == self._parent or self.menu._openlist == self._parent) and self.cantype and not ctrl() then
        text:replace_text(s)       
        self:add_history_point(number and (tonumber(text:text()) or self:one_point_back()) or text:text())
        self:update_caret()
        if self:fixed_text(text:text()) == text:text() then
            self:update_text(text:text(), true, false, true)
        end
    end
end

function TextBoxBase:KeyPressed(o, k)
    if not alive(self.panel) then
        return
    end
	local text = self.panel:child("text")

 	if k == Idstring("enter") or k == Idstring("esc") then
 		self.cantype = false
        text:stop()
 		self:CheckText(text)
 	end
     if self.cantype then
        text:stop()
        text:animate(callback(self, self, "key_hold"), k)
        return true
    end
	self:update_caret()
end

function TextBoxBase:update_caret()
    if not self._parent:alive() or not alive(self.panel) then
        self.cantype = false
        return
    end
    local text = self.panel:child("text")
    local lines = math.max(1, text:number_of_lines())
    local _,_,_,h = text:text_rect()
    h = math.max(h, text:font_size())
    if not self.lines or (self.lines > 1 and self.lines <= lines) then
        self.panel:set_h(h)
        self.panel:parent():set_h(h)
        text:set_h(h)
        self.panel:child("line"):set_bottom(h)
        self._parent:SetText(self._parent.text)
    end
    if self.parent then
        self.parent:AlignItems()
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
    local caret = self.panel:child("caret")
    caret:set_world_position(x, y + 1)
    caret:set_visible(self.cantype)
    caret:set_color(text:color():with_alpha(1))
    self.caret_visible = self.cantype
end

function TextBoxBase:MousePressed(button, x, y)
    if not alive(self.panel) or not alive(self.panel:child("text")) then
        return
    end
    local text = self.panel:child("text")
    local cantype = self.cantype
    self.cantype = text:inside(x,y) and button == Idstring(self.btn)
    if self.cantype then
        BeardLib:AddUpdater("CheckMouseOut"..tostring(self), function()
            local x,y = managers.mouse_pointer:world_position()
            local cantype = self.cantype
            if x ~= self._old_x or y ~= self._old_y then
                self.cantype = self.panel:inside(x,y) and self.cantype or false
            end
            if cantype and not self.cantype then
                self:CheckText(text)
            end
            self:update_caret()
            if not self.cantype then
                BeardLib:RemoveUpdater("CheckMouseOut"..tostring(self))
            end
            self._old_x = x
            self._old_y = y
        end, true)
        local i = text:point_to_index(x, y)
        self._start_select = i
        self._select_neg = nil
        text:set_selection(i, i)
        self:update_caret()
        return true
    elseif cantype == true and self.cantype == false then
        self:update_text(text:text(), false, true, true)
        return true
    end
end

function TextBoxBase:MouseMoved(x, y)
    local text = self.panel:child("text")
    if self._start_select then
        local i = text:point_to_index(x, y)
        local s, e = text:selection()
        local old = self._select_neg
        if self._select_neg == nil or (s == e) then
            self._select_neg = (x - self.menu._old_x) < 0
        end
        if self._select_neg then
            text:set_selection(i - 1, self._start_select)
        else
            text:set_selection(self._start_select, i + 1)
        end
    end
end

function TextBoxBase:MouseReleased(button, x, y)
    self._start_select = nil
end