Menu = Menu or class(MenuUI)

function Menu:init( menu, params )
	local MenuPanel = menu._panel  
    params.text_color = params.text_color or menu.text_color
    if menu.tabs then
    	params.panel = MenuPanel:panel({ 
    		name = params.name,
          	y = 10, 
          	x = 5,
          	h = 24,
          	layer = 21,
        }) 
        local Marker = params.panel:rect({
            name = "bg", 
            h = 24,
            color = menu.background_color or Color.white,
            halign="grow", 
            valign="grow", 
            layer = -1 
        })       
        local ItemText = params.panel:text({
    	    name = "title",
    	    text = params.text,
    	    vertical = "center",
    	    align = "left",
    	    x = 4,
    	   	h = 24,
    	    layer = 6,
    	    color = params.text_color or Color.black,
    	    font = "fonts/font_medium_mf",
    	    font_size = 16
    	}) 
    	local _,_,w,_ = ItemText:text_rect()
	    params.panel:set_w(w + 8)  	    
	    ItemText:set_w(w)
	    params.visible = true      
    end	    
    params.items_panel = menu._scroll_panel:panel({ 
        name = params.name .. "_items",
        w = MenuPanel:w() - 12, 
        visible = not menu._first_parent,
        layer = 21,
    })     
    if not menu._first_parent then
        self.visible = true
        menu._first_parent = self
        menu._current_menu = self
    else
        self.visible = false
    end    
    table.merge(self, params)
    self.menu = menu
    self._items = {}     
    table.insert(menu._menus, self)   
    if menu.tabs then
        if menu._first_parent == self then
            self:SetVisible(true) 
        end    
        menu:AlignMenus()
    end 
end

function Menu:mouse_pressed( o, button, x, y )
	local menu = self.menu        
	if menu._current_menu == self then
		if menu._highlighted then
			if menu._highlighted:mouse_pressed( o, button, x, y ) then
                return true
            end
		end
        if button == Idstring("mouse wheel down") then
            self:scroll_down()
        elseif button == Idstring("mouse wheel up") then
            self:scroll_up()
        end	
        if button == Idstring("0") then
			if self.menu._scroll_panel:child("scroll_bar"):child("rect"):inside(x, y) then
				self.menu._grabbed_scroll_bar = true
                return true
			end	
			if self.menu._scroll_panel:child("scroll_bar"):inside(x, y) then
				self.menu._grabbed_scroll_bar = true
				local where = (y - self.menu._scroll_panel:world_top()) / (self.menu._scroll_panel:world_bottom() - self.menu._scroll_panel:world_top())
				self:scroll(where * self.items_panel:h())
                return true
			end
		end
	else
	    if self.panel and self.panel:child("bg"):inside(x,y) then
	    	managers.menu_component:post_event("menu_enter")
	        self:SetVisible(true)
	        self:AlignScrollBar()
	        menu._current_menu:SetVisible(false)
	        menu._current_menu = self
	        return true
	    end	
	end		

end
function Menu:mouse_moved( o, x, y )
	if self.menu._current_menu == self then
		for _, item in ipairs(self._items) do
			item:mouse_moved( o, x, y )
		end     
	    if self.menu._grabbed_scroll_bar then
			local where = (y - self.menu._scroll_panel:world_top()) / (self.menu._scroll_panel:world_bottom() - self.menu._scroll_panel:world_top())
			self:scroll(where * self.items_panel:h())
	    end		  	
    end
	if self.panel and self.panel:child("bg"):inside(x,y) then
        self:SetHighlight(true)
        self.menu:set_help(self.help)
    elseif self.menu._current_menu ~= self then
	    self:SetHighlight(false) 	        		
    end 	
end

function Menu:key_press( o, k )	
	if self.menu._current_menu == self and self.menu._highlighted then
		self.menu._highlighted:key_press( o, k )
	end
end

function Menu:SetHighlight( highlight )
	self.highlight = highlight	
	self.panel:child("bg"):set_color(highlight and Color(0.2, 0.5, 1) or self.menu.background_color or Color.white) 
end
function Menu:SetVisible( visible )
	self.items_panel:set_visible(visible)
	self:SetHighlight(visible)
	self.visible = visible
    if self.menu._openlist then
        self.menu._panel:child(self.menu._openlist.name .. "list"):hide()
        self.menu._openlist = nil
    end       
end

function Menu:AlignItem(Item)	
	local h = 0 
	for i, item in ipairs(self._items) do
		h = h + item.panel:h()
	end
	self.items_panel:set_h(h)
	if #self._items == 1 then
		Item.panel:set_top(0)
	else
		Item.panel:set_top(self._items[#self._items - 1].panel:bottom())
	end
	self:AlignScrollBar()
end

function Menu:AlignItems() --Makes search units stuck and crash sometimes..
    local h = 0 
	for i, item in ipairs(self._items) do
		if i == 1 then
			item.panel:set_top(0)
		else
			item.panel:set_top(self._items[i - 1].panel:bottom())
		end
        h = h + item.panel:h()
	end
    self.items_panel:set_h(h)
    if self.items_panel:h() < self.menu._scroll_panel:h() then 	
		self.items_panel:set_top(0)
    end	
  	self:AlignScrollBar()
end
function Menu:AlignScrollBar()
	local scroll_bar = self.menu._scroll_panel:child("scroll_bar")
	local scroll_bar_rect = scroll_bar:child("rect")
	local bar_h = self.menu._scroll_panel:top() - self.menu._scroll_panel:bottom()
	scroll_bar_rect:set_h(math.abs(self.menu._scroll_panel:h() * (bar_h / self.items_panel:h() )))
 	scroll_bar_rect:set_y( -(self.items_panel:y()) * self.menu._scroll_panel:h()  / self.items_panel:h())
	scroll_bar:set_left(self.menu._scroll_panel:left())
	scroll_bar:set_visible(self.items_panel:h() > self.menu._scroll_panel:h())
end
function Menu:GetItem( name )
	for _, item in pairs(self._items) do
		if item.name == name then
			return item
		end
	end
	return nil
end
function Menu:scroll_up()
	if self.items_panel:h() > self.menu._scroll_panel:h() then
		self.items_panel:set_top(math.min(0, self.items_panel:top() + 20))
		self:AlignScrollBar()
		return true
	end
end

function Menu:scroll_down()
	if self.items_panel:h() > self.menu._scroll_panel:h() then
		self.items_panel:set_bottom(math.max(self.items_panel:bottom() - 20, self.menu._scroll_panel:h()))
		self:AlignScrollBar()
		return true
	end
end
function Menu:scroll(y)
	if self.items_panel:h() > self.menu._scroll_panel:h() then
		self.items_panel:set_y(math.clamp(-y, -self.items_panel:h() ,0))
		self:AlignScrollBar()
		return true
	end
end
function Menu:ClearItems(label)
    local temp = self._items
    self._items = {}
	for k, item in pairs(temp) do
        if not label or item.label == label then
		    item.panel:parent():remove(item.panel)
        else
            table.insert(self._items, item)
        end
	end
    self.items_panel:set_y(0)
end
function Menu:RemoveItem(name)
	for k, item in pairs(self._items) do
		if item.name == name then
			item.panel:parent():remove(item.panel)
			table.remove(self._items, k)
			self:AlignItems()
		end
	end
end
 

function Menu:Toggle( params )
	local Item = Toggle:new(self, params)
    return self:NewItem(Item) 
end
function Menu:Button( params )
	local Item = Item:new(self, params)
    return self:NewItem(Item)  	
end
function Menu:ComboBox( params )
	local Item = ComboBox:new(self, params)
    return self:NewItem(Item)
end 
function Menu:TextBox( params )
	local Item = TextBox:new(self, params)
    return self:NewItem(Item)
end 
function Menu:ComboBox( params )
	local Item = ComboBox:new(self, params)
    return self:NewItem(Item)
end 
function Menu:Slider( params )
	local Item = Slider:new(self, params)
    return self:NewItem(Item)
end 
function Menu:Divider( params )
	local Item = Divider:new(self, params)
    return self:NewItem(Item)
end
function Menu:Table( params )
	local Item = Table:new(self, params)
    return self:NewItem(Item)
end 

function Menu:NewItem( Item )
    local temp = self._items
    if Item.index then
        self._items = {}
        for k,v in pairs(temp) do
            if Item.index == k then
                table.insert(self._items, Item)
            end
            table.insert(self._items, v)
        end
        self:AlignItems()
    else    
        table.insert(self._items, Item)
        self:AlignItem(Item)   
    end
    return Item
end