MenuUI = MenuUI or class()
function MenuUI:init(params)
    if not managers.gui_data then
        Hooks:Add("SetupInitManagers", "CreateMenuUI"..tostring(self), function()
            self:init(params)
        end)
        return
    end
    table.merge(self, params)
    self.type_name = "MenuUI"
    self.layer = self.layer or 200 --Some fucking layer that is higher than most vanilla menus
    self._ws = managers.gui_data:create_fullscreen_workspace()
	self._ws:connect_keyboard(Input:keyboard())
    tweak_data.gui.MOUSE_LAYER = 9999999999 --nothing should have a layer that is bigger than mouse tbh
    self._panel = self._ws:panel():panel({
        name = self.name or self.type_name, 
        alpha = 0, layer = self.layer
    })
    self._panel:key_press(callback(self, self, "KeyPressed"))
    self._panel:key_release(callback(self, self, "KeyReleased"))

    self._panel:bitmap({
        name = "bg",
        halign = "grow",
        valign = "grow",
        visible = self.background_blur ~= nil or self.background_color ~= nil,
        render_template = self.background_blur and "VertexColorTexturedBlur3D",
        texture = self.background_blur and "guis/textures/test_blur_df",
        w = self.background_blur and self._panel:w(),
        h = self.background_blur and self._panel:h(),
        color = self.background_color,
    })

    self._help = self._panel:panel({name = "help", alpha = 0, w = self.help_width or 300})
    self.help_background_color = NotNil(self.help_background_color, Color.white)
    self._help:rect({
        name = "bg",
        halign ="grow",
        valign ="grow",
        color = self.help_background_color,
    })    
    self._help:text({
        name = "text",
        font = self.help_font or "fonts/font_large_mf",
        font_size = self.help_font_size or 16,
        layer = 2,
        wrap = true,
        word_wrap = true,
        text = "",
        color = self.help_color or Color.black
    })

    self._menus = {}
    self.private = {}
	if self.visible == true and managers.mouse_pointer then self:enable() end

    BeardLib:AddUpdater("MenuUIUpdate"..tostring(self), callback(self, self, "Update"), true)
    if self.create_items then self:create_items() end
end

function MenuUI:ReloadInterface(params, shallow)
    table.merge(self, params or {})
    self._panel:child("bg"):configure({
        visible = not not self.background_blur or not not self.background_color,
        render_template = self.background_blur and "VertexColorTexturedBlur3D" or "VertexColorTextured",
        texture = self.background_blur and "guis/textures/test_blur_df",
        w = self.background_blur and self._panel:w(),
        h = self.background_blur and self._panel:h(),
        color = self.background_color,
        alpha = self.background_alpha,       
    })
    self._help:child("bg"):configure({
        color = self.help_background_color or self.background_color,
        alpha = self.help_background_alpha or self.background_alpha,       
    })
    self._help:child("text"):configure({
        font = self.help_font or "fonts/font_large_mf",
        font_size = self.help_font_size or 16,       
        color = self.help_color or Color.black       
    })
    if not shallow then
        for _, menu in pairs(self._menus) do
            menu:ReloadInterface()
        end
    end
end

function MenuUI:ShowDelayedHelp(item)
    DelayedCalls:Add("ShowItemHelp"..tostring(self), self.show_help_time or 1, function()
        if not alive(item) then
            self:HideHelp()
            return
        end
        if self._showing_help and self._showing_help ~= item then
            self:HideHelp()
        end
        if self._highlighted == item and not self:Typing() then
            self._help:set_layer(item:Panel():parent():layer() + 50000)
            help_text = self._help:child("text")
            help_text:set_w(300)
            help_text:set_text(item.help_localized and managers.localization:text(item.help) or item.help)
            local _,_,w,h  = help_text:text_rect()
            w = math.min(w, 300)
            self._help:set_size(w + 8, h + 8)
            help_text:set_shape(4, 4, w + 4, h + 4)

            local mouse = managers.mouse_pointer:mouse()
            local mouse_p = mouse:parent()
            local bottom_h = (mouse_p:world_bottom() - mouse:world_bottom()) 
            local top_h = (mouse:world_y() - mouse_p:world_y()) 
            local normal_pos = h <= bottom_h or bottom_h >= top_h
            self._help:set_world_left(mouse:world_left() + 7)
            if normal_pos then
                self._help:set_world_y(mouse:world_bottom() - 5)
            else
                self._help:set_world_bottom(mouse:world_y() - 5)
            end
            play_anim(self._help, {set = {alpha = 1}})
            self._showing_help = item
            self._saved_help_x = self._old_x
            self._saved_help_y = self._old_y
        end
    end)
end

function MenuUI:HideHelp()
    if self._showing_help then
        stop_anim(self._help)
        self._help:set_alpha(0)
    end
end

function MenuUI:Group(params)
    return self:AddMenu(BeardLib.Items.Group:new(self:ConfigureMenu(params)))
end

function MenuUI:DivGroup(params)
    local _params = self:ConfigureMenu(params)
    _params.divider_type = true
    return self:AddMenu(BeardLib.Items.Group:new(_params))
end

function MenuUI:Menu(params)
    return self:AddMenu(BeardLib.Items.Menu:new(self:ConfigureMenu(params)))
end

function MenuUI:ConfigureMenu(params)
    local _params = clone(params)
    _params.parent_panel = self._panel
    _params.parent = self
    _params.menu = self
    _params.inherit = NotNil(_params.inherit, self)
    return _params
end

function MenuUI:AddMenu(menu)
    table.insert(self._menus, menu)
    return menu
end

function MenuUI:Enabled() return self._enabled end

function MenuUI:IsMouseActive()
    local mc = managers.mouse_pointer._mouse_callbacks
    return mc[#mc] and mc[#mc].parent == self
end

function MenuUI:Enable()
    if self:Enabled() then
        return
    end
    if self.animate_toggle then
        play_anim(self._panel, {set = {alpha = 1}, time = 0.2})       
    else
        self._panel:set_alpha(1)
    end
	self._enabled = true
    self._mouse_id = self._mouse_id or managers.mouse_pointer:get_id()
	managers.mouse_pointer:use_mouse({
		mouse_move = callback(self, self, "MouseMoved"),
		mouse_press = callback(self, self, "MousePressed"),
		mouse_double_click = callback(self, self, "MouseDoubleClick"),
		mouse_release = callback(self, self, "MouseReleased"),
		id = self._mouse_id,
        parent = self
	})
end

function MenuUI:Disable()
    if not self:Enabled() then
        return
    end
    if self.animate_toggle then
        play_anim(self._panel, {set = {alpha = 0}, time = 0.2})
    else
        self._panel:set_alpha(0)
    end
	self._enabled = false
	if self._highlighted then self._highlighted:UnHighlight() end
	if self._openlist then self._openlist:hide() end
	managers.mouse_pointer:remove_mouse(self._mouse_id)
end

function MenuUI:RunToggleClbk()
    if self.toggle_clbk then
        self.toggle_clbk(self:Enabled())
    end           
end

function MenuUI:CheckOpenedList()
	if self._openlist and not self._openlist.parent:Enabled() then
		self._openlist:hide()
	end
end

function MenuUI:Toggle()
    if not self:Enabled() then
        self:enable()
        if self.toggle_clbk then
            self.toggle_clbk(self:Enabled())
        end
    elseif self:ShouldClose() then
        self:disable()
        if self.toggle_clbk then
            self.toggle_clbk(self:Enabled())
        end
    end
end

function MenuUI:Update()
    local x,y = managers.mouse_pointer:world_position()
    if self._slider_hold then self._slider_hold:SetValueByMouseXPos(x) end
    self._old_x = x
    self._old_y = y
    if self._showing_help and (not alive(self._showing_help) or not self._showing_help:MouseInside(x, y)) then
        self:HideHelp()
    end
end

function MenuUI:KeyReleased(o, k)
    if self.always_key_released then self.always_key_released(o, k) end
    self._scroll_hold = nil
    self._key_pressed = nil   
    if not self:Enabled() then
        return
    end
    if self.key_released then self.key_release(o, k) end
end

function MenuUI:MouseInside()
    for _, menu in pairs(self._menus) do
        if menu:MouseFocused() then
            return true
        end
    end
end

function MenuUI:KeyPressed(o, k)
    if self.always_key_press then self.always_key_press(o, k) end
    self._key_pressed = k
    if self.active_textbox then
        self.active_textbox:KeyPressed(o, k)
    end
    if self._openlist then
        self._openlist:KeyPressed(o, k)
    end
    if self.toggle_key and k == Idstring(self.toggle_key) then
        self:toggle()
    end
    if not self:Enabled() then
        return
    end
    if self:IsMouseActive() and self._highlighted and self._highlighted.parent:Enabled() and self._highlighted:KeyPressed(o, k) then
        return 
    end 
    for _, menu in pairs(self._menus) do
        if menu:KeyPressed(o, k) then
            return
        end
    end
    if self.key_press then self.key_press(o, k) end
end

function MenuUI:Param(param)
    return self[param]
end

function MenuUI:SetParam(param, value)
    self[param] = value
end

function MenuUI:MouseReleased(o, button, x, y)
	self._slider_hold = nil
    for _, menu in pairs(self._menus) do
        if menu:MouseReleased(button, x, y) then
            return
        end
    end
    if self.mouse_release then
        self.mouse_release(o, k)
    end
end

function MenuUI:MouseDoubleClick(o, button, x, y)
    if self.always_mouse_double_click then self.always_mouse_double_click(button, x, y) end
	for _, menu in pairs(self._menus) do
		if menu:MouseDoubleClick(button, x, y) then
            return
		end
	end
    if self.mouse_double_click then self.mouse_double_click(button, x, y) end
end

local scroll_up = Idstring("mouse wheel up")
local scroll_down = Idstring("mouse wheel down")

function MenuUI:MousePressed(o, button, x, y)
    self:HideHelp()
    if self.active_textbox and button ~= scroll_down and button ~= scroll_up then
        if self.active_textbox:MousePressed(button, x, y) then
            return
        elseif  self.active_textbox then
            self.active_textbox:set_active(false)
        end
    end
    if self.always_mouse_press then self.always_mouse_press(button, x, y) end
    if self._openlist then
        if self._openlist.parent:Enabled() then
            if self._openlist:MousePressed(button, x, y) then
                return
            end
        else
            self._openlist:hide()
        end
    else    
    	for _, menu in pairs(self._menus) do
            if menu:MouseFocused() then
        		if menu:MousePressed(button, x, y) then
                    return
        		end
            end
    	end
    end
    if self.mouse_press then self.mouse_press(button, x, y) end
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

    if self.active_textbox and not self.active_textbox:MouseMoved(x, y) then
        if self.active_textbox then
            self.active_textbox:set_active(false)
        end
    end

    if self._openlist then
        if self._openlist.parent:Enabled() then
            if self._openlist:MouseMoved(x, y) then
                return
            end
        else
            self._openlist:hide()
        end
    else
        if self._highlighted and not self._highlighted:MouseFocused() and not self._scroll_hold and not self._highlighted.parent.always_highlighting then
            self._highlighted:UnHighlight()
        else
            for _, menu in pairs(self._menus) do
                if menu:MouseMoved(x, y) then
                    return
                end
            end
        end        
    end
    if self.mouse_move then self.mouse_move(x, y) end
end

function MenuUI:GetMenu(name, shallow)
    for _, menu in pairs(self._menus) do
        if menu.name == name then
            return menu
        elseif not shallow then
            local item = menu:GetMenu(name)
            if item and item.name then
                return item
            end
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

function MenuUI:GetItemByLabel(label, shallow)
    for _, item in pairs(self._menus) do
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

function MenuUI:Focused()
    if self:Typing() then
        return true
    end
	for _, menu in pairs(self._menus) do
		if menu:Visible() then
            return self._highlighted
        end
	end
    return false
end

function MenuUI:Typing()
    return alive(self.active_textbox) and self.active_textbox.cantype
end

--Deprecated Functions--
function MenuUI:SwitchMenu(menu)
    if self._current_menu then
        self._current_menu:SetVisible(false)
    end
    menu:SetVisible(true)
    self._current_menu = menu
end

function MenuUI:NewMenu(params) return self:Menu(params) end
function MenuUI:enable() return self:Enable() end
function MenuUI:disable() return self:Disable() end
function MenuUI:toggle() return self:Toggle() end