ColorDialog = ColorDialog or class(MenuDialog)
function ColorDialog:show(...)
    self:Show(...)
end

function ColorDialog:create_items(params, menu)  
    params.position = params.position or "Center"
    params.background_color = params.background_color or Color(0.2, 0.2, 0.2)
    params.background_alpha = params.background_alpha or 0.6
    params.override_size_limit = true
    params.visible = true
    params.w = 400
    params.offset = 8
    params.automatic_height = true
    params.items_size = 20
    params.auto_align = true
    ColorDialog.super.create_items(self, params, menu) 
end

function ColorDialog:Show(params)   
    params = params or self._params or {}
    self._filter = ""
    self._params = params
    self._params.color = self._params.color or Color.white
    self._menu:ClearItems()
    local preview = self._menu:Divider({
        name = "ColorPreview",
        offset = 0,
        marker_color = self._params.color,
    })
    for _, ctrl in pairs({"Red", "Green", "Blue"}) do
        self._menu:Slider({
            name = ctrl,
            text = ctrl,
            min = 0,
            max = 255,
            callback = callback(self, self, "update_color"),
            value = self._params.color[ctrl:lower()] * 255
        })   
    end
    self._menu:Slider({
        name = "Alpha",
        text = "Alpha",
        min = 0,
        max = 100,
        callback = callback(self, self, "update_color"),
        value = self._params.color.alpha * 100
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
    if BeardLib.DialogOpened == self then
        return
    end
    self._dialog:enable()    
    self._trigger = managers.menu._controller:add_trigger(Idstring("esc"), callback(self, self, "hide"))    
    BeardLib.DialogOpened = self
end

function ColorDialog:update_color(menu)
    self._params.color = Color(menu:GetItem("Alpha"):Value() / 100, menu:GetItem("Red"):Value() / 255, menu:GetItem("Green"):Value() / 255, menu:GetItem("Blue"):Value() / 255)
    menu:GetItem("ColorPreview"):Panel():child("bg"):set_color(self._params.color)
end

function ColorDialog:hide(yes)
    managers.menu:post_event("prompt_exit")
    self._dialog:disable()
    self._menu:ClearItems()
    local clbk = self._params and (yes == true and self._params.callback or self._params.no_callback)
    if clbk then
        clbk(self._params.color)
    end
   managers.menu._controller:remove_trigger(self._trigger)     
   BeardLib.DialogOpened = nil
end