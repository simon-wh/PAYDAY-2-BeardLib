ScrollablePanelModified = ScrollablePanelModified or class(ScrollablePanel)
local PANEL_PADDING = 4

function ScrollablePanelModified:init(panel, name, data)
	ScrollablePanelModified.super.init(self, panel, name, data)
	data = data or {}
	data.scroll_width = data.scroll_width or 4
	data.color = data.color or Color.black
	self._scroll_width = data.scroll_width
	self._scroll_speed = data.scroll_speed or 28
	self._count_invisible = data.count_invisible
	self._debug = data.debug

	local panel = self:panel()
	self:canvas():set_w(panel:w() - data.scroll_width)
	panel:child("scroll_up_indicator_arrow"):hide()
	panel:child("scroll_down_indicator_arrow"):hide()
	self._scroll_bar:hide()
	self._scroll_bar:set_w(data.scroll_width)
	self._scroll_bar:set_right(self:panel():w())
	self._scroll_bar_box_class:hide()

	self._scroll_rect = self._scroll_bar:rect({
		name = "scroll_rect",
		color = data.color,
		halign = "grow",
		valign = "grow"
	})

	self._scroll_bg = panel:rect({
		name = "scroll_bg",
		color = data.color:contrast():with_alpha(0.1),
		visible = not data.hide_scroll_background,
		x = self._scroll_bar:x(),
		w = data.scroll_width,
		valign = "grow",
	})

	if data.hide_shade then
		panel:child("scroll_up_indicator_shade"):hide()
		panel:child("scroll_down_indicator_shade"):hide()
	end
	self:set_scroll_color(data.color)
end

function ScrollablePanelModified:set_scroll_color(color)
	color = color or Color.white
	self._scroll_rect:set_color(color)
end

function ScrollablePanelModified:set_size(...)
    ScrollablePanelModified.super.set_size(self, ...)
	self:canvas():set_w(self:canvas_max_width())
	self._scroll_bar:set_right(self:panel():w())
	self._scroll_bg:set_x(self._scroll_bar:x())
	self:set_scroll_state()
end

function ScrollablePanelModified:update_canvas_size(additional_h)
	local orig_w = self:canvas():w()
	local max_h = 0
	local children = self:canvas():children()
	local visible_children = {}
	for i, panel in pairs(children) do
		local item = panel:script().menuui_item
		if self._count_invisible or (item and item.visible) or panel:visible() then
			table.insert(visible_children, panel)
			local h = panel:bottom()
			if max_h < h then
				max_h = h
			end
		end
	end
	local scroll_h = self:canvas_scroll_height()
	local show_scrollbar = scroll_h > 0 and scroll_h < max_h
	local max_w = show_scrollbar and self:canvas_scroll_width() or self:canvas_max_width()

	self:canvas():grow(max_w - self:canvas():w(), max_h - self:canvas():h())
	self:canvas():set_w(math.min(self:canvas():w(), self:scroll_panel():w()))
	if self._on_canvas_updated then
		self._on_canvas_updated(max_w)
	end

	max_h = 0

	for _, panel in pairs(visible_children) do
		local h = panel:bottom()
		if max_h < h then
			max_h = h
		end
	end

	max_h = max_h + (additional_h or 0)

	if max_h <= self:scroll_panel():h() then
		max_h = self:scroll_panel():h()
	end

	self:set_canvas_size(nil, max_h)
end

function ScrollablePanelModified:is_scrollable()
	if not self:alive() then
		return false
	end
	return (self:canvas():h() - self:scroll_panel():h()) > 2
end

function ScrollablePanelModified:canvas_max_width()
	return self:canvas_scroll_width()
end

function ScrollablePanelModified:force_scroll()
	if self:canvas():h() <= self:scroll_panel():h() then
		self:canvas():set_y(0)
	else
		self:perform_scroll(0, 0)
	end
end

function ScrollablePanelModified:scroll(x, y, direction, force)
	if self:panel():inside(x, y) or force then
		self:perform_scroll(self._scroll_speed * TimerManager:main():delta_time() * 200, direction)
		return true
	end
end

function ScrollablePanelModified:mouse_moved(button, x, y)
	if self._grabbed_scroll_bar then
		self:scroll_with_bar(y, self._current_y)
		self._current_y = y
		return true, "grab"
	elseif alive(self._scroll_bar) and self._scroll_bar:visible() and self._scroll_bar:inside(x, y) then
		return true, "hand"
	end
end

function ScrollablePanelModified:canvas_scroll_width()
	return math.max(0, self:scroll_panel():w() - self._scroll_bar:w())
end

function ScrollablePanelModified:set_canvas_size(w, h)
	w = w or self:canvas():w()
	h = h or self:canvas():h()
	self:canvas():set_size(w, h)
	self:force_scroll()
	self:set_scroll_state()
end

function ScrollablePanelModified:set_scroll_state()
	local show_scrollbar = (self:canvas():h() - self:scroll_panel():h()) > 0.5

	--Weird bug, y and h are basically "nan" if I don't set them here.
	self._scroll_rect:set_y(0)
	self._scroll_rect:set_h(self._scroll_bar:h())
	self._scroll_bar_box_class:hide()

	if not show_scrollbar then
		self._scroll_bar:set_alpha(0)
		self._scroll_bar:hide()
	else
		self._scroll_bar:set_alpha(1)
		self._scroll_bar:show()
		self:_set_scroll_indicator()
		self:_check_scroll_indicator_states()
	end
end

function ScrollablePanelModified:set_element_alpha_target(element, target, speed)
	play_anim(self:panel():child(element), {set = {alpha = target}})
end

function ScrollablePanelModified:scrollbar_x_padding()
	return self._x_padding or PANEL_PADDING
end

function ScrollablePanelModified:scrollbar_y_padding()
	return self._y_padding or PANEL_PADDING
end

function ScrollablePanelModified:_set_scroll_indicator()
	self._scroll_bar:set_h(math.max((self:panel():h() * self:scroll_panel():h()) / self:canvas():h(), self._bar_minimum_size))
end

function ScrollablePanelModified:_check_scroll_indicator_states()
	local canvas_h = self:canvas():h() ~= 0 and self:canvas():h() or 1
	local at = self:canvas():y() / (self:scroll_panel():h() - canvas_h)
	local max = self:panel():h() - self._scroll_bar:h()

	self._scroll_bar:set_y(max * at)
end