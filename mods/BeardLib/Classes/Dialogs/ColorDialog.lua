ColorDialog = ColorDialog or class(MenuDialog)
ColorDialog.type_name = "ColorDialog"
ColorDialog._default_width = 420
function ColorDialog:init(params, menu)
    params = params or {}
    params = deep_clone(params)
    self.super.init(self, table.merge(params, {
        w = ColorDialog._default_width,
        offset = 8,
        auto_height = true,
        items_size = 20,
        auto_align = true
    }), menu)
end

function ColorDialog:Show(params)   
    if not self:basic_show(params) then
        return
    end
    params.color = params.color or Color.white
    self._color = params.color
    local preview = self._menu:Divider({
        name = "ColorPreview",
        text = "",
        items_size = 32,
        offset = 0,
        marker_color = params.color,
    })
    self._menu:TextBox({
        name = "Hex",
        text = "Hex:",
        value = "",
        lines = 1,
        position = "CenterLeft",
        marker_color = Color.transparent,
        marker_highlight_color = Color.transparent,
        callback = callback(self, self, "update_hex"),
        w = 100,
        items_size = 20,
        override_parent = preview
    })
    if params.create_items then
        params.create_items(self._menu)
    end
    for _, ctrl in pairs({"Red", "Green", "Blue"}) do
        self._menu:Slider({
            name = ctrl,
            text = ctrl,
            min = 0,
            max = 255,
            callback = callback(self, self, "update_color"),
            value = params.color[ctrl:lower()] * 255
        })   
    end
    self._menu:Slider({
        name = "Alpha",
        text = "Alpha",
        min = 0,
        max = 100,
        callback = callback(self, self, "update_color"),
        value = params.color.alpha * 100
    })
    self._menu:Button({
        name = "Apply",
        text = "Apply",
        callback = callback(self, self, "hide", true),  
        label = "temp"
    })
    self._menu:Button({
        name = "Close",
        text = "Cancel",
        callback = callback(self, self, "hide"),  
        label = "temp"
    })
    self:update_color(self._menu)
    self:show_dialog()
end

--http://stackoverflow.com/questions/3942878/how-to-decide-font-color-in-white-or-black-depending-on-background-color
function ColorDialog:update_hex_color()
    local item = self._menu:GetItem("Hex")
    local color = self._color:contrast()
    item.text_color = color
    item._textbox.text_color = color
    item._textbox.line_color = color
    item:DoHighlight(item.highlighted)
    item:SetVisible(self._color.a == 1)
end

function ColorDialog:update_hex(menu, item)
   self._color.color = Color(item:Value())
   menu:GetItem("Alpha"):SetValue(self._color.alpha * 100)
   menu:GetItem("Red"):SetValue(self._color.red * 255)
   menu:GetItem("Green"):SetValue(self._color.green * 255)
   menu:GetItem("Blue"):SetValue(self._color.blue * 255)
   menu:GetItem("ColorPreview"):Panel():child("bg"):set_color(self._color)
   self:update_hex_color()
end

function ColorDialog:update_color(menu)
    self._color = Color(menu:GetItem("Alpha"):Value() / 100, menu:GetItem("Red"):Value() / 255, menu:GetItem("Green"):Value() / 255, menu:GetItem("Blue"):Value() / 255)
    menu:GetItem("ColorPreview"):Panel():child("bg"):set_color(self._color)
    local Hex = menu:GetItem("Hex")
    Hex:SetValue(self._color:to_hex())
    self:update_hex_color()
end

function ColorDialog:run_callback(clbk)
    if clbk then
        clbk(self._color, self._menu)
    end
end