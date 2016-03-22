ScriptDataConveterManager = ScriptDataConveterManager or class()

ScriptDataConveterManager.script_file_from_types = {
    {name = "binary", func = "ScriptSerializer:from_binary", open_type = "rb"},
    {name = "json", func = "json.custom_decode"},
    {name = "xml", func = "ScriptSerializer:from_xml"},
    {name = "generic_xml", func = "ScriptSerializer:from_generic_xml"},
    {name = "custom_xml", func = "ScriptSerializer:from_custom_xml"},
}

ScriptDataConveterManager.script_file_to_types = {
    {name = "binary", open_type = "wb"},
    {name = "json"},
    {name = "generic_xml"},
    {name = "custom_xml"},
}

ScriptDataConveterManager.NodeName = "BeardLibScriptDataMenu"

ScriptDataConveterManager.script_data_paths = {
    {path = "%userprofile%", name = "User Folder"},
    {path = "%userprofile%/Documents/", name = "Documents"},
    {path = "%userprofile%/Desktop/", name = "Desktop"},
    {path = string.gsub(Application:base_path(), "\\", "/"), name = "PAYDAY 2 Directory"},
    {name = "PAYDAY 2 Assets", assets = true}
}

function ScriptDataConveterManager:init()
    
    self:init_paths()
end

function ScriptDataConveterManager:init_paths()
    table.insert(self.script_data_paths, {
        path = "C:/", name = "C Drive"
    })
    
    table.insert(self.script_data_paths, {
        path = "D:/", name = "D Drive"
    })
    
    table.insert(self.script_data_paths, {
        path = "E:/", name = "E Drive"
    })
    
    table.insert(self.script_data_paths, {
        path = "F:/", name = "F Drive"
    })

    local user_path = string.gsub(Application:windows_user_folder(),  "\\", "/")
    local split_user_path = string.split(user_path, "/")
    for i = 1, 3 do
        table.remove(split_user_path, #split_user_path)
    end
    user_path = table.concat(split_user_path, "/")
    for i, path_data in pairs(self.script_data_paths) do
        if path_data.path then
            path_data.path = string.gsub(path_data.path, "%%userprofile%%", user_path)
            if not string.ends(path_data.path, "/") then
                path_data.path = path_data.path .. "/"
            end
        end
        
        if not path_data.assets then
            path_data.assets = false
        end
    end
    
    
end

function ScriptDataConveterManager:GetTypeDataFrom(file, typ)
    local read_data = file:read("*all")
    
    local new_data
    if typ == "json" then
        new_data = json.custom_decode(read_data)
    elseif typ == "xml" then
        new_data = ScriptSerializer:from_xml(read_data)
    elseif typ == "custom_xml" then
        new_data = ScriptSerializer:from_custom_xml(read_data)
    elseif typ == "generic_xml" then
        new_data = ScriptSerializer:from_generic_xml(read_data)
    elseif typ == "binary" then
        new_data = ScriptSerializer:from_binary(read_data)
    end
    
    return new_data
end

function ScriptDataConveterManager:GetTypeDataTo(data, typ)
    local new_data
    if typ == "json" then
        new_data = json.custom_encode(data)
    elseif typ == "custom_xml" then
        new_data = ScriptSerializer:to_custom_xml(data)
    elseif typ == "generic_xml" then
        new_data = ScriptSerializer:to_generic_xml(data)
    elseif typ == "binary" then
        new_data = ScriptSerializer:to_binary(data)
    end
    
    return new_data
end

function ScriptDataConveterManager:ConvertFile(file, from_i, to_i, filename_dialog)
    local from_data = self.script_file_from_types[from_i]
    local to_data = self.script_file_to_types[to_i]
    
    local file_split = string.split(file, "%.")
    local filename_split = string.split(file_split[1], "/")
    
    local from_file = not self.assets and io.open(file, from_data.open_type or 'r') or nil
    if from_file == nil and not self.assets then
        BeardLib:log("[Error] File not accessible")
        return
    end
    
    local convert_data = self.assets and PackageManager:_script_data(file_split[2]:id(), file_split[1]:id()) or self:GetTypeDataFrom(from_file, from_data.name)
    if from_file then
        from_file:close()
    end
    
    local new_path = self.assets and string.gsub(Application:base_path(),  "\\", "/") .. filename_split[#filename_split] .. "." .. to_data.name or file .. "." .. to_data.name
    
    if filename_dialog then
        --Use system_menu dialog
        managers.system_menu:show_keyboard_input({text = new_path, title = "File name", callback_func = callback(self, self, "SaveConvertedData", {to_data = to_data, convert_data = convert_data})})
    else
        self:SaveConvertedData({to_data = to_data, convert_data = convert_data}, true, new_path)
    end
end

function ScriptDataConveterManager:SaveConvertedData(params, success, value)
    if not success then
        return
    end
    log("writefile")
    log(value)
    local to_file = io.open(value, params.to_data.open_type or "w+")
    local new_data = self:GetTypeDataTo(params.convert_data, params.to_data.name)
    to_file:write(new_data)
    to_file:close()
    
    self:RefreshFilesAndFolders()
end

function ScriptDataConveterManager:GetFilesAndFolders(current_path)
    local folders, files
    
    if self.assets then
        local path_split = string.split(current_path, "/")
        local tbl = BeardLib.DBEntries
        for _, part in pairs(path_split) do
            if tbl[part] then
                tbl = tbl[part]
            else
                tbl = {}
            end
        end
        
        folders = {}
        files = {}
        
        for i, j in pairs(tbl) do
            if tonumber(i) ~= nil then
                log(j.name)
                table.insert(files, j.name .. "." .. j.file_type)
            else
                table.insert(folders, i)
            end
        end
    else
        folders = file.GetDirectories(current_path)
        files = file.GetFiles(current_path)
    end
    
    return files or {}, folders or {}
end

function ScriptDataConveterManager:RefreshFilesAndFolders()
    local node = MenuHelperPlus:GetNode(nil, self.NodeName)
    node:clean_items()
    
    local gui_class = managers.menu:active_menu().renderer
    
    self.path_text = self.path_text or gui_class.safe_rect_panel:child("BeardLibPathText") or gui_class.safe_rect_panel:text({
        name = "BeardLibPathText",
        text = "",
        font =  tweak_data.menu.pd2_medium_font, 
        font_size = 25,
        layer = 20,
        color = Color.yellow
    })
    self.path_text:set_text(self.current_script_path)
    self.path_text:set_visible(true)
    local x, y, w, h = self.path_text:text_rect()
    self.path_text:set_size(w, h)
    self.path_text:set_position(0, 0)
    
    MenuHelperPlus:AddButton({
        id = "BackToStart",
        title = "Back to Shortcuts",
        callback = "BeardLibScriptStart",
        node = node,
        localized = false
    })
    
    if not self.assets then
        MenuHelperPlus:AddButton({
            id = "OpenFolderInExplorer",
            title = "Open In Explorer",
            callback = "BeardLibOpenInExplorer",
            node = node,
            localized = false
        })
    end
    
    local up_level = string.split(self.current_script_path, "/")
    if #up_level > 1 or self.assets and #up_level > 0 then
        table.remove(up_level, #up_level)
        
        local up_string = table.concat(up_level, "/")
        MenuHelperPlus:AddButton({
            id = "UpLevel",
            title = "UP A DIRECTORY...",
            callback = "BeardLibFolderClick",
            node = node,
            localized = false,
            merge_data = {
                base_path = up_string .. (up_string == "" and "" or "/")
            }
        })
    end
    
    MenuHelperPlus:AddDivider({
        id = "fileDivider",
        node = node,
        size = 15
    })
    
    local files, folders = self:GetFilesAndFolders(self.current_script_path)
    
    if folders then
        table.sort(folders)
        for i, folder in pairs(folders) do
            MenuHelperPlus:AddButton({
                id = "BeardLibPath" .. folder,
                title = folder,
                callback = "BeardLibFolderClick",
                node = node,
                localized = false,
                merge_data = {
                    base_path = self.current_script_path .. folder .. "/",
                    row_item_color = Color.yellow,
                    hightlight_color = Color.yellow,
                    to_upper = false
                }
            })
        end
    end
    
    if files then
        table.sort(files)
        for i, file in pairs(files) do
            local file_parts = string.split(file, "%.")
            local extension = file_parts[#file_parts]
            local colour = Color.white
            if self.assets and not PackageManager:has(extension:id(), (self.current_script_path .. file_parts[1]):id()) then
                colour = Color.red
            end
            if table.contains(BeardLib.script_data_types, extension) or table.contains(BeardLib.script_data_formats, extension) then
                MenuHelperPlus:AddButton({
                    id = "BeardLibPath" .. file,
                    title = file,
                    callback = "BeardLibFileClick",
                    node = node,
                    localized = false,
                    merge_data = {
                        base_path = self.current_script_path .. file,
                        row_item_color = colour,
                        hightlight_color = colour,
                        to_upper = false
                    }
                })
            end
        end
    end
    
    managers.menu:add_back_button(node)
    
    BeardLib:RefreshCurrentNode()
end

function ScriptDataConveterManager:CreateScriptDataFileOption()
    local node = MenuHelperPlus:GetNode(nil, self.NodeName)
    node:clean_items()
    
    MenuHelperPlus:AddButton({
        id = "BackToStart",
        title = "Back to Shortcuts",
        callback = "BeardLibScriptStart",
        node = node,
        localized = false
    })
    
    MenuHelperPlus:AddButton({
        id = "Cancel",
        title = "Cancel",
        callback = "BeardLibFolderClick",
        node = node,
        localized = false,
        merge_data = {
            base_path = self.current_script_path
        }
    })
    
    MenuHelperPlus:AddDivider({
        id = "fileDivider",
        node = node,
        size = 15
    })
    
    --log(self.current_selected_file_path)
    
    if self.path_text then
        self.path_text:set_visible(true)
        self.path_text:set_text(self.current_selected_file_path)
        local x, y, w, h = self.path_text:text_rect()
        self.path_text:set_size(w, h)
        self.path_text:set_position(0, 0)
    end
    
    local file_parts = string.split(self.current_selected_file, "%.")
    local extension = file_parts[#file_parts]
    local selected_from = 1
    for i, typ in pairs(self.script_file_from_types) do
        if typ.name == extension then
            selected_from = i
            break
        end
    end
    
    MenuHelperPlus:AddMultipleChoice({
        id = "convertfrom",
        title = "from",
        node = node,
        value = selected_from,
        items = BeardLib:GetSubValues(self.script_file_from_types, "name"),
        localized = false,
        localized_items = false,
        enabled = not self.assets
    })
    
    MenuHelperPlus:AddMultipleChoice({
        id = "convertto",
        title = "to",
        node = node,
        items = BeardLib:GetSubValues(self.script_file_to_types, "name"),
        localized = false,
        localized_items = false
    })
    
    MenuHelperPlus:AddButton({
        id = "convert",
        title = "convert",
        callback = "BeardLibConvertClick",
        node = node,
        localized = false
    })
    
    managers.menu:add_back_button(node)
    
    BeardLib:RefreshCurrentNode()
end

function ScriptDataConveterManager:CreateRootItems()
    local node = MenuHelperPlus:GetNode(nil, self.NodeName)
    node:clean_items()
    
    for i, path_data in pairs(self.script_data_paths) do
        MenuHelperPlus:AddButton({
            id = "BeardLibPath" .. path_data.name,
            title = path_data.name,
            callback = "BeardLibFolderClick",
            node = node,
            localized = false,
            merge_data = {
                base_path = path_data.path,
                assets = path_data.assets
            }
        })
    end
    
    managers.menu:add_back_button(node)
end

function ScriptDataConveterManager:BuildNode(main_node)
    MenuCallbackHandler.BeardLibScriptDataMenuBack = function(this, item)
        self:CreateRootItems()
        self.current_script_path = ""
        if self.path_text then
            self.path_text:set_visible(false)
        end
    end

    MenuCallbackHandler.BeardLibFolderClick = function(this, item)
        self.current_script_path = item._parameters.base_path or ""
        
        if item._parameters.assets ~= nil then
            self.assets = item._parameters.assets
        end
        
        self:RefreshFilesAndFolders()
    end
    
    MenuCallbackHandler.BeardLibFileClick = function(this, item)
        self.current_selected_file = item._parameters.text_id
        self.current_selected_file_path = item._parameters.base_path
        
        self:CreateScriptDataFileOption()
    end
    
    MenuCallbackHandler.BeardLibScriptStart = function(this, item)
        local gui_class = managers.menu:active_menu().renderer:active_node_gui()
        local path_text = gui_class.safe_rect_panel:child("BeardLibPathText")
        
        if path_text then
            gui_class.safe_rect_panel:remove(path_text)
        end
        
        local node = MenuHelperPlus:GetNode(nil, self.NodeName)
        node:clean_items()
    
        self.current_script_path = ""
        self:CreateRootItems()
        
        if self.path_text then
            self.path_text:set_visible(false)
        end
        
        BeardLib:RefreshCurrentNode()
    end
    
    MenuCallbackHandler.BeardLibConvertClick = function(this, item)
        local node = MenuHelperPlus:GetNode(nil, self.NodeName)
        
        local convertfrom_item = node:item("convertfrom")
        local convertto_item = node:item("convertto")
        
        if convertfrom_item and convertto_item then
            self:ConvertFile(self.current_selected_file_path, convertfrom_item:value(), convertto_item:value(), true)
        end
    end
    
    MenuCallbackHandler.BeardLibOpenInExplorer = function(this, item)
        local open_path = string.gsub(self.current_script_path, "%./", "")
        open_path = string.gsub(self.current_script_path, "/", "\\")
        
        os.execute('start "" "' .. open_path .. '"')
    end
    
    local node = MenuHelperPlus:NewNode(nil, {
        name = self.NodeName,
        back_callback = "BeardLibScriptDataMenuBack"
    })
        
    MenuHelperPlus:AddButton({
        id = "BeardLibScriptDataMenu",
        title = "BeardLibScriptDataMenu_title",
        node = main_node,
        next_node = self.NodeName,
    })
    
    self:CreateRootItems()
end