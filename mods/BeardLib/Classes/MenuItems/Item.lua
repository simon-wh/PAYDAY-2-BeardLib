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
	self.override_parent = self.override_parent
	self:Reposition()
    if self.items then
		self._list = ContextMenu:new(self, 20) 
    end
end

function Item:SetEnabled(enabled)
	Item.super.SetEnabled(self, enabled)
	if self.title then
		self.title:set_alpha(enabled and 1 or 0.5)
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

function Item:SetColor(color)
	self.color = color
	if color then
		self.div:set_color(color)
	end
	if alive(self.div) then
		self.div:set_visible(color ~= nil)
	end
	self:SetText(self.text)
end

function Item:SetText(text)
	if self.title then
		self.text = text
		self.title:set_text(self.localized and text and managers.localization:text(text) or text)
		local lines = math.max(1, self.title:number_of_lines()) 
		self.panel:set_h(math.max(self.items_size * lines, self.panel:h()))
		local offset = math.max(self.color and 2 or 0, self.text_offset)
		self.title:set_shape(offset, 0, self.panel:w() - offset, self.panel:h())
		local _,_,w,h = self.title:text_rect()
		if self.size_by_text then
			self.panel:set_size(w + (offset * 2) + (self.type_name == "Toggle" and self.items_size or 0), h)
			self.w, self.h = self.panel:size()
			self.title:set_shape(offset, 0, w, h)
		end
	end
end

function Item:DoHighlight(highlight)
	self.bg:set_color(highlight and self.marker_highlight_color or self.marker_color)
	if self.title then self.title:set_color(highlight and self.text_highlight_color or self.text_color) end
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