MenuDialog = MenuDialog or class()
function MenuDialog:init(params, existing_menu)
    if exisiting_menu then
        self._dialog = existing_menu
        self:create_items({}, self._dialog)
        return
    end    
    params = params or {}
    table.merge(params, {
        layer = 100,
        marker_color = params.marker_color or Color.white:with_alpha(0),
        marker_highlight_color = params.marker_highlight_color or Color("4385ef"),
        create_items = callback(self, self, "create_items", params)        
    })
    self._dialog = MenuUI:new(params)    
end

function MenuDialog:create_items(params, menu)   
    params.name = "dialog"
    params.position = "Center"
    params.scrollbar = params.scrollbar or false
    params.background_color = params.background_color or Color(0.2, 0.2, 0.2)
    params.background_alpha = params.background_alpha or 0.6
    params.override_size_limit = true
    params.visible = true
    self._menu = menu:NewMenu(params) 
end

function MenuDialog:show(params)
    if BeardLib.DialogOpened == self then
        return
    end
    params = params or {}
    self._menu:ClearItems("default")
    self._dialog:enable()
    self._params = params
    params.w = params.w or 600
    params.h = params.h or 500
    self._menu.text_color = params.text_color or Color.white
    self._menu.text_highlight_color = params.text_highlight_color or Color.white
    self._menu.marker_color = params.marker_color or Color("33476a"):with_alpha(0)
    self._menu.marker_highlight_color = params.marker_highlight_color or Color("33476a") 
    self._menu.background_alpha = params.background_alpha or 0.6
    self._menu:SetSize(params.w, params.h)
    self._menu.items_size = params.items_size or 20
    if params.title then
        self._menu:Divider({
            name = "title",
            color = Color.white,
            text = params.title,
            label = "default",
            h = 30,
        })
    end
    if params.items then
        for k, item in pairs(params.items) do
            if self._menu[item.type] then
                item.label = "default"
                params.items[k] = self._menu[item.type](self._menu, item)
            end 
        end
    end
    self._menu:Button({
        name = "yes_btn",
        text = params.yes or (params.no and "Yes") or "Close",
        label = "default",
        callback = callback(self, self, "hide", true)
    })
    if params.no then
        self._menu:Button({
            name = "no_btn",
            text = params.no,
            label = "default",
            callback = callback(self, self, "hide")
        })
    end
    self._trigger = managers.menu._controller:add_trigger(Idstring("esc"), callback(self, self, "hide"))    
    BeardLib.DialogOpened = self
end
function MenuDialog:hide(yes)
    managers.menu:post_event("prompt_exit")
    self._dialog:disable()
    self._menu:ClearItems()
    local clbk = self._params and (yes == true and self._params.callback or self._params.no_callback)
    if clbk then
        clbk(self._params.items)
    end
   managers.menu._controller:remove_trigger(self._trigger)     
   BeardLib.DialogOpened = nil
end