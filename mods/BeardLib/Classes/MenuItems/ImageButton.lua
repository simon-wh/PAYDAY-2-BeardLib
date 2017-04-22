ImageButton = ImageButton or class(Item)
ImageButton.type_name = "ImageButton"
function ImageButton:Init()
    self.w = self.w or self.items_size
    self.h = self.h or self.items_size
    self.super.Init(self)
end

function ImageButton:InitBasicItem()
    self.panel = self.parent_panel:panel({ 
        name = self.name,
        w = self.w,
        h = self.h,
    })
    self.bg = self.panel:rect({
        name = "bg", 
        color = self.marker_color,
        alpha = self.marker_alpha,
        halign = "grow",
        valign = "grow",
        layer = 0
    })
    self.icon = self.panel:bitmap({
        name = "icon", 
        texture = self.texture,
        texture_rect = self.texture_rect,
        color = self.icon_color,
        alpha = self.icon_alpha,
        w = self.icon_w or self.w - 4,
        h = self.icon_h or self.h - 4,
        halign = "center", 
        valign = "center",
        layer = 1
    })
    self.icon:set_world_center(self.panel:world_center())
    self.div = self.panel:rect({
        color = self.color,
        visible = self.color ~= nil,
        w = 2,
    })
end

function ImageButton:SetEnabled(enabled)
    self.enabled = enabled
    self.icon:set_alpha(enabled and 1 or 0.5)
end

function ImageButton:SetImage(texture, texture_rect)
    self.icon:set_image(texture, texture_rect)
end