ComboBox = ComboBox or class(Item)

function ComboBox:init( menu, params )
	self.super.init( self, menu, params )
 	local combo_selected = params.panel:text({
	    name = "combo_selected",
	    text = params.items[params.value],
	    valign = "center",
	    align = "center",
	    vertical = "center",
	    layer = 6,
	    color = Color.black,
	    font = "fonts/font_large_mf",
	    font_size = 16
	}) 			    
	local list_icon = params.panel:text({
	    name = "list_icon",
	    text = "^",
	    rotation = 180,
	    valign = "right",
	    align = "right",
	    vertical = "center",
	    w = 18,
	    h = 18,
	    layer = 6,
	    color = Color.black,
	    font = "fonts/font_large_mf",
	    font_size = 16
	}) 		
	local combo_bg = params.panel:bitmap({
        name = "combo_bg",
        y = 4,
        x = -2,
        w = params.panel:w() / 1.5,
        h = 16,
        layer = 5,
        color = Color(0.6, 0.6, 0.6),
    })	
    combo_bg:set_world_right(params.panel:right() - 4)
    combo_selected:set_center(combo_bg:center())
	local combo_list = self.menu._panel:panel({
		name = params.name.."list",
      	y = 0, 
      	w = 120, 
      	h = #params.items * 18,
      	layer = 100,
      	visible = false,
      	halign = "left", 
      	align = "left"
    })    
    combo_list:rect({
      	name = "bg", 
      	halign="grow", 
      	valign="grow", 
        layer = -1 
    })   
   -- if params.index < 12 then Later: Check if its outside the panel
    	combo_list:set_lefttop(combo_bg:world_left(), combo_bg:world_bottom() + 4)
---	else
    --	combo_list:set_leftbottom(combo_bg:world_left(), combo_bg:world_top() - 4)			
--	end
    list_icon:set_left(combo_bg:right() - 12)
    for k, text in pairs(params.items) do
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
		}) 							
    end	
end

function ComboBox:SetValue(value)
	self.super.SetValue(self, value)
	self.panel:child("combo_selected"):set_text(self.localize_items and managers.localization:text(self.items[value]) or self.items[value])
end

function ComboBox:mouse_pressed( o, button, x, y )
    local combo_list = self.menu._panel:child(self.name .. "list")
    if not self.menu._openlist and self.panel:inside(x,y) then
    	if button == Idstring("0") then
        	combo_list:show()
        	self.menu._openlist = self
        end
        local wheelup = (button == Idstring("mouse wheel up") and 1) or (button == Idstring("mouse wheel down") and 0) or -1
        if wheelup ~= -1 then
            if not self.menu._openlist then
                if ((self.value - 1) ~= 0) and ((self.value + 1) < (#self.items + 1))  then
                    self:SetValue(self.value + ((wheelup == 1) and -1 or 1))
                    if self.callback then
                    	self.callback(self.menu, self)
                    end
                end
            end
        end        
    elseif self.menu._openlist == self and combo_list:inside(x,y) then
		 for k, v in pairs(self.items) do
            if combo_list:child("item"..k):inside(x,y) then
                self:SetValue(k)
                combo_list:hide()
                self.menu._openlist = nil               
            end
        end
    else
       	self.menu._panel:child(self.menu._openlist.name .. "list"):hide()
       	self.menu._openlist = nil    	
    end 	
    self.super.mouse_pressed(self, o, button, x, y)
end

function ComboBox:key_press( o, k )
 	local combo_list = self.menu._panel:child(self.name .. "list")
	 if not self.menu._openlist then
	 	combo_list:show()
	 	self.menu._openlist = self
	 else
       	self.menu._panel:child(self.menu._openlist.name .. "list"):hide()
       	self.menu._openlist = nil    
	 end
end 

function ComboBox:mouse_moved(o, x, y )
	self.super.mouse_moved(self, o, x, y)
  	if self.menu._openlist == self then
  	 	for k, v in pairs(self.items) do
      	 	local combo_list = self.menu._panel:child(self.name .. "list") 
      	 	combo_list:child("bg"..k):set_color(combo_list:child("bg"..k):inside(x,y) and Color(0, 0.5, 1) or Color.white)
  	 	end
  	end
end
