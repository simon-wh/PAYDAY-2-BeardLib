MenuDialog = MenuDialog or class()
MenuDialog.type_name = "MenuDialog"

local Managers = BeardLib.Managers

function MenuDialog:init(params, menu)
    if self.type_name == MenuDialog.type_name then
        params = params and clone(params) or {}
    end
    self._default_width = self._default_width or 420
    self._no_blur = params.no_blur
    self._bg_color = params.bg_color
    self._tbl = {}
    menu = menu or Managers.Dialog:Menu()
    self._menu = menu:Menu(table.merge({
        name = "dialog"..tostring(self),
        position = "Center",
        align_items = "grid",
        w = MenuDialog._default_width,
        visible = false,
        auto_height = true,
        auto_foreground = true,
        always_highlighting = true,
        reach_ignore_focus = true,
        scrollbar = false,
        max_height = 700,
        size = 20,
        offset = 8,
        accent_color = BeardLib.Options:GetValue("MenuColor"),
        background_color = Color.black:with_alpha(0.75),
    }, params))
    Managers.Dialog:AddDialog(self)
end

function MenuDialog:Destroy()
    self:hide()
    Managers.Dialog:RemoveDialog(self)
    if self._menus then
        for _, menu in pairs(self._menus) do
            menu:Destroy()
        end
    end
    self._menu:Destroy()
end

function MenuDialog:Show(params)
    Managers.Dialog:OpenDialog(self, type_name(params) == "table" and params or nil)
end

function MenuDialog:SetCurrentId(id)
    self.current_id = id
end

function MenuDialog:show(...)
    return self:Show(...)
end

function MenuDialog:_Show(params)
    if not self:basic_show(params) then
        return false
    end
    self:CreateCustomStuff(params)
    self:show_dialog()
    return true
end

function MenuDialog:CreateCustomStuff(params)
    if params.title then
         self._menu:Divider(table.merge({
            name = "Title",
            text = params.title,
            background_color = self._menu.accent_color,
            offset = 0,
            text_offset = 6,
            size = self._menu.size + 4,
        }, params.title_merge or {}))
    end

    if params.create_items then
        params.create_items(self._menu)
    end
    if params.yes ~= false then
        self._menu:Button({
            name = "Yes",
            text = params.yes or (params.no and "Yes") or managers.localization:text("beardlib_close"),
            reachable = true,
            highlight = true,
            on_callback = ClassClbk(self, "hide", true)
        })
    end
    if params.no then
        self._menu:Button({
            name = "No",
            text = params.no,
            reachable = true,
            on_callback = ClassClbk(self, "hide", false)
        })
    end
    local scroll = self._menu:Menu({name = "MessageScroll", index = 2, private = {offset = 0}, hide_scroll_background = true, auto_height = true, h = 0, max_height = params.content_max_h or 540})
    if params.create_items_contained then
        params.create_items_contained(scroll)
    end
    if params.message then
        scroll:Divider({
            name = "Message",
            text = params.message,
        })
    end
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
    self._no_blur = NotNil(params.no_blur, self._no_blur, false)
    Managers.Dialog:ShowDialog(self)
    self._tbl = {}
    self._params = params
    params = type_name(params) == "table" and params or {}
    self._callback = params.on_callback or params.callback
    self._no_callback = params.no_callback
    if not self._no_clearing_menu then
        self._menu:ClearItems()
    end
    self._menu:SetLayer(Managers.Dialog:GetMyIndex(self) * 50)
    if self.type_name == MenuDialog.type_name then
        self._menu.auto_height = NotNil(params.auto_height, true)
    end
    if not self._no_reshaping_menu then
        self._menu:SetSize(params.w or self._default_width, params.h)
        self._menu:SetPosition(params.position or "Center")
    end
    if self._menus then
        for _, menu in pairs(self._menus) do
            menu:SetLayer(Managers.Dialog:GetMyIndex(self) * 50)
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

function MenuDialog:Hide(yes, item)
    return self:hide(yes, item)
end

function MenuDialog:should_close()
    return self._menu:ShouldClose()
end

function MenuDialog:hide(yes, item)
    Managers.Dialog:CloseDialog(self)
    local menu = Managers.Dialog:Menu()
    if menu.active_textbox then
        menu.active_textbox:set_active(false) 
    end
    --TODO: allow for multiple no functions
    local clbk = (yes == true and self._callback) or (not yes and self._no_callback)
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

function MenuDialog:on_escape(yes)
    self:hide(yes)
    managers.menu:post_event("prompt_exit")
end

function QuickDialog(opt, items)
    opt = opt or {}
    local dialog = opt.dialog or Managers.Dialog:Simple()
    opt.dialog = nil
    opt.title = opt.title or "Info"
    items = items or opt.items
    dialog:Show(table.merge({no = managers.localization:text("beardlib_close"), yes = false, create_items = function(menu)
        for _, item in ipairs(items) do
            local name, clbk, should_close, is_no = unpack(item)
            should_close = NotNil(should_close, true)
            if is_no == true then
                dialog._no_callback = clbk
            end
            menu:Button({highlight = true, reachable = true, name = type_name(item) == "table" and name or item, on_callback = function()
                if type(clbk) == "function" then
                    clbk(dialog)
                end
                if should_close then
                    dialog:hide(not is_no)
                end
            end, type_name(item) == "table" and clbk})
        end
    end}, opt))
end