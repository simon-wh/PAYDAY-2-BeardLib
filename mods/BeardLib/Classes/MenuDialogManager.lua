MenuDialogManager = MenuDialogManager or class()
function MenuDialogManager:Init()
    self._menu = MenuUI:new({
        name = "BeardLibDialogs",
        layer = 800,
        marker_color = Color.white:with_alpha(0),
        marker_highlight_color = Color("4385ef"),
    })
    self._dialogs = {}
    self._opened_dialogs = {}
    self.list = ListDialog:new()
    self.select_list = SelectListDialog:new()
    self.color = ColorDialog:new()
    self.filebrowser = FileBrowserDialog:new()
end

function MenuDialogManager:OpenDialog(dialog)
    table.insert(self._opened_dialogs, dialog)
    if dialog._menu and dialog._menu.menu == self._menu then
        self:Show()
    end
end

function MenuDialogManager:CloseDialog(dialog)
    table.delete(self._opened_dialogs, dialog)
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

function MenuDialogManager:List() return self.list end
function MenuDialogManager:SelectList() return self.select_list end
function MenuDialogManager:Color() return self.color end
function MenuDialogManager:FileBrowser() return self.filebrowser end
function MenuDialogManager:Menu() return self._menu end
function MenuDialogManager:Show() self._menu:enable() end
function MenuDialogManager:Hide() self._menu:disable() end
function MenuDialogManager:GetNewIndex() return #self._dialogs + 1 end
function MenuDialogManager:AddDialog(dialog) table.insert(self._dialogs, dialog) end

return MenuDialogManager