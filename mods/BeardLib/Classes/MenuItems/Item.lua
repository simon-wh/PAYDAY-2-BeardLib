Item = Item or class()

function Item:init(parent, params)
	self.type = self.type or "Button"
	if params.override_parent then
		params.override_parent:AddItem(self)
	end
	params.panel = params.parent_panel:panel({
		name = params.name,
		w = params.w - params.padding,
		h = params.h or params.items_size,
		x = params.padding,
	})
	local Marker = params.panel:rect({
		name = "bg",
		color = params.marker_color,
		halign="grow",
		valign="grow",
		layer = -2
	})
	params.title = params.panel:text({
		name = "title",
		text = params.localized and params.text and managers.localization:text(params.text) or params.text,
		vertical = "center",
		x = params.padding,
		align = params.align,
		w = params.panel:w(),
		h = params.items_size,
		layer = 6,
		color = params.text_color or Color.black,
		font = "fonts/font_large_mf",
		font_size = params.items_size
	})
	params.div = params.panel:rect({
		color = params.color,
		visible = params.color ~= nil,
		w = 2,
	})
	local _,_,w,h = params.title:text_rect()
	params.title:set_h(h)
	params.title:set_y(0)
	if params.size_by_text then
		params.panel:set_size(w + params.items_size + 10,h)
		params.title:set_size(params.panel:w(), h)
		params.title:set_x(params.color and 2 or 0)
	end
	if self.type == "Divider" then
		params.title:set_world_center_y(params.panel:world_center_y())
	end
	self._items = {}
	params.option = params.option or params.name
	table.merge(self, params)
	self:SetPositionByString(params.position)
	if params.group then
		if params.group.type == "ItemsGroup" then
			params.group:AddItem(self)
		else
			BeardLib:log(self.name .. " group is not a group item!")
		end
	end
end
function Item:Panel()
	return self.panel
end
function Item:SetPosition( x,y )
	self.panel:set_position(x,y)
end
function Item:SetPositionByString( pos )
	if not pos then
		return
	end
	if string.match(pos, "Center") then
	   self.panel:set_world_center(self.parent_panel:world_center())
	end
	if string.match(pos, "Bottom") then
	   self.panel:set_world_bottom(self.parent_panel:world_bottom())
	end
	if string.match(pos, "Top") then
		self.panel:set_world_top(self.parent_panel:world_top())
	end
	if string.match(pos, "Right") then
		self.panel:set_world_right(self.parent_panel:world_right())
	end
	if string.match(pos, "Left") then
		self.panel:set_world_left(self.parent_panel:world_left())
	end
end
function Item:AddItem(item)
	table.insert(self._items, item)
end
function Item:SetValue(value, run_callback)
	self.value = value
	if run_callback then
		self:RunCallback()
	end
end
function Item:SetEnabled(enabled)
	self.enabled = enabled
end
function Item:Index()
	return self.parent:GetIndex(self.name)
end
function Item:KeyPressed( o, k )
	for _, item in pairs(self._items) do
		if item:KeyPressed(o, k) then
			return true
		end
	end
end
function Item:MousePressed( button, x, y )
	if not self.enabled or self.type == "Divider" then
		return
	end
	for _, item in pairs(self._items) do
		if item:MousePressed(button, x, y) then
			return true
		end
	end
	if alive(self.panel) and self.panel:inside(x,y) and button == Idstring("0") then
		self:RunCallback()
		return true
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
end
function Item:SetText(text)
	params.text = text
	self.panel:child("title"):set_text(self.localized and text and managers.localization:text(text) or text)
end

function Item:SetLabel( label )
	self.label = label
end

function Item:SetCallback( callback )
	self.callback = callback
end
function Item:MouseMoved( x, y, highlight )
	if not alive(self.panel) or not self.enabled or self.type == "Divider" then
		return
	end
	if not self.menu._openlist and not self.menu._slider_hold then
		for _, item in pairs(self._items) do
			item:MouseMoved(x,y)
		end
		if self.panel:inside(x, y) then
			if highlight ~= false then
				self.panel:child("bg"):set_color(self.marker_highlight_color)
				self.panel:child("title"):set_color(self.text_highlight_color)
			end
			self.highlight = true
			self.menu._highlighted = self
		else
			self.panel:child("bg"):set_color(self.marker_color)
			self.panel:child("title"):set_color(self.text_color)
			self.highlight = false
		end
		self.menu._highlighted = self.menu._highlighted and (alive(self.menu._highlighted.panel) and self.menu._highlighted.panel:inside(x,y)) and self.menu._highlighted or nil
	end
end

function Item:MouseReleased( button, x, y )

end
