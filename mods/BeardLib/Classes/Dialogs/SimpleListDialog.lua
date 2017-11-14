SimpleListDialog = SimpleListDialog or class(ListDialog)
SimpleListDialog.type_name = "SimpleListDialog"
function SimpleListDialog:init(params, menu)
    if self.type_name == SimpleListDialog.type_name then
        params = clone(params or {})
    end

    params.w = 400
    params.h = 500
    params.main_h = 40
    
    SimpleListDialog.super.init(self, params, menu)
end

function SimpleListDialog:_Show(params)
    if not self:basic_show(params) then
        return
    end

    params = clone(params or {})
    
    if self.type_name == SimpleSelectListDialog.type_name then
        self._single_select = params.single_select or false
        self._allow_multi_insert = params.allow_multi_insert or false
        self._selected_list = params.selected_list or {}
    end

    self._filter = {}
    self._case_sensitive = NotNil(params.case_sensitive, false)
    self._limit = NotNil(params.limit, true)
    self._list = params.list
    local bs = self._menu.h + 4
    local tw = self._menu.w - (bs * 2)
    
    self._menu:TextBox({
        name = "Search",
        w = tw,
        control_slice = 0.98,
        text = false,
        callback = callback(self, self, "Search"),  
        label = "temp"
    })

    local close = self._menu:ImageButton({
        name = "Close",
        w = bs,
        h = self._menu.h,
        icon_w = 14,
        icon_h = 14,
        position = "CenterRight",
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {84, 89, 36, 36},
        callback = callback(self, self, "hide", false),  
        label = "temp"
    })

    self._menu:ImageButton({
        name = "Apply",
        w = bs,
        h = self._menu.h,
        icon_w = 14,
        icon_h = 14,
        position = function(item)
            item:Panel():set_righttop(close:Panel():position())
        end,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {82, 50, 36, 36},
        callback = callback(self, self, "hide", true),  
        label = "temp"
    })
    if params.sort ~= false then
        table.sort(params.list, function(a, b) 
            return (type(a) == "table" and a.name or a) < (type(b) == "table" and b.name or b) 
        end)
    end
    self:MakeListItems(params)
end