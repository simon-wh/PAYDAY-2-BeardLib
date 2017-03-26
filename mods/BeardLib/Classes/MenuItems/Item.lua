Item = Item or class()
function Item:init(parent, params)
	self.type_name = self.type_name or "Button"
	if params.override_parent then
		params.override_parent:AddItem(self)
	end
	params.panel = params.parent_panel:panel({
		name = params.name,
		w = params.w,
		h = params.h or params.items_size,
	})
	params.bg = params.panel:rect({
		name = "bg",
		color = params.marker_color,
		alpha = params.marker_alpha,
		halign="grow",
		valign="grow",
		layer = 0
	})
	local offset = math.max(params.color and 2 or 0, params.text_offset)
	params.title = params.panel:text({
		name = "title",
		x = offset,
		w = params.panel:w() - offset,
		h = params.panel:h(),
		align = params.align,
		wrap = not params.size_by_text,
		word_wrap = not params.size_by_text,
		text = params.text,
		layer = 3,
		color = params.text_color or Color.black,
		font = params.font,
		font_size = params.items_size
	})
	params.div = params.panel:rect({
		color = params.color,
		visible = not not params.color,
		w = 2,
	})
	if self.type_name == "Divider" then
		params.title:set_world_center_y(params.panel:world_center_y())
	end
	self._items = {}
	params.option = params.option or params.name
	table.merge(self, params)
	self.override_parent = params.override_parent
	self:SetText(self.text)
	self:SetPosition(params.position)
	if params.group then
		if params.group.type_name == "ItemsGroup" then
			params.group:AddItem(self)
		else
			BeardLib:log(self.name .. " group is not a group item!")
		end
	end
    if self.items then
		self._list = ContextMenu:new(self, 20) 
    end
end

function Item:SetParam(param, value)
    self[param] = value
end

function Item:TryRendering()
	local p = self.parent_panel
	local visible = false
	if alive(self.panel) then		
	 	visible = p:inside(p:world_x(), self.panel:world_y()) == true or p:inside(p:world_x(), self.panel:world_bottom()) == true
		self.panel:set_visible(visible)
	end
	return visible
end

function Item:Panel()
	return self.panel
end

function Item:__tostring()
	return string.format("[%s - %s]", tostring(self.name), tostring(self.type_name))
end

function Item:alive()
	return alive(self.panel) 
end

function Item:SetPosition(x,y)
	self.parent.SetPosition(self, x, y)
end

function Item:Reposition()
	self.parent.Reposition(self)
end

function Item:SetPositionByString(pos)
	if not pos then
		BeardLib:log("[ERROR] Position for item %s in menu %s is nil!", tostring(self.name), tostring(self.parent.name))
		return
	end
    local pos_panel = self.parent_panel
    for _, p in pairs({"center", "bottom", "top", "right", "left"}) do
        if pos:lower():match(p) then
            self.panel["set_world_"..p](self.panel, pos_panel["world_"..p](pos_panel))
        end
    end
end

function Item:AddItem(item)
	table.insert(self._items, item)
end

function Item:SetValue(value, run_callback)
	if run_callback then
		run_callback = value ~= self.value
	end
	self.value = value
	if run_callback then
		self:RunCallback()
	end
end

function Item:Value()
	return self.value
end

function Item:SetEnabled(enabled)
	self.enabled = enabled
	self.title:set_alpha(enabled and 1 or 0.5)
end

function Item:Index()
	return self.parent:GetIndex(self.name)
end

function Item:KeyPressed(o, k)
	if self._items then
		for _, item in pairs(self._items) do
			if item.KeyPressed and item:KeyPressed(o, k) then
				return true
			end
		end
	end
end

function Item:MousePressed(button, x, y)
	if not self.enabled or self.type_name == "Divider" then
		return
	end
	for _, item in pairs(self._items) do
		if item:MousePressed(button, x, y) then
			return true
		end
	end
	if self:alive() and self.parent.panel:inside(x,y) and self.panel:inside(x,y) then
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

function Item:RunCallback(clbk, ...)
	clbk = clbk or self.callback
	if clbk then
		clbk(self.parent, self, ...)
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
	local title = self.panel:child("title")
	self.text = text
	title:set_text(self.localized and text and managers.localization:text(text) or text)
	local lines = math.max(1, title:number_of_lines()) 
	self.panel:set_h(math.max(self.items_size * lines, self.panel:h()))
	local offset = math.max(self.color and 2 or 0, self.text_offset)
	title:set_shape(offset, 0, self.panel:w() - offset, self.panel:h())
	local _,_,w,h = self.title:text_rect()
	if self.size_by_text then		
		self.panel:set_size(w + (offset * 2) + (self.type_name == "Toggle" and self.items_size or 0), h)
		self.w, self.h = self.panel:size()
		self.title:set_shape(offset, 0, w, h)
	end
end

function Item:SetLabel(label)
	self.label = label
end

function Item:SetCallback(callback)
	self.callback = callback
end

function Item:Highlight()
	if not self:alive() then
		return
	end
	self.bg:set_color(self.marker_highlight_color)
	if self.title then
		self.title:set_color(self.text_highlight_color)
	end
	self.highlight = true
	self.menu._highlighted = self
end

function Item:UnHighlight()
	if self.menu._highlighted == self then
		self.menu._highlighted = nil
	end
	self.highlight = false	
	if not self:alive() then
		return 
	end
	self.bg:set_color(self.marker_color)
	if self.title then
		self.title:set_color(self.text_color)
	end
end

function Item:MouseMoved(x, y)
	if not self:alive() or not self.enabled or self.type_name == "Divider" then
		return false
	end
	if not self.menu._openlist and not self.menu._slider_hold then
		if self.panel:inside(x, y) then
			self:Highlight()
			return true
		else
			self:UnHighlight()
			return true
		end
	end
end

function Item:MouseReleased(button, x, y)
	if self._list then
		self._list:MouseReleased(button, x, y)
	end
end