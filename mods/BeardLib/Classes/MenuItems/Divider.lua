Divider = Divider or class(Menu)

function Divider:init( parent, params )
    self.type = "Divider"
    local panel = params.group and params.group.panel or parent.items_panel
	params.panel = panel:panel({ 
		name = params.name,
        y = 10, 
        x = params.group and 4 or 10,
        w = parent.items_panel:w() - (params.group and 15 or 10),
      	h = params.size or 30,
      	layer = 21,
    }) 
    params.title = params.panel:text({
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
	params.div = params.panel:rect({
		h = 2,
        x = 4,
        visible = params.color ~= false or params.text ~= nil,
		color = params.color or params.text_color or Color.black
	})    
    table.merge(self, params)
	local _,_,w,h = self.title:text_rect() 
    self.div:set_top(self.title:bottom())
	self.div:set_w(w)
    self.parent = parent
    self.menu = parent.menu
    if params.group then
        params.group:AddItem(self)
    end    
end

function Divider:SetValue(value)

end
function Divider:SetEnabled(enalbed)

end
function Divider:Index()
    return self.parent:GetIndex(self.name)
end

function Divider:SetText(text)
    self.title:set_text(text)
end

function Divider:SetColor(color)
    self.div:set_color(color or Color.white)
end

function Divider:key_press( o, k )

end
function Divider:mouse_pressed( button, x, y )

end
function Divider:mouse_moved( x, y )

end
function Divider:mouse_released( button, x, y )

end
