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
    self:Browse(params.where)
    self:show_dialog()
end

function FileBrowserDialog:init(params, menu)  
    if self.type_name == FileBrowserDialog.type_name then
        params = params and clone(params) or {}
    end

    menu = menu or BeardLib.managers.dialog:Menu()
    
    self._folders_menu = menu:Menu(table.merge(params, {
        w = 300,
        h = 600,
        background_color = params.background_color or Color(0.6, 0.2, 0.2, 0.2),
        name = "Folders",
        position = function(item)
            item:SetPositionByString("CenterLeft")
            item:Panel():move(200)
        end,
        auto_height = false,
        visible = false
    })) 

    self._files_menu = menu:Menu(table.merge(params, {
        name = "Files",
        position = function(item)
            item:Panel():set_position(self._folders_menu:Panel():right() + 1, self._folders_menu:Panel():top())
        end,
        w = 600
    }))
    local s = self._files_menu.size + 8
    FileBrowserDialog.super.init(self, table.merge(params, {
        w = 900,
        h = s,
        auto_height = false,
        position = function(item)
            item:Panel():set_leftbottom(self._folders_menu:Panel():left(), self._folders_menu:Panel():top() - 1)
        end,
        text_align = "center",
        text_vertical = "center",
        align_method = "grid",
        offset = 0
    }), menu)
    self._menus = {self._files_menu, self._folders_menu}
    self._menu:Button({
        name = "Backward",
        w = 30,
        h = s,
        text = "<",
        on_callback = ClassClbk(self, "FolderBack"),  
        label = "temp"
    })    
    enabled = self._old_dir and self._old_dir ~= self._current_dir or false
    self._menu:Button({
        name = "Forward",
        w = 30,
        h = s,
        text = ">",
        on_callback = function()
            self:Browse(self._old_dir)
        end,  
        label = "temp"
    })    
    self._menu:TextBox({
        name = "CurrentPath",
        text = false,
        w = 540,
        h = s,
        lines = 1,
        control_slice = 1,
        forbidden_chars = {':','*','?','"','<','>','|'},
        on_callback = ClassClbk(self, "OpenPathSetDialog"),
    })
    self._menu:TextBox({
        name = "Search",
        w = 260,
        h = s,
        lines = 1,
        control_slice = 0.75,
        text_align = "left",
        on_callback = ClassClbk(self, "Search"),  
        label = "temp"
    })
    self._menu:ImageButton({
        name = "Close",
        w = 40,
        h = s,
        icon_w = 14,
        icon_h = 14,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {84, 89, 36, 36},
        on_callback = ClassClbk(self, "hide"),  
        label = "temp"
    })
    self._search = ""
end

function FileBrowserDialog:Browse(where, params)
    if not FileIO:Exists(where) then
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
            if v:match(self._search) then
                table.insert(f, v)
            end
        end
        for _, v in pairs(temp_d) do
            if v:match(self._search) then
                table.insert(d, v)
            end
        end
    end
    self:MakeFilesAndFolders(f, d)
end

function FileBrowserDialog:MakeFilesAndFolders(files, folders)
    for _,v in pairs(files) do
        local tbl = type(v) == "table"
        local pass = true
        if self._extensions then
            for _, ext in pairs(self._extensions) do
                if ext == Path:GetFileExtension(v) then
                    pass = true
                    break
                else
                    pass = false
                end
            end
        end
        if pass then
            self._files_menu:Button({
                name = tbl and v.name or v,
                text = tbl and v.name or v,
                path = tbl and v.path or Path:Combine(self._current_dir, v),
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
    self._search = item:Value()
    self:Browse(self._current_dir)
end

function FileBrowserDialog:OpenPathSetDialog(item)
    self:Browse(item:Value())
end

function FileBrowserDialog:FileClick(item)
    if self._file_click then
        self._file_click(item.path)
    end
end 

function FileBrowserDialog:FolderClick(item)
    self._old_dir = nil
    self:Browse(self._current_dir .. "/" .. item.text)
    if item.press_clbk then
        item.press_clbk()
    end
end

function FileBrowserDialog:FolderBack()
    if self._searching then
        self._searching = false
        self:Browse()
    else
        local str = string.split(self._current_dir, "/")
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
        return true
    end
end