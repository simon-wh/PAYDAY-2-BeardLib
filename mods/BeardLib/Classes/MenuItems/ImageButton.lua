ImageButton = ImageButton or class(Item)

function ImageButton:init(parent, params)
    self.type_name = "ImageButton"
    params.w = params.w or params.items_size
    params.h = params.h or params.items_size
    params.panel = params.parent_panel:panel({ 
        name = params.name,
        w = params.w,
        h = params.h,
    }) 
    params.bg = params.panel:rect({
        name = "bg", 
        color = params.marker_color,
        alpha = params.marker_alpha,
        halign="grow", 
        valign="grow", 
        layer = -1 
    })    
    params.icon = params.panel:bitmap({
        name = "icon", 
        texture = params.texture,
        texture_rect = params.texture_rect,
        color = params.icon_color,
        alpha = params.icon_alpha,
        w = params.icon_w or params.w - 4,
        h = params.icon_h or params.h - 4,
        halign="center", 
        valign="center",         
        layer = 1
    })
    params.icon:set_world_center(params.panel:world_center())
    params.div = params.panel:rect({
        color = params.color,
        visible = params.color ~= nil,
        w = 2,
    })
    params.option = params.option or params.name    
    table.merge(self, params)
    self.parent = parent
    self.menu = parent.menu    
    self._items = {}
    if params.group then
      if params.group.type_name == "group" then
          params.group:AddItem(self)
      else
          BeardLib:log(self.name .. " group is not a groupitem!")
      end
    end
end

function ImageButton:SetEnabled(enabled)
    self.enabled = enabled
    self.icon:set_alpha(enabled and 1 or 0.5)
end

function ImageButton:SetImage(texture, texture_rect)
    self.panel:child("icon"):set_image(texture, texture_rect)
end
