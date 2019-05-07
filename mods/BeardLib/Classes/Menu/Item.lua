BeardLib.Items.Item = BeardLib.Items.Item or class()
local Item = BeardLib.Items.Item
function Item:init(params)
    if params and params.menu_type then
        self:Menuify()
    end
	table.careful_merge(self, params or {})
	self.type_name = self.type_name or "Button"
	self.private = self.private or {}
	local mitem = getmetatable(self)
	function mitem:__tostring() --STOP FUCKING RESETING
		return string.format("[%s][%s] %s", self:alive() and "Alive" or "Dead", tostring(self.type_name), tostring(self.name)) 
	end
	self:Init()
	self:PostInit()
	self.initialized = true
end

function Item:Init(params)
	if not alive(self.parent_panel) then
		return
	end

	self:WorkParams(params)

	self.panel = self.parent_panel:panel({
		name = self.name,
		layer = self.layer or 1,
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
end

function Item:PostInit()
    self:SetEnabled(self.enabled)
    self:SetVisible(self.visible)
    if self.highlight then
        self:Highlight()
    else
        self:UnHighlight()
    end
end

function Item:InitBasicItem()
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

function Item:InitBGs()
	local bgc = self.unhighlight_color or self.background_color
	self.bg = self.panel:rect({
		name = "background",
		color = bgc or bgc,
		visible = bgc ~= false,
		alpha = self.highlight and 0 or 1,
		h = self.GROUP and self.size,
		halign = not self.GROUP and "grow",
		valign = not self.GROUP and "grow",
		layer = 0
	})
	self.highlight_bg = self.panel:rect({
		name = "highlight",
		color = self.highlight_color,
		visible = self.highlight_color ~= false, 
		alpha = self.highlight and 1 or 0,
		h = self.GROUP and self.size,
		halign = not self.GROUP and "grow",
		valign = not self.GROUP and "grow",
		layer = 1
	})
end

function Item:MakeBorder()
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

local ids_0 = Idstring("0")

function Item:WorkParams(params)
	params = params or {}
	self.enabled = NotNil(self.enabled, true)
	self.visible = NotNil(self.visible, true)
	self:WorkParam("unhighlight_color")
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
	self:WorkParam("control_slice", 0.6)
	self:WorkParam("font", tweak_data.menu.pd2_large_font or tweak_data.menu.default_font)
	self:WorkParam("border_size", 2)
	--self:WorkParam("last_y_offset")
	self:WorkParam("accent_color")
	self:WorkParam("scroll_color", self.accent_color)
	self:WorkParam("slider_color", self.accent_color)
	self:WorkParam("border_color", self.accent_color)
	self:WorkParam("line_color", self.accent_color)
	self.ignore_align = NotNil(self.ignore_align, false)
	self:WorkParam("localized")
	self:WorkParam("help_localized", self.localized)
	self:WorkParam("animate_colors")
	self:WorkParam("context_screen_offset_y", 32)
	self:WorkParam("context_scroll_width", 10)
	self:WorkParam("context_font_size", 20)
	self:WorkParam("context_text_offset")
	
	self:WorkParam("click_btn", ids_0)

	--Specific items
	self:WorkParam("wheel_control")
	self:WorkParam("floats")
	self:WorkParam("focus_mode")
	self:WorkParam("supports_keyboard")
	self:WorkParam("supports_mouse")
	self:WorkParam("color_dialog")
	self:WorkParam("use_alpha")
	self:WorkParam("items_localized", self.localized)
	self:WorkParam("items_uppercase")
    self:WorkParam("items_lowercase")
    if not self.MENU then
        self:WorkParam("align_method", "grid_from_right")
    end

	self:WorkParam("auto_align", true)

	self.name = NotNil(self.name, self.text, "")
	self.text = NotNil(self.text, self.text ~= false and self.name)
	self.fit_width = NotNil(self.fit_width, self.parent.align_method ~= "grid")
	self.click_btn = self.click_btn:id()

	if not self.offset then
		self:WorkParam("offset")
	end

	if not self.text_offset then
		self:WorkParam("text_offset")
	end

	self:WorkParam("shrink_width")
	self:WorkParam("max_height")
	self:WorkParam("min_height")
	self:WorkParam("max_width")
	self:WorkParam("min_width")

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
	
	if not self.initialized then
		if self.parent ~= self.menu then
			if (not self.w or self.fit_width) then
				self.w = (self.w or self.parent_panel:w()) - ((self.size_by_text or self.type_name == "ImageButton") and 0 or self.offset[1] * 2)
			end
			self.w = math.clamp(self.w, self.min_width or 0, self.max_width or self.w)
		else
			self.w = self.w or self.parent_panel:w()
			self.h = self.h or self.parent_panel:h()
		end
		if self.shrink_width then
			self.w = self.w * self.shrink_width
			self.shrink_width = nil
		end
		if self.w == "half" then
			self.w = self.parent_panel:w() / 2
		end
		self.orig_h = self.h
	end
	
	self.should_render = true
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



--Item Creation--

function Item:Create(type, ...)
    return self[type](self, ...)
end

function Item:Group(params) return self:NewItem(BeardLib.Items.Group:new(self:ConfigureItem(params, true))) end
function Item:NoteBook(params) return self:NewItem(BeardLib.Items.NoteBook:new(self:ConfigureItem(params, true))) end
function Item:PopupMenu(params) return self:NewItem(BeardLib.Items.PopupMenu:new(self:ConfigureItem(params, true))) end
function Item:Menu(params) return self:NewItem(BeardLib.Items.Menu:new(self:ConfigureItem(params, true))) end
function Item:ComboBox(params) return self:NewItem(BeardLib.Items.ComboBox:new(self:ConfigureItem(params))) end
function Item:TextBox(params) return self:NewItem(BeardLib.Items.TextBox:new(self:ConfigureItem(params))) end
function Item:ComboBox(params) return self:NewItem(BeardLib.Items.ComboBox:new(self:ConfigureItem(params))) end
function Item:Slider(params) return self:NewItem(BeardLib.Items.Slider:new(self:ConfigureItem(params))) end
function Item:KeyBind(params) return self:NewItem(BeardLib.Items.KeyBindItem:new(self:ConfigureItem(params))) end
function Item:Toggle(params) return self:NewItem(BeardLib.Items.Toggle:new(self:ConfigureItem(params))) end
Item.ItemsGroup = Item.Group

function Item:ImageButton(params)
    local w = params.w or not params.icon_h and params.size
    local h = params.h or params.icon_h or params.size
    local _params = self:ConfigureItem(params)
    _params.w = w or _params.w
    _params.h = h or _params.h or _params.size
    return self:NewItem(BeardLib.Items.ImageButton:new(_params))
end

function Item:Button(params) 
	local _params = self:ConfigureItem(params)
	_params.button_type = true
	return self:NewItem(BeardLib.Items.Item:new(_params))
end

function Item:NumberBox(params)
    local _params = self:ConfigureItem(params)
    _params.type_name = "NumberBox"
    _params.filter = "number"
    return self:NewItem(BeardLib.Items.TextBox:new(_params))
end

function Item:Text(text, params)
    return self:Divider({text = text}, params)
end

function Item:Divider(params)
    local _params = self:ConfigureItem(params)
    _params.divider_type = true
    return self:NewItem(BeardLib.Items.Item:new(_params))
end

function Item:ToolBar(params)
    params.text = params.text or ""
    local _params = self:ConfigureItem(params)
    _params.divider_type = true
    _params.menu_type = true
	_params.align_method = _params.align_method or "grid"
	
    return self:NewItem(BeardLib.Items.Item:new(_params))
end

function Item:Image(params)
    params.divider_type = true
    return self:ImageButton(params)
end

function Item:DivGroup(params)
    local _params = self:ConfigureItem(params)
    _params.divider_type = true
    return self:NewItem(BeardLib.Items.Group:new(_params))
end

function Item:ConfigureItem(item, menu)
    item = clone(item)
    if type(item) ~= "table" then
        log(tostring(debug.traceback()))
        return
    end
    local inherit = NotNil(item.inherit, self)
    item.inherit = inherit
    item.parent = self
    item.menu = self.menu
    item.parent_panel = item.use_main_panel and self.panel or self:ItemsPanel()
    if type(item.index) == "string" then
        local split = string.split(item.index, "|")
        local wanted_item = self:GetItem(split[2] or split[1]) 
        if wanted_item then
            item.index = wanted_item:Index() + (split[1] == "After" and 1 or split[1] == "Before" and -1 or 0)
        else
            BeardLib:log("Could not create index from string, %s, %s", tostring(item.index), tostring(item))
            item.index = nil
        end
    end
    item.indx = item.indx or item.index
    item.index = nil
    return item
end

function Item:Menuify(item)
	self._my_items = self._my_items or {}
	self._reachable_items = self._reachable_items or {}
	self._visible_items = self._visible_items or {}
	self.menu_type = true
end

function Item:NewItem(item)
    if not alive(self) then
        return
    end
    
	if self.override_panel then
		self.override_panel:Create(self.type_name, item)
		self.override_panel = nil
		return
	end

    self:Menuify()

    if item.indx then
        table.insert(self._my_items, item.indx, item)
    else
        table.insert(self._my_items, item)
	end
	
    local index = #self._my_items
    if item.reachable then
        table.insert(self._reachable_items, item)
	end
	
    item.indx = item.indx or index
    if self.auto_align then self:AlignItems() end
	if managers.mouse_pointer then
		item:MouseMoved(managers.mouse_pointer:world_position())
	end
    return item
end

function Item:CheckItems()
    if self.menu_type then
        self._visible_items = {}
        for _, item in pairs(self._my_items) do
            if item:TryRendering() then
                table.insert(self._visible_items, item)
            end
            if item.CheckItems then
                item:CheckItems()
            end
        end
    end
end

function Item:Destroy()
	if not self:alive() then
		return
	end
	self.parent:RemoveItem(self)
end

function Item:RemoveItem(item)
    if not item then
        return
    end
    if item.menu_type then
        item:ClearItems()
    end

    if item._list then
        item._list:Destroy()
	end
	
	if item == self.menu._highlighted then
		self.menu:UnHighlight()
	end
	
    table.delete(self._reachable_items, item)
    table.delete(self._my_items, item)
    local panel = item:Panel()
	if alive(panel) then		
        panel:parent():remove(panel)
    end
    if self.auto_align then
        self:AlignItems()
    end
end

function Item:RecreateItem(item, align_items)
    if item.list then
        item.list:parent():remove(item.list)
    end
    local panel = item:Panel()
    if alive(panel) then
        panel:parent():remove(panel)
	end
	item.parent_panel = (alive(item.parent_panel) and item.parent_panel) or item.use_main_panel and self.panel or self:ItemsPanel()
    item:Init()
    item:PostInit()
    if item.menu_type then
        item:RecreateItems()
    end
    if align_items then
        self:AlignItems(true)
    end
end

function Item:RecreateItems()
    for _, item in pairs(self._my_items) do
        self:RecreateItem(item)
    end
    if self.auto_align then
        self:AlignItems(true)
    end
end

function Item:ClearItems(label)
	if not self.menu_type then
		return
	end

    local temp = clone(self._my_items)
    self._my_items = {}
    self._reachable_items = {}
    for _, item in pairs(temp) do
        if not label or type(label) == "table" or item.label == label then
            self:RemoveItem(item)
        elseif item:alive() then
            table.insert(self._my_items, item)
            if item.reachable then
                table.insert(self._reachable_items, item)
            end
        end
    end
    self.menu:CheckOpenedList()
    if self.auto_align then
        self:AlignItems(true)
    end
end

--Get Funcs
function Item:ItemsPanel() return self.panel end
function Item:ItemsWidth() return self:Panel():w() end
function Item:ItemsHeight() return self:Panel():h() end
function Item:Items() return self._my_items end
function Item:ShouldClose()
	local should_close = not ((self._textbox and self._textbox.cantype) or self.CanEdit)
	if self.menu_type then
		for _, item in pairs(self._my_items) do
			if not item:ShouldClose() then
				return false
			end
		end
	end
	return should_close
end

function Item:GetMenus(match, deep, menus)
	menus = menus or {}
    for _, menu in pairs(self._my_items) do
        if menu.menu_type then
            if not match or menu.name:find(match) then
                table.insert(menus, menu)
            elseif deep then
                local item = menu:GetMenus(name, true, menus)
                if item and item.name then
                    return item
                end
            end
        end
    end
    return menus
end

function Item:GetMenu(name, shallow)
    for _, menu in pairs(self._my_items) do
        if menu.menu_type then
            if menu.name == name then
                return menu
            elseif not shallow then
                local item = menu:GetMenu(name)
                if item and item.name then
                    return item
                end
            end
        end
    end
    return false
end

function Item:GetItem(name, shallow)
    for _, item in pairs(self._my_items) do
        if item.name == name then
            return item
        elseif item.menu_type and not shallow then
            local i = item:GetItem(name)
            if i then
                return i
            end
        end
    end
    return nil
end

function Item:GetItemWithType(name, type, shallow)
    for _, item in pairs(self._my_items) do
        if item.type_name == type and item.name == name then
            return item
        elseif item.menu_type and not shallow then
            local i = item:GetItem(name)
            if i then
                return i
            end
        end
    end
    return nil
end

function Item:GetItemByLabel(label, shallow)
    for _, item in pairs(self._my_items) do
        if item.label == label then
            return item
        elseif item.menu_type and not shallow then
            local i = item:GetItemByLabel(label)
            if i then
                return i
            end
        end
    end
    return nil
end

function Item:MouseCheck(press)
	if not self:alive() or not self.enabled or not self.visible or not self.should_render or (press and self.menu._highlighted ~= self) then
		return false
	end
	return not self.divider_type, true
end

function Item:GetIndex(item)
    return table.index_of(self._my_items, item)
end

function Item:GetForeground(highlight)
	highlight = highlight or self.highlight
	local fgcolor = highlight and self.foreground_highlight or self.foreground
	return NotNil(fgcolor) or (highlight and self.highlight_color or self.unhighlight_color or self.background_color or Color.black):contrast()
end

function Item:BestAlpha(...)
	local big
	
	for _, c in pairs({...}) do
		if c and c.a and (not big or c.a > big.a) then
			big = c
		end
	end
	return big or Color.white
end

--Hopefully this reaches the base MenuUI and not cause a stack overflow xd
function Item:GetBackground()
	return self:BestAlpha(self.background_color, self.parent:GetBackground()) or Color.black
end

function Item:ConvertOffset(offset, no_default)
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

function Item:MouseFocused(x, y)
    if not x and not y then
        x,y = managers.mouse_pointer._mouse:world_position()
    end
    return self:alive() and self.panel:inside(x,y) and self:Visible()
end

function Item:ChildrenMouseFocused(x, y, excluded_label)
    if not x and not y then
        x,y = managers.mouse_pointer._mouse:world_position()
    end
	for _, item in pairs(self._my_items) do
		if (not excluded_label or item.label ~= excluded_label) and item:MouseFocused(x,y) then
			return true
		end
	end
	return false
end

function Item:Panel() return self.panel end
function Item:Parent() return self.parent end
function Item:ParentPanel() return self.panel:parent() end
	function Item:X() return self:Panel():x() end
	function Item:Y() return self:Panel():y() end
	function Item:W() return self:Panel():w() end
	function Item:H() return self:Panel():h() end
	function Item:Right() return self:Panel():right() end
	function Item:Bottom() return self:Panel():bottom() end
function Item:AdoptedItems() return {} end
function Item:Position() return self.position end
function Item:Location() return self:Panel():position() end
function Item:LeftTop() return self:Panel():lefttop() end
function Item:RightTop() return self:Panel():righttop() end
function Item:LeftBottom() return self:Panel():leftbottom() end
function Item:RightBottom() return self:Panel():rightbottom() end
function Item:CenterX() return self:Panel():center_x() end
function Item:CenterY() return self:Panel():center_y() end
function Item:Center() return self:Panel():center() end
function Item:Name() return self.name end
function Item:Label() return self.label end
function Item:Text() return type(self.text) == "string" and self.text or "" end
function Item:TextValue() return self:Text() end
function Item:Height() return self:Panel():h() end
function Item:OuterHeight() return self:Height() + self:Offset()[2] end
function Item:Width() return self:Panel():w() end
function Item:OuterWidth() return self:Width() + self:Offset()[1]  end
function Item:Offset() return self.offset end
function Item:OffsetX() return self.offset[1] end
function Item:OffsetY() return self.offset[2] end
function Item:TextOffset() return self.text_offset end
function Item:TextOffsetX() return self.text_offset[1] end
function Item:TextOffsetY() return self.text_offset[2] end
function Item:alive() return alive(self.panel) end
function Item:title_alive() return type_name(self.title) == "Text" and alive(self.title) end
function Item:Value() return self.value end
function Item:Enabled() return self.enabled end
function Item:Index() return self.parent:GetIndex(self) end
function Item:MouseInside(x, y) return self.panel:inside(x,y) end
function Item:Inside(x, y) return self.panel:inside(x,y) end
function Item:Visible() return self:alive() and self.visible and self.should_render end
function Item:_Visible() return self:alive() and self.visible end
function Item:TextHeight() return self:title_alive() and self.title:bottom() + self:TextOffsetY() or 0 end

--Set Funcs

function Item:SetLayer(layer)
    self:Panel():set_layer(layer)
    self.layer = layer
end

function Item:SetEnabledAlpha(alpha)
	self.enabled_alpha = alpha
	self:SetEnabled(self.enabled)
end

function Item:SetDisabledAlpha(alpha)
	self.disabled_alpha = alpha
	self:SetEnabled(self.enabled)
end

function Item:SetEnabled(enabled)
    self.enabled = enabled == true
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

function Item:SetBorder(config)
	self.border_size = NotNil(config.size, self.border_size)
	self.border_visible = NotNil(config.visible, self.border_visible)
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
	self:MakeBorder()
end

function Item:WorkParam(param, ...)
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

function Item:SetPosition(x,y)
    if type(x) == "number" or type(y) == "number" then
        self.position = {x or self.panel:x(),y or self.panel:y()}
    else
        self.position = x
    end
    self:Reposition()
end

function Item:SetPointer(state) self.menu:SetPointer(state) end
function Item:SetCallback(callback) self.on_callback = callback end
function Item:SetLabel(label) self.label = label end
function Item:SetParam(k,v) self[k] = v end

function Item:Configure(params)
	table.careful_merge(self, params)
	self.parent:RecreateItem(self, true)
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
function Item:SetPositionByString(pos)
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

function Item:SetValue(value, run_callback)
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

function Item:SetIndex(index, no_align)
	table.delete(self.parent._my_items, self)
	table.insert(self.parent._my_items, index, self)
	if not no_align and self.parent.auto_align then
		self:AlignItems(true)
	end
end

--function Item:SetVisible(visible, no_align)
function Item:SetVisible(visible, animate, no_align)
    local panel = self:Panel()
    if not alive(panel) then
        return
    end
	local was_visible = self.visible

	self._hidden_by_menu = nil
	self.visible = visible == true
	local function setvisible()
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
	self.menu:CheckOpenedList()
	
	if animate and visible ~= was_visible then
		if visible then
			panel:set_alpha(0)
			panel:set_visible(true)
		end
		play_value(panel, "alpha", visible and 1 or 0, {time = 0.2, callback = setvisible})
	else
		setvisible()
	end
end

function Item:SetChecked(name, checked, run_callback)
	local toggle = self:GetItemWithType(name, "Toggle", true)
	if toggle then
		toggle:SetValue(checked, run_callback)
	end
end

--Events
function Item:RunCallback(clbk, ...)
	clbk = clbk or self.on_callback
	if clbk then
		table.insert(self.menu._callbacks, SimpleClbk(clbk, self, ...))
	elseif self.callback then --Old.
		table.insert(self.menu._callbacks, SimpleClbk(self.callback, self.parent, self, ...))
	end
end


function Item:Reposition(last_positioned_item, prev_item)
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
    return not not self.position
end

function Item:TryRendering()
	if not self.visible then
		return false
	end
	
	local p = self.parent

	local visible = false
	if alive(self.panel) then		
		local y = self.panel:world_y()
		local b = self.panel:world_bottom()
	
		while p ~= nil do
			--local pan = p._scroll and p._scroll:scroll_panel() or self.parent_panel
			local pan = self.parent_panel
			if p.should_render and b > pan:world_y() and y < pan:world_bottom() then
				visible = true
				if p.parent == self.menu then
					p = nil
				else
					p = p.parent
				end
			else
				visible = false
				break
			end
		end

		self.panel:set_visible(visible)
		self.should_render = visible
	end
	return visible
end

function Item:MouseReleased(b, x, y)
	if self.menu_type then
		if not self.menu._highlighted then
			self:SetPointer()
		end
		for _, item in pairs(self._my_items) do
			if item:MouseReleased(button, x, y) then
				return true
			end
		end
	end

	if self._list then
		self._list:MouseReleased(button, x, y)
	end
end

local enter_ids = Idstring("enter")
function Item:KeyPressed(o, k)
	if self.menu_type then
		if self:Enabled() and (self:MouseFocused(x, y) or self.reach_ignore_focus) then
			local dir = k == Idstring("down") and 1 or k == Idstring("up") and -1
			local h = self.menu._highlighted
			local next_item
			if dir then
				local next_index = (h and table.get_key(self._reachable_items, h) or (dir == 1 and 0 or #self._reachable_items)) + dir
				if next_index > #self._reachable_items then
					next_index = 1
				elseif next_index < 1 then
					next_index = #self._reachable_items
				end
				next_item = self._reachable_items[next_index]
			end
			if next_item then
				next_item:Highlight()
				return true
			end
		end
	end
	if k == enter_ids and self.type_name == "Button" and self.menu._highlighted == self then
		self:RunCallback()
	end
	if self.on_key_press then
		self.on_key_press(self, k)
	end
end

local mouse_1 = Idstring("1")
Item.UNCLICKABLE = 1 --null is "unknown".
Item.CLICKABLE = 2
Item.INTERRUPTED = 3
function Item:MousePressed(b, x, y)
	if self.menu_type and self:MousePressedMenuEvent(b, x, y) then
		return true
	else
		return self:MousePressedSelfEvent(b, x, y)
	end
end

function Item:MousePressedSelfEvent(button, x, y)
    if not self:MouseCheck(true) then
        return false, self.UNCLICKABLE
	end

	if self:MouseInside(x,y) then
		if self.on_click then
			if self.on_click(self, button, x, y) == false then
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

function Item:MousePressedMenuEvent(button, x, y)
    local menu = self.menu
    if self:Enabled() then
        for _, item in pairs(self._visible_items) do
            if item:MousePressed(button, x, y) then
                return true, item
            end
        end
        if alive(self._scroll) then
            if button == Idstring("0") then
                if self._scroll:mouse_pressed(button, x, y) then
                    menu._scroll_hold = true
                    self:CheckItems()
                    return true
                end
            elseif self._scroll:is_scrollable() then
                if button == Idstring("mouse wheel down") then
                    if self._scroll:scroll(x, y, -1) then
                        if menu._highlighted and menu._highlighted.parent == self then
                            menu._highlighted:MouseMoved(x,y)
                        end 
                        self:CheckItems()
                        return true
                    end
                elseif button == Idstring("mouse wheel up") then
                    if self._scroll:scroll(x, y, 1) then
                        if menu._highlighted and menu._highlighted.parent == self then
                            menu._highlighted:MouseMoved(x,y)
                        end 
                        self:CheckItems()
                        return true
                    end
                end
            end
        else
            self:CheckItems()
        end
    end
    return false
end

function Item:MouseMoved(x,y)
	return (self.menu_type and self:MouseMovedMenuEvent(x,y)) or self:MouseMovedSelfEvent(x,y)
end

function Item:MouseMovedSelfEvent(x, y)
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

function Item:MouseMovedMenuEvent(x, y)
    if self:Enabled() and self:MouseFocused(x, y) then
        if alive(self._scroll) then
            local _, pointer = self._scroll:mouse_moved(nil, x, y)
            if pointer then
                self:CheckItems()
                self:SetPointer(pointer)
                return true
            else
                self:SetPointer()
            end
        end
        for _, item in pairs(self._visible_items) do
            if item:MouseMoved(x, y) then
                return true
            end
        end
    end
    return false
end

function Item:MouseDoubleClick(button, x, y)	
	if self:Enabled() then
		if self.menu_type then
			for _, item in pairs(self._visible_items) do
				if item:MouseDoubleClick(button, x, y) then
					return true
				end
			end
		end
		
		if not self:MouseCheck(true) then
			return false
		end
		
		if self:MouseInside(x,y) and self.on_double_click then
			self.on_double_click(item, button, x, y)
			return true
		end
	end
end

Item.GrowHeight = Item.AlignItems
function Item:UpdateCanvas(h) end

--Other

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