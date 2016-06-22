ImageButton = ImageButton or class(Menu)

function ImageButton:init( parent, params )
    self.type = "ImageButton"
    params.panel = params.parent_panel:panel({ 
        name = params.name,
        w = params.w,
        h = params.h,
        x = params.padding / 2,
        y = 10,
    }) 
    local Marker = params.panel:rect({
        name = "bg", 
        color = params.normal_color,
        halign="grow", 
        valign="grow", 
        layer = -1 
    })    
    local Icon = params.panel:bitmap({
        name = "icon", 
        texture = params.texture,
        texture_rect = params.texture_rect,
        color = params.icon_color,
        alpha = params.icon_alpha,
        w = params.w - 4,
        h = params.h - 4,
        halign="center", 
        valign="center",         
        layer = 1
    })
    Icon:set_world_center(params.panel:world_center())
    params.div = params.panel:rect({
        color = params.color,
        visible = params.color ~= nil,
        w = 2,
    })
    params.option = params.option or params.name    
    table.merge(self, params)
    self.parent = parent
    self.menu = parent.menu    
    if params.group then
      if params.group.type == "group" then
          params.group:AddItem(self)
      else
          BeardLib:log(self.name .. " group is not a groupitem!")
      end
    end
end

function ImageButton:SetValue(value)
    self.value = value
end
function ImageButton:SetEnabled(enabled)
    self.enabled = enabled
end
function ImageButton:Index()
    return self.parent:GetIndex(self.name)
end
function ImageButton:key_press( o, k )

end
function ImageButton:mouse_pressed( button, x, y )
    if not self.enabled then
        return
    end
    if self.callback and alive(self.panel) and self.panel:inside(x,y) and button == Idstring("0") then
        self.callback(self.parent, self)
        return true
    end
end

function ImageButton:RunCallback()
    if self.callback then
        self.callback(self.menu, self)
    end  
end
function ImageButton:SetImage(texture, texture_rect)
    self.panel:child("icon"):set_image(texture, texture_rect)
end

function ImageButton:SetCallback( callback )
    self.callback = callback
end

function ImageButton:mouse_moved( x, y, highlight )
    if not self.enabled then
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

function ImageButton:mouse_released( button, x, y )

end