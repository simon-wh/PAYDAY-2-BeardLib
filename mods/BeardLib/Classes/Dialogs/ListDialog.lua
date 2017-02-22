ListDialog = ListDialog or class(MenuDialog)
function ListDialog:show(...)
    self:Show(...)
end

function ListDialog:create_items(params, menu)  
    params.w = 900
    params.h = 600
    params.name = "List"
    params.auto_align = false
    params.position = "CenterLeft"
    params.background_color = params.background_color or Color(0.2, 0.2, 0.2)
    params.background_alpha = params.background_alpha or 0.6
    params.override_size_limit = true
    params.visible = true
    self._list_menu = menu:NewMenu(params) 
    self._list_menu:Panel():move(200)
    params.w = 900
    params.h = 20
    params.row_max = 1
    params.auto_align = true
    ListDialog.super.create_items(self, params, menu) 
    self._menu:Panel():set_leftbottom(self._list_menu:Panel():left(), self._list_menu:Panel():top() - 1)
end

function ListDialog:Show(params)   
    params = params or self._params or {}
    self._filter = ""
    self._params = params
    self._params.limit = true
    self._menu:ClearItems()
    self._list_menu:ClearItems()  
    self._menu:TextBox({
        name = "Search",
        w = 758,
        control_slice = 1.25,
        text = "Search",
        callback = callback(self, self, "Search"),  
        label = "temp"
    })
    self._menu:Toggle({
        name = "CaseSensitive",
        w = 32,
        text = "Aa",
        value = self._params.case_sensitive,
        callback = function(menu, item)
            self._params.case_sensitive = item:Value()
            self:MakeListItems()
        end,  
        label = "temp"
    })    
    self._menu:Toggle({
        name = "Limit",
        w = 42,
        text = ">|",
        value = self._params.limit,
        callback = function(menu, item)
            self._params.limit = item:Value()
            self:MakeListItems()
        end,  
        label = "temp"
    })
    self._menu:Button({
        name = "Close",
        w = 68,
        text = "Close",
        callback = callback(self, self, "hide"),  
        label = "temp"
    })
    self:MakeListItems()
    if BeardLib.DialogOpened == self then
        return
    end
    self._dialog:enable()    
    self._trigger = managers.menu._controller:add_trigger(Idstring("esc"), callback(self, self, "hide"))    
    BeardLib.DialogOpened = self
end

function ListDialog:MakeListItems()
    self._list_menu:ClearItems("temp2")  
    local case = self._params.case_sensitive
    local limit = self._params.limit
    for _,v in pairs(self._params.list) do
        local t = type(v) == "table" and v.name or v
        if self._filter == "" or (case and string.match(t, self._filter) or not case and string.match(t:lower(), self._filter:lower())) then
            if not limit or #self._list_menu._items <= 250 then
                if type(v) == "table" and v.create_group then 
                    v.group = self._list_menu:GetItem(v.create_group) or self._list_menu:ItemsGroup({
                        name = v.create_group,
                        text = v.create_group,
                        label = "temp2"
                    })             
                end
                self._list_menu:Button(table.merge(type(v) == "table" and v or {}, {
                    name = t,
                    text = t,
                    callback = function(menu, item)
                        if self._params.callback then
                            self._params.callback(v)
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

function ListDialog:hide()
    managers.menu:post_event("prompt_exit")
    self._dialog:disable()
    self._menu:ClearItems()
   managers.menu._controller:remove_trigger(self._trigger)     
   BeardLib.DialogOpened = nil
end