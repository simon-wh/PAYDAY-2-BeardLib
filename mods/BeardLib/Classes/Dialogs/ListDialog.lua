ListDialog = ListDialog or class(MenuDialog)
ListDialog.type_name = "ListDialog"
ListDialog._no_reshaping_menu = true
function ListDialog:init(params, menu)
    params = params or {}
    params = deep_clone(params)
    menu = menu or BeardLib.managers.dialog:Menu()
    self._list_menu = menu:Menu(table.merge({
        w = 900,
        h = params.h and params.h - 20 or 600,
        name = "List",
        items_size = 18,
        auto_align = false,
        position = params.position or "Center",
        visible = false,
    }, params))
    
    ListDialog.super.init(self, table.merge({
        h = 20,
        w = 900,
        items_size = 20,
        offset = 0,
        auto_height = false,
        align_method = "grid",
        auto_align = true
    }, params), menu)
    self._menus = {self._list_menu}
    self._menu:Panel():set_leftbottom(self._list_menu:Panel():left(), self._list_menu:Panel():top() - 1)
end

function ListDialog:_Show(params)
    if not self:basic_show(params) then
        return
    end
    self._filter = {}
    self._case_sensitive = params.case_sensitive
    self._limit = NotNil(params.limit, true)
    self._list = params.list

    self._menu:TextBox({
        name = "Search",
        w = self._menu.w - 152,
        control_slice = 1.25,
        text = "Search",
        callback = callback(self, self, "Search"),  
        label = "temp"
    })
    self._menu:Toggle({
        name = "CaseSensitive",
        w = 42,
        text = "Aa",
        value = self._case_sensitive,
        callback = function(menu, item)
            self._case_sensitive = item:Value()
            self:MakeListItems()
        end,  
        label = "temp"
    })    
    self._menu:Toggle({
        name = "Limit",
        w = 42,
        text = ">|",
        value = self._limit,
        callback = function(menu, item)
            self._limit = item:Value()
            self:MakeListItems()
        end,  
        label = "temp"
    })
    self._menu:Button({
        name = "Close",
        w = 68,
        text_align = "center",
        text = "Close",
        callback = callback(self, self, "hide"),  
        label = "temp"
    })
    self:MakeListItems(params)
end

function ListDialog:ItemsCount()
    return #self._list_menu._all_items
end

function ListDialog:SearchCheck(t)
    if #self._filter == 0 then
        return true
    end
    local match
    for _, s in pairs(self._filter) do
        match = (self._case_sensitive and string.match(t, s) or not self._case_sensitive and string.match(t:lower(), s:lower())) 
    end
    return match
end

function ListDialog:MakeListItems(params)
    self._list_menu:ClearItems("temp2")  
    local case = self._case_sensitive
    local limit = self._limit
    local groups = {}
    for _,v in pairs(self._list) do
        local t = type(v) == "table" and v.name or v
        if self:SearchCheck(t) then
            if not limit or self:ItemsCount() <= 250 then
                local menu = self._list_menu
                if type(v) == "table" and v.create_group then 
                    menu = groups[v.create_group] or self._list_menu:Group({
                        auto_align = false,
                        name = v.create_group,
                        text = v.create_group,
                        label = "temp2"
                    }) 
                    groups[v.create_group] = menu
                end
                menu:Button(table.merge(type(v) == "table" and v or {}, {
                    name = t,
                    text = t,
                    callback = function(menu, item)
                        if self._callback then
                            self._callback(v)
                        end
                    end, 
                    label = "temp2"
                }))
            end
        end
    end
    self:show_dialog()
    self._list_menu:AlignItems(true)
end

function ListDialog:Search(menu, item)
    self._filter = {}
    for _, s in pairs(string.split(item:Value(), ",")) do
        table.insert(self._filter, s)
    end
    self:MakeListItems()
end

function ListDialog:run_callback(clbk)
end

function ListDialog:should_close()
    return self._menu:ShouldClose() or self._list_menu:ShouldClose()
end

function ListDialog:hide(yes)
    self._list_menu:SetVisible(false)
    return ListDialog.super.hide(self, yes)
end