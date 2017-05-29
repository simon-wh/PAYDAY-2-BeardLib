FileBrowserDialog = FileBrowserDialog or class(MenuDialog)
function FileBrowserDialog:show(...)
    self:Browse(...)
end

function FileBrowserDialog:Show(...)
    self:Browse(...)
end

function FileBrowserDialog:init(params, menu)  
    menu = menu or BeardLib.managers.dialog:Menu()
    params = params or {}

    self._folders_menu = menu:Menu(table.merge(params, {
        w = 300,
        h = 600,
        name = "Folders",
        position = "CenterLeft",
        position = function(item)
            item:SetPositionByString("CenterLeft")
            item:Panel():move(200)
        end,
        background_color = params.background_color or Color(0.2, 0.2, 0.2),
        background_alpha = params.background_alpha or 0.6,
        visible = false        
    })) 

    self._files_menu = menu:Menu(table.merge(params, {
        name = "Files",
        position = function(item)
            item:Panel():set_position(self._folders_menu:Panel():right() + 1, self._folders_menu:Panel():top())
        end,
        w = 600
    }))
    table.merge(params, {
        w = 901,
        h = 16,
        position = function(item)
            item:Panel():set_leftbottom(self._folders_menu:Panel():left(), self._folders_menu:Panel():top() - 1)
        end,
        row_max = 1,
        offset = 0
    })
    FileBrowserDialog.super.init(self, params, menu) 

    self._menu:Button({
        name = "Backward",
        w = 30,
        text = "<",
        callback = callback(self, self, "FolderBack"),  
        label = "temp"
    })    
    enabled = self._old_dir and self._old_dir ~= self._current_dir or false
    self._menu:Button({
        name = "Forward",
        w = 30,
        text = ">",
        callback = function()
            self:Browse(self._old_dir)
        end,  
        label = "temp"
    })    
    self._menu:TextBox({
        w = 540,
        control_slice = 1.01,
        forbidden_chars = {':','*','?','"','<','>','|'},
        callback = callback(self, self, "OpenPathSetDialog"),
        text = false,
        name = "CurrentPath",
    })
    self._menu:TextBox({
        name = "Search",
        w = 200,
        callback = callback(self, self, "Search"),  
        label = "temp"
    })
    self._menu:Button({
        name = "Close",
        w = 100,
        text = "Close",
        callback = callback(self, self, "hide"),  
        label = "temp"
    })
    self._search = ""
end

function FileBrowserDialog:Browse(where, params)
    if not FileIO:Exists(where) then
        return
    end
    params = params or self._params or {}
    self._params = params
    self._files_menu:ClearItems()
    self._folders_menu:ClearItems()
    if self._current_dir ~= where then
        self._search = ""
        self._menu:GetItem("Search"):SetValue("")
    end
    self._current_dir = where or ""
    local enabled = where ~= params.base_path
    self._menu:GetItem("CurrentPath"):SetValue(where)
    self._menu:GetItem("Backward"):SetEnabled(enabled)
    self._menu:GetItem("Forward"):SetEnabled(enabled)
    local f = {}
    local d = {}
    if params.browse_func then  
        f, d = params.browse_func(self)
    else
        f = SystemFS:list(where)
        d = SystemFS:list(where, true)
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
    if BeardLib.DialogOpened == self then
        return
    end
    self._dialog:enable()    
    self._trigger = managers.menu._controller:add_trigger(Idstring("esc"), callback(self, self, "hide"))    
    BeardLib.DialogOpened = self
end

function FileBrowserDialog:MakeFilesAndFolders(files, folders)
    for _,v in pairs(files) do
        local tbl = type(v) == "table"
        local pass = true
        if self._params.extensions then
            for _, ext in pairs(self._params.extensions) do
                if ext == BeardLib.Utils.Path:GetFileExtension(v) then
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
                path = tbl and v.path or BeardLib.Utils.Path:Combine(self._current_dir, v),
                callback = callback(self, self, "FileClick"), 
                label = "temp2",
            })
        end       
    end       
    for _,v in pairs(folders) do
         self._folders_menu:Button({
            name = v,
            text = v,
            callback = callback(self, self, "FolderClick"), 
            label = "temp2"
        })        
    end
end

function FileBrowserDialog:Search(menu, item)
    self._search = item:Value()
    self:Browse(self._current_dir)
end

function FileBrowserDialog:OpenPathSetDialog(menu, item)
    self:Browse(item:Value())
end

function FileBrowserDialog:FileClick(menu, item)
    if self._params.file_click then
        self._params.file_click(item.path)
    end
end 

function FileBrowserDialog:FolderClick(menu, item)
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
    if self.super.hide(self, ...) then
        self._params = nil
        self._old_dir = nil
        return true
    end
end