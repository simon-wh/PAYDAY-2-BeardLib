MenuUI = MenuUI or class()
function MenuUI:init(params)
    self.type_name = "MenuUI"
    local texture = "guis/textures/menuicons"
    FileManager:AddFile("texture", texture, BeardLib.Utils.Path:Combine(BeardLib.config.assets_dir, texture .. ".texture"))
	local ws = managers.gui_data:create_fullscreen_workspace()
 	ws:connect_keyboard(Input:keyboard())
    ws:connect_mouse(Input:mouse())
    params.override_size_limit = params.override_size_limit or true
    params.layer = params.layer or 0
	self._ws = ws
    self._ws_pnl = ws:panel():panel({alpha = 0, layer = (tweak_data.gui.MOUSE_LAYER - 190) + params.layer})
    self._menus = {}
    self._panel = self._ws_pnl:panel({
        name = "menu_panel",
        halign = "center",
        align = "center",
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
    table.merge(self, params)
	if params.create_items then
		params.create_items(self)
	end
	self._menu_closed = true
	if params.closed == false then
		if managers.mouse_pointer then
			self:enable()
		end
	end
    self._ws_pnl:key_press(callback(self, self, "KeyPressed"))
    self._ws_pnl:key_release(callback(self, self, "KeyReleased"))
    BeardLib:AddUpdater("MenuUI"..tostring(self), function() --Using this way for sliders weirdly fixes the glitch problems caused by normal mouse_moved
        local x,y = managers.mouse_pointer:world_position()
        if self._slider_hold then
            self._slider_hold:SetValueByMouseXPos(x)
        end
        self._old_x = x
        self._old_y = y       
    end, true)    
    return self
end

--Deprecated Function--
function MenuUI:NewMenu(params)
    return self:Menu(params)
end

function MenuUI:Menu(params)
    params.parent_panel = self._panel
    params.parent = self
    params.menu = self
    local menu = Menu:new(params)
    table.insert(self._menus, menu)
    return menu
end

function MenuUI:enable()
	self._ws_pnl:set_alpha(1)
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
    if self._menu_closed then
        return
    end
	self._ws_pnl:set_alpha(0)
	self._menu_closed = true
	self._highlighted = nil
	if self._openlist then
		if self._openlist.list then
			self._openlist.list:hide()
		else
			self._openlist:hide()
		end
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
        if menu:MouseFocused() then
            return true
        end
    end
end

function MenuUI:KeyPressed(o, k)
    self._key_pressed = k
    if self._openlist then
        self._openlist:KeyPressed(o, k)
    end
    if self.toggle_key and k == Idstring(self.toggle_key) then
        self:toggle()
    end
    if self._menu_closed then
        return
    end
    if self._highlighted and self._highlighted.parent:Visible() then
        self._highlighted:KeyPressed(o, k) 
        return 
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

function MenuUI:MouseReleased(o, button, x, y)
	self._slider_hold = nil    
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
    if self.always_mouse_press then self.always_mouse_press(button, x, y) end
    if self._openlist then
        if self._openlist.parent:Visible() then
            if self._openlist:MousePressed(button, x, y) then
                return
            end
        else
            self._openlist:hide()
        end
    else    
    	for _, menu in ipairs(self._menus) do
            if menu:MouseFocused() then
        		if menu:MousePressed(button, x, y) then
                    return
        		end
            end
    	end
    end
    if self.mouse_press then
        self.mouse_press(button, x, y)
    end
end

function MenuUI:ShouldClose()
	if not self._slider_hold and not self._grabbed_scroll_bar then
		for _, menu in pairs(self._menus) do
            if not menu:ShouldClose() then
                return false
            end
		end
		return true
	end
	return false
end

function MenuUI:MouseMoved(o, x, y)
    if self.always_mouse_move then self.always_mouse_move(x, y) end
    if self._openlist then
        if self._openlist.parent:Visible() then
            if self._openlist:MouseMoved(x, y) then
                return
            end
        else
            self._openlist:hide()
        end
    else
        if self._highlighted and not self._highlighted:MouseFocused() and not self._scroll_hold then
            self._highlighted:UnHighlight()
        else
            for _, menu in ipairs(self._menus) do
                if menu:MouseMoved(x, y) then
                    return
                end
            end
        end        
    end
    if self.mouse_move then self.mouse_move(x, y) end
end

function MenuUI:SwitchMenu(menu) --Deprecated--
    self._current_menu:SetVisible(false)
    menu:SetVisible(true)
    self._current_menu = menu
end

function MenuUI:GetMenu(name)
    for _, menu in pairs(self._menus) do
        if menu.name == name then
            return menu
        end
    end
    return false
end

function MenuUI:GetItem(name, shallow)
    for _, menu in pairs(self._menus) do
        if menu.name == name then
            return menu
        elseif not shallow then
            local item = menu:GetItem(name)
            if item and item.name then
                return item
            end
        end
    end
    return false
end

function MenuUI:Focused()
	for _, menu in pairs(self._menus) do
		if menu:Focused() then
            return true
        end
	end
    return false
end
