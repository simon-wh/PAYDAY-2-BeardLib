SelectListDialog = SelectListDialog or class(ListDialog)
SelectListDialog.type_name = "SelectListDialog"
SelectListDialog.MAX_ITEMS = 150

function SelectListDialog:init(params, menu)
    if self.type_name == SelectListDialog.type_name then
        params = params and clone(params) or {}
    end
    self._visible_items = {}
    SelectListDialog.super.init(self, params, menu)
end

function SelectListDialog:_Show(params)
    params = params or {}
    self._single_select = params.single_select or false
    self._allow_multi_insert = params.allow_multi_insert or false
    if params.selected_list then
        params.selected_list = clone(params.selected_list)
    end
    self._selected_list = params.selected_list or {}
    SelectListDialog.super._Show(self, params)
end

function SelectListDialog:CreateShortcuts(...)
    local offset, bw = SelectListDialog.super.CreateShortcuts(self, ...)
    self._menu:Button({
        name = "TickAll",
        offset = offset,
        text = "+*",
        text_align = "center",
        help = "beardlib_tick_all",
        help_localized = true,
        w = bw,
        on_callback = ClassClbk(self, "TickAllPresent", true),
        label = "temp"
    })
    self._menu:Button({
        name = "UntickAll",
        offset = offset,
        text = "-*",
        text_align = "center",
        help = "beardlib_untick_all",
        help_localized = true,
        w = bw,
        on_callback = ClassClbk(self, "TickAllPresent", false),
        label = "temp"
    })
    return offset, bw
end

function SelectListDialog:TickAllPresent(set)
    for _, item in pairs(self._visible_items) do
        if (set and item.can_be_ticked ~= false) or (not set and item.can_be_unticked ~= false) then
            item:SetValue(set, false)
            item:RunCallback(nil, true)
        end
    end
    self:MakeListItems()
end

function SelectListDialog:ShowItem(t, selected)
    if not selected and self._list_menu:GetItem(t) then
        return false
    end
    if self:SearchCheck(t) then
        if not self._limit or #self._visible_items <= self._max_items then
            return true
        end
    end
    return false
end

function SelectListDialog:MakeListItems(params)
    self._visible_items = {}
    self._list_menu:ClearItems("list_items")
    for _, v in pairs(self._selected_list) do
        local t = type(v) == "table" and v.name or v
        if self:ShowItem(t, true) then
            self:ToggleItem(t, true, v)
        end
    end
    for _, v in pairs(self._list) do
        local t = type(v) == "table" and v.name or v
        if self:ShowItem(t) then
            self:ToggleItem(t, false, v)
        end
    end
    self:show_dialog()
    self._list_menu:AlignItems(true)
end

function SelectListDialog:ToggleClbk(value, item, no_refresh)
    if self._single_select then
        for _,v in pairs(self._list) do
            local toggle = self._list_menu:GetItem(type(v) == "table" and v.name or v)
            if toggle and toggle ~= item then
                toggle:SetValue(false)
            end
        end
    end
    if item:Value() == true then
        if not table.contains(self._selected_list, value) or self._allow_multi_insert then
            if self._single_select then
                self._selected_list = {value}
            else
                table.insert(self._selected_list, type(value) == "table" and clone(value) or value)
            end
        end
    else
        if self._single_select then
            self._selected_list = {}
        else
            table.delete(self._selected_list, value)
        end
    end
    if not no_refresh then
        self:MakeListItems()
    end
end

function SelectListDialog:ToggleItem(name, selected, value)
    table.insert(self._visible_items, self._list_menu:Toggle({
        name = name,
        text = name,
        value = selected,
        on_callback = ClassClbk(self, "ToggleClbk", value),
        label = "list_items"
    }))
end

function SelectListDialog:run_callback(clbk)
    if clbk then
        clbk(self._selected_list)
    end
end

function SelectListDialog:hide()
    SelectListDialog.super.hide(self, true)
end