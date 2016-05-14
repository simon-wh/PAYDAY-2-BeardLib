MenuDialog = MenuDialog or class()
function MenuDialog:init()
    self._dialog = MenuUI:new({
        w = 500,
        h = 160,
        layer = 999,
        position = "center",
        tabs = false,
        create_items = callback(self, self, "create_items")
    })    
end

function MenuDialog:create_items(Menu)   
    self._menu = Menu:NewMenu({
        name = "dialog",           
    }) 
end

function MenuDialog:show( params )
    self._menu:ClearItems()
    self._dialog:enable()
    self._params = params
    if params.w or params.h then
        params.w = params.w or 500
        params.h = params.h or 160
        self._dialog:SetSize(params.w, params.h)
    end
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