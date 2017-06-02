ListDialog = ListDialog or class(MenuDialog)
ListDialog.type_name = "ListDialog"
function ListDialog:init(params, menu)
    params = params or {}
    params = deep_clone(params)
    menu = menu or BeardLib.managers.dialog:Menu()
    self._list_menu = menu:Menu(table.merge({
        w = 900,
        h = params.h and params.h - 20 or 600,
        name = "List",
        auto_align = false,
        position = params.position or "Center",
        layer = BeardLib.managers.dialog:GetNewIndex(),
        visible = false,
    }, params))
    
    ListDialog.super.init(self, table.merge({
        h = 20,
        w = 900,
        items_size = 20,
        offset = 0,
        align_method = "grid",
        auto_align = true    
    }, params), menu) 
    self._menu:Panel():set_leftbottom(self._list_menu:Panel():left(), self._list_menu:Panel():top() - 1)
end

function ListDialog:Show(params)
    if not self:basic_show(params) then
        return
    end
    self._filter = ""
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
    self:MakeListItems()
end

function ListDialog:MakeListItems()
    self._list_menu:ClearItems("temp2")  
    local case = self._case_sensitive
    local limit = self._limit
    for _,v in pairs(self._list) do
        local t = type(v) == "table" and v.name or v
        if self._filter == "" or (case and string.match(t, self._filter) or not case and string.match(t:lower(), self._filter:lower())) then
            if not limit or #self._list_menu._all_items <= 250 then
                local menu = self._list_menu
                if type(v) == "table" and v.create_group then 
                    menu = self._list_menu:GetItem(v.create_group) or self._list_menu:ItemsGroup({
                        name = v.create_group,
                        text = v.create_group,
                        label = "temp2"
                    })             
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
    self._list_menu:AlignItems()
end

function ListDialog:Search(menu, item)
    self._filter = item.value
    self:MakeListItems()
end

function ListDialog:basic_show(params)
    self._list_menu:ClearItems()
    self._list_menu:SetVisible(true)
    return ListDialog.super.basic_show(self, params)
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