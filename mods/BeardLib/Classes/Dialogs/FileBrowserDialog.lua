FileBrowserDialog = FileBrowserDialog or class(MenuDialog)
function FileBrowserDialog:show(...)
    self:Browse(...)
end

function FileBrowserDialog:create_items(params, menu)  
    params.w = 300
    params.h = 600
    params.name = "Folders"
    params.position = "CenterLeft"
    params.background_color = params.background_color or Color(0.2, 0.2, 0.2)
    params.background_alpha = params.background_alpha or 0.6
    params.override_size_limit = true
    params.visible = true
    self._folders_menu = menu:NewMenu(params) 
    self._folders_menu:Panel():move(200)
    params.name = "Files"
    params.position = table.pack(self._folders_menu:Panel():right() + 1, self._folders_menu:Panel():top())
    params.w = 600
    self._files_menu = menu:NewMenu(params) 
    params.w = 901
    params.h = 16
    params.row_max = 1
    FileBrowserDialog.super.create_items(self, params, menu) 
    self._menu:Panel():set_leftbottom(self._folders_menu:Panel():left(), self._folders_menu:Panel():top() - 1)
end

function FileBrowserDialog:Browse(where, params)   
    params = params or self._params or {}
    self._params = params
    self._menu:ClearItems()
    self._files_menu:ClearItems()
    self._folders_menu:ClearItems()
    self._current_dir = where or ""
    local enabled = where ~= params.base_path
    self._menu:Button({
        name = "Backward",
        w = 30,
        enabled = enabled,
        text_color = not enabled and Color(.8, .8, .8),
        text_highlight_color = not enabled and Color(.8, .8, .8),
        marker_highlight_color = not enabled and Color(0,0,0,0),
        text = "<",
        callback = callback(self, self, "FolderBack"),  
        label = "temp"
    })    
    enabled = self._old_dir and self._old_dir ~= self._current_dir or false
    self._menu:Button({
        name = "Forward",
        w = 30,
        enabled = enabled,
        text_color = not enabled and Color(.8, .8, .8),
        text_highlight_color = not enabled and Color(.8, .8, .8),
        marker_highlight_color = not enabled and Color(0,0,0,0),
        text = ">",
        callback = function()
            self:Browse(self._old_dir)
        end,  
        label = "temp"
    })    
    self._menu:Button({
        w = 540,
        callback = callback(self, self, "OpenPathSetDialog"),  
        name = "CurrentPath",
        text = tostring(where),
    })
    self._menu:TextBox({
        name = "Search",
        w = 200,
        --callback = callback(self, self, "Search"),  
        label = "temp"
    })
    self._menu:Button({
        name = "Close",
        w = 100,
        text = "Close",
        callback = callback(self, self, "hide"),  
        label = "temp"
    })
    local f = {}
    local d = {}
    if params.browse_func then  
        f, d = params.browse_func(self)
    else
        f = SystemFS:list(where)
        d = SystemFS:list(where, true)
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
    self._files_menu:ClearItems()
    self._folders_menu:ClearItems()
    self._menu:GetItem("CurrentPath"):SetText("Searching.. " .. tostring( item.value ))
    self:MakeFilesAndFolders(SystemFS:list(where, item.value), SystemFS:list(where, item.value, true))
end

function FileBrowserDialog:OpenPathSetDialog(menu, item)
    managers.system_menu:show_keyboard_input({
        text = self._current_dir,
        title = "Set path to:",
        callback_func = function(success, search)
            if not success or search == self._current_dir then
                return
            end    
            self:Browse(search)            
        end
    })
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
    self.super.hide(self, ...)
    self._params = nil
    self._old_dir = nil
end