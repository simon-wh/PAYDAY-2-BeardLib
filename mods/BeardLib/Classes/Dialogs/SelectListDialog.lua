SelectListDialog = SelectListDialog or class(ListDialog) 
function SelectListDialog:MakeListItems()
    self._list_menu:ClearItems("temp2")  
    local case = self._params.case_sensitive
    local limit = self._params.limit
    for _,v in pairs(self._params.list) do
        local t = type(v) == "table" and v.name or v
        if self._filter == "" or (case and string.match(t, self._filter) or not case and string.match(t:lower(), self._filter:lower())) then
            if not limit or #self._list_menu._items <= 250 then 
            	local selected = table.contains(self._params.selected_list, v)
                self._list_menu:Toggle({
                    name = t,
                    text = t,
                    value = selected,
                    index = selected and 1,
                    callback = function(menu, item)
                    	if item:Value() == true then
                            if not table.contains(self._params.selected_list, v) then
                                table.insert(self._params.selected_list, v)
                            end
                    	else
                    		table.delete(self._params.selected_list, v)
                    	end
       				    if self._params.callback then
    				        self._params.callback(self._params.selected_list)
    				    end
                    end, 
                    group = items,
                    label = "temp2"
                })  
            end   
        end
    end    
    self._list_menu:AlignItems()
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