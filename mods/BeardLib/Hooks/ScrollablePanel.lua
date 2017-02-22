Hooks:PostHook(ScrollablePanel, "init", "BeardLibScrollablePanelInit", function(self, panel, name, data)
	data = data or {}
	self._scroll_speed = data.scroll_speed or 28
	if data.scroll_width then
		self._scroll_width = true
		self:canvas():set_w(self:panel():w() - (data.scroll_width * 2))
		self:panel():child("scroll_up_indicator_arrow"):set_size(data.scroll_width, data.scroll_width)
		self:panel():child("scroll_up_indicator_arrow"):set_world_left(self:canvas():world_right() + 2)
		self:panel():child("scroll_down_indicator_arrow"):set_size(data.scroll_width, data.scroll_width)
		self:panel():child("scroll_down_indicator_arrow"):set_world_left(self:canvas():world_right() + 2)
		self._scroll_bar:set_w(data.scroll_width)
		self._scroll_bar:set_center_x(self:panel():child("scroll_down_indicator_arrow"):center_x())
	end
	if data.hide_shade then
		self:panel():child("scroll_up_indicator_shade"):hide()
		self:panel():child("scroll_down_indicator_shade"):hide()
	end
end)

Hooks:PostHook(ScrollablePanel, "set_size", "BeardLibScrollablePanelSetSize", function(self)
	if self._scroll_width then
		self:canvas():set_w(self:canvas_max_width())
		self:panel():child("scroll_up_indicator_arrow"):set_world_left(self:canvas():world_right() + 2)
		self:panel():child("scroll_down_indicator_arrow"):set_world_left(self:canvas():world_right() + 2)
		self._scroll_bar:set_center_x(self:panel():child("scroll_down_indicator_arrow"):center_x())
	end
end)

function ScrollablePanel:canvas_max_width()
	if self._scroll_width then
		return self:canvas_scroll_width()
	else
		return self:scroll_panel():w()
	end 
end

function ScrollablePanel:scroll(x, y, direction)
	if self:panel():inside(x, y) then
		self:perform_scroll(self._scroll_speed * TimerManager:main():delta_time() * 200, direction)
		return true
	end
end

function ScrollablePanel:mouse_moved(button, x, y)
	if self._grabbed_scroll_bar then
		self:scroll_with_bar(y, self._current_y)
		self._current_y = y
		return true, "grab"
	elseif alive(self._scroll_bar) and self._scroll_bar:visible() and self._scroll_bar:inside(x, y) then
		return true, "hand"
	elseif self:panel():child("scroll_up_indicator_arrow"):inside(x, y) then
		if self._pressing_arrow_up then
			self:perform_scroll(self._scroll_speed * 0.1, 1)
		end
		return true, "link"
	elseif self:panel():child("scroll_down_indicator_arrow"):inside(x, y) then
		if self._pressing_arrow_down then
			self:perform_scroll(self._scroll_speed * 0.1, -1)
		end
		return true, "link"
	end
end

function ScrollablePanel:canvas_scroll_width()
	if self._scroll_width then
		return self:scroll_panel():w() - ((self._scroll_bar:w() * 2) - 2)
	else
		return self:scroll_panel():w() - self:padding() - 5
	end
end