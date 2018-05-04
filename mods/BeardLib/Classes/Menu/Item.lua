BeardLib.Items.Item = BeardLib.Items.Item or class(BeardLib.Items.BaseItem)
local Item = BeardLib.Items.Item

function Item:Init(params)
	self:WorkParams(params)
	self.panel = self.parent_panel:panel({
		name = self.name,
		visible = self.visible,
		alpha = self.enabled and self.enabled_alpha or self.disabled_alpha,
		w = self.w,
		h = self.h or self.size,
	})

	self.panel:script().menuui_item = self
		
	self:InitBasicItem()
	if self.divider_type and alive(self.title) then
		self.title:set_world_center_y(self.panel:world_center_y())
	end
	self:Reposition()
    if self.items then
		self._list = BeardLib.Items.ContextMenu:new(self, self.parent_panel:layer() + 100) 
	end
	if self.override_panel then
		self.override_panel:AddItem(self)
	end
end

function Item:GetForeground(highlight)
	highlight = highlight or self.highlight
	local fgcolor = highlight and self.foreground_highlight or self.foreground
	return NotNil(fgcolor) or (highlight and self.highlight_color or self.background_color or Color.black):contrast()
end

function Item:SetEnabled(enabled)
	Item.super.SetEnabled(self, enabled)
	if self:alive() then
		self.panel:set_alpha(self.enabled and self.enabled_alpha or self.disabled_alpha)
	end
	if self._list then
		self._list:hide()
	end
	if not self.enabled then
		self:UnHighlight()
	end
end

local enter_ids = Idstring("enter")
function Item:KeyPressed(o, k)
	if self._adopted_items then
		for _, item in pairs(self._adopted_items) do
			if item.KeyPressed and item:KeyPressed(o, k) then
				return true
			end
		end
	end
	if k == enter_ids and self.type_name == "Button" and self.menu._highlighted == self then
		self:RunCallback()
	end
end

local mouse_1 = Idstring("1")
Item.UNCLICKABLE = 1 --null is "unknown".
Item.CLICKABLE = 2
Item.INTERRUPTED = 3
function Item:MousePressed(button, x, y)
	if not self.menu_type then
	    for _, item in pairs(self._adopted_items) do
	        if item:MousePressed(button, x, y) then
	            return true
	        end
	    end
	end

    if not self:MouseCheck(true) then
        return false, self.UNCLICKABLE
	end

	if self:MouseInside(x,y) then
		if self.on_click then
			if self:on_click(button, x, y) == false then
				return false, self.INTERRUPTED
			end
		end
		if self.button_type and button == self.click_btn then
            self:RunCallback()
			return true
		end

		local right_click = button == mouse_1
		if self._list and not self.menu._openlist then
			if (not self.open_list_key and right_click) or (self.open_list_key and button == self.open_list_key:id()) then
				self._list:update_search()
				self._list:show()
				return true
			end
		end
	
		if self.on_right_click and (not self._list or self.open_list_key ~= mouse_1) then
			self:RunCallback(self.on_right_click)
		end
		return false, self.CLICKABLE
	else
		return false
    end
end

function Item:SetBorder(config)
	self.border_color = NotNil(config.color, self.border_color)
	self.border_left = NotNil(config.left, self.border_left)
	self.border_right = NotNil(config.right, self.border_right)
	self.border_top = NotNil(config.top, self.border_top)
	self.border_bottom = NotNil(config.bottom, self.border_bottom)
	self:MakeBorder()
end

function Item:SetColor(color)
	self.border_left = NotNil(self.border_left, true)
	self:SetBorder({color = color})
	self:_SetText(self.text)
end

function Item:_SetText(text)
    if self:alive() and self:title_alive() then
        self.text = text
        self.title:set_text(self.localized and text and managers.localization:text(text) or text)
        local offset_x = math.max(self.border_left and self.border_width or 0, self.text_offset[1])
		local offset_y = math.max(self.border_top and self.border_size or 0, self.text_offset[2])
		local offset_w = offset_x * 2
		local offset_h = offset_y * 2

		local lines = math.max(1, self.title:number_of_lines())
		
		self.title:set_shape(offset_x, offset_y, self.panel:w() - offset_w, math.max(self.title:line_height(), self.panel:h() - offset_h))
        local _,_,w,h = self.title:text_rect()
        self.title:set_h(math.clamp(h, self.min_height and self.min_height - offset_h or h, self.max_height and self.max_height - offset_h or h))
        if self.size_by_text then
			local new_w = w + offset_w + (self.type_name == "Toggle" and self.size or 0)
			local new_h = self.title:bottom() + offset_y
            self.panel:set_size(math.clamp(new_w, self.min_width or 0, self.max_width or new_w), math.clamp(new_h, self.min_height or 0, self.max_height or new_h))
            self.w, self.h = self.panel:size()
            self.title:set_w(math.clamp(w, self.min_width and self.min_width - offset_w or w, self.max_width and self.max_width - offset_w or w))
		end
		if self.SetScrollPanelSize then
            self:SetScrollPanelSize()
		elseif not self.size_by_text and not self.h then
			local new_h = math.max(self.title:bottom() + offset_y, self.size, self._textbox and alive(self._textbox.panel) and self._textbox.panel:h() or 0)
            self.panel:set_h(math.clamp(new_h, self.min_height or 0, self.max_height or new_h))
		end
        return true
    end
    return false
end

function Item:SetTextLight(text)
	self.text = text
	self.title:set_text(self.localized and text and managers.localization:text(text) or text)
end

function Item:SetText(text)
	self:_SetText(text)
	if self.parent.auto_align then
		self.parent:AlignItems()
	end
end

function Item:DoHighlight(highlight)
	local foreground = self:GetForeground(highlight)
	if self.animate_colors then
		if self.bg then play_anim(self.bg, {set = {alpha = highlight and self.highlight_bg and self.highlight_bg:visible() and 0 or 1}}) end
		if self.highlight_bg then play_anim(self.highlight_bg, {set = {alpha = highlight and 1 or 0}}) end
		if self.title then play_color(self.title, foreground) end
		if self.border_highlight_color then
			for _, v in pairs({"left", "top", "right", "bottom"}) do
				local side = self.panel:child(v)
				if alive(side) and side:visible() then
					play_color(side, highlight and self.border_highlight_color or self.border_color or foreground)
				end
			end
		end
	else
		if self.bg then self.bg:set_alpha(highlight and self.highlight_bg and self.highlight_bg:visible() and 0 or 1) end
		if self.highlight_bg then self.highlight_bg:set_alpha(highlight and 1 or 0) end
		if self.title then self.title:set_color(foreground) end
		if self.border_highlight_color then
			for _, v in pairs({"left", "top", "right", "bottom"}) do
				local side = self.panel:child(v)
				if alive(side) and side:visible() then
					side:set_color(highlight and self.border_highlight_color or self.border_color or foreground)
				end
			end
		end
	end
end

function Item:Highlight()
    if not self:alive() then
        return
    end
    self:DoHighlight(true)
    managers.mouse_pointer:set_pointer_image("link")
    if self.menu._highlighted and self.menu._highlighted ~= self then
        self.menu._highlighted:UnHighlight()
    end
    self.highlight = true
    self.menu._highlighted = self
    if self.help then
        self.menu:ShowDelayedHelp(self)
    end
end

function Item:UnHighlight()
	if self.menu._highlighted == self then
		if managers.mouse_pointer.set_pointer_image then
			managers.mouse_pointer:set_pointer_image("arrow")
		end
		self.menu._highlighted = nil
	end
	self.highlight = false	
	if not self:alive() then
		return 
	end
	self:DoHighlight(false)
end

function Item:MouseMoved(x, y)
	if self._has_adopted_items then
		if self.menu_type then
			for _, item in pairs(self._adopted_items) do
				if item:MouseInside(x,y) then
					return false
				end
			end
		else
			for _, item in pairs(self._adopted_items) do
				if item:MouseMoved(x, y) then
					return true
				end
			end	
		end
	end
    if not self:MouseCheck() then
        return false
    end
    if not self.menu._openlist and not self.menu._slider_hold then
        if self:MouseInside(x,y) then
            self:Highlight()
            return true
        elseif not self.parent.always_highlighting then
            self:UnHighlight()
            return false
        end
    end
end

function Item:AlignRight(last_item)
	if last_item then
		local p = last_item:Panel()
		self:Panel():set_righttop(p:x() - self:OffsetX(), p:y())
	else
		self:SetPositionByString("RightTop")
		self:Panel():move(-self:OffsetX(), self:OffsetY())
	end
end

function Item:AlignLeft(last_item)
	if last_item then
		local p = last_item:Panel()
		self:Panel():set_position(p:x() + self:OffsetX(), p:y())
	else
		self:SetPositionByString("LeftTop")
		self:Panel():move(self:OffsetX(), self:OffsetY())
	end
end

function Item:MouseReleased(button, x, y)
	if self._list then
		self._list:MouseReleased(button, x, y)
	end
end