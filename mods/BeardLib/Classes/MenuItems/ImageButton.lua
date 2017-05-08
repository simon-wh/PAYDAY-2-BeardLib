ImageButton = ImageButton or class(Item)
ImageButton.type_name = "ImageButton"
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
    self.img = self.panel:bitmap({
        name = "img", 
        texture = self.texture,
        texture_rect = self.texture_rect,
        color = self.img_color,
        alpha = self.img_alpha,
        w = self.icon_w or self.w - 4,
        h = self.icon_h or self.h - 4,
        halign = "center", 
        valign = "center",
        layer = 1
    })
    self.img:set_world_center(self.panel:world_center())
    self:MakeBorder()
end

function ImageButton:SetEnabled(enabled)
    self.enabled = enabled
    self.img:set_alpha(enabled and 1 or 0.5)
end

function ImageButton:SetImage(texture, texture_rect)
    self.img:set_image(texture, texture_rect)
end