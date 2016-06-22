Item = Item or class(Menu)

function Item:init( parent, params )
    self.type = params.type or "Button"
	  params.panel = params.parent_panel:panel({ 
		    name = params.name,
        w = params.w - params.padding,      
        h = params.items_size * 2,
        x = params.padding / 2,
      	y = 10, 
    }) 
    local Marker = params.panel:rect({
      	name = "bg", 
      	color =  params.normal_color,
      	halign="grow", 
      	valign="grow", 
        layer = -1 
    })
    params.title = params.panel:text({
  	    name = "title",
  	    text = params.text,
  	    vertical = "center",
        x = 4,
  	    align = params.align,
  	   	h = params.items_size,
  	    layer = 6,
  	    color = params.text_color or Color.black,
  	    font = "fonts/font_medium_mf",
  	    font_size = params.items_size
  	})
    params.div = params.panel:rect({
        color = params.color,
        visible = params.color ~= nil,
        w = 2,
    })
  	local _,_,w,h = params.title:text_rect()
  	params.title:set_h(h)
    params.title:set_y(0)
    if params.size_by_text then
        params.panel:set_size(w + params.items_size + 10,h)
        params.title:set_x(params.color and 2 or 0)
    end    
    if self.type == "Divider" then
        params.title:set_world_center_y(params.panel:world_center_y())   
    end
    params.option = params.option or params.name    
    table.merge(self, params)
    if params.group then
        if params.group.type == "ItemsGroup" then
            params.group:AddItem(self)
        else
            BeardLib:log(self.name .. " group is not a group item!")
        end
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
    if not self.enabled or self.type == "Divider" then
        return
    end
    if alive(self.panel) and self.panel:inside(x,y) and button == Idstring("0") then
        self:RunCallback()
        return true
    end
end

function Item:RunCallback(clbk)
    clbk = clbk or self.callback
    if clbk then
        clbk(self.parent, self)
    end  
end
function Item:SetText(text)
    self.panel:child("title"):set_text(text)
end

function Item:SetCallback( callback )
    self.callback = callback
end

function Item:mouse_moved( x, y, highlight )
    if not self.enabled or self.type == "Divider" then
        return
    end    
  	if not self.menu._openlist and not self.menu._slider_hold then
  	    if self.panel:inside(x, y) then
          if highlight ~= false then
  		        self.panel:child("bg"):set_color(self.highlight_color)
          end
  		    self.menu:SetHelp(self.help)
  		    self.highlight = true
  		    self.menu._highlighted = self
  	    else
  	      self.panel:child("bg"):set_color(self.normal_color)
          self.highlight = false       
  		end	
  		self.menu._highlighted = self.menu._highlighted and (alive(self.menu._highlighted.panel) and self.menu._highlighted.panel:inside(x,y)) and self.menu._highlighted or nil
  	end
end

function Item:mouse_released( button, x, y )

end