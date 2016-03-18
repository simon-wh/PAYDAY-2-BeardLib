Menu = Menu or class(MenuUI)

function Menu:init( menu, params )
	local MenuPanel = menu._panel
	params.panel = MenuPanel:panel({ 
		name = params.name,
      	y = 10, 
      	x = 10,
      	h = 24,
      	layer = 21,
    }) 
    local Marker = params.panel:rect({
      	name = "bg", 
      	h = 24,
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
	    color = Color.black,
	    font = "fonts/font_medium_mf",
	    font_size = 16
	}) 
	params.items_panel = menu._scroll_panel:panel({ 
		name = params.name .. "_items",
      	w = MenuPanel:w() - 12, 
      	visible = not menu._first_parent,
      	layer = 21,
	})  
	local _,_,w,_ = ItemText:text_rect()
	    params.panel:set_w(w + 8)  	    
	    ItemText:set_w(w)
	    params.visible = true
    if not menu._first_parent then
    	menu._menus[1] = self
    	params.index = 1
    	menu._first_parent = self
    	Marker:set_color(Color(0, 0.5, 1))   
    	menu._current_menu = self
    else
    	menu._menus[#menu._menus + 1] = self
    	params.index = #menu._menus
    	params.panel:set_left(menu._menus[#menu._menus - 1].panel:right() + 2)
    	menu._menus[params.index].visible = false
    end	
    table.merge(self,params)
    self.menu = menu
    self._items = {}    
    if params.browser then
    	self:browse(params)
    end  
end
function Menu:mouse_pressed( o, button, x, y )
	local menu = self.menu        
	if menu._current_menu == self then
		if menu._highlighted then
			menu._highlighted:mouse_pressed( o, button, x, y)
		end
        if button == Idstring("mouse wheel down") then
            self:scroll_down()
        elseif button == Idstring("mouse wheel up") then
            self:scroll_up()
        end
	else
	    if self.panel:child("bg"):inside(x,y) then
	    	managers.menu_component:post_event("menu_enter")
	        self:SetVisible(true)
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
     end
	if self.panel:child("bg"):inside(x,y) then
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
	self.panel:child("bg"):set_color(highlight and Color(0, 0.5, 1) or Color.white) 
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
end

function Menu:AlignItems() --Makes search units stuck and crash sometimes..
	self.items_panel:set_h(0)
	for i, item in ipairs(self._items) do
		if i == 1 then
			item.panel:set_top(0)
		else
			item.panel:set_top(self._items[i - 1].panel:bottom())
		end
		self.items_panel:grow(0, item.panel:h())
	end
    if self.items_panel:h() < self.menu._scroll_panel:h() then 	
		self.items_panel:set_top(0)
    end	
end
function Menu:GetItem( name )
	for _, item in ipairs(self._items) do
		if item.name == name then
			log("yes " .. item.name .. " == " .. name)
			return item
		end
	end
	return nil
end
function Menu:scroll_up()
	if self.items_panel:h() > self.menu._scroll_panel:h() then
		self.items_panel:set_top(math.min(0, self.items_panel:top() + 20))
		return true
	end
end
function Menu:scroll_down()
	if self.items_panel:h() > self.menu._scroll_panel:h() then
		self.items_panel:set_bottom(math.max(self.items_panel:bottom() - 20, self.menu._scroll_panel:h()))
		return true
	end
end
function Menu:ClearItems()
	for k, item in pairs(self._items) do
		item.panel:parent():remove(item.panel)
	end
	self._items = {}
end
function Menu:RemoveItem(name)
	for k, item in pairs(self._items) do
		if item.name == name then
			item.panel:parent():remove(item.panel)
			table.remove(self._items, k)
		end
	end
end

function Menu:browse( config )
	local folders
	local files
	if config.directory then
		self:ClearItems()
		self.items_panel:set_y(0)
		self.current_dir = self.current_dir or self.directory
		BeardLib:log(self.current_dir)
		folders = file.GetDirectories( self.current_dir )
	    files = file.GetFiles( self.current_dir )
	end
    self:Button({
   		name = "back_btn",
    	text = "^ ( " .. (self.current_dir or self.custom_dir) .. " )",
    	callback = callback(self, self, "folder_back"),
    })    
    self:Button({
   		name = "search_btn",
    	text = "Search",
    	callback = callback(self, self, "file_search"),
    })
    if folders then
	    for _, folder in pairs(folders) do
	    	self:Button({
	    		name = folder,
	    		text = folder,
	    		callback = callback(self, self, "folder_click"),
	    	})
	    end
	end
	if files then
	    for _,file in pairs(files) do
	    	if file:match("unit") then
		    	self:Button({
		    		name = file:gsub(".unit", ""),
		    		text = file,
		    		path = self.current_dir:gsub("assets/extract/", "") .. "/" .. file:gsub(".unit", ""),
		    		color = PackageManager:has(Idstring("unit"), Idstring(self.current_dir:gsub("assets/extract/", "") .. "/" .. file:gsub(".unit", ""))) and Color.green or Color.red,
		    		callback = self.file_click,
		    	})
		    end
	    end	
	end
end
function Menu:search(path, success, search)
	if not success then
		return
	end
	if not self.menu._is_searching then
		self:ClearItems()
		self:browse({custom_dir = "Searching " .. tostring(search) })
		self.menu._is_searching = true
	end
	local files = file.GetFiles( path )
	if files ~= false then
		for _, unit_path in pairs(BeardLib.DBPaths["unit"]) do
			local split = string.split(unit_path, "/")
			local unit = split[#split]
			if unit:match(search) then
		    	self:Button({
		    		name = unit,
		    		text = unit,
		    		path = unit_path,
		    		color = PackageManager:has(Idstring("unit"), Idstring(unit_path)) and Color.green or Color.red,
		    		callback = self.file_click,
		    	})
		    end			
		end
	end
end

function Menu:folder_click(menu, item)
	self.current_dir = self.current_dir .. "/" .. item.text
	self:browse(self)
	local folder_click = self:GetItem(item.parent).folder_click
	if folder_click then
		folder_click()
	end
end
function Menu:file_search(menu, item)
	self.menu._is_searching = false
	managers.system_menu:show_keyboard_input({
		text = "", 
		title = "Search:", 
		callback_func = callback(self, self, "search", self.menu._current_menu.directory),
	})	
end
function Menu:GetItem( name )  
	for _,item in pairs(self._items) do
		if item.name == name then
			return item
		end
	end	
	return {}
end
function Menu:folder_back(menu, item)
	if self.menu._is_searching then
		self.menu._is_searching = false
		self:browse(self)
	else
		local str = string.split(self.menu._current_menu.current_dir, "/")
		table.remove(str, #str)
		self.menu._current_menu.current_dir = table.concat(str, "/")
		self:browse(self)
	end
end

function Menu:Toggle( params )
	local Item = Toggle:new(self, params)
 	table.insert(self._items, Item)
 	self:AlignItem(Item)
end
function Menu:Button( params )
	local Item = Item:new(self, params)
 	table.insert(self._items, Item)
 	self:AlignItem(Item) 	
end
function Menu:ComboBox( params )
	local Item = ComboBox:new(self, params)
 	table.insert(self._items, Item)
 	self:AlignItem(Item) 	
end 
function Menu:TextBox( params )
	local Item = TextBox:new(self, params)
 	table.insert(self._items, Item)
 	self:AlignItem(Item) 	
end 
function Menu:ComboBox( params )
	local Item = ComboBox:new(self, params)
 	table.insert(self._items, Item)
 	self:AlignItem(Item) 	
end 
function Menu:Slider( params )
	local Item = Slider:new(self, params)
 	table.insert(self._items, Item)
  	self:AlignItem(Item)	
end 
function Menu:Divider( params )
	local Item = Divider:new(self, params)
 	table.insert(self._items, Item)
  	self:AlignItem(Item)	
end 