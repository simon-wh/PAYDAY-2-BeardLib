BeardLib.Items.ImageButton = BeardLib.Items.ImageButton or class(BeardLib.Items.Item)
local ImageButton = BeardLib.Items.ImageButton 
ImageButton.type_name = "ImageButton"
function ImageButton:InitBasicItem()
    self.h = self.h or self.w
    self.panel = self.parent_panel:panel({ 
        name = self.name,
        w = self.w,
        h = self.h,
	})
    self:InitBGs()
    self.img = self.panel:bitmap({
        name = "img", 
        texture = self.texture,
        texture_rect = self.texture_rect,
        color = self.img_color or self.foreground,
        w = self.icon_w or self.w - (self.img_offset[1] * 2),
        h = self.icon_h or self.h - (self.img_offset[2] * 2),
        halign = "center", 
        valign = "center",
        layer = 5
    })
    self.img:set_world_center(self.panel:world_center())
    self:MakeBorder()
end

function ImageButton:WorkParams(params)
    ImageButton.super.WorkParams(self, params)
    self.img_offset = self.img_offset and self:ConvertOffset(self.img_offset, true) or {0,0}
    self.img_offset[1] = self.img_offset_x or self.img_offset[1]
	self.img_offset[2] = self.img_offset_y or self.img_offset[2]
	self.button_type = true
end

function ImageButton:DoHighlight(highlight)
    ImageButton.super.DoHighlight(self, highlight)
    if self.highlight_image and self.img then
        if self.animate_colors then
            play_color(self.img, self:GetForeground(highlight))
        else
            self.img:set_color(self:GetForeground(highlight))            
        end
    end
end

function ImageButton:SetImage(texture, texture_rect)
    self.img:set_image(texture, texture_rect)
end