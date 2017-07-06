MenuDialogManager = MenuDialogManager or class()
function MenuDialogManager:Init()
    self._menu = MenuUI:new({
        name = "BeardLibDialogs",
        layer = 800,
        background_blur = true,
        marker_color = Color.white:with_alpha(0),
        marker_highlight_color = Color("4385ef"),
    })
    self._dialogs = {}
    self._opened_dialogs = {}
    self._waiting_to_open = {}
    self.simple = MenuDialog:new()
    self.list = ListDialog:new()
    self.select_list = SelectListDialog:new()
    self.color = ColorDialog:new()
    self.filebrowser = FileBrowserDialog:new()
    self.input = InputDialog:new()
    self._ready_to_open = true
end

function MenuDialogManager:OpenDialog(dialog, params)
    if not table.has(self._opened_dialogs, dialog) then
        table.insert(self._opened_dialogs, dialog)
    end
    if params then
        table.insert(self._waiting_to_open, {dialog = dialog, params = params})
    end
    self:EnableOnlyLast()
    if dialog._menu and dialog._menu.menu == self._menu then
        self:Show()
    end
end

function MenuDialogManager:EnableOnlyLast()
    for k, dialog in pairs(self._opened_dialogs) do
        local enabled = k == #self._opened_dialogs
        if dialog._menu then
            dialog._menu:SetEnabled(enabled)
        end
        if dialog._menus then
            for _, menu in pairs(dialog._menus) do
                menu:SetEnabled(enabled)
            end
        end
    end
end

function MenuDialogManager:CloseDialog(dialog)
    table.delete(self._opened_dialogs, dialog)
    self:EnableOnlyLast()
    local opened
    for _, d in pairs(self._opened_dialogs) do
        if d._menu and d._menu.menu == self._menu then
            opened = true
            break
        end
    end
    if #self._opened_dialogs == 0 or not opened then
        self:Hide()
    end
    self._ready_to_open = true
end

function MenuDialogManager:OpenAfterClose(dialog, params)
    table.insert(self._delay_open, {dialog = dialog, params = params})
end

function MenuDialogManager:DialogOpened(dialog)
    if dialog then
        return table.contains(self._opened_dialogs, dialog)
    end
    return #self._opened_dialogs > 0
end

function MenuDialogManager:CloseLastDialog()
    if BeardLib.IgnoreDialogOnce then
        BeardLib.IgnoreDialogOnce = false
        return false 
    end
    local dialog = self._opened_dialogs[#self._opened_dialogs]
    if not dialog then
        return false
    end
    if dialog:should_close() and dialog:hide() then
        managers.menu:post_event("prompt_exit")
    end
    return true
end

function MenuDialogManager:Show() 
    self._menu:enable()
    local dialog = self._opened_dialogs[#self._opened_dialogs]
    if dialog then
        self._menu:ReloadInterface({background_blur = not dialog._no_blur})
    end 
end

function MenuDialogManager:update()
    if self._ready_to_open then
        local to_open = self._waiting_to_open[1]
        if to_open then
            to_open.dialog:_Show(to_open.params)
            table.remove(self._waiting_to_open, 1)
            self._ready_to_open = false
        end
    end
end

function MenuDialogManager:List() return self.list end
function MenuDialogManager:SelectList() return self.select_list end
function MenuDialogManager:Color() return self.color end
function MenuDialogManager:FileBrowser() return self.filebrowser end
function MenuDialogManager:Input() return self.input end
function MenuDialogManager:Menu() return self._menu end
function MenuDialogManager:Hide() self._menu:disable() end
function MenuDialogManager:GetMyIndex(dialog) return tonumber(table.get_key(self._opened_dialogs, dialog)) or 0 end
function MenuDialogManager:AddDialog(dialog) table.insert(self._dialogs, dialog) end

return MenuDialogManager