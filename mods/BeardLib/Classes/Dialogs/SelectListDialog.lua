SelectListDialog = SelectListDialog or class(ListDialog)
SelectListDialog.type_name = "SelectListDialog"
function SelectListDialog:_Show(params)
    params = params or {}
    self._single_select = params.single_select or false
    self._selected_list = params.selected_list or {}
    SelectListDialog.super._Show(self, params)
end

function SelectListDialog:MakeListItems(params)
    self._list_menu:ClearItems("list_items")
    local function ShowItem(t) 
        if self:SearchCheck(t) then
            if not self._limit or self:ItemsCount() <= 250 then
                return true
            end
        end
        return false
    end
    for _,v in pairs(self._selected_list) do
        local t = type(v) == "table" and v.name or v
        if ShowItem(t) then
            self:ToggleItem(t, true, v)
        end
    end
    for _,v in pairs(self._list) do
        local t = type(v) == "table" and v.name or v
        if ShowItem(t) and not self._list_menu:GetItem(t) then
            self:ToggleItem(t, false, v)
        end
    end
    self:show_dialog()
    self._list_menu:AlignItems(true)
end

function SelectListDialog:ToggleClbk(value, menu, item)
    if item:Value() == true then
        if not table.contains(self._selected_list, value) then
            if self._single_select then
                self._selected_list = {value}
            else
                table.insert(self._selected_list, value)
            end
        end
    else
        if self._single_select then
            self._selected_list = {}
        else
            table.delete(self._selected_list, value)
        end
    end
end

function SelectListDialog:ToggleItem(name, selected, value)
    self._list_menu:Toggle({
        name = name,
        text = name,
        value = selected,
        callback = callback(self, self, "ToggleClbk", value),
        label = "list_items"
    })
end

function SelectListDialog:run_callback(clbk)
    if clbk then
        clbk(self._selected_list)
    end
end

function SelectListDialog:hide()
    SelectListDialog.super.hide(self, true)
end