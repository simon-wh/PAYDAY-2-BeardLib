Item = Item or class(Menu)

function Item:init( parent, params )
	params.panel = parent.items_panel:panel({ 
		name = params.name,
      	y = 10, 
      	x = 10,
      	w = parent.items_panel:w() - 10,
      	h = 24,
      	layer = 21,
    }) 
    local Marker = params.panel:rect({
      	name = "bg", 
      	color = Color.white:with_alpha(0),
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
 	if params.color then
 		local color = params.panel:rect({
 			color = params.color,
 			w = 2,
 		})
 	end  	
	local _,_,w,h = ItemText:text_rect()
	ItemText:set_w(w)
    params.option = params.option or params.name    
    table.merge(self, params)
    self.parent = parent
    self.menu = parent.menu
end

function Item:SetValue(value)
	self.value = value
end

function Item:key_press( o, k )

end
function Item:mouse_pressed( o, button, x, y )
    if self.callback and self.panel:inside(x,y) and button == Idstring("0") then
        self.callback(self.menu, self)
    end
end

function Item:mouse_moved( o, x, y )
	if not self.menu._openlist and not self.menu._slider_hold then
	    if self.panel:inside(x, y) then
		    self.panel:child("bg"):set_color(Color(0, 0.5, 1))
		    self.menu:set_help(self.help)
		    self.highlight = true
		    self.menu._highlighted = self
	    else
	    	self.panel:child("bg"):set_color(Color.white:with_alpha(0))
	        self.highlight = false       
		end	
		self.menu._highlighted = self.menu._highlighted and (alive(self.menu._highlighted.panel) and self.menu._highlighted.panel:inside(x,y)) and self.menu._highlighted or nil
	end
end
