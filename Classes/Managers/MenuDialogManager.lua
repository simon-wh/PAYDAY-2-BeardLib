MenuDialogManager = MenuDialogManager or BeardLib:ManagerClass("Dialog")

function MenuDialogManager:init()
    self.biggest_id = 0
    self._menu = MenuUI:new({
        name = "BeardLibDialogs",
        layer = 5000,
        background_blur = true,
        bg_callbacks = false,
        create_items = ClassClbk(self, "CreateDialogs"),
        pre_key_press = ClassClbk(self, "KeyPressed")
    })
    self._dialogs = {}
    self._opened_dialogs = {}
    self._waiting_to_open = {}

    -- Deprecated, try not to use.
    BeardLib.managers.dialog = self
end

function MenuDialogManager:CreateDialogs()
    self.simple = MenuDialog:new()
    self.list = ListDialog:new()
    self.select_list = SelectListDialog:new()
    self.simple_list = SimpleListDialog:new()
    self.simple_select_list = SimpleSelectListDialog:new()
    self.color = ColorDialog:new()
    self.filebrowser = FileBrowserDialog:new()
    self.input = InputDialog:new()
    self.download = DownloadDialog:new()
    self._ready_to_open = true
end

function MenuDialogManager:ShowDialog(dialog)
    if not table.contains(self._opened_dialogs, dialog) then
        table.insert(self._opened_dialogs, 1, dialog)
    end
    self:EnableOnlyLast()
    if dialog._menu and dialog._menu.menu == self._menu then
        self:Show()
    end
end

function MenuDialogManager:OpenDialog(dialog, params)
    self.biggest_id = self.biggest_id + 1
    if params and params.force then
        table.insert(self._waiting_to_open, 1, {dialog = dialog, params = params, id = self.biggest_id})
        self._ready_to_open = true
    else
        table.insert(self._waiting_to_open, {dialog = dialog, params = params, id = self.biggest_id})
    end
end

function MenuDialogManager:EnableOnlyLast()
    for k, dialog in pairs(self._opened_dialogs) do
        local enabled = k == 1
        if dialog._menu and dialog._menu.SetEnabled then
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
    for i, to_open in pairs(self._waiting_to_open) do
        if dialog.current_id == to_open.id then
            dialog.current_id = nil
            table.remove(self._waiting_to_open, i)
            break
        end
    end
    if #self._opened_dialogs == 0 or not opened then
        self:Hide()
    end
    if not self._opened_dialogs[1] or not self._opened_dialogs[1]._Show then
        self._ready_to_open = true
	end
	BeardLib.Managers.MenuUI:CloseMenuEvent()
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
    local dialog = self._opened_dialogs[1]
    if not dialog then
        return false
    end
    if dialog:should_close() then
        if dialog.on_escape then
            dialog:on_escape()
        elseif dialog:hide() then
            managers.menu:post_event("prompt_exit")
        end
    end
    return true
end

function MenuDialogManager:Show()
	BeardLib.Managers.MenuUI:CloseMenuEvent()
    self._menu:enable()
    local dialog = self._opened_dialogs[1]
    if dialog then
        self._menu:ReloadInterface({background_blur = not dialog._no_blur, background_color = dialog._bg_color or false})
        for _, dialog in pairs(self._opened_dialogs) do
            if dialog.ReloadInterface then
                dialog:ReloadInterface()
            end
        end
	end
end

local enter_ids = Idstring("enter")
function MenuDialogManager:KeyPressed(o, k)
    local dialog = self._opened_dialogs[1]
    if self._menu:Enabled() and dialog and dialog._is_input and k == enter_ids then
        dialog:hide(true)
        return false
    end
end

function MenuDialogManager:Update()
    if self._ready_to_open or #self._opened_dialogs == 0 then
        local to_open = self._waiting_to_open[1]
        if to_open and (not to_open.dialog._params or to_open.dialog._params ~= to_open.params) then
            to_open.dialog:SetCurrentId(to_open.id)
            to_open.dialog:_Show(to_open.params)
            self._ready_to_open = false
        end
    end
end

function MenuDialogManager:Simple() return self.simple end
function MenuDialogManager:List() return self.list end
function MenuDialogManager:SelectList() return self.select_list end
function MenuDialogManager:SimpleList() return self.simple_list end
function MenuDialogManager:SimpleSelectList() return self.simple_select_list end
function MenuDialogManager:Color() return self.color end
function MenuDialogManager:FileBrowser() return self.filebrowser end
function MenuDialogManager:Input() return self.input end
function MenuDialogManager:Download() return self.download end
function MenuDialogManager:Menu() return self._menu end
function MenuDialogManager:Hide() self._menu:disable() end
function MenuDialogManager:GetMyIndex(dialog) return ((#self._opened_dialogs + 1) - tonumber(table.get_key(self._opened_dialogs, dialog))) or 0 end
function MenuDialogManager:AddDialog(dialog) table.insert(self._dialogs, dialog) end
function MenuDialogManager:RemoveDialog(dialog) table.delete(self._dialogs, dialog) end