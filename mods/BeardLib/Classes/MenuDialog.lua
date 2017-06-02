MenuDialog = MenuDialog or class()
MenuDialog.type_name = "MenuDialog"
function MenuDialog:init(params, menu)
    params = params or {}
    if self.type_name == "MenuDialog" then
        params = deep_clone(params)
    end
    menu = menu or BeardLib.managers.dialog:Menu()
    self._menu = menu:Menu(table.merge({
        name = "dialog",
        position = "Center",
        layer = BeardLib.managers.dialog:GetNewIndex(),
        visible = false,
        scrollbar = false,
        background_color = Color(0.6, 0.2, 0.2, 0.2),
        w = 600,
        h = 500
    }, params)) 
    BeardLib.managers.dialog:AddDialog(self)
end

function MenuDialog:show(...)
    return self:Show(params)
end

function MenuDialog:Show(params)
    if not self:basic_show(params) then
        return false
    end
    if params.title then
        self._menu:Divider(table.merge({
            name = "Title",
            text = params.title,
            items_size = self._menu.items_size + 4,
        }, params.title_merge or {}))
    end
    if params.create_items then
        params.create_items(self._menu)
    end
    self._menu:Button({
        name = "Yes",
        text_align = "right",
        text = params.yes or (params.no and "Yes") or "Close",
        callback = callback(self, self, "hide", true)
    })
    if params.no then
        self._menu:Button({
            name = "No",
            text_align = "right",
            text = params.no,
            callback = callback(self, self, "hide")
        })
    end
    return true
end

function MenuDialog:basic_show(params)
    if BeardLib.managers.dialog:DialogOpened(self) then
        return false
    end
    params = params or {}
    BeardLib.managers.dialog:OpenDialog(self)
    self._callback = params.callback
    self._no_callback = params.no_callback
    if not self._no_clearing_menu then
        self._menu:ClearItems()
    end
    self._menu:SetVisible(true)
    if params.w or params.h then
        self._menu:SetSize(params.w, params.h)
    end
    if params.position then
        self._menu:SetPosition(params.position)
    end
    return true
end

function MenuDialog:run_callback(clbk)
    if clbk then
        clbk(self._menu)
    end
end

function MenuDialog:Hide(yes, menu, item)
    self:hide(yes, menu, item)
end

function MenuDialog:should_close()
    return self._menu:ShouldClose()
end

function MenuDialog:hide(yes, menu, item)
    BeardLib.managers.dialog:CloseDialog(self)

    local clbk = yes == true and self._callback or self._no_callback
    self:run_callback(clbk)
    if not self._no_clearing_menu then
        self._menu:ClearItems()
    end
    self._menu:SetVisible(false)
    self._callback = nil
    self._no_callback = nil
    return true
end