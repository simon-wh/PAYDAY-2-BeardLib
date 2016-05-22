OptionModule = OptionModule or class(ModuleBase)

--Need a better name for this
OptionModule.type_name = "Options"

function OptionModule:init(core_mod, config)
    self.super.init(self, core_mod, config)

    self.FileName = self._config.save_file or self._mod.Name .. "_Options.txt"

    self._storage = {}

    self._name = config.name or self.type_name

    if not self._config.options then
        BeardLib:log(string.format("[ERROR] Mod: %s, must contain an options table for the OptionModule", self._mod.Name))
        return
    end

    if self._config.loaded_callback then
        self._on_load_callback = self._mod:StringToCallback(self._config.loaded_callback)
    end

    self:InitOptions(self._config.options, self._storage)

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
    local ret, data = pcall(function() return json.decode(file:read("*all")) end)

    if not ret then
        BeardLib:log("[ERROR] Unable to load save file for mod, " .. self._mod.Name)
        BeardLib:log(tostring(data))

        --Save the corrupted file incase the option values should be recovered
        local corrupted_file = io.open(self._mod.SavePath .. self.FileName .. "_corrupted", "w+")
        corrupted_file:write(file:read("*all"))

        corrupted_file:close()

        --Save the Options file with the current option values
        self:Save()
        return
    end

    --Close the file handle
    file:close()

    --Merge the loaded options with the existing options
    self:ApplyValues(self._storage, data)

    if self._on_load_callback then
        self._on_load_callback()
    end
end

function OptionModule:ApplyValues(tbl, value_tbl)
    for i, sub_tbl in pairs(tbl) do
        if sub_tbl._meta then
            if sub_tbl._meta == "option" and value_tbl[sub_tbl.name] ~= nil then
                sub_tbl.value = value_tbl[sub_tbl.name]
            elseif (sub_tbl._meta == "option_group" or sub_tbl._meta == "option_set") and value_tbl[sub_tbl.name] then
                self:ApplyValues(sub_tbl, value_tbl[sub_tbl.name])
            end
        end
    end
end



function OptionModule:InitOptions(tbl, option_tbl)
    for i, sub_tbl in ipairs(tbl) do
        if sub_tbl._meta then
            if sub_tbl._meta == "option" then
                if sub_tbl.type == "multichoice" then
                    sub_tbl.values = sub_tbl.values_tbl and self._mod:StringToTable(sub_tbl.values_tbl) or BeardLib.Utils:RemoveNonNumberIndexes(sub_tbl.values)
                end

                if sub_tbl.value_changed then
                    sub_tbl.value_changed = self._mod:StringToCallback(sub_tbl.value_changed)
                end

                if sub_tbl.enabled_callback then
                    sub_tbl.enabled_callback = self._mod:StringToCallback(sub_tbl.enabled_callback)
                end

                option_tbl[sub_tbl.name] = sub_tbl
                option_tbl[sub_tbl.name].value = sub_tbl.default_value
            elseif sub_tbl._meta == "option_group" then
                option_tbl[sub_tbl.name] = BeardLib.Utils:RemoveAllSubTables(clone(sub_tbl))
                self:InitOptions(sub_tbl, option_tbl[sub_tbl.name])
            elseif sub_tbl._meta == "option_set" then
                local tbl = sub_tbl.items and BeardLib.Utils:RemoveNonNumberIndexes(sub_tbl.items)
                if sub_tbl.items_tbl then
                    tbl = self._mod:StringToTable(sub_tbl.values_tbl)
                elseif sub_tbl.populate_items then
                    local clbk = self._mod:StringToCallback(sub_tbl.populate_items)
                    tbl = assert(clbk)()
                end

                for _, item in pairs(tbl) do
                    local new_tbl = BeardLib.Utils:RemoveAllNumberIndexes(deep_clone(sub_tbl.item_parameters))
                    new_tbl._meta = "option"
                    table.insert(sub_tbl, table.merge(new_tbl, item))
                end

                option_tbl[sub_tbl.name] = BeardLib.Utils:RemoveAllSubTables(clone(sub_tbl))
                self:InitOptions(sub_tbl, option_tbl[sub_tbl.name])
            end
        end
    end
end

--Only for use by the SetValue function
function OptionModule:_SetValue(tbl, name, value, full_name)
    if tbl[name] == nil then
        BeardLib:log(string.format("[ERROR] Option of name %q does not exist in mod, %s", name, self._mod.Name))
        return
    end
    tbl[name].value = value

    if tbl[name].value_changed then
        tbl[name].value_changed(full_name, value)
    end
end

function OptionModule:SetValue(name, value)
    if string.find(name, "/") then
        local string_split = string.split(name, "/")

        local option_name = table.remove(string_split)

        local tbl = self._storage
        for _, part in pairs(string_split) do
            if tbl[part] == nil then
                BeardLib:log(string.format("[ERROR] Option Group of name %q does not exist in mod, %s", name, self._mod.Name))
                return
            end
            tbl = tbl[part]
        end

        self:_SetValue(tbl, option_name, value, name)
    else
        self:_SetValue(self._storage, name, value, name)
    end

    self:Save()
end

function OptionModule:GetOption(name)
    if string.find(name, "/") then
        local string_split = string.split(name, "/")

        local option_name = table.remove(string_split)

        local tbl = self._storage
        for _, part in pairs(string_split) do
            if tbl[part] == nil then
                BeardLib:log(string.format("[ERROR] Option Group of name %q does not exist in mod, %s", name, self._mod.Name))
                return
            end
            tbl = tbl[part]
        end

        return tbl[option_name]
    else
        return self._storage[name]
    end
end

function OptionModule:GetValue(name, real)
    local option = self:GetOption(name)
    if option then
        if real and option.type == "multichoice" then
            return option.values[option.value]
        else
            return option.value
        end
    else
        return
    end

    return option.value
end

function OptionModule:LoadDefaultValues()
    self:_LoadDefaultValues(self._storage)
end

function OptionModule:_LoadDefaultValues(option_tbl)
    for i, sub_tbl in pairs(option_tbl) do
        if sub_tbl._meta then
            if sub_tbl._meta == "option" then
                option_tbl[sub_tbl.name].value = sub_tbl.default_value
            elseif sub_tbl._meta == "option_group" or sub_tbl._meta == "option_set" then
                self:_LoadDefaultValues(option_tbl[sub_tbl.name])
            end
        end
    end
end

function OptionModule:PopulateSaveTable(tbl, save_tbl)
    for i, sub_tbl in pairs(tbl) do
        if sub_tbl._meta then
            if sub_tbl._meta == "option" then
                save_tbl[sub_tbl.name] = sub_tbl.value
            elseif sub_tbl._meta == "option_group" or sub_tbl._meta == "option_set" then
                save_tbl[sub_tbl.name] = {}
                self:PopulateSaveTable(sub_tbl, save_tbl[sub_tbl.name])
            end
        end
    end
end

function OptionModule:Save()
    local file = io.open(self._mod.SavePath .. self.FileName, "w+")
    local save_data = {}
    self:PopulateSaveTable(self._storage, save_data)
	file:write(json.encode(save_data))
	file:close()
end

function OptionModule:GetParameter(tbl, i)
    if tbl[i] then
        if type(tbl[i]) == "function" then
            return tbl[i]()
        else
            return tbl[i]
        end
    end

    return nil
end

function OptionModule:CreateSlider(option_tbl, parent_node, option_path)
    local id = self._mod.Name .. option_tbl.name

    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name

    local enabled = not self:GetParameter(option_tbl, "disabled")

    if option_tbl.enabled_callback then
        enabled = option_tbl:enabled_callback()
    end

    local self_vars = {
        option_key = option_path,
        module = self
    }

    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = BeardLib.Utils:RemoveAllNumberIndexes(merge_data)

    MenuHelperPlus:AddSlider(table.merge({
        id = self:GetParameter(option_tbl, "name"),
        title = self:GetParameter(option_tbl, "title_id") or id .. "TitleID",
        node = parent_node,
        desc = self:GetParameter(option_tbl, "desc_id") or id .. "DescID",
        callback = "OptionModuleGeneric_ValueChanged",
        min = self:GetParameter(option_tbl, "min"),
        max = self:GetParameter(option_tbl, "max"),
        step = self:GetParameter(option_tbl, "step"),
        enabled = enabled,
        value = self:GetValue(option_path),
        show_value = self:GetParameter(option_tbl, "show_value"),
        merge_data = self_vars
    }, merge_data))
end

function OptionModule:CreateToggle(option_tbl, parent_node, option_path)
    local id = self._mod.Name .. option_tbl.name

    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name

    local enabled = not self:GetParameter(option_tbl, "disabled")

    if option_tbl.enabled_callback then
        enabled = option_tbl:enabled_callback()
    end

    local self_vars = {
        option_key = option_path,
        module = self
    }

    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = BeardLib.Utils:RemoveAllNumberIndexes(merge_data)

    MenuHelperPlus:AddToggle(table.merge({
        id = self:GetParameter(option_tbl, "name"),
        title = self:GetParameter(option_tbl, "title_id") or id .. "TitleID",
        node = parent_node,
        desc = self:GetParameter(option_tbl, "desc_id") or id .. "DescID",
        callback = "OptionModuleGeneric_ValueChanged",
        value = self:GetValue(option_path),
        enabled = enabled,
        merge_data = self_vars
    }, merge_data))
end

function OptionModule:CreateMultiChoice(option_tbl, parent_node, option_path)
    local id = self._mod.Name .. option_tbl.name

    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name

    local options = self:GetParameter(option_tbl, "values")

    if not options then
        BeardLib:log("[ERROR] Unable to get an option table for option " .. option_tbl.name)
    end

    local enabled = not self:GetParameter(option_tbl, "disabled")

    if option_tbl.enabled_callback then
        enabled = option_tbl:enabled_callback()
    end

    local self_vars = {
        option_key = option_path,
        module = self
    }

    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = BeardLib.Utils:RemoveAllNumberIndexes(merge_data)

    MenuHelperPlus:AddMultipleChoice(table.merge({
        id = self:GetParameter(option_tbl, "name"),
        title = self:GetParameter(option_tbl, "title_id") or id .. "TitleID",
        node = parent_node,
        desc = self:GetParameter(option_tbl, "desc_id") or id .. "DescID",
        callback = "OptionModuleGeneric_ValueChanged",
        value = self:GetValue(option_path),
        items = options,
        localized_items = self:GetParameter(option_tbl, "localized_items"),
        enabled = enabled,
        merge_data = self_vars
    }, merge_data))
end

function OptionModule:CreateOption(option_tbl, parent_node, option_path)
    if option_tbl.type == "number" then
        self:CreateSlider(option_tbl, parent_node, option_path)
    elseif option_tbl.type == "bool" or option_tbl.type == "boolean" then
        self:CreateToggle(option_tbl, parent_node, option_path)
    elseif option_tbl.type == "multichoice" then
        self:CreateMultiChoice(option_tbl, parent_node, option_path)
    else
        BeardLib:log("[ERROR] No supported type for option " .. tostring(option_tbl.name) .. " in mod " .. self._mod.Name)
    end
end

function OptionModule:CreateDivider(parent_node, tbl)
    local merge_data = self:GetParameter(tbl, "merge_data") or {}
    merge_data = BeardLib.Utils:RemoveAllNumberIndexes(merge_data)
    MenuHelperPlus:AddDivider(table.merge({
        id = self:GetParameter(tbl, "name"),
        node = parent_node,
        size = self:GetParameter(tbl, "size")
    }, merge_data))
end

function OptionModule:CreateSubMenu(option_tbl, parent_node, option_path)
    local name = self:GetParameter(option_tbl, "name")
    local base_name = name .. self._name
    local menu_name = self:GetParameter(option_tbl, "node_name") or  base_name .. "Node"

    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = BeardLib.Utils:RemoveAllNumberIndexes(merge_data)
    local main_node = MenuHelperPlus:NewNode(nil, table.merge({
        name = menu_name
    }, merge_data))

    self:InitializeNode(option_tbl, main_node, option_path == "" and name or option_path .. "/" .. name)

    MenuHelperPlus:AddButton({
        id = base_name .. "Button",
        title = self:GetParameter(option_tbl, "title_id") or base_name .. "ButtonTitleID",
        desc = self:GetParameter(option_tbl, "desc_id") or base_name .. "ButtonDescID",
        node = parent_node,
        next_node = menu_name
    })

    managers.menu:add_back_button(main_node)
end

function OptionModule:InitializeNode(option_tbl, node, option_path)
    option_path = option_path or ""
    for i, sub_tbl in ipairs(option_tbl) do
        if sub_tbl._meta then
            if sub_tbl._meta == "option" and not sub_tbl.hidden then
                self:CreateOption(sub_tbl, node, option_path)
            elseif sub_tbl._meta == "divider" then
                self:CreateDivider(node, sub_tbl)
            elseif sub_tbl._meta == "option_group" or sub_tbl._meta == "option_set" then
                self:CreateSubMenu(sub_tbl, node, option_path)
            end
        end
    end
end

function OptionModule:BuildMenu()
    Hooks:Add("MenuManagerSetupCustomMenus", self._mod.Name .. "Build" .. self._name .. "Menu", function(self_menu)
        local base_name = self._mod.Name .. self._name
        self._menu_name = self:GetParameter(self._config.options, "node_name") or base_name .. "Node"
        local merge_data = self:GetParameter(self._config.options, "merge_data") or {}
        merge_data = BeardLib.Utils:RemoveAllNumberIndexes(merge_data)
        local main_node = MenuHelperPlus:NewNode(nil, table.merge({
            name = self._menu_name
        }, merge_data))

        self:InitializeNode(self._config.options, main_node)

        MenuHelperPlus:AddButton({
            id = base_name .. "Button",
            title = self:GetParameter(self._config.options, "title_id") or base_name .. "ButtonTitleID",
            node_name = LuaModManager.Constants._lua_mod_options_menu_id,
            next_node = self._menu_name
        })

        managers.menu:add_back_button(main_node)
    end)
end

--Create MenuCallbackHandler callbacks
Hooks:Add("BeardLibCreateCustomNodesAndButtons", "BeardLibOptionModuleCreateCallbacks", function(self_menu)
    MenuCallbackHandler.OptionModuleGeneric_ValueChanged = function(this, item)
        OptionModule.SetValue(item._parameters.module, item._parameters.option_key, item:value())
    end
end)
