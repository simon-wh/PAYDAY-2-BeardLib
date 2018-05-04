BeardLib.Items.Menu = BeardLib.Items.Menu or class(BeardLib.Items.Item)
local Menu = BeardLib.Items.Menu
Menu.type_name = "Menu"
function Menu:Init(params)
    self:WorkParams(params)
    self.menu_type = true
    self.panel = self.parent_panel:panel({
        name = self.name .. "_panel",
        w = self.w,
        h = self.h,
        visible = self.visible == true,
        layer = self.layer or 1,
    })
    self.panel:script().menuui_item = self
    self.bg = self.panel:bitmap({
        name = "background",
        halign = "grow",
        valign = "grow",
        visible = not not self.background_color and self.background_visible,
        render_template = self.background_blur and "VertexColorTexturedBlur3D",
        texture = self.background_blur and "guis/textures/test_blur_df",
        color = self.background_color,
        alpha = self.background_alpha,
        layer = 0
    })
    self._scroll = ScrollablePanelModified:new(self.panel, "ItemsPanel", {
        layer = 4,
        padding = 0, 
        scroll_width = self.scrollbar == false and 0 or self.scroll_width, 
		hide_shade = true,
        color = self.scroll_color or self.highlight_color,
        hide_scroll_background = self.hide_scroll_background,
        scroll_speed = self.scroll_speed
    })
    self.items_panel = self._scroll:canvas()
    self._my_items = self._my_items or {}
    self._reachable_items = self._reachable_items or {}
    self._visible_items = {}
    self:Reposition()
    self:SetEnabled(self.enabled)
    self:SetVisible(self.visible)
    self:GrowHeight()
end

function Menu:GrowHeight(speed)
    self:AlignItems()
end

function Menu:SetScrollSpeed(speed)
    self.scroll_speed = speed
    self._scroll._scroll_speed = self.scroll_speed
end

function Menu:ReloadInterface()
    self.panel:child("background"):configure({
       --visible = self.background_color ~= nil and self.background_visible,
       --render_template = self.background_blur and "VertexColorTexturedBlur3D" or "VertexColorTextured",
       --texture = self.background_blur and "guis/textures/test_blur_df" or "units/white_df",
        color = self.background_color,
        alpha = self.background_alpha,        
    })
    self._scroll:set_scroll_color(self.scroll_color or self.highlight_color)
    self:RecreateItems()
end

function Menu:WorkParams(params)
    Menu.super.WorkParams(self, params)
    params = params or {}
    self:WorkParam("scroll_width", 8)
    self:WorkParam("scroll_speed", 48)
    self.background_visible = NotNil(self.background_visible, self.type_name == "Menu" and true or false)
    self.private.background_color = NotNil(self.private.background_color, self.background_visible and self.background_color or nil)    
    self.auto_align = NotNil(self.auto_align, true)
    self.auto_height = NotNil(self.auto_height, self.type_name == "Group" and true or false)
    self.scrollbar = NotNil(self.scrollbar, self.auto_height ~= true or self.min_height ~= nil or self.max_height ~= nil)
    if self.w == "half" then
        self.w = self.parent_panel:w() / 2
    end
end

function Menu:SetSize(w, h)
    self.orig_h = h
    self:_SetSize(w, h)
end

function Menu:_SetSize(w, h)
    if not self:alive() then
        return
	end
	
	w = w or self.w
	h = h or self.orig_h or self.h
	h = math.clamp(h, self.min_height or 0, self.max_height or h)
	self.panel:set_size(w, h)
	self:SetScrollPanelSize()
    self.w, self.h = self.panel:size()
    self:Reposition()
    self:MakeBorder()
end

function Menu:SetScrollPanelSize()
    if not self:alive() or not self._scroll:alive() then
        return
    end
    self._scroll:set_size(self.panel:w(), self.panel:h() - self:TextHeight())
	self._scroll:panel():set_bottom(self.panel:h())
	self._scroll:force_scroll()
end

function Menu:UpdateCanvas(h)
    if not self:alive() then
        return
	end
	if not self.auto_height and h < self._scroll:scroll_panel():h() then
		h = self._scroll:scroll_panel():h()
	end
	
	self._scroll:set_canvas_size(nil, h)
	self:_SetSize(nil, self.auto_height and self.items_panel:h() + self:TextHeight() or nil, true)

	self:CheckItems()
end

function Menu:KeyPressed(o, k)
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

function Menu:MouseDoubleClick(button, x, y)
    local menu = self.menu
    if self:Enabled() then
        if menu._highlighted and menu._highlighted.parent == self then
            if menu._highlighted.MouseDoubleClick and menu._highlighted:MouseDoubleClick(button, x, y) then
                return true
            end
        end
    end
end

function Menu:MousePressed(button, x, y)
    local menu = self.menu
    if self:Enabled() then
        for _, item in pairs(self._visible_items) do
            if item:MousePressed(button, x, y) then
                return true
            end
        end
        if button == Idstring("0") then
            if self._scroll:mouse_pressed(button, x, y) then
                menu._scroll_hold = true
                self:CheckItems()
                return true
            end
        elseif self.scrollbar and self._scroll:is_scrollable() then
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
    end
    return false
end

function Menu:MouseMoved(x, y)
    if self:Enabled() and self:MouseFocused(x, y) then
        local _, pointer = self._scroll:mouse_moved(nil, x, y) 
        if pointer then
            self:CheckItems()
            if managers.mouse_pointer.set_pointer_image then
                managers.mouse_pointer:set_pointer_image(pointer)
            end
            return true
        else
            if managers.mouse_pointer.set_pointer_image then
                managers.mouse_pointer:set_pointer_image("arrow")
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

function Menu:CheckItems()
    self._visible_items = {}
    for _, item in pairs(self._my_items) do
        if item:TryRendering() and (not item.override_panel or item.override_panel == self) then
            table.insert(self._visible_items, item)
        end
    end
end

function Menu:MouseReleased(button, x, y)
    self._scroll:mouse_released(button, x, y)
    if not self.menu._highlighted then
        managers.mouse_pointer:set_pointer_image("arrow")
    end
    for _, item in pairs(self._my_items) do
        if item:MouseReleased(button, x, y) then
            return true
        end
    end
end

function Menu:SetVisible(visible, animate, no_align)
    local panel = self:Panel()
    if not alive(panel) then
        return
    end
    local was_visible = self.visible
    BeardLib.Items.Item.super.SetVisible(self, visible, true)
    if animate and visible and not was_visible then
        panel:set_alpha(0)
        play_anim(panel, {set = {alpha = 1}, time = 0.2})
    end
    if not no_align and self.parent.auto_align then
    	self.parent:AlignItems()
    end
    self.menu:CheckOpenedList()
end

function Menu:GetMenus(match, deep, menus)
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

function Menu:GetMenu(name, shallow)
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

function Menu:GetItem(name, shallow)
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

function Menu:GetItemByLabel(label, shallow)
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

function Menu:ClearItems(label)
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

function Menu:RecreateItems()
    for _, item in pairs(self._my_items) do
        self:RecreateItem(item)
    end
    if self.auto_align then
        self:AlignItems(true)
    end
end

function Menu:RecreateItem(item, align_items)
    if item.list then
        item.list:parent():remove(item.list)
    end
    local panel = item:Panel()
    if alive(panel) then
        panel:parent():remove(panel)
    end
    local pitem = item.override_panel
    if pitem then
        table.delete(pitem._adopted_items, item)
        pitem._has_adopted_items = #pitem._adopted_items > 0
        if pitem.Panel then
            item.parent_panel = pitem:Panel()
        end
    end
    item.parent_panel = alive(item.parent_panel) and item.parent_panel or self.items_panel
    item:Init()
    item:PostInit()
    if item.menu_type then
        item:RecreateItems()
    end
    if align_items then
        self:AlignItems(true)
    end
end

function Menu:RemoveItem(item)
    if not item then
        return
    end
    if item.menu_type then
        item:ClearItems()
    end
    if item._adopted_items then
        for _, v in pairs(item._adopted_items) do
            v.override_panel = nil
            v:Destroy()
        end
    end
    if item.override_panel then
        table.delete(item.override_panel._adopted_items, item)
    end

    if item._list then
        item._list:Destroy()
    end
    
    table.delete(self._reachable_items, item)
    table.delete(self._my_items, item)
    table.delete(self._adopted_items, item)
    local panel = item:Panel()
    if alive(panel) then
        panel:parent():remove(panel)
    end
    if self.auto_align then
        self:AlignItems()
    end
end

function Menu:ShouldClose()
    for _, item in pairs(self._my_items) do
        if item.menu_type and not item:ShouldClose() then
            return false
        end
        if (item._textbox and item._textbox.cantype) or item.CanEdit then
            return false
        end
    end
    return true
end

function Menu:Items() return self._my_items end
function Menu:ItemsWidth() return self.items_panel:w() end
function Menu:ItemsHeight() return self.items_panel:h() end
function Menu:ItemsPanel() return self.items_panel end

function Menu:Create(type, ...)
    return self[type](self, ...)
end

function Menu:ImageButton(params)
    local w = params.w or not params.icon_h and params.size
    local h = params.h or params.icon_h or params.size
    local _params = self:ConfigureItem(params)
    _params.w = w or _params.w
    _params.h = h or _params.h or _params.size
    return self:NewItem(BeardLib.Items.ImageButton:new(_params))
end

function Menu:Group(params) return self:NewItem(BeardLib.Items.Group:new(self:ConfigureItem(params, true))) end
function Menu:Menu(params) return self:NewItem(BeardLib.Items.Menu:new(self:ConfigureItem(params, true))) end
function Menu:ComboBox(params) return self:NewItem(BeardLib.Items.ComboBox:new(self:ConfigureItem(params))) end
function Menu:TextBox(params) return self:NewItem(BeardLib.Items.TextBox:new(self:ConfigureItem(params))) end
function Menu:ComboBox(params) return self:NewItem(BeardLib.Items.ComboBox:new(self:ConfigureItem(params))) end
function Menu:Slider(params) return self:NewItem(BeardLib.Items.Slider:new(self:ConfigureItem(params))) end
function Menu:KeyBind(params) return self:NewItem(BeardLib.Items.KeyBindItem:new(self:ConfigureItem(params))) end
function Menu:Toggle(params) return self:NewItem(BeardLib.Items.Toggle:new(self:ConfigureItem(params))) end
function Menu:ItemsGroup(params) return self:Group(params) end --Deprecated--

function Menu:Button(params) 
	local _params = self:ConfigureItem(params)
	_params.button_type = true
	return self:NewItem(BeardLib.Items.Item:new(_params))
end

function Menu:NumberBox(params)
    local _params = self:ConfigureItem(params)
    _params.type_name = "NumberBox"
    _params.filter = "number"
    return self:NewItem(BeardLib.Items.TextBox:new(_params))
end

function Menu:Text(text, params)
    return self:Divider({text = text}, params)
end

function Menu:Divider(params)
    local _params = self:ConfigureItem(params)
    _params.divider_type = true
    return self:NewItem(BeardLib.Items.Item:new(_params))
end

function Menu:Image(params)
    params.divider_type = true
    return self:ImageButton(params)
end

function Menu:DivGroup(params)
    local _params = self:ConfigureItem(params)
    _params.divider_type = true
    return self:NewItem(BeardLib.Items.Group:new(_params))
end

function Menu:GetIndex(item)
    return table.index_of(self._my_items, item)
end

function Menu:ConfigureItem(item, menu)
    item = clone(item)
    if type(item) ~= "table" then
        log(tostring(debug.traceback()))
        return
    end
    local inherit = NotNil(item.inherit, self)
    item.inherit = inherit
    item.parent = self
    item.menu = self.menu
    item.parent_panel = self.items_panel
    if item.override_panel and item.override_panel.Panel then
        item.parent_panel = item.override_panel:Panel()
    end
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

function Menu:NewItem(item)
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