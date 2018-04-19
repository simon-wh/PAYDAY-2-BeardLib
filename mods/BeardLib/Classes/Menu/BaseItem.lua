BeardLib.Items.BaseItem = BeardLib.Items.BaseItem or class()
local BaseItem = BeardLib.Items.BaseItem
function BaseItem:Init() end
function BaseItem:init(params)
	table.careful_merge(self, params or {})
	self.type_name = self.type_name or "Button"
	self.private = self.private or {}
	self._adopted_items = {}
	local mitem = getmetatable(self)
	function mitem:__tostring() --STOP FUCKING RESETING
		return string.format("[%s][%s] %s", self:alive() and "Alive" or "Dead", tostring(self.type_name), tostring(self.name)) 
	end
	self:Init()
	self:PostInit()
	self.initialized = true
end

function BaseItem:PostInit()
    self:SetEnabled(self.enabled)
    self:SetVisible(self.visible)
    if self.highlight then
        self:Highlight()
    else
        self:UnHighlight()
    end
end

function BaseItem:InitBasicItem()
	self.title = self.panel:text({
		name = "title",
		align = self.text_align,
		vertical = self.text_vertical,
		wrap = not self.size_by_text,
		word_wrap = not self.size_by_text,
		text = self.text,
		layer = 3,
		color = self:GetForeground(),
		font = self.font,
		font_size = self.font_size or self.size,
		kern = self.kerning
	})
	self:InitBGs()
	self:_SetText(self.text)
	self:MakeBorder()
end

function BaseItem:InitBGs()
	self.bg = self.panel:rect({
		name = "background",
		color = self.background_color,
		visible = self.background_color ~= false,
		alpha = self.highlight and 0 or 1,
		h = self.type_name == "Group" and self.size,
		halign = self.type_name ~= "Group" and "grow",
		valign = self.type_name ~= "Group" and "grow",
		layer = 0
	})
	self.highlight_bg = self.panel:rect({
		name = "highlight",
		color = self.highlight_color,
		visible = self.highlight_color ~= false, 
		alpha = self.highlight and 1 or 0,
		h = self.type_name == "Group" and self.size,
		halign = self.type_name ~= "Group" and "grow",
		valign = self.type_name ~= "Group" and "grow",
		layer = 1
	})
end

function BaseItem:BestAlpha(...)
	local big
	for _, c in pairs({...}) do
		if c and (not big or c.alpha > big.alpha) then
			big = c
		end
	end
	return big
end

--Hopefully this reaches the base MenuUI and not cause a stack overflow xd
function BaseItem:GetBackground()
	return self:BestAlpha(self.background_color, self.parent:GetBackground()) or Color.black
end

function BaseItem:WorkParams(params)
	params = params or {}
	self.enabled = NotNil(self.enabled, true)
	self.visible = NotNil(self.visible, true)
	self:WorkParam("highlight_color", Color.white:with_alpha(0.1))
	self:WorkParam("context_background_color", self.background_color, Color.black)	
	self:WorkParam("background_color", Color.transparent)

	local bg, bgh
	self:WorkParam("auto_foreground")

	if self.auto_foreground then
		bg = self:GetBackground()
		bgh = self:BestAlpha(self.highlight_color, bg)
	end

	self:WorkParam("foreground", foreground)
	if self.auto_foreground and self.foreground ~= false then
		self.foreground = bg:contrast()
	end	
	self:WorkParam("foreground_highlight")
	if self.auto_foreground and self.foreground_highlight ~= false then
		self.foreground_highlight = bgh:contrast()
	end

	--Bad/Old names
	self:WorkParam("items_size", 18)
	--
	
	self:WorkParam("size", self.items_size)
	self:WorkParam("enabled_alpha", 1)
	self:WorkParam("disabled_alpha", 0.5)
	self:WorkParam("background_alpha")
	self:WorkParam("text_align", "left")
	self:WorkParam("text_vertical", "top")
	self:WorkParam("size_by_text")
	self:WorkParam("control_slice", 0.5)
	self:WorkParam("font", tweak_data.menu.pd2_large_font or tweak_data.menu.default_font)
	self:WorkParam("border_size", 2)
	--self:WorkParam("last_y_offset")
	self:WorkParam("accent_color")
	self:WorkParam("scroll_color", self.accent_color)
	self:WorkParam("slider_color", self.accent_color)
	self:WorkParam("border_color", self.accent_color)
	self:WorkParam("line_color", self.accent_color)
	self:WorkParam("ignore_align", self.override_panel)
	self:WorkParam("localized")
	self:WorkParam("help_localized", self.localized)
	self:WorkParam("items_localized", self.localized)
	self:WorkParam("animate_colors")

	--Specific items
	self:WorkParam("wheel_control")
	self:WorkParam("floats")
	self:WorkParam("focus_mode")
	self:WorkParam("supports_keyboard")
	self:WorkParam("supports_mouse")
	self:WorkParam("color_dialog")
	self:WorkParam("use_alpha")

	self.name = NotNil(self.name, self.text, "")
	self.text = NotNil(self.text, self.text ~= false and self.name)
	self.fit_width = NotNil(self.fit_width, self.parent.align_method ~= "grid")

	if not self.offset then
		self:WorkParam("offset")
	end

	if not self.text_offset then
		self:WorkParam("text_offset")
	end

	self.offset = self:ConvertOffset(self.offset)
	self.text_offset = self:ConvertOffset(self.text_offset, true) or {4,2}

	self.text_offset[1] = self.text_offset_x or self.text_offset[1]
	self.text_offset[2] = self.text_offset_y or self.text_offset[2]
	self.offset[1] = self.offset_x or self.offset[1]
	self.offset[2] = self.offset_y or self.offset[2]

	if self.inherit_values then
		if self.inherit_values.offset then
			self.inherit_values.offset = self:ConvertOffset(self.inherit_values.offset)
		end
		if self.inherit_values.text_offset then
			self.inherit_values.text_offset = self:ConvertOffset(self.inherit_values.text_offset)
		end	
	end

	if not self.initialized and self.parent ~= self.menu then
		if (not self.w or self.fit_width) then
			self.w = (self.w or self.parent_panel:w()) - ((self.size_by_text or self.type_name == "ImageButton") and 0 or self.offset[1] * 2)
		end
		self.w = math.clamp(self.w, self.min_width or 0, self.max_width or self.w)
	end
	self.should_render = true
end

function BaseItem:MakeBorder()
	if not self:alive() then
		return
	end
	
	for _, v in pairs({"left", "top", "right", "bottom"}) do
		local side = self.panel:child(v)
		if alive(side) then
			self.panel:remove(side)
		end
	end

	if self.color then
		self.border_left = NotNil(self.border_left, true)
		self.border_color = NotNil(self.border_color, self.color)
		self.border_lock_height = NotNil(self.border_lock_height, true)
		self.color = nil
	end

	local opt = {
		halign = "left",
		valign = "top",
		layer = 4,
		color = self.border_color,
	}
	opt.name = "left"
	local left = self.panel:bitmap(opt)
	opt.name = "bottom"
	opt.valign = "bottom"
	local bottom = self.panel:bitmap(opt)
	opt.name = "top"
	opt.halign = "right"
	local top = self.panel:bitmap(opt)
	opt.name = "right"
	opt.valign = "bottom"
	local right = self.panel:bitmap(opt)

	local vis = self.border_visible
	local w,h = self.border_size, self.border_lock_height and self:TextHeight() or self.panel:h()
    bottom:set_size(self.border_width or self.panel:w(), w)
    right:set_size(w, self.border_height or h)
    top:set_size(self.border_width or self.panel:w(), w)
    left:set_size(w, self.border_height or h)
    bottom:set_halign("grow")
    top:set_halign("grow")
    bottom:set_visible(vis or self.border_bottom)
    left:set_visible(vis or self.border_left)
    right:set_visible(vis or self.border_right)
    top:set_visible(vis or self.border_top)

	right:set_rightbottom(self.panel:size())    
	top:set_right(self.panel:w())
	bottom:set_bottom(self.panel:h())

	if self.title then
		if self.border_center_as_title then
			left:set_center_y(self.title:center_y())
			right:set_center_y(self.title:center_y())	
			top:set_center_x(self.title:center_x())
			bottom:set_center_x(self.title:center_x())
		end
		if self.border_position_below_title then
			bottom:set_top(self.title:bottom())
		end
	end
end

function BaseItem:TryRendering()
	if not self.visible then
		return false
	end
	local p
	if self.override_panel then
		p = self.parent_panel
	else
		p = self.parent._scroll._scroll_panel
	end
	local visible = false
	if alive(self.panel) then		
		local x = p:world_x()
	 	visible = p:inside(x, self.panel:world_y()) == true or p:inside(x, self.panel:world_bottom()) == true
		self.panel:set_visible(visible)
		self.should_render = visible
		if self.debug then
			BeardLib:log("Item %s has been set to rendering=%s", tostring(self), tostring(visible))
		end
	end
	return visible
end

function BaseItem:SetVisible(visible, no_align)
	if not self:alive() then
		return
	end
	self._hidden_by_menu = nil
    self.visible = visible == true
    self.panel:set_visible(self.visible)
    if not self.visible then
        if self:Enabled() then
            self._was_enabled = self.enabled
            self:SetEnabled(self.visible)
        end
    elseif self._was_enabled then
        self:SetEnabled(true)
    end
    if not no_align and self.parent.auto_align then
    	self.parent:AlignItems()
    end
end

--Return Funcs--
function BaseItem:Panel() return self.panel end
function BaseItem:Parent() return self.parent end
function BaseItem:ParentPanel() return self.panel:parent() end
	function BaseItem:X() return self:Panel():x() end
	function BaseItem:Y() return self:Panel():y() end
	function BaseItem:W() return self:Panel():w() end
	function BaseItem:H() return self:Panel():h() end
	function BaseItem:Right() return self:Panel():right() end
	function BaseItem:Bottom() return self:Panel():bottom() end
function BaseItem:AdoptedItems() return self._adopted_items end
function BaseItem:Position() return self.position end
function BaseItem:Location() return self:Panel():position() end
function BaseItem:LeftTop() return self:Panel():lefttop() end
function BaseItem:RightTop() return self:Panel():righttop() end
function BaseItem:LeftBottom() return self:Panel():leftbottom() end
function BaseItem:RightBottom() return self:Panel():rightbottom() end
function BaseItem:CenterX() return self:Panel():center_x() end
function BaseItem:CenterY() return self:Panel():center_y() end
function BaseItem:Center() return self:Panel():center() end
function BaseItem:Name() return self.name end
function BaseItem:Label() return self.label end
function BaseItem:Text() return type(self.text) == "string" and self.text or "" end
function BaseItem:Height() return self:Panel():h() end
function BaseItem:OuterHeight() return self:Height() + self:Offset()[2] end
function BaseItem:Width() return self:Panel():w() end
function BaseItem:OuterWidth() return self:Width() + self:Offset()[1]  end
function BaseItem:Offset() return self.offset end
function BaseItem:OffsetX() return self.offset[1] end
function BaseItem:OffsetY() return self.offset[2] end
function BaseItem:TextOffset() return self.text_offset end
function BaseItem:TextOffsetX() return self.text_offset[1] end
function BaseItem:TextOffsetY() return self.text_offset[2] end
function BaseItem:alive() return alive(self.panel) end
function BaseItem:title_alive() return type_name(self.title) == "Text" and alive(self.title) end
function BaseItem:Value() return self.value end
function BaseItem:Enabled() return self.enabled end
function BaseItem:Index() return self.parent:GetIndex(self) end
function BaseItem:MouseInside(x, y) return self.panel:inside(x,y) end
function BaseItem:Inside(x, y) return self.panel:inside(x,y) end
function BaseItem:Visible() return self:alive() and self.visible and self.should_render end
function BaseItem:TextHeight() return self:title_alive() and self.title:bottom() + self:TextOffsetY() or 0 end
function BaseItem:MouseFocused(x, y)
    if not x and not y then
        x,y = managers.mouse_pointer._mouse:world_position()
    end
    return self:alive() and self.panel:inside(x,y) and self:Visible()
end

--Add/Set Funcs--
function BaseItem:AddItem(item) 
	table.insert(self._adopted_items, item)
	self._has_adopted_items = true
end
function BaseItem:SetCallback(callback) self.on_callback = callback end
function BaseItem:SetLabel(label) self.label = label end
function BaseItem:SetParam(k,v) self[k] = v end
function BaseItem:SetEnabled(enabled) self.enabled = enabled == true end
function BaseItem:WorkParam(param, ...)
	if self[param] == nil then
		if self.private[param] ~= nil then
			v = self.private[param]
		elseif self.inherit.inherit_values and self.inherit.inherit_values[param] ~= nil then
			v = self.inherit.inherit_values[param]
		elseif self.inherit.private[param] == nil and self.inherit[param] ~= nil then
			v = self.inherit[param]
		else
			v = NotNil(...)
		end
		if type(v) == "table" then
			v = clone(v)
		end
		self[param] = v
	end
end

function BaseItem:ConvertOffset(offset, no_default)
	if offset then
		local t = type(offset)
        if t == "number" then
            return {offset, offset}
		elseif t == "table" then
            return {offset[1], offset[2]}
		end
	end
    if not no_default then
        return {6,2}
    end
end

--Position Func--
function BaseItem:Reposition(last_positioned_item, prev_item)
	if not self:alive() then
		return false
	end
    local t = type(self.position)
    if t == "table" then
        self.panel:set_position(unpack(self.position))
    elseif t == "function" then
        self:position(last_positioned_item, prev_item)
    elseif t == "string" then
        self:SetPositionByString(self.position)
	end
    return t ~= "nil"
end

function BaseItem:SetPosition(x,y)
    if type(x) == "number" or type(y) == "number" then
        self.position = {x or self.panel:x(),y or self.panel:y()}
    else
        self.position = x
    end
    self:Reposition()
end

local pos_funcs = {
    ["Left"] = function(panel) panel:set_x(0) end,
    ["Top"] = function(panel) panel:set_y(0) end,
    ["Right"] = function(panel, parent) panel:set_right(parent:w()) end,
    ["Bottom"] = function(panel, parent) panel:set_bottom(parent:h()) end,
    ["Centerx"] = function(panel, parent) panel:set_center_x(parent:w() / 2) end,
    ["Centery"] = function(panel, parent) panel:set_center_y(parent:y() / 2) end,
    ["Center"] = function(panel, parent) panel:set_world_center(parent:world_center()) end,
    ["Offsetx"] = function(panel, parent, offset) panel:move(offset[1]) end,
    ["Offset-x"] = function(panel, parent, offset) panel:move(-offset[1]) end,
    ["Offsety"] = function(panel, parent, offset) panel:move(0, offset[2]) end,
    ["Offset-y"] = function(panel, parent, offset) panel:move(0, -offset[2]) end,
    ["Offset"] = function(panel, parent, offset) panel:move(offset[1], offset[2]) end,
    ["Offset-"] = function(panel, parent, offset) panel:move(-offset[1], -offset[2]) end,
    ["Offsetx-y"] = function(panel, parent, offset) panel:move(offset[1], -offset[2]) end,
    ["Offset-xy"] = function(panel, parent, offset) panel:move(-offset[1], offset[2]) end,
}
function BaseItem:SetPositionByString(pos)
	if not pos then
		BeardLib:log("[ERROR] Position for item %s in parent %s is nil!", tostring(self.name), tostring(self.parent.name))
		return
	end
	local panel = self.panel
	local parent_panel = self.parent_panel
	local offset = self.offset
	for p in pos:gmatch("%u%U+") do
		if pos_funcs[p] then
			pos_funcs[p](panel, parent_panel, offset)
		end
	end
end

function BaseItem:SetValue(value, run_callback)
	if not self:alive() then
		return false
	end
	if run_callback then
		run_callback = value ~= self.value
	end
	self.value = value
	if run_callback then
		self:RunCallback()
	end
	return true
end

function BaseItem:MouseCheck(press)
	if not self:alive() or not self.enabled or (press and self.menu._highlighted ~= self) then
		return false
	end
	return not self.divider_type, true
end

function BaseItem:SetIndex(index, no_align)
	table.delete(self.parent._my_items, self)
	table.insert(self.parent._my_items, index, self)
    if not no_align and self.parent.auto_align then
        self:AlignItems(true)
    end
end

function BaseItem:SetLayer(layer)
    self:Panel():set_layer(layer)
    self.layer = layer
end

function BaseItem:SetEnabledAlpha(alpha)
	self.enabled_alpha = alpha
	self:SetEnabled(self.enabled)
end

function BaseItem:SetDisabledAlpha(alpha)
	self.disabled_alpha = alpha
	self:SetEnabled(self.enabled)
end

function BaseItem:RunCallback(clbk, ...)
	clbk = clbk or self.on_callback
	if clbk then
		clbk(self, ...)
	elseif self.callback then --Old.
		self.callback(self.parent, self, ...)
	end
end

function BaseItem:Destroy()
	if not self:alive() then
		return
	end
	self.parent:RemoveItem(self)
end

function BaseItem:Configure(params)
	table.careful_merge(self, params)
	self.parent:RecreateItem(self, true)
end