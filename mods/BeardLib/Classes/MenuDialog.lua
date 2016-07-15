MenuDialog = MenuDialog or class()
function MenuDialog:init()
    self._dialog = MenuUI:new({
        layer = 999,
        text_color = Color.white,
        marker_color = Color("33476a"):with_alpha(0),
        marker_highlight_color = Color("33476a"),        
        position = "Center",
        create_items = callback(self, self, "create_items")
    })    
end

function MenuDialog:create_items(Menu)   
    self._menu = Menu:NewMenu({
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.6,
        name = "dialog",           
        visible = true,
    }) 
end

function MenuDialog:show( params )
    self._menu:ClearItems()
    self._dialog:enable()
    self._params = params
    params.w = params.w or 600
    params.h = params.h or 500
    self._menu:SetSize(params.w, params.h)
    self._menu:SetPositionByString("Center")
    self._menu:Divider({
        name = "title",
        text = params.title,
        size = 30,
    })
    for k, item in pairs(params.items) do
        if self._menu[item.type] then
            params.items[k] = self._menu[item.type](self._menu, item)
        end 
    end
    self._menu:Button({
        name = "yes_btn",
        text = params.yes or "Yes",
        callback = callback(self, self, "hide", true)
    })
    if params.no then
        self._menu:Button({
            name = "no_btn",
            text = params.no or "No",
            callback = callback(self, self, "hide", false)
        })
    end
end
function MenuDialog:hide(callback)
    self._dialog:disable()
    self._menu:ClearItems()
    if callback and self._params and self._params.callback then
        self._params.callback(self._params.items)
    end
end