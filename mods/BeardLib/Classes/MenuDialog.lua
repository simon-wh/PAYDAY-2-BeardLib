MenuDialog = MenuDialog or class()
MenuDialog.type_name = "MenuDialog"
function MenuDialog:init(params, menu)
    params = params or {}
    self._default_width = 420
    self._no_blur = params.no_blur
    self._tbl = {}
    if self.type_name == "MenuDialog" then
        params = deep_clone(params)
    end
    menu = menu or BeardLib.managers.dialog:Menu()
    self._menu = menu:Menu(table.merge({
        name = "dialog"..tostring(self),
        position = "Center",
        w = MenuDialog._default_width,
        visible = false,
        auto_height = true,
        auto_text_color = true,
        always_highlighting = true,
        reach_ignore_focus = true,
        scrollbar = false,
        items_size = 20,
        offset = 8,
        marker_highlight_color = Color("719ee8"),
        background_color = Color(0.6, 0.2, 0.2, 0.2),
    }, params))
    BeardLib.managers.dialog:AddDialog(self)
end

function MenuDialog:Show(params)
    BeardLib.managers.dialog:OpenDialog(self, type_name(params) == "table" and params or nil)
end

function MenuDialog:show(...)
    return self:Show(...)
end

function MenuDialog:_Show(params)
    if not self:basic_show(params) then
        return false
    end
    if params.title then
        self._menu:Divider(table.merge({
            name = "Title",
            text = params.title,
            border_bottom = true,
            border_color = self._menu.marker_highlight_color,
            items_size = self._menu.items_size + 4,
        }, params.title_merge or {}))
    end
    if params.message then
        self._menu:Divider({
            name = "Message",
            text = params.message,
            items_size = self._menu.items_size + 2,
        })
    end
    if params.create_items then
        params.create_items(self._menu)
    end
    if params.yes ~= false then
        self._menu:Button({
            name = "Yes",
            text = params.yes or (params.no and "Yes") or "Close",
            reachable = true,
            highlight = true,
            callback = callback(self, self, "hide", true)
        })
    end
    if params.no then
        self._menu:Button({
            name = "No",
            text = params.no,
            reachable = true,
            callback = callback(self, self, "hide")
        })
    end
    self:show_dialog()
    return true
end

function MenuDialog:show_dialog()
    self._menu:SetVisible(true, true)
    if self._menus then
        for _, menu in pairs(self._menus) do
            menu:SetVisible(true, true)
        end
    end
end

function MenuDialog:basic_show(params, force)
    BeardLib.managers.dialog:ShowDialog(self)
    self._tbl = {}
    self._params = params
    params = type_name(params) == "table" and params or {}
    self._callback = params.callback
    self._no_callback = params.no_callback
    if not self._no_clearing_menu then
        self._menu:ClearItems()
    end
    self._menu:SetLayer(BeardLib.managers.dialog:GetMyIndex(self) * 50)
    if not self._no_reshaping_menu then
        self._menu:SetSize(params.w or self._default_width, params.h)
        self._menu:SetPosition(params.position or "Center")
    end
    if self._menus then
        for _, menu in pairs(self._menus) do
            menu:SetLayer(BeardLib.managers.dialog:GetMyIndex(self) * 50)
            if not self._no_clearing_menu then
                menu:ClearItems()
            end
        end
    end
    return true
end

function MenuDialog:run_callback(clbk)
    if clbk then
        clbk(self._menu)
    end
end

function MenuDialog:Hide(yes, menu, item)
    return self:hide(yes, menu, item)
end

function MenuDialog:should_close()
    return self._menu:ShouldClose()
end

function MenuDialog:hide(yes, menu, item)
    BeardLib.managers.dialog:CloseDialog(self)
    local clbk = yes == true and self._callback or yes ~= false and self._no_callback
    if not self._no_clearing_menu then
        self._menu:ClearItems()
    end
    self._menu:SetVisible(false, true)
    if self._menus then
        for _, menu in pairs(self._menus) do
            menu:SetVisible(false, true)
            if not self._no_clearing_menu then
                menu:ClearItems()
            end
        end
    end
    self._callback = nil
    self._no_callback = nil
    self._params = nil
    if type(clbk) == "function" then
        self:run_callback(clbk)
    end
    self._tbl = {}
    return true
end

function QuickDialog(opt, items)
    opt = opt or {}
    local dialog = opt.dialog or BeardLib.managers.dialog.simple
    opt.dialog = nil
    opt.title = opt.title or "Info"
    dialog:Show(table.merge({no = "Close", yes = false, create_items = function(menu)
        for i, item in pairs(items) do
            if item[3] == true then
                dialog._no_callback = item[2]
            end
            menu:Button({highlight = true, reachable = true, name =  type_name(item) == "table" and item[1] or item, callback = function() 
                if type(item[2]) == "function" then
                    item[2]()
                end
                dialog:hide(false)
            end, type_name(item) == "table" and item[2]})
        end
    end}, opt))
end