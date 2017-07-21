ScrollablePanelModified = ScrollablePanelModified or class(ScrollablePanel)
function ScrollablePanelModified:init(panel, name, data)
	ScrollablePanelModified.super.init(self, panel, name, data)
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
	self:set_scroll_color(data.color)
end

function ScrollablePanelModified:set_scroll_color(color)
	color = color or Color.white
	local function set_boxgui_img(pnl)
		for _, child in pairs(pnl:children()) do
			local typ = CoreClass.type_name(child)
			if typ == "Panel" then
				set_boxgui_img(child)
			elseif typ == "Bitmap" then
				if child:texture_name() == Idstring("guis/textures/pd2/shared_lines") then
					child:set_image("units/white_df")
				end
				child:set_color(color)
			end
		end
	end
	set_boxgui_img(self:panel())
end

function ScrollablePanelModified:set_size(...)
    ScrollablePanelModified.super.set_size(self, ...)
    if self._scroll_width then
        self:canvas():set_w(self:canvas_max_width())
        local scroll_down_indicator_arrow = self:panel():child("scroll_down_indicator_arrow")
        scroll_down_indicator_arrow:set_world_rightbottom(self:panel():world_right() - 2, self:panel():world_bottom())
        self:panel():child("scroll_up_indicator_arrow"):set_world_righttop(self:panel():world_right() - 2, self:panel():world_top())
        self._scroll_bar:set_center_x(scroll_down_indicator_arrow:center_x())
        self._scroll_bar:set_world_bottom(scroll_down_indicator_arrow:world_top())
    end
end

function ScrollablePanelModified:is_scrollable()
	return (self:canvas():h() - self:scroll_panel():h()) > 1
end

function ScrollablePanelModified:canvas_max_width()
	if self._scroll_width then
		return self:canvas_scroll_width()
	else
		return self:scroll_panel():w()
	end 
end

function ScrollablePanelModified:scroll(x, y, direction)
	if self:panel():inside(x, y) then
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

function ScrollablePanelModified:canvas_scroll_width()
	if self._scroll_width then
		return self:scroll_panel():w() - ((self._scroll_bar:w() * 2) - 2)
	else
		return self:scroll_panel():w() - self:padding() - 5
	end
end
function ScrollablePanelModified:set_canvas_size(w, h)
	w = w or self:canvas():w()
	h = h or self:canvas():h()
	if h <= self:scroll_panel():h() then
		h = self:scroll_panel():h()
		self:canvas():set_y(0)
	end
	self:canvas():set_size(w, h)
	local show_scrollbar = (h - self:scroll_panel():h()) > 0.5
	if not show_scrollbar then
		self._scroll_bar:set_alpha(0)
		self._scroll_bar:set_visible(false)
		self._scroll_bar_box_class:hide()
		self:set_element_alpha_target("scroll_up_indicator_arrow", 0)
		self:set_element_alpha_target("scroll_down_indicator_arrow", 0)
		self:set_element_alpha_target("scroll_up_indicator_shade", 0)
		self:set_element_alpha_target("scroll_down_indicator_shade", 0)
	else
		self._scroll_bar:set_alpha(1)
		self._scroll_bar:set_visible(true)
		self._scroll_bar_box_class:show()
		self:_set_scroll_indicator()
		self:_check_scroll_indicator_states()
	end
end

function ScrollablePanelModified:set_element_alpha_target(element, target, speed)
	QuickAnim:Work(self:panel():child(element), "alpha", target)
end