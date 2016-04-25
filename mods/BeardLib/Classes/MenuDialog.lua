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
    self._dialog_menu = Menu:NewMenu({
        name = "dialog",           
    }) 
end

function MenuDialog:show( params )
    self._dialog_menu:ClearItems()
    self._dialog:enable()
    self._params = params
    self._dialog_menu:Divider({
        name = "title",
        text = params.title,
        size = 30,
    })
    for k, item in pairs(params.items) do
        if self._dialog_menu[item.type] then
            params.items[k] = self._dialog_menu[item.type](self._dialog_menu, item)
        end 
    end
    self._dialog_menu:Button({
        name = "yes_btn",
        text = params.yes or "Yes",
        callback = callback(self, self, "hide", true)
    })
    if params.no then
        self._dialog_menu:Button({
            name = "no_btn",
            text = params.no or "No",
            callback = callback(self, self, "hide", false)
        })
    end
end
function MenuDialog:hide(callback)
    self._dialog:disable()
    self._dialog_menu:ClearItems()
    if callback and self._params and self._params.callback then
        self._params.callback(self._params.items)
    end
end