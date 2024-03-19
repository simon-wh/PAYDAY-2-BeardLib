FileBrowserDialog = FileBrowserDialog or class(MenuDialog)
FileBrowserDialog._no_clearing_menu = true
FileBrowserDialog._no_reshaping_menu = true
FileBrowserDialog.type_name = "FileBrowserDialog"
--TODO: Clean this
function FileBrowserDialog:_Show(params, force)
    if not self:basic_show(params) then
        return
    end
    self._extensions = params.extensions
    self._file_click = params.file_click
    self._base_path = params.base_path
    self._browse_func = params.browse_func
    self._openclose:SetText(params.save and "Save" or params.folder_browser and "Select" or "Open")
    self._save = params.save
    self._folder_browser = params.folder_browser
    self:Browse(Path:Normalize(params.where))
    self:show_dialog()
end

function FileBrowserDialog:init(params, menu)
    if self.type_name == FileBrowserDialog.type_name then
        params = params and clone(params) or {}
    end

    menu = menu or BeardLib.Managers.Dialog:Menu()
    FileBrowserDialog.super.init(self, table.merge(params, {
        w = 900,
        h = 624,
        auto_height = false,
        text_vertical = "center",
        align_method = "grid",
        offset = 0
    }), menu)

    self._menu:Button({
        name = "Backward",
        w = 30,
        text = "<",
        on_callback = ClassClbk(self, "FolderBack"),
        label = "temp"
    })
    self._menu:Button({
        name = "Forward",
        w = 30,
        text = ">",
        on_callback = function()
            self:Browse(self._old_dir)
        end,
        label = "temp"
    })
    self._menu:TextBox({
        name = "CurrentPath",
        text = " ",
        w = 540,
        lines = 1,
        control_slice = 1,
      --  forbidden_chars = {':','*','?','"','<','>','|'},
        on_callback = ClassClbk(self, "OpenPathSetDialog"),
    })
    local search = self._menu:TextBox({
        name = "Search",
        w = 260,
        lines = 1,
        control_slice = 0.75,
        text_align = "left",
        on_callback = ClassClbk(self, "Search"),
        label = "temp"
    })
    self._menu:ImageButton({
        name = "Close",
        w = 40,
        h = search:H(),
        icon_w = 14,
        icon_h = 14,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {84, 89, 36, 36},
        on_callback = ClassClbk(self, "hide"),
        label = "temp"
    })

    self._folders_menu = self._menu:Menu({
        name = "Folders",
        private = {offset = 0},
        w = 300,
        h = 540,
        auto_height = false,
    })

    self._files_menu = self._menu:Menu({
        name = "Files",
        private = {offset = 0},
        w = 600,
        h = 540
    })

    self._actions_menu = self._menu:Menu({
        name = "Actions",
        align_method = "grid_from_right",
        private = {offset = 0},
        w = 900,
        h = 60
    })

    self._file_types = self._actions_menu:ComboBox({
        name = "FileType",
        value = 1,
        items = {},
        text = " ",
        control_slice = 1,
        shrink_width = 0.2
    })
    self._file_name = self._actions_menu:TextBox({
        name = "File name",
        control_slice = 0.8,
        shrink_width = 0.75
    })
    self._actions_menu:Button({
        name = "Cancel",
        w = 95,
        on_callback = ClassClbk(self, "hide", false)
    })
    self._openclose = self._actions_menu:Button({
        name = "Open",
        w = 95,
        on_callback = ClassClbk(self, "FileDoubleClick")
    })

    self._search = ""
end

function FileBrowserDialog:Browse(where, params)
    if where ~= "" and not FileIO:Exists(where) then
        return
    end
    self._files_menu:ClearItems()
    self._folders_menu:ClearItems()
    if self._current_dir ~= where then
        self._search = ""
        self._menu:GetItem("Search"):SetValue("")
    end
    self._current_dir = where or ""
    local enabled = where ~= self._base_path
    self._menu:GetItem("CurrentPath"):SetValue(where)
    self._menu:GetItem("Backward"):SetEnabled(enabled)
    self._menu:GetItem("Forward"):SetEnabled(enabled)
    self._file_name:SetValue("")
    self._file_types:SetItems({'All Files ("*.*")'})
    self._file_types:SetValue(1)
    for _, ext in pairs(self._extensions) do
        self._file_types:Append(ext)
    end
    local f = {}
    local d = {}
    if self._browse_func then
        f, d = self._browse_func(self)
    else
        f = FileIO:GetFiles(where)
        d = FileIO:GetFolders(where)
    end
    if self._search:len() > 0 then
        local temp_f = clone(f)
        local temp_d = clone(d)
        f = {}
        d = {}
        for _, v in pairs(temp_f) do
            if v:find(self._search) then
                table.insert(f, v)
            end
        end
        for _, v in pairs(temp_d) do
            if v:find(self._search) then
                table.insert(d, v)
            end
        end
    end
    self:MakeFilesAndFolders(f, d)
end

function FileBrowserDialog:MakeFilesAndFolders(files, folders)
    for _, v in pairs(files) do
        local tbl = type(v) == "table"
        local pass = true
        if self._extensions then
            local file_ext = Path:GetFileExtension(v)
            local selected_ext = self._file_types:SelectedItem()
            if self._file_types:Value() == 1 then
                for _, ext in pairs(self._extensions) do
                    if ext == file_ext  then
                        pass = true
                        break
                    else
                        pass = false
                    end
                end
            else
                pass = file_ext == selected_ext
            end
        end
        if pass then
            self._files_menu:Button({
                name = tbl and v.name or v,
                text = tbl and v.name or v,
                path = tbl and v.path or Path:Combine(self._current_dir, v),
                on_double_click = ClassClbk(self, "FileDoubleClick"),
                on_key_press = ClassClbk(self, "FileDoubleClick"),
                on_callback = ClassClbk(self, "FileClick"),
                label = "temp2",
            })
        end
    end

    for _,v in pairs(folders) do
         self._folders_menu:Button({
            name = v,
            text = v,
            on_callback = ClassClbk(self, "FolderClick"),
            label = "temp2"
        })
    end
end

function FileBrowserDialog:Search(item)
    self._search = item:Value():escape_special()
    self:Browse(self._current_dir)
end

function FileBrowserDialog:OpenPathSetDialog(item)
    self:Browse(item:Value())
end

function FileBrowserDialog:FileClick(item)
    self._file_name:SetValue(item.text)
end

function FileBrowserDialog:FileDoubleClick(item, key)
    if key == Idstring("esc") then
        return
    end

    if self._file_click then
        if self._folder_browser then
            self._file_click(self._current_dir)
        else
            local path = self._current_dir and Path:Combine(self._current_dir, self._file_name:Value()) or self._file_name:Value()
            if FileIO:Exists(path) then
                if self._save then
                    QuickDialog({force = true, title = "Alert", message = "File already exists, replace the file?", no = "No"}, {{"Yes", SimpleClbk(self._file_click, path)}})
                else
                    self._file_click(path)
                end
            elseif self._save then
                self._file_click(path)
            else
                QuickDialog({force = true, title = "Error", message = "File does not exist!"})
            end
        end
    end
end

function FileBrowserDialog:FolderClick(item)
    self._old_dir = nil
    self:Browse(Path:Normalize(Path:CombineDir(self._current_dir, item.text)))
    if item.press_clbk then
        item.press_clbk()
    end
end

function FileBrowserDialog:FolderBack()
    if self._searching then
        self._searching = false
        self:Browse()
    else
        local str = string.split(Path:Normalize(self._current_dir), "/")
        table.remove(str)
        self._old_dir = self._current_dir
        self:Browse(table.concat(str, "/"))
    end
end

function FileBrowserDialog:hide( ... )
    if FileBrowserDialog.super.hide(self, ...) then
        self._current_dir = nil
        self._old_dir = nil
        self._extensions = nil
        self._file_click = nil
        self._browse_func = nil
        self._base_path = nil
        self._save = nil
        self._folder_browser = nil
        return true
    end
end