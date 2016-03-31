OptionModule = OptionModule or class(ModuleBase)

--Need a better name for this
OptionModule.type_name = "OptionsManager"

function OptionModule:init(core_mod, config)
    self.super.init(self, core_mod, config)
    
    self.FileName = self._config.save_file or self._mod.Name .. "_Options.txt"
    
    self._option_key = self._config.global_key or "Options"
    
    self._mod[self._option_key] = {}
    
    if not self._config.options then
        BeardLib:log(string.format("[ERROR] Mod: %s, must contain an options table for the OptionModule", self._mod.Name))
        return
    end
    
    self:LoadDefaultValues()
    
    if self._config.build_menu then
        self:BuildMenu()
    end
    
    if self._config.auto_load then
        self:Load()
    end
end

function OptionModule:Load()
    if not io.file_is_readable(self._mod.SavePath .. self.FileName) then
        --Save the Options file with the current option values
        self:Save()
        return
    end
    
    local file = io.open(self._mod.SavePath .. self.FileName, 'r')
    
    --pcall for json decoding
    local ret, err = pcall(function() return json.decode(file:read("*all")) end)
    
    if not ret then
        BeardLib:log("[ERROR] Unable to load save file for mod, " .. self._mod.Name)
        BeardLib:log(tostring(err))
        
        --Save the corrupted file incase the option values should be recovered
        local corrupted_file = io.open(self._mod.SavePath .. self.FileName .. "_corrupted", "w+")
        corrupted_file:write(file:read("*all"))
        
        --Save the Options file with the current option values
        self:Save()
        return
    end
    
    --Close the file handle
    file:close()
    
    --Merge the loaded options with the existing options
    table.merge(self._mod[self._option_key], ret)
end

--Only for use by the SetValue function
function OptionModule:_SetValue(tbl, name, value)
    if tbl[name] == nil then
        BeardLib:log(string.format("[ERROR] Option of name %q does not exist in mod, %s", name, self._mod.Name))
        return
    end
    tbl[name] = value
end

function OptionModule:SetValue(name, value)
    if string.find(name, "/") then
        local string_split = string.split(name, "/")
        
        local option_name = table.remove(string_split)
        
        local tbl = self._mod[self._option_key]
        for _, part in pairs(string_split) do
            if tbl[part] == nil then
                BeardLib:log(string.format("[ERROR] Option Group of name %q does not exist in mod, %s", name, self._mod.Name))
                return
            end
            tbl = tbl[part]
        end
        
        self:_SetValue(tbl, option_name, value)
    else
        self:_SetValue(self._mod[self._option_key], name, value)
    end
    
    self:Save()
end

function OptionModule:GetValue(name)
    if string.find(name, "/") then
        local string_split = string.split(name, "/")
        
        local option_name = table.remove(string_split)
        
        local tbl = self._mod[self._option_key]
        for _, part in pairs(string_split) do
            if tbl[part] == nil then
                BeardLib:log(string.format("[ERROR] Option Group of name %q does not exist in mod, %s", name, self._mod.Name))
                return
            end
            tbl = tbl[part]
        end
        
        return tbl[option_name]
    else
        return self._mod[self._option_key][name]
    end
end

function OptionModule:LoadDefaultValues()
    self:_LoadDefaultValues(self._config.options, self._mod[self._option_key])
end

function OptionModule:_LoadDefaultValues(tbl, option_tbl)
    for i = 1, table.maxn(tbl) do
        local sub_tbl = tbl[i]
        
        if sub_tbl._meta then
            if sub_tbl._meta == "option" and sub_tbl.default_value ~= nil then
                tbl[sub_tbl.name] = sub_tbl.default_value
            elseif sub_tbl._meta == "option_group" then
                option_tbl[sub_tbl.name] = {}
                self:_LoadDefaultValues(sub_tbl, option_tbl[sub_tbl.name])
            end
            
        end
    end
end

function OptionModule:Save()
    local file = io.open(self.FileName, "w+")
	file:write(json.encode(self._mod[self._option_key]))
	file:close()
end

function OptionModule:StringToCallback(str)
    local split = string.split(str, ":")
    
    local func_name = table.remove(split)
    
    local global_tbl_name = split[1]
    if (string.find(global_tbl_name, "$")) then
        global_tbl_name = string.gsub(global_tbl_name, "%$(%w+)%$", { ["global"] = self._mod.GlobalKey })
    end
    
    local global_tbl = BeardLib.Utils:StringToTable(global_tbl_name)
    
    if global_tbl then
        return callback(global_tbl, global_tbl, func_name)
    else
        return nil
    end
end

function OptionModule:CreateSlider(option_tbl, parent_node, option_path)
    local id = option_tbl.name .. self._option_key .. "Slider"
    
    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name
    
    MenuHelperPlus:AddSlider({
        id = id,
        title = option_tbl.title_id or id .. "TitleID",
        node = parent_node,
        desc = option_tbl.desc_id or id .. "DescID",
        callback = "OptionModuleGeneric_ValueChanged",
        min = option_tbl.min,
        max = option_tbl.max,
        step = option_tbl.step,
        value = self:GetValue(option_path),
        merge_data = {
            set_value = callback(self, self, "SetValue"),
            get_value = callback(self, self, "GetValue"),
            option_key = option_path,
            option_value_changed = option_tbl.value_changed and self:StringToCallback(option_tbl.value_changed) or nil
        }
    })
end

function OptionModule:CreateToggle(option_tbl, parent_node, option_path)
    local id = option_tbl.name .. self._option_key .. "Toggle"
    
    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name
    
    MenuHelperPlus:AddToggle({
        id = id,
        title = option_tbl.title_id or id .. "TitleID",
        node = parent_node,
        desc = option_tbl.desc_id or id .. "DescID",
        callback = "OptionModuleGeneric_ValueChanged",
        value = self:GetValue(option_path),
        merge_data = {
            set_value = callback(self, self, "SetValue"),
            get_value = callback(self, self, "GetValue"),
            option_key = option_path,
            option_value_changed = option_tbl.value_changed and self:StringToCallback(option_tbl.value_changed) or nil
        }
    })
end

function OptionModule:CreateOption(option_tbl, parent_node, option_path)
    if option_tbl.type == "number" then
        self:CreateSlider(option_tbl, parent_node, option_path)
    elseif option_tbl.type == "bool" or option_tbl.type == "boolean" then
        self:CreateToggle(option_tbl, parent_node, option_path)
    else
        BeardLib:log("[ERROR] No supported type for option " .. tostring(option_tbl.name) .. " in mod " .. self._mod.Name)
    end
end

function OptionModule:CreateSubMenu(option_tbl, parent_node, option_path)
    local menu_name = option_tbl.node_name or option_tbl.name .. self._option_key .. "Node"

    local main_node = MenuHelperPlus:NewNode(nil, {
        name = menu_name
    })
    
    self:InitializeNode(option_tbl, main_node, option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name)
    
    MenuHelperPlus:AddButton({
        id = menu_name .. "Button",
        title = option_tbl.title_id or menu_name .. "ButtonTitleID",
        node_name = parent_node._paramaters.name,
        next_node = menu_name
    })
end

function OptionModule:InitializeNode(option_tbl, node, option_path)
    option_path = option_path or ""
    
    for i = 1, table.maxn(tbl) do
        local sub_tbl = tbl[i]
        if sub_tbl._meta then
            if sub_tbl._meta == "option" then
                self:CreateOption(sub_tbl, node, option_path)
            elseif sub_tbl._meta == "option_group" then
                self:CreateSubMenu(sub_tbl, node, option_path)
            end
        end
    end
end

function OptionModule:BuildMenu()
    Hooks:Add("BeardLibCreateCustomNodesAndButtons", self._mod.Name .. "Build" .. self._option_key .. "Menu", function(self_menu)
        self._menu_name = self._config.options.node_name or self._mod.Name .. self._option_key .. "Node"
        
        local main_node = MenuHelperPlus:NewNode(nil, {
            name = self._menu_name
        })
        
        self:InitializeNode(self._config.options, main_node)
        
        MenuHelperPlus:AddButton({
            id = self._menu_name .. "Button",
            title = self._config.options.title_id or self._menu_name .. "ButtonTitleID",
            node_name = LuaModManager.Constants._lua_mod_options_menu_id,
            next_node = self._menu_name,
        })
    end)
end

--Create MenuCallbackHandler callbacks
Hooks:Add("BeardLibCreateCustomNodesAndButtons", "BeardLibOptionModuleCreateCallbacks", function(self_menu)
    MenuCallbackHandler.OptionModuleGeneric_ValueChanged = function(this, item)
        item._paramaters:set_value(item._paramaters.option_key, item:value())
        
        if item._paramaters.option_value_changed then
            item._paramaters:option_value_changed(item._paramaters.option_key, item:value())
        end
    end

end)