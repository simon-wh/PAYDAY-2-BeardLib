BeardLib.Items.Slider = BeardLib.Items.Slider or class(BeardLib.Items.Item)
local Slider = BeardLib.Items.Slider
Slider.type_name = "Slider"
function Slider:Init()
    self.value = self.value or 1
    self.size_by_text = false
	Slider.super.Init(self)
    self.step = self.step or 1
    self.value = tonumber(self.value) or 0
    self.min = self.min or self.value
    self.max = self.max or self.value
    if self.max or self.min then
        self.value = math.clamp(self.value, self.min, self.max)
    end
    self:WorkParam("floats", 3)
    self.filter = "number"
    self.min = self.min or 0
    self.max = self.max or self.min
    local item_width = self.panel:w() * self.control_slice
    local slider_width = item_width * self.slider_slice
    local text_width = item_width - slider_width

    local fgcolor = self:GetForeground()
    self._textbox = BeardLib.Items.TextBoxBase:new(self, {
        lines = 1,
        btn = "1",
        panel = self.panel,
        fit_text = true,
        text_align = "center",
        layer = 10,
        line = false,
        w = text_width,
        value = self.value,
    })
    self._slider = self.panel:panel({
        w = slider_width,
        name = "slider",
        layer = 4,
    })
    local ch = self.size - 4
    self.circle = self._slider:bitmap({
        name = "circle",
        w = ch,
        h = ch,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {92, 1, 34, 34},
        layer = 3,
        color = fgcolor,
    })
    self.circle:set_center_y(self._slider:h() / 2)

    self.sfg = self._slider:rect({
        name = "fg",
        x = ch / 2,
        w = self._slider:w() * (self.value / self.max),
        h = 2,
        layer = 2,
        color = fgcolor
    })
    self.sfg:set_center_y(self._slider:h() / 2)

    self.sbg = self._slider:rect({
        name = "bg",
        x = ch / 2,
        w = self._slider:w() - ch,
        h = 2,
        layer = 1,
        color = fgcolor:with_alpha(0.25),
    })
    self.sbg:set_center_y(self._slider:h() / 2)


    self._slider:set_right(self._textbox.panel:x())
    self._mouse_pos_x, self._mouse_pos_y = 0,0
    self._textbox:PostInit()
end

function Slider:SetStep(step)
    self.step = step
end

function Slider:TextBoxSetValue(value, run_callback, reset_selection, no_format)
    value = tonumber(value) or 0
    if self.max or self.min then
        value = math.clamp(value, self.min, self.max)
    end
    value = tonumber(value)
    local final_number = self.floats and string.format("%." .. self.floats .. "f", value) or tostring(value)
    local text = self._textbox.text
    self.sfg:set_w(self.sbg:w() * ((value - self.min) / (self.max - self.min)))
    self._slider:child("circle"):set_center(self.sfg:right(), self.sfg:center_y())
    if not no_format then
        text:set_text(final_number:gsub("%.0+$", ""))
    end
    if reset_selection then
        text:set_selection(text:text():len())
    end
    self._before_text = self.value
    Slider.super.SetValue(self, value, run_callback)
end

function Slider:SetValue(value, ...)
    if not self:alive() then
        return false
    end
    if self.value ~= value then
        self._textbox:add_history_point(value)
    end
    self:TextBoxSetValue(value, ...)
    return true
end

function Slider:SetValueByPercentage(percent, run_callback)
    local max_min_diff = self.max - self.min
    local val = self.min + max_min_diff * percent
    if self.round_sliding and not ctrl() then
        local round
        if type(self.round_sliding) == "number" then
            round = self.round_sliding
        else
            round = max_min_diff > 1 and 0 or math.abs(math.ceil(math.log10(max_min_diff))) + 1
        end
        self:SetValue((self.round_sliding and val ~= self.min and val ~= self.max) and math.round_with_precision(val, round) or val, run_callback, true)
    else
        self:SetValue(val, run_callback, true)
    end
end

function Slider:MouseReleased(b, x, y)
    self._textbox:MouseReleased(b, x, y)
    return Slider.super.MouseReleased(self, b,x,y)
end

function Slider:DoHighlight(highlight)
    Slider.super.DoHighlight(self, highlight)
    self._textbox:DoHighlight(highlight)
    local fgcolor = self:GetForeground(highlight)
    if self.sfg then
        if self.animate_colors then
            play_color(self.sfg, fgcolor)
            play_color(self.sbg, fgcolor:with_alpha(0.25))
            play_color(self.circle, fgcolor)
        else
            self.sfg:set_color(fgcolor)
            self.sbg:set_color(fgcolor:with_alpha(0.25))
            self.circle:set_color(fgcolor)
        end
    end
end

local wheel_up = Idstring("mouse wheel up")
local wheel_down = Idstring("mouse wheel down")
function Slider:MousePressed(button, x, y)
	local result, state = Slider.super.MousePressed(self, button, x, y)
	if state == self.UNCLICKABLE or state == self.INTERRUPTED then
		return result, state
	end

    self._textbox:MousePressed(button, x, y)
    local inside = self._slider:inside(x,y)
    if inside then
        local wheelup = (button == wheel_up and 0) or (button == wheel_down and 1) or -1
        if self.wheel_control and wheelup ~= -1 then
            self:SetValue(self.value + ((wheelup == 1) and -self.step or self.step), true, true)
            return true
        end
    	if button == self.click_btn then
            self.menu._slider_hold = self
            if self.max or self.min then
                local slider_bg = self._slider:child("bg")
                local where = (x - slider_bg:world_left()) / (slider_bg:world_right() - slider_bg:world_left())
                managers.menu_component:post_event("menu_enter")
                self:SetValueByPercentage(where, true)
            end
            return true
        end
	end
	return result, state
end

function Slider:SetValueByMouseXPos(x)
    if not alive(self.panel) then
        return
    end
    local slider_bg = self._slider:child("bg")
    self:SetValueByPercentage((x - slider_bg:world_x()) / (slider_bg:w()), true)
end
