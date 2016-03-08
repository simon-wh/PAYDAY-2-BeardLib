MenuMapEditor = MenuMapEditor or class()
function MenuMapEditor:init()
	local ws = managers.gui_data:create_fullscreen_workspace()   
 	ws:connect_keyboard(Input:keyboard())  
    ws:connect_mouse(Input:mouse())  
	self._fullscreen_ws = ws
    self._fullscreen_ws_pnl = ws:panel():panel({alpha = 0})
    self._options = {}
    self._menus = {}
    self._menu_panel = self._fullscreen_ws_pnl:panel({
        name = "menu_panel",
        halign = "center", 
        align = "center",
        layer = 1000,
        w = self._fullscreen_ws_pnl:w() / 4.5,
        alpha = 1
    })      
    self._scroll_panel = self._menu_panel:panel({
        name = "scroll_panel",
        halign = "center", 
        align = "center",
        y = 35,
        h = self._menu_panel:h() - 35,
        w = self._menu_panel:w(),
    })  
    self._menu_panel:text({
    	name = "unit_data",
    	color = Color.black,
    	y = 300,
    	x = 4,
    	layer = 20,
    	visible = false,
    	text = "Unit data: none",
    	font = "fonts/font_medium_mf",
    	font_size = 20,
    })
    self._fullscreen_ws_pnl:rect({
      	name = "crosshair_vertical", 
      	w = 2,
      	h = 6,
      	alpha = 0.8, 
        layer = 999 
    }):set_center(self._fullscreen_ws_pnl:center())        
    self._fullscreen_ws_pnl:rect({
      	name = "crosshair_horizontal", 
      	w = 6,
      	h = 2,
      	alpha = 0.8, 
        layer = 999 
    }):set_center(self._fullscreen_ws_pnl:center())
    self._menu_panel:rect({
      	name = "menu_bg", 
      	halign="grow", 
      	valign="grow", 
      	alpha = 0.8, 
        layer = 19 
    })      
    self._hide_panel = self._fullscreen_ws_pnl:panel({
      	name = "hide_panel", 
      	w = 16,
      	h = 16,
      	y = 16,
        layer = 25 
    })  
    self._hide_panel:rect({
      	name = "bg", 
      	halign="grow", 
      	valign="grow", 
      	alpha = 0.8, 
    })    
  	self._hide_panel:text({
	    name = "text",
	    text = "<",
	    layer = 20,
	    w = 16,
	    h = 16,
		align = "center",	   
	    color = Color.black,
	    font = "fonts/font_large_mf",
	    font_size = 16
	})    
	self._hide_panel:set_left(self._menu_panel:right())  
	self._help_panel = self._menu_panel:panel({
        name = "help_panel",
        x = 30,
	    y = 10,
	    w = self._menu_panel:w() - 100,
        layer = 20,
     })   
    self._help_panel:rect()
    self._help_panel:rect({
    	name = "line",
    	w = 2,
    	color = Color(0, 0.5, 1),
    })
	self._help_text = self._help_panel:text({
	    name = "help_text",
	    text = "",
	    layer = 1,
	    wrap = true,
	    x = 4,
	    word_wrap = true,
	    valign = "left",
	    align = "left",
	    vertical = "top",	    
	    color = Color.black,
	    font = "fonts/font_large_mf",
	    font_size = 16
	})  
	local _,_,w,h = self._help_text:text_rect()
	self._help_panel:set_size(w + 10,h)
	self:CreateItems()
    self._menu_closed = true
    self._fullscreen_ws_pnl:key_press(callback(self, self, "key_press"))    
    self._fullscreen_ws_pnl:key_release(callback(self, self, "key_release"))    
    
end

 

function MenuMapEditor:enable()
	self._fullscreen_ws_pnl:set_alpha(1)
	self._menu_closed = false
	managers.mouse_pointer:use_mouse({
		mouse_move = callback(self, self, "mouse_moved"),
		mouse_press = callback(self, self, "mouse_pressed"),
		mouse_release = callback(self, self, "mouse_release"),
		id = self._mouse_id
	}) 	
end

function MenuMapEditor:disable()

	self._fullscreen_ws_pnl:set_alpha(0)
	self._menu_closed = true
	self._highlighted = nil
	for _, item in pairs(self._current_menu.children) do
		item.highlight = false
	end	
	if self._openlist then
	 	self._menu_panel:child(self._openlist.name .. "list"):set_visible(false)
	 	self._openlist = nil
	end		
	managers.mouse_pointer:remove_mouse(self._mouse_id)
end

function MenuMapEditor:key_release( o, k )
	self.key_pressed = nil
end
 
function MenuMapEditor:key_press( o, k )
	self._mouse_id = self._mouse_id or managers.mouse_pointer:get_id()
	if self._current_menu and not self._menu_closed then
		self.key_pressed = k 
		for _, item in pairs(self._current_menu.children) do
			if item.type ~= "menu" and item.highlight then
				if k == Idstring("enter") then
					if item.callback and item.type ~= "slider" and item.type ~= "combo" then
						if item.type == "toggle" then
							item.value = not item.value
						end	
						MenuMapEditor[item.callback](self, item)
						managers.menu_component:post_event("menu_enter")
						MenuMapEditor:set_value(item, item.value)
					elseif item.type == "combo" then
						 local combo_list = self._menu_panel:child(item.name .. "list")
						 if not self._openlist then
						 	combo_list:set_visible(true)
						 	self._openlist = item
						 	return
						 end
						 if self._openlist then
						 	self._menu_panel:child(self._openlist.name .. "list"):set_visible(false)
						 	self._openlist = nil
						 	return
						 end	
					end
				else
					if item.type == "textbox" then	
						local text = item.panel:child("text")												
						text:animate(callback(self, self, "key_hold"), k, item)												
					end				
				end
			end
		end
	end
end
function MenuMapEditor:key_hold( text, k, item )
	local sec = 0 
  	while self.key_pressed == k and self._highlighted.panel == text:parent() do
  		if k == Idstring("backspace") then
	 		local s, e = text:selection()
			local n = utf8.len(text:text())
			if s == e and s > 0 then
				text:set_selection(s - 1, e)
			end 		
			text:replace_text("")		
		else
			text:enter_text(callback(self, self, "enter_text"))	
		end
	  	wait(math.max(0.3 - sec, 0.1))		
	  	sec = sec + 0.05
  	end
  	self:set_value(item, text:text())
  	text:enter_text(nil)
end
function MenuMapEditor:enter_text( text, s )
	text:replace_text(s)
end
function MenuMapEditor:mouse_moved( o, x, y )
	if self._slider_hold and self._old_x then
		local slider_bg = self._slider_hold.panel:child("slider_bg")
		self._slider_hold.value = self._slider_hold.value + (x - self._old_x)
      	MenuMapEditor[self._slider_hold.callback](self, self._slider_hold)
      	MenuMapEditor:set_value(self._slider_hold, self._slider_hold.value)
    end	
  	if self._openlist then
  	 	for k, v in pairs(self._openlist.items) do
      	 	local combo_list = self._menu_panel:child(self._openlist.name .. "list") 
      	 	if combo_list:child("bg"..k):inside(x,y) then 		
      	 		combo_list:child("bg"..k):set_color(Color(0, 0.5, 1))
      	 	else
				combo_list:child("bg"..k):set_color(Color.white)
      	 	end
  	 	end
  	end
    for _,item in pairs(self._options) do
      	if not item.parent then
  			if item.panel:child("bg"):inside(x,y) then
        		item.panel:child("bg"):set_color(Color(0, 0.5, 1)) 
        		item.highlight = true  
        		self:set_help(item.help)
        	elseif self._current_menu ~= item then
	        	item.panel:child("bg"):set_color(Color.white)  
	        	item.highlight = false	   	        		
        	end
        end
   	end
   	local found = false
   	for _, item in pairs(self._current_menu.children) do
   		if not self._openlist and not self._slider_hold then
		    if item.panel:inside(x, y) then
			    item.panel:child("bg"):set_color(Color(0, 0.5, 1))
			    self:set_help(item.help)
			    item.highlight = true
			    found = true
			    self._highlighted = item
			    if item.type == "toggle" then
			    	item.panel:child("toggle"):set_color(Color.black)
			    end
		    else
		    	item.panel:child("bg"):set_color(Color.white:with_alpha(0))
		        item.highlight = false
			    if item.type == "toggle" then
			    	item.panel:child("toggle"):set_color(Color.black)
			    end        
		    end
		end
   	end		    	
   	if not found then 
		self._highlighted = nil
	end
   	self._old_x = x
end
 
function MenuMapEditor:set_help(help)
	self._help_text:set_text(help)
	local _,_,w,h = self._help_text:text_rect()
	self._help_panel:set_size(w + 10,h)
end
function MenuMapEditor:mouse_release( o, button, x, y )
	self._slider_hold = nil
end
function MenuMapEditor:mouse_pressed( o, button, x, y )
if button == Idstring("0") then
    if self._hide_panel:inside(x,y) then
        self._hide_panel:child("text"):set_text(self._hidden and "<" or ">")
        self._menu_panel:set_right(self._hidden and self._menu_panel:w() or 0  )
        self._hidden = not self._hidden
        self._hide_panel:set_left(self._menu_panel:right())
        return
    end
    if self._openlist and self._menu_panel:child(self._openlist.name .. "list"):inside(x,y) then
        for k, v in pairs(self._openlist.items) do
            if self._openlist and self._menu_panel:child(self._openlist.name .. "list"):child("item"..k):inside(x,y) then
                self:set_value(self._openlist, self._openlist.value)
                self[self._openlist.callback](self, self._openlist)
                managers.menu_component:post_event("menu_enter")
                self._menu_panel:child(self._openlist.name .. "list"):set_visible(false)
                self._openlist = nil
                return
            end
        end
    elseif self._openlist then
        self._menu_panel:child(self._openlist.name .. "list"):hide()
        self._openlist = nil
        return
    end
    for _, item in pairs(self._options) do
        if (item.type == "menu" or item.type == "browser") and item.panel:child("bg"):inside(x,y) then
            self._menus[item.index].items_panel:show()
            managers.menu_component:post_event("menu_enter")
            if self._openlist then
                self._menu_panel:child(self._openlist.name .. "list"):hide()
                self._openlist = nil
            end
            item.visible = true
            self._current_menu = self._menus[item.index]
            item.panel:child("bg"):set_color(Color(0, 0.5, 1))
            for index,parent in pairs(self._menus) do
                if parent ~= self._menus[item.index] then
                    parent.items_panel:hide()
                    parent.panel:child("bg"):set_color(Color.white)
                    parent.visible = false
                end
            end
            return
        end
    end
    if self._highlighted and alive(self._highlighted.panel) and self._highlighted.panel:inside(x,y) then
        local item = self._highlighted
        managers.menu_component:post_event("menu_enter")
        if item.callback then
            if item.type == "toggle" then
                self:set_value(item, not item.value)
            end
            self[item.callback](self, item)
        end
        if item.type == "slider" then
            if item.panel:child("slider_bg"):inside(x,y) then
                self._slider_hold = item
                return
            end
        elseif item.type == "combo" then
            local combo_list = self._menu_panel:child(item.name .. "list")
            if not self._openlist and item.panel:inside(x,y) then
                combo_list:show()
                self._openlist = item
                return
            end
        end
    end
    if not self._openlist and not self._slider_hold and not self._highlighted then
        BeardLib.MapEditor:select_unit()
        return
    end
end
if self._highlighted and alive(self._highlighted.panel) and self._highlighted.panel:inside(x,y) then
    local item = self._highlighted
    local wheelup = (button == Idstring("mouse wheel up") and true) or (button == Idstring("mouse wheel down") and false)
    if wheelup ~= nil and item.type == "combo" then
        if not self._openlist then
            if (wheelup and (item.value - 1) ~= 0) or (not wheelup and (item.value + 1) < (#item.items + 1))  then
                self:set_value(item, item.value + (wheelup and -1) or (not wheelup and 1))
                self[item.callback](self, item)
                return
            end
        end
    end
end
if self._current_menu.items_panel:inside(x,y) then
    if button == Idstring("mouse wheel down") then
        self:scroll_down()
    elseif button == Idstring("mouse wheel up") then
        self:scroll_up()
    end
end	
end

 

function MenuMapEditor:set_value(item, value)		
	item.value = value
	if item.type == "toggle" then
		if value == true then
			item.panel:child("toggle"):set_texture_rect(24,0,24,24)
		else
			item.panel:child("toggle"):set_texture_rect(0,0,24,24)			
		end
	elseif item.type == "slider" then
		local slider_value = item.panel:child("slider_value")
		slider_value:set_text(string.format("%.2f", value))
	elseif item.type == "textbox" then
		local text = item.panel:child("text")
		text:set_text(value)
		text:set_selection(text:text():len())
 	elseif item.type == "combo" then
		item.panel:child("combo_selected"):set_text(item.localize_items and managers.localization:text(item.items[value]) or item.items[value])
	end
end 
function MenuMapEditor:CreateItem( config ) 
	local panel = config.parent and  self._scroll_panel:child(config.parent.."_items") or self._menu_panel
	local item_panel = panel:panel({ 
		name = config.name,
      	y = 10, 
      	x = 10,
      	w = self._menu_panel:w() - 32, 
      	h = 24,
      	layer = 21,
    })    
    local marker = item_panel:rect({
      	name = "bg", 
      	color = Color.white:with_alpha(config.parent and 0 or 1),
      	h = 24,
      	halign="grow", 
      	valign="grow", 
        layer = -1 
    })
    local item_text = item_panel:text({
	    name = "title",
	    text = config.text,
	    vertical = "center",
	    align = config.parent and "left" or "center",
	    x = 4,
	   	h = 24,
	    layer = 6,
	    color = Color.black,
	    font = "fonts/font_medium_mf",
	    font_size = 16
	})  	
	local _,_,w,h = item_text:text_rect()
	item_text:set_w(w)
    config.panel = item_panel  
    config.option = config.option or config.name

    self._options[config.name] = config
    if config.parent then  
		if config.type == "toggle" then
			config.callback = config.callback or "toggleclbk"
		elseif config.type ~= "button" then
			config.callback = config.callback or "valueclbk"
		end
		local parent = self._options[config.parent].index
	    if not self._menus[parent].children then
	        self._menus[parent].children[1] = config
	    else
	        self._menus[parent].children[#self._menus[parent].children + 1] = config
	    end
	    panel:set_h(32 * #self._menus[parent].children)
	    config.index = #self._menus[parent].children
	   	if config.index ~= 1 then
	    	item_panel:set_top(self._menus[parent].children[config.index - 1].panel:bottom() + 4)
	    end	
	end	      
 	if config.color then
 		local color = item_panel:rect({
 			color = config.color,
 			w = 2,
 		})
 	end
	if not config.parent then  
		config.items_panel = self._scroll_panel:panel({ 
			name = config.name .. "_items",
	      	w = self._menu_panel:w() - 24, 
	      	visible = not self._first_parent,
	      	layer = 21,
    	})  
		local _,_,w,_ = item_text:text_rect()
 	    item_panel:set_w(w + 8)  	    
 	    item_text:set_w(w)
 	    config.visible = true
 	    config.children = {}
	    if not self._first_parent then
	    	self._menus[1] = config
	    	config.index = 1
	    	self._first_parent = config
	    	marker:set_color(Color(0, 0.5, 1))   
	    	self._current_menu = config
	    else
	    	self._menus[#self._menus + 1] = config
	    	config.index = #self._menus
	    	item_panel:set_left(self._menus[#self._menus - 1].panel:right() + 2)
	    	self._menus[config.index].visible = false
	    end	
	    if config.type == "browser" then
	    	self:browse(config)
	    end
	elseif config.type == "toggle" and config.parent then 
	    local toggle = item_panel:bitmap({
	        name = "toggle",
	        x = 2,
	        w = item_panel:h() -2,
	        h = item_panel:h() -2,
	        layer = 6,
	        color = Color.black,
	        texture = "guis/textures/menu_tickbox",
	        texture_rect = config.value and {24,0,24,24} or {0,0,24,24}
	    })  
	    toggle:set_world_right(item_panel:right() - 4)
	elseif config.type == "combo" and config.parent then 
	    local combo_selected = item_panel:text({
		    name = "combo_selected",
		    text = config.items[config.value],
		    valign = "center",
		    align = "center",
		    vertical = "center",
		    w = item_panel:w(),
		    h = item_panel:h(),
		    x = 2,
		    layer = 6,
		    color = Color.black,
		    font = "fonts/font_large_mf",
		    font_size = 16
		}) 			    
		local list_icon = item_panel:text({
		    name = "list_icon",
		    text = "^",
		    rotation = 180,
		    valign = "right",
		    align = "right",
		    vertical = "center",
		    w = 18,
		    h = 18,
		    x = 2,
		    layer = 6,
		    color = Color.black,
		    font = "fonts/font_large_mf",
		    font_size = 16
		}) 		
		local combo_bg = item_panel:bitmap({
	        name = "combo_bg",
	        y = 4,
	        w = 180,
	        h = 16,
	        layer = 5,
	        color = Color(0.6, 0.6, 0.6),
	    })	
	    combo_bg:set_world_right(item_panel:right() - 4)
	    combo_selected:set_center(combo_bg:center())
		local combo_list = self._menu_panel:panel({
			name = config.name.."list",
	      	y = 0, 
	      	w = 120, 
	      	h = #config.items * 18,
	      	layer = 100,
	      	visible = false,
	      	halign = "left", 
	      	align = "left"
	    })    
	    combo_list:rect({
	      	name = "bg", 
	      	halign="grow", 
	      	valign="grow", 
	      	blend_mode = "normal", 
	      	alpha = 1, 
	        color = Color.white, 
	        layer = -1 
	    })   
	    if config.index < 12 then
	    	combo_list:set_lefttop(combo_bg:world_left(), combo_bg:world_bottom() + 4)
		else
	    	combo_list:set_leftbottom(combo_bg:world_left(), combo_bg:world_top() - 4)			
		end
	    list_icon:set_left(combo_bg:right() - 12)
	    for k, text in pairs(config.items) do
	    	local combo_item = combo_list:text({
			    name = "item"..k,
			    text = text,
			    align = "center",
			    w = combo_list:w(),
			    h = 18,
			    y = 18 * (k - 1),
			    layer = 6,
			    color = Color.black,
			    font = "fonts/font_large_mf",
			    font_size = 16
			}) 
			local combo_item_bg = combo_list:bitmap({
			    name = "bg"..k,
			    align = "center",
			    w = combo_list:w(),
			    h = 18,
			    y = 18 * (k - 1),
			    layer = 5,
			    color = Color.white,
			}) 							
	    end
	elseif config.type == "slider" and config.parent then 
		local slider_value = item_panel:text({
		    name = "slider_value",
		    text = tostring(string.format("%.2f", config.value)),
		    valign = "center",
		    align = "center",
		    vertical = "center",
		    w = item_panel:w(),
		    h = item_panel:h(),
		    x = 2,
		    layer = 8,
		    color = Color.black,
		    font = "fonts/font_large_mf",
		    font_size = 16
		}) 	
		local slider_bg = item_panel:bitmap({
	        name = "slider_bg",
	        y = 4,
	        w = 180,
	        h = 16,
	        layer = 5,
	        color = Color(0.6, 0.6, 0.6),
	    })			
	    slider_bg:set_world_right(item_panel:right() - 4)
	    slider_value:set_center(slider_bg:center())
	elseif config.type == "textbox" and config.parent then 
		local text = item_panel:text({
		    name = "text",
		    text = config.value,
		    valign = "center",
		    align = "center",
		    vertical = "center",
		    w = 180,
		    h = 16,
		    x = 2,
		    layer = 8,
		    color = Color.black,
		    font = "fonts/font_medium_mf",
		    font_size = 16
		}) 	
		local bg = item_panel:bitmap({
	        name = "bg",
	        y = 4,
	        w = 180,
	        h = 16,
	        layer = 5,
	        color = Color(0.5, 0.5, 0.5),
	    })			
	    bg:set_world_right(item_panel:right() - 4)
	    text:set_center(bg:center())
	end
end

function MenuMapEditor:get_item( name )  
	for _,item in pairs(self._options) do
		if item.name == name then
			return item
		end
	end
end  
function MenuMapEditor:reset(item, value)
	if item and item.type ~= "button" then
		MenuMapEditor[item.callback](self, item)
		MenuMapEditor:set_value(item, item.value)
	end
end

function MenuMapEditor:CreateItems()
    self:CreateItem({
        name = "unit_options",
        text = "Selected Unit",
        help = "",
        type = "menu"  
    })      
    self:CreateItem({
        name = "units_browser",
        text = "Units",
        help = "",
        directory = "assets/extract/units",
        type = "browser"  
    })      
    self:CreateItem({
        name = "missions_options",
        text = "Missions",
        help = "",
        type = "menu"  
    })            
    self:CreateItem({
        name = "continents_options",
        text = "Continents",
        help = "",
        type = "menu"  
    })      
    self:CreateItem({
        name = "game_options",
        text = "Game",
        help = "",
        type = "menu"  
    })        
    self:CreateItem({
        name = "unit_name",
        text = "Name: ",
        value = "",
        help = "",
        parent = "unit_options",
        type = "textbox"  
    })    
    self:CreateItem({
        name = "unit_id",
        text = "ID: ",
        value = "",
        help = "",
        parent = "unit_options",
        type = "textbox"  
    })         
    self:CreateItem({
        name = "unit_path",
        text = "Unit path: ",
        value = "",
        help = "",
        parent = "unit_options",
        type = "textbox"  
    })      
    self:CreateItem({
        name = "positionx",
        text = "Position x: ",
        value = 0,
        help = "",
        callback = "set_unit_data", 
        parent = "unit_options",
        type = "slider"  
    })     
    self:CreateItem({
        name = "positiony",
        text = "Position Y: ",
        value = 0,
        help = "",
        callback = "set_unit_data", 
        parent = "unit_options",
        type = "slider"  
    })       
    self:CreateItem({
        name = "positionz",
        text = "Position z: ",
        value = 0,
        help = "",
        callback = "set_unit_data", 
        parent = "unit_options",
        type = "slider"  
    })       
    self:CreateItem({
        name = "rotationyaw",
        text = "Rotation yaw: ",
        value = 0,
        help = "",
        callback = "set_unit_data", 
        parent = "unit_options",
        type = "slider"  
    })     
    self:CreateItem({
        name = "rotationpitch",
        text = "Rotation pitch: ",
        value = 0,
        help = "",
        callback = "set_unit_data",       
        parent = "unit_options",
        type = "slider"  
    })       
    self:CreateItem({
        name = "rotationroll",
        text = "Rotation roll: ",
        value = 0,
        help = "",
        callback = "set_unit_data",
        parent = "unit_options",
        type = "slider"  
    })          
    self:CreateItem({
        name = "unit_delete_btn",
        text = "Delete unit",
        help = "",
        callback = "delete_unit",
        parent = "unit_options",
        type = "button"  
    })      
    self:CreateItem({
        name = "continents_savepath",
        text = "Save path: ",
        value = "maps",
        help = "",
        parent = "continents_options",
        type = "textbox"  
    })       
    self:CreateItem({
        name = "continents_filetype",
        text = "Type: ",
        value = 1,
        items = {"custom_xml", "generic_xml", "json"},
        help = "",
        parent = "continents_options",
        type = "combo"  
    })     
    self:CreateItem({
        name = "continents_savebtn",
        text = "Save",
        help = "",
        callback = "save_continents",
        parent = "continents_options",
        type = "button"  
    })  
    self:CreateItem({
        name = "units_visibility",
        text = "MenuMapEditor units visibility",
        help = "",
        value = false,
        callback = "set_MenuMapEditor_units_visible",
        parent = "continents_options",
        type = "toggle"  
    })      
    self:CreateItem({
        name = "units_highlight",
        text = "Highlight all units",
        help = "",
        value = false,
        parent = "continents_options",
        type = "toggle"  
    })       
    self:CreateItem({
        name = "show_elements",
        text = "Show elements",
        help = "",
        value = false,
        parent = "missions_options",
        type = "toggle"  
    })         
    self:CreateItem({
        name = "teleport_player",
        text = "Teleport player",
        help = "",
        callback = "teleport_me",
        parent = "game_options",
        type = "button"  
    })      
 end
function MenuMapEditor:teleport_me()
	BeardLib.MapEditor:drop_player()
end
function MenuMapEditor:_unit_color()
	local num = self._selected_unit:num_bodies()
	for i = 0, num - 1 do
		local body = self._selected_unit:body(i)
		if body:has_ray_type(Idstring("MenuMapEditor")) or not body:has_ray_type(Idstring("body")) then
			if body:has_ray_type(Idstring("walk")) and not body:has_ray_type(Idstring("body")) then
				if body:has_ray_type(Idstring("mover")) then
					return Color(1, 1, 0.25, 1)
				end
				if not body:has_ray_type(Idstring("mover")) then
					return Color(1, 0.25, 1, 1)
				end
			end
			if body:has_ray_type(Idstring("mover")) then
				return Color(1, 1, 1, 0.25)
			end
		end
	end
	return Color(1, 0.5, 0.5, 0.85)
end

function MenuMapEditor:update()		
	if self.units_found then
		for _, unit in pairs(self.units_found) do
			Application:draw(unit, 1, 1,1)
		end
	end		
	if alive(self._selected_unit) then
		Application:draw(self._selected_unit, self:_unit_color():unpack())	
		name_brush = Draw:brush(self:_unit_color())
	else
		name_brush = Draw:brush(Color.green)
	end
	if self:get_item("units_highlight").value then
		local name_brush
		for _, unit in pairs(World:find_units_quick("all")) do
			if unit:MenuMapEditor_id() ~= -1 then
				Application:draw(unit, 1, 1,1)
			end
		end
		name_brush:set_font(Idstring("fonts/font_medium"), 32)
		if managers.viewport:get_current_camera() then
			local cam_up = managers.viewport:get_current_camera():rotation():z()
			local cam_right = managers.viewport:get_current_camera():rotation():x()
			if alive(self._selected_unit) then
				name_brush:center_text(self._selected_unit:position() + Vector3(-10, -10, 200), self._selected_unit:unit_data().name_id .. "[ " .. self._selected_unit:MenuMapEditor_id() .. " ]", cam_right, -cam_up)
			end
		end	
	end
end

function MenuMapEditor:load_continents(continents)
    for continent_name, _ in pairs(continents) do
	    self:CreateItem({
	        name = continent_name,
	        text = "Save continent: " .. continent_name,
	        help = "",
	        value = true,
	        parent = "continents_options",
	        type = "toggle"  
	    })     
    end
end
function MenuMapEditor:delete_unit( item )
	if alive(self._selected_unit) then
		setup._world_holder._definition:delete_unit(self._selected_unit)		
		World:delete_unit(self._selected_unit)
		self:set_unit(nil)			
	end
end
function MenuMapEditor:set_MenuMapEditor_units_visible( item )
	for _, unit in pairs(World:find_units_quick("all")) do
		if type(unit:unit_data()) == "table" and unit:unit_data().only_visible_in_MenuMapEditor then
			unit:set_visible( item.value )
		end
	end
end
function MenuMapEditor:set_unit( unit )
	self._selected_unit = unit	
	self:set_value(self:get_item("unit_name"), unit and unit:unit_data().name_id or "")
	self:set_value(self:get_item("unit_path"), unit and unit:unit_data().name or "")
	self:set_value(self:get_item("unit_id"), unit and unit:unit_data().unit_id or "")	
	self:set_value(self:get_item("positionx"), unit and unit:position().x or 0)
	self:set_value(self:get_item("positiony"), unit and unit:position().y or 0)
	self:set_value(self:get_item("positionz"), unit and unit:position().z or 0)	
	self:set_value(self:get_item("rotationyaw"), unit and unit:rotation():yaw() or 0)
	self:set_value(self:get_item("rotationpitch"), unit and unit:rotation():pitch() or 0)
	self:set_value(self:get_item("rotationroll"), unit and unit:rotation():roll() or 0)
end
function MenuMapEditor:save_continents()
	local item = self:get_item("continents_filetype")
	local type = item.items[item.value]
	local path = self:get_item("continents_savepath").value
	local world_def = setup._world_holder._definition
	if file.DirectoryExists( path ) then
		for continent_name, _ in pairs(world_def._continent_definitions) do
			if self:get_item(continent_name).value then
				world_def:save_continent(continent_name, type, path)
			end
		end
	else
		log("Directory doesn't exists.")
	end
end
function MenuMapEditor:set_unit_data( item )
	if alive(self._selected_unit) then
		BeardLib.MapEditor:set_position(Vector3(self:get_item("positionx").value, self:get_item("positiony").value, self:get_item("positionz").value), Rotation(self:get_item("rotationyaw").value, self:get_item("rotationpitch").value, self:get_item("rotationroll").value))
		if self._selected_unit:MenuMapEditor_id() then
			setup._world_holder._definition:set_unit(self._selected_unit:MenuMapEditor_id(), {position = self._selected_unit:position(), rotation = self._selected_unit:rotation()})
		end
	end
end
function MenuMapEditor:browse( config )
	local folders
	local files
	if config.directory then
		self:clear(config)
		config.items_panel:set_y(0)
		config.current_dir = config.current_dir or config.directory
		log(config.current_dir)
		folders = file.GetDirectories( config.current_dir )
	    files = file.GetFiles( config.current_dir )
	end
    self:CreateItem({
   		name = "back_btn",
    	text = "^ ( " .. (config.current_dir or config.custom_dir) .. " )",
    	parent = config.name or self._current_menu.name,
    	callback = "folder_back" ,
    	type = "button",
    })    
    self:CreateItem({
   		name = "search_btn",
    	text = "Search",
    	parent = config.name or self._current_menu.name,
    	callback = "file_search",
    	type = "button",
    })
    if folders then
	    for _, folder in pairs(folders) do
	    	self:CreateItem({
	    		name = folder,
	    		text = folder,
	    		parent = config.name,
	    		callback = "folder_click",
	    		type = "button",
	    	})
	    end
	end
	if files then
	    for _,file in pairs(files) do
	    	if file:match("unit") then
		    	self:CreateItem({
		    		name = file:gsub(".unit", ""),
		    		text = file,
		    		path = config.current_dir:gsub("assets/extract/", "") .. "/" .. file:gsub(".unit", ""),
		    		color = PackageManager:has(Idstring("unit"), Idstring(config.current_dir:gsub("assets/extract/", "") .. "/" .. file:gsub(".unit", ""))) and Color.green or Color.red,
		    		parent = config.name,
		    		callback = "file_click",
		    		type = "button",
		    	})
		    end
	    end	
	end
end

 
 
function MenuMapEditor:scroll_up()
	if self._current_menu.items_panel:h() > self._scroll_panel:h() then
		self._current_menu.items_panel:set_top(math.min(0, self._current_menu.items_panel:top() + 20))
		return true
	end
end
function MenuMapEditor:scroll_down()
	if self._current_menu.items_panel:h() > self._scroll_panel:h() then
		self._current_menu.items_panel:set_bottom(math.max(self._current_menu.items_panel:bottom() - 20, self._scroll_panel:h()))
		return true
	end
end

function MenuMapEditor:folder_click(item)
	self._current_menu.current_dir = self._current_menu.current_dir .. "/" .. item.text
	self:browse(self._current_menu)
end
function MenuMapEditor:file_search(item)
	self._is_searching = false
	managers.system_menu:show_keyboard_input({
		text = "", 
		title = "Search:", 
		callback_func = callback(self, self, "search", self._current_menu.directory),
	})	
end
function MenuMapEditor:search(path, success, search)
	if not success then
		return
	end
	if not self._is_searching then
		self:clear(self._current_menu)
		self:browse({custom_dir = "Searching " .. tostring(search) })
		self._is_searching = true
	end
	local files = file.GetFiles( path )
	if files ~= false then
		for _, file in pairs(files) do
			if file:match("unit") and file:match(search) then
		    	self:CreateItem({
		    		name = file:gsub(".unit", ""):gsub(".xml", ""),
		    		text = file,
		    		path = path:gsub("assets/extract/", "") .. "/" .. file:gsub(".unit", ""):gsub(".xml", ""),
		    		color = PackageManager:has(Idstring("unit"), Idstring(path:gsub("assets/extract/", "") .. "/" .. file:gsub(".unit", ""):gsub(".xml", "xml"))) and Color.green or Color.red,
		    		parent = self._current_menu.name,
		    		callback = "file_click",
		    		type = "button",
		    	})
		    end			
		end
	end
	local folders = file.GetDirectories( path )
	if folders ~= false then
		for _, folder in pairs(folders) do 	    	
			self:search(path .. "/" .. folder, true, search)
		end
	end

end
function MenuMapEditor:file_click(item)
	local cam = managers.viewport:get_current_camera()
	local unit_path = self._current_menu.current_dir:gsub("assets/extract/", "") .. "/" .. item.name:gsub(".unit", "")
	local unit_path = item.path
	local SpawnUnit = function()
		local unit
		if MassUnitManager:can_spawn_unit(Idstring(unit_path)) then
			unit = MassUnitManager:spawn_unit(Idstring(unit_path), cam:position() + cam:rotation():y(), Rotation(0,0,0))
		else
			unit = CoreUnit.safe_spawn_unit(unit_path,  cam:position() + cam:rotation():y(),  Rotation(0,0,0))
		end	
		unit:unit_data().name_id = "new_unit"
		unit:unit_data().unit_id = math.random(99999)
		unit:unit_data().name = unit_path
		unit:unit_data().position = unit:position()
		unit:unit_data().rotation = unit:rotation()
		setup._world_holder._definition:add_unit(unit)
	end
	if item.color == Color.red then
		QuickMenu:new( "Warning", "Unit is not loaded, load it?", 
		{[1] = {text = "Yes", callback = function()	
			managers.dyn_resource:load(Idstring("unit"), Idstring(unit_path), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)
			self:browse(self._current_menu)
			SpawnUnit()			
  		end
  		},[2] = {text = "No", is_cancel_button = true}}, true)
	else
		SpawnUnit()
	end
end
function MenuMapEditor:folder_back(item)
	if self._is_searching then
		self._is_searching = false
		self:browse(self._current_menu)
	else
		local str = string.split(self._current_menu.current_dir, "/")
		table.remove(str, #str)
		self._current_menu.current_dir = table.concat(str, "/")
		self:browse(self._current_menu)
	end

end
function MenuMapEditor:clear( menu )
	for k, item in pairs(self._current_menu.children) do
		item.panel:parent():remove(item.panel)
	end
	self._current_menu.children = {}
end
function MenuMapEditor:toggleclbk(item)
	if item.value then
		managers.menu_component:post_event("box_tick")
	else
		managers.menu_component:post_event("box_untick")
	end
end
function MenuMapEditor:valueclbk(item)

end

