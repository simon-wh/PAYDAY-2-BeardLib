Item = Item or class(Menu)

function Item:init( parent, params )
    self.type = "button"
    if params.enabled == nil then params.enabled = true end
    params.text_color = params.text_color or parent.text_color
    params.text_color = params.text_color or parent.text_color
    params.items_size = parent.items_size
    local panel = params.group and params.group.panel or parent.items_panel
	  params.panel = panel:panel({
		    name = params.name,
      	y = 10,
      	x = params.group and 4 or 10,
      	w = parent.items_panel:w() - (params.group and 15 or 10),
      	h = params.items_size,
      	layer = 20,
    })
    local Marker = params.panel:rect({
      	name = "bg",
      	color = Color.white:with_alpha(0),
      	h = self.items_size,
      	halign="grow",
      	valign="grow",
        layer = -1
    })
    params.title = params.panel:text({
	    name = "title",
	    text = params.text,
	    vertical = "center",
	    align = "left",
	    x = 4,
	   	h = self.items_size,
	    layer = 6,
	    color = params.text_color or Color.black,
	    font = "fonts/font_medium_mf",
	    font_size = 16
  	})
   	if params.color then
   		local color = params.panel:rect({
   			color = params.color,
   			w = 2,
   		})
   	end  	
  	local _,_,w,h = params.title:text_rect()
  	params.title:set_w(w)
    params.option = params.option or params.name    
    table.merge(self, params)
    self.parent = parent
    self.menu = parent.menu    
    if params.group then
        params.group:AddItem(self)
    end
end

function Item:SetValue(value)
    self.value = value
end
function Item:SetEnabled(enabled)
	self.enabled = enabled
end
function Item:Index()
    return self.parent:GetIndex(self.name)
end
function Item:key_press( o, k )

end
function Item:mouse_pressed( button, x, y )
    if not self.enabled then
        return
    end
    if self.callback and alive(self.panel) and self.panel:inside(x,y) and button == Idstring("0") then
        self.callback(self.parent, self)
        return true
    end
end

function Item:SetText(text)
    self.panel:child("title"):set_text(text)
end

function Item:SetCallback( callback )
    self.callback = callback
end

function Item:mouse_moved( x, y, highlight )
    if not self.enabled then
        return
    end    
  	if not self.menu._openlist and not self.menu._slider_hold then
  	    if self.panel:inside(x, y) then
          if highlight ~= false then
  		        self.panel:child("bg"):set_color(self.parent.highlight_color or Color.white)
          end
  		    self.menu:SetHelp(self.help)
  		    self.highlight = true
  		    self.menu._highlighted = self
  	    else
  	      self.panel:child("bg"):set_color(Color.white:with_alpha(0))
          self.highlight = false       
  		end	
  		self.menu._highlighted = self.menu._highlighted and (alive(self.menu._highlighted.panel) and self.menu._highlighted.panel:inside(x,y)) and self.menu._highlighted or nil
  	end
end

function Item:mouse_released( button, x, y )

end