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
        color = self.img_color or self.text_color,
        alpha = self.img_alpha,
        w = self.icon_w or self.w - 4,
        h = self.icon_h or self.h - 4,
        halign = "center", 
        valign = "center",
        layer = 5
    })
    self.img:set_world_center(self.panel:world_center())
    self:MakeBorder()
end

function ImageButton:DoHighlight(highlight)
    ImageButton.super.DoHighlight(self, highlight)
    self.img:set_color(highlight and (self.img_highlight_color or self.text_highlight_color) or (self.img_color or self.text_color))
end

function ImageButton:SetImage(texture, texture_rect)
    self.img:set_image(texture, texture_rect)
end