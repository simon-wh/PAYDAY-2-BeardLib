ListDialog = ListDialog or class(MenuDialog)
ListDialog.type_name = "ListDialog"
ListDialog._no_reshaping_menu = true
ListDialog.MAX_ITEMS = 1000

function ListDialog:init(params, menu)
    if self.type_name == ListDialog.type_name then
        params = params and clone(params) or {}
    end

    menu = menu or BeardLib.Managers.Dialog:Menu()

    local h = params.h
    params.h = nil

    ListDialog.super.init(self, table.merge({
        h = params.main_h or 20,
        w = 900,
        size = 20,
        offset = 0,
        align_method = "grid",
        position = function(item)
            if alive(self._list_menu) then
                item:Panel():set_leftbottom(self._list_menu:Panel():left(), self._list_menu:Panel():top() - 1)
            end
        end,
        auto_align = true
    }, params), menu)

    params.position = nil
    params.h = h

    self._list_menu = menu:Menu(table.merge({
        name = "List",
        w = 900,
        h = params.h and params.h - self._menu.h or 600,
        size = 18,
        auto_foreground = true,
        auto_align = false,
        background_color = self._menu.background_color,
        accent_color = self._menu.accent_color,
        position = params.position or "Center",
        visible = false,
    }, params))

    self._menus = {self._list_menu}
end

function ListDialog:CreateShortcuts(params)
    local offset = {4, 0}
    local bw = self._menu:Toggle({
        name = "Limit",
        w = bw,
        offset = offset,
        text = ">|",
        help = "beardlib_limit_results",
        help_localized = true,
        size_by_text = true,
        value = self._limit,
        on_callback = function(item)
            self._limit = item:Value()
            self:MakeListItems()
        end,
        label = "temp"
    }):Width()

    self._menu:Toggle({
        name = "CaseSensitive",
        w = bw,
        offset = offset,
        text = "Aa",
        help = "beardlib_match_case",
        help_localized = true,
        value = self._case_sensitive,
        on_callback = function(item)
            self._case_sensitive = item:Value()
            self:MakeListItems()
        end,
        label = "temp"
    })

    return offset, bw
end

function ListDialog:_Show(params)
    if not self:basic_show(params) then
        return
    end
    if not params.no_reset_search then
        self._search = nil
        self._filter = {}
    end
    self._case_sensitive = params.case_sensitive
    self._limit = NotNil(params.limit, true)
    self._list = params.list
    self._max_items = params.max_items or self.MAX_ITEMS

    self._params = params
    self:CreateTopMenu(params)
    if params.sort ~= false then
        table.sort(params.list, function(a, b)
            return (type(a) == "table" and a.name or a) < (type(b) == "table" and b.name or b)
        end)
    end
    self:MakeListItems(params)
end

function ListDialog:CreateTopMenu()
    self._menu:ClearItems()
    local offset, bw = self:CreateShortcuts(params)
    local close = self._menu:ImageButton({
        name = "Close",
        w = bw,
        offset = offset,
        h = self._menu:H(),
        icon_w = 14,
        icon_h = 14,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {84, 89, 36, 36},
        on_callback = ClassClbk(self, "hide"),
        label = "temp"
    })
    self._menu:TextBox({
        name = "Search",
        w = self._menu:ItemsWidth() - close:Right(),
        control_slice = 0.86,
        focus_mode = true,
        auto_focus = true,
        index = 1,
        value = self._search,
        text = "beardlib_search",
        localized = true,
        on_callback = ClassClbk(self, "Search"),
        label = "temp"
    })
end

function ListDialog:ItemsCount()
    return #self._list_menu:Items()
end

function ListDialog:SearchCheck(t)
    if #self._filter == 0 then
        return true
    end
    local match
    for _, s in pairs(self._filter) do
        if (self._case_sensitive and string.find(t, s) or not self._case_sensitive and string.find(t:lower(), s:lower())) then
            return true
        end
    end
    return false
end

function ListDialog:MakeListItems(params)
    self._list_menu:ClearItems("list_items")
    local case = self._case_sensitive
    local limit = self._limit
    local groups = {}
    local i = 0
    for _, v in pairs(self._list) do
        if limit and i > self._max_items then
            break
        end
        local t = type(v) == "table" and v.name or v
        if self:SearchCheck(t) then
            i = i + 1
            local menu = self._list_menu
            if type(v) == "table" and v.create_group then
                menu = groups[v.create_group] or self._list_menu:Group({
                    auto_align = false,
                    name = v.create_group,
                    text = v.create_group,
                    label = "list_items"
                })
                groups[v.create_group] = menu
            end
            menu:Button(table.merge(type(v) == "table" and v or {}, {
                name = t,
                text = t,
                on_callback = function(item)
                    if self._callback then
                        self._callback(v)
                    end
                end,
                label = "list_items"
            }))
        end
    end

    self:show_dialog()
    self._list_menu:AlignItems(true)
end

function ListDialog:ReloadInterface()
    self._list_menu:AlignItems(true)
end

function ListDialog:Search(item)
    BeardLib:AddDelayedCall("ListSearch", 0.15, function()
        self._search = item:Value()
        self._filter = {}
        for _, s in pairs(string.split(self._search, ",")) do
            s = s:escape_special()
            table.insert(self._filter, s)
        end
        self:MakeListItems()
    end, true)
end

function ListDialog:on_escape()
    if self._no_callback then
        self._no_callback()
    end
    ListDialog.super.on_escape(self)
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