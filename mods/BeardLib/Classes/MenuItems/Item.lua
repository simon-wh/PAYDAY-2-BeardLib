Item = Item or class(BaseItem)
function Item:Init()
	if self.override_parent then
		self.override_parent:AddItem(self)
	end
	self.panel = self.parent_panel:panel({
		name = self.name,
		w = self.w,
		h = self.h or self.items_size,
	})
	self:InitBasicItem()
	if self.divider_type then
		self.title:set_world_center_y(self.panel:world_center_y())
	end
	self._my_items = {}
	self:Reposition()
    if self.items then
		self._list = ContextMenu:new(self, 20) 
    end
end

function Item:Get2ndBackground(color)
	return (color or self.background_color or Color.white):contrast(Color(0.85, 0.85, 0.85), Color(0.15, 0.15, 0.15))
end

function Item:SetEnabled(enabled)
	Item.super.SetEnabled(self, enabled)
	if self.title then
		self.title:set_alpha(enabled and 1 or 0.5)
	end
	for _, v in pairs({"left", "top", "right", "bottom"}) do
		local side = self.panel:child(v)
		if alive(side) then
			side:set_alpha(enabled and 1 or 0.5)
		end
	end
end

function Item:KeyPressed(o, k)
	if self._my_items then
		for _, item in pairs(self._my_items) do
			if item.KeyPressed and item:KeyPressed(o, k) then
				return true
			end
		end
	end
end

function Item:MousePressed(button, x, y)
	if not self.menu_type then
	    for _, item in pairs(self._my_items) do
	        if item:MousePressed(button, x, y) then
	            return true
	        end
	    end
	end
    if not self:MouseCheck(true) then
        return
    end
    if self:alive() and self:MouseInside(x,y) then
        if button == Idstring("0") then
            self:RunCallback()
            return true
        elseif button == Idstring("1") then
            if self._list then
                self._list:show()
            end
        end
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
	self:SetText(self.text)
end

function Item:SetText(text)
	if self:alive() and self.title then
		self.text = text
		self.title:set_text(self.localized and text and managers.localization:text(text) or text)
		local lines = math.max(1, self.title:number_of_lines()) 
		self.panel:set_h(math.max(self.items_size * lines, self.panel:h()))
		local offset = math.max(self.border_left and self.border_width or 0, self.text_offset)
		self.title:set_shape(offset, 0, self.panel:w() - offset, self.panel:h())
		local _,_,w,h = self.title:text_rect()
		self.title:set_h(h)
		if self.size_by_text then
			self.panel:set_size(w + (offset * 2) + (self.type_name == "Toggle" and self.items_size or 0), h)
			self.w, self.h = self.panel:size()
			self.title:set_shape(offset, 0, w, h)
		end
		if self.SetSize then
			self:SetSize(nil, nil, true)
		end
		return true
	end
	return false
end

function Item:DoHighlight(highlight)
	if self.bg then self.bg:set_color(highlight and self.marker_highlight_color or self.marker_color) end
	if self.title then self.title:set_color(highlight and self.text_highlight_color or self.text_color) end
	if self.border_highlight_color then
		for _, v in pairs({"left", "top", "right", "bottom"}) do
			local side = self.panel:child(v)
			if alive(side) and side:visible() then
				side:set_color(highlight and self.border_highlight_color or self.border_color)
			end
		end
	end
end

function Item:Highlight()
	if not self:alive() then
		return
	end
	self:DoHighlight(true)
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
		self.menu._highlighted = nil
	end
	self.highlight = false	
	if not self:alive() then
		return 
	end
	self:DoHighlight(false)
end

function Item:MouseMoved(x, y)
	if not self.menu_type then
	    for _, item in ipairs(self._my_items) do
	        if item:MouseMoved(x, y) then
	            return true
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
        else
            self:UnHighlight()
            return false
        end
    end
end

function Item:MouseReleased(button, x, y)
	if self._list then
		self._list:MouseReleased(button, x, y)
	end
end