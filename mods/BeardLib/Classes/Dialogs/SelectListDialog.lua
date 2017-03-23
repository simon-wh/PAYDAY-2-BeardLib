SelectListDialog = SelectListDialog or class(ListDialog) 
function SelectListDialog:MakeListItems()
    self._list_menu:ClearItems("temp2")  
    local function ShowItem(t) 
        if self._filter == "" or (self._params.case_sensitive and string.match(t, self._filter) or not self._params.case_sensitive and string.match(t:lower(), self._filter:lower())) then
            if not self._params.limit or #self._list_menu._items <= 250 then
                return true
            end
        end
        return false
    end
    for _,v in pairs(self._params.selected_list) do
        local t = type(v) == "table" and v.name or v
        if ShowItem(t) then
            self:Toggle(t, true, v)
        end
    end
    for _,v in pairs(self._params.list) do
        local t = type(v) == "table" and v.name or v
        if ShowItem(t) and not self._list_menu:GetItem(t) then
            self:Toggle(t, false, v)
        end
    end    
    self._list_menu:AlignItems()
end

function SelectListDialog:Toggle(name, selected, value)
    self._list_menu:Toggle({
        name = name,
        text = name,
        value = selected,
        callback = function(menu, item)
            if item:Value() == true then
                if not table.contains(self._params.selected_list, value) then
                    table.insert(self._params.selected_list, value)
                end
            else
                table.delete(self._params.selected_list, value)
            end
            if self._params.callback then
                self._params.callback(self._params.selected_list)
            end
        end, 
        label = "temp2"
    })
end

function SelectListDialog:hide()
    managers.menu:post_event("prompt_exit")
    self._dialog:disable()
    self._menu:ClearItems()
    if self._params.callback then
        self._params.callback(self._params.selected_list)
    end
   	managers.menu._controller:remove_trigger(self._trigger)     
   	BeardLib.DialogOpened = nil
end