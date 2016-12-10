MenuUI = MenuUI or class()
function MenuUI:init(params)
    local texture = "guis/textures/menuicons"
    FileManager:AddFile("texture", texture, path:Combine(BeardLib.config.assets_dir, texture))
	local ws = managers.gui_data:create_fullscreen_workspace()
 	ws:connect_keyboard(Input:keyboard())
    ws:connect_mouse(Input:mouse())
    params.position = params.position or "Left"
    params.override_size_limit = params.override_size_limit or true
	self._fullscreen_ws = ws
    self._fullscreen_ws_pnl = ws:panel():panel({alpha = 0, layer = params.layer or 500})
    self._options = {}
    self._menus = {}

    if params.w == "full" then
        params.w = self._fullscreen_ws_pnl:w()
    elseif params.w == "half" then
        params.w = self._fullscreen_ws_pnl:w() / 2
    end
    self._panel = self._fullscreen_ws_pnl:panel({
        name = "menu_panel",
        halign = "center",
        align = "center",
        h = params.h or self._fullscreen_ws_pnl:h(),
        w = params.w or self._fullscreen_ws_pnl:w(),
    })
    self._panel:rect({
        name = "bg",
        halign="grow",
        valign="grow",
        visible = params.background_color ~= nil,
        color = params.background_color,
        alpha = params.background_alpha,
        layer = 0
    })
    if type(params.position) == "table" then
        self._panel:position(params.position[1] or self._panel:x(), params.position[2] or self._panel:y())
    else
         if string.match(params.position, "Center") then
            self._panel:set_center(self._fullscreen_ws_pnl:center())
        end
        if string.match(params.position, "Bottom") then
            self._panel:set_bottom(self._fullscreen_ws_pnl:bottom())
        end
        if string.match(params.position, "Top") then
            self._panel:set_top(self._fullscreen_ws_pnl:top())
        end
        if string.match(params.position, "Right") then
            self._panel:set_right(self._fullscreen_ws_pnl:right())
        end
    end
    self._scroll_panel = self._panel:panel({
        name = "scroll_panel",
    })
    local bar_h = self._scroll_panel:top() - self._scroll_panel:bottom()
    self._scroll_panel:panel({
        name = "scroll_bar",
        w = 4,
        layer = 20,
    }):rect({
		name = "rect",
		color = params.text_color or Color.black,
		layer = 4,
		alpha = params.alpha or 0.5,
		h = bar_h,
    })
    table.merge(self, params)
	if params.create_items then
		params.create_items(self)
	else
		BeardLib:log("No create items callback found")
	end
	self._menu_closed = true
	if params.closed == false then
		if managers.mouse_pointer then
			self:enable()
		else
			BeardLib:log("Menu " .. tostring(self.name) .. " failed to open")
		end
	end
    self._fullscreen_ws_pnl:key_press(callback(self, self, "KeyPressed"))
    self._fullscreen_ws_pnl:key_release(callback(self, self, "KeyReleased"))
    BeardLib:AddUpadter("MenuUI"..tostring(self), function() --Using this way for sliders weirdly fixes the glitch problems caused by normal mouse_moved
        local x,y = managers.mouse_pointer:world_position()
        if self._slider_hold then
            self._slider_hold:SetValueByMouseXPos(x)
        end
        self._old_x = x
        self._old_y = y       
    end, true)    
    return self
end

function MenuUI:UpdateParams(params)
    params.position = params.position or "Left"
    table.merge(self, params)
    self._panel:child("bg"):configure({
        visible = params.background_color ~= nil,
        color = params.background_color,
        alpha = params.background_alpha,        
    })    
    self._scroll_panel:child("scroll_bar"):child("rect"):configure({
        color = self.text_color or Color.black,
        alpha = self.alpha or 0.5,        
    })
    if type(self.position) == "table" then
        self._panel:position(self.position[1] or self._panel:x(), self.position[2] or self._panel:y())
    else
         if string.match(self.position, "Center") then
            self._panel:set_center(self._fullscreen_ws_pnl:center())
        end
        if string.match(self.position, "Bottom") then
            self._panel:set_bottom(self._fullscreen_ws_pnl:bottom())
        end
        if string.match(self.position, "Top") then
            self._panel:set_top(self._fullscreen_ws_pnl:top())
        end
        if string.match(self.position, "Right") then
            self._panel:set_right(self._fullscreen_ws_pnl:right())
        end
    end    
end

function MenuUI:NewMenu(params)
    local menu = Menu:new(self, params)
    table.insert(self._menus, menu)
    return menu
end

function MenuUI:SetSize( w, h )
    self._panel:set_size(w, h)
    if self.position == "right" then
        self._panel:set_right(self._fullscreen_ws_pnl:right())
    elseif self.position == "center" then
        self._panel:set_center(self._fullscreen_ws_pnl:center())
    end
    self._scroll_panel:set_size(w,  h - (self.tabs and 35 or 0))
    self._scroll_panel:set_x(0)
    self._scroll_panel:child("scroll_bar"):set_h(h)
    for i, menu in pairs(self._menus) do
        menu.items_panel:set_size(w- 12, h)
        menu:RecreateItems()
    end
end
function MenuUI:enable()
	self._fullscreen_ws_pnl:set_alpha(1)
	self._menu_closed = false
	managers.mouse_pointer:use_mouse({
		mouse_move = callback(self, self, "MouseMoved"),
		mouse_press = callback(self, self, "MousePressed"),
		mouse_double_click = callback(self, self, "MouseDoubleClick"),
		mouse_release = callback(self, self, "MouseReleased"),
		id = self._mouse_id
	})
end

function MenuUI:disable()
	self._fullscreen_ws_pnl:set_alpha(0)
	self._menu_closed = true
	self._highlighted = nil
	if self._current_menu then
		for _, item in pairs(self._current_menu._items) do
			item.highlight = false
		end
	end
	if self._openlist then
	 	self._openlist.list:hide()
	 	self._openlist = nil
	end
	managers.mouse_pointer:remove_mouse(self._mouse_id)
end
function MenuUI:RunToggleClbk()
    if self.toggle_clbk then
        self.toggle_clbk(self._menu_closed)
    end           
end
function MenuUI:toggle()
    if self._menu_closed then
        self:enable()
        if self.toggle_clbk then
            self.toggle_clbk(self._menu_closed)
        end
    elseif self:ShouldClose() then    
        self:disable()
        if self.toggle_clbk then
            self.toggle_clbk(self._menu_closed)
        end
    end        
end
function MenuUI:KeyReleased( o, k )
	self._key_pressed = nil
    if self.key_released then
        self.key_release(o, k)
    end
end

function MenuUI:MouseInside()
    for _, menu in pairs(self._menus) do
        if menu:MouseInside() then
            return true
        end
    end
end

function MenuUI:KeyPressed(o, k)
    if self.toggle_key and k == Idstring(self.toggle_key) then
        self:toggle()
    end
    if self._menu_closed then
        return
    end
	self._key_pressed = k
	for _, menu in pairs(self._menus) do
        if menu:KeyPressed(o, k) then
            return true
        end
	end
    if self.key_press then
        self.key_press(o, k)
    end
end
function MenuUI:Param(param)
    return self[param]
end
function MenuUI:SetParam(param, value)
    self[param] = value
end
function MenuUI:MouseReleased( o, button, x, y )
	self._slider_hold = nil
	self._grabbed_scroll_bar = nil
    for _, menu in ipairs(self._menus) do
        if menu:MouseReleased(button, x, y) then
            return
        end
    end
    if self.mouse_release then
        self.mouse_release(o, k)
    end
end
function MenuUI:MouseDoubleClick(o, button, x, y)
	for _, menu in ipairs(self._menus) do
		if menu:MouseDoubleClick(button, x, y) then
            return
		end
	end
    if self.mouse_double_click then
        self.mouse_double_click(button, x, y)
    end
end
function MenuUI:MousePressed(o, button, x, y)
	for _, menu in ipairs(self._menus) do
		if menu:MousePressed(button, x, y) then
            return
		end
	end
    if self.mouse_press then
        self.mouse_press(button, x, y)
    end
end
function MenuUI:ShouldClose()
	if not self._slider_hold and not self._grabbed_scroll_bar then
		for _, menu in pairs(self._menus) do
			for _, item in pairs(menu._items) do
				if item.cantype or item.CanEdit then
					return false
				end
			end
		end
		return true
	end
	return false
end
function MenuUI:MouseMoved(o, x, y)
	for _, menu in ipairs( self._menus ) do
		menu:MouseMoved(x, y)
	end
    if self.mouse_move then
        self.mouse_move(x, y)
    end
end
function MenuUI:SwitchMenu(menu)
    self._current_menu:SetVisible(false)
    menu:SetVisible(true)
    self._current_menu = menu
end
function MenuUI:GetItem(name, menu_wanted)
	for _,menu in pairs(self._menus) do
		if menu.name == name then
			return menu
		elseif not menu_wanted then
			local item = menu:GetItem(name)
			if item and item.name then
				return item
			end
		end
	end
end
