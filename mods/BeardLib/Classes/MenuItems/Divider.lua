Divider = Divider or class(Menu)

function Divider:init( parent, params )
	params.panel = parent.items_panel:panel({ 
		name = params.name,
      	y = 10, 
      	x = 10,
      	w = parent.items_panel:w() - 10,
      	h = params.size or 30,
      	layer = 21,
    }) 
    local DividerText = params.panel:text({
	    name = "title",
	    text = params.text,
	    vertical = "center",
	    align = "left",
	    x = 4,
	   	h = 24,
	    layer = 6,
	    color = params.text_color or Color.black,
	    font = parent.menu.font or "fonts/font_medium_mf",
	    font_size = 16
	})	
	local Divider = params.panel:rect({
		h = 2,
        visible = params.text ~= nil,
		color = params.color or params.text_color or Color.black
	})
	local _,_,w,h = DividerText:text_rect()
	DividerText:set_w(w)
	Divider:set_top(DividerText:bottom())
    table.merge(self, params)
    self.parent = parent
    self.menu = parent.menu
end

function Divider:SetValue(value)

end

function Divider:SetText(text)
    self.panel:child("title"):set_text(text)
end

function Divider:key_press( o, k )

end
function Divider:mouse_pressed( button, x, y )

end

function Divider:mouse_moved( x, y )

end
function Divider:mouse_released( button, x, y )

end
