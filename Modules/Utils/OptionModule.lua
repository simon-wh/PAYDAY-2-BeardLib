OptionModule = OptionModule or BeardLib:ModuleClass("Options", ModuleBase)
OptionModule.auto_load = false

function OptionModule:init(...)
    self.required_params = table.add(clone(self.required_params), {"options"})
    if not OptionModule.super.init(self, ...) then
        return false
    end

    self.FileName = self._config.save_file or self._mod.Name .. "_Options.txt"

    self._storage = {}
    self._menu_items = {}

    if self._config.loaded_callback then
        self._on_load_callback = self._mod:StringToCallback(self._config.loaded_callback)
    end

    self._manual_save = NotNil(self._config.manual_save, false)

    if self._config.build_menu ~= nil then
        self._config.auto_build_menu = self._config.build_menu
    end

    if self._config.auto_build_menu == nil or self._config.auto_build_menu then
        self:BuildMenuHook()
    end

    if self._config.early_post_init then
        self:PostInit()
    end

    return true
end

function OptionModule:PostInit()
	if self._post_init_complete then
        return false
	end
	self:InitFirstOptions()
	OptionModule.super.PostInit(self)
end

function OptionModule:InitFirstOptions()
	if self._options_init then
		return
	end

    self:InitOptions(self._config.options, self._storage)

    if self._config.auto_load == nil or self._config.auto_load then
        self:Load()
    end

	self._options_init = true
end

function OptionModule:OnValueChanged(full_name, value)
	if not self._config.value_changed then
		return
	end
	if not self._value_changed then
		self._value_changed = self._mod:StringToCallback(self._config.value_changed)
	end
	if self._value_changed then
		self._value_changed(full_name, value)
	end
end

function OptionModule:Load()
    if not FileIO:Exists(self._mod.SavePath .. self.FileName) then
        --Save the Options file with the current option values
        self:Save()
        return
    end

    local file = io.open(self._mod.SavePath .. self.FileName, 'r')

    --pcall for json decoding
    local ret, data = pcall(function() return json.custom_decode(file:read("*all")) end)

    if not ret then
        self:Err("Unable to load save file for mod %s", self._mod.Name)
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
    if tbl._meta == "option_set" and tbl.not_pre_generated then
        for key, value in pairs(value_tbl) do
            local new_tbl = BeardLib.Utils:RemoveAllNumberIndexes(tbl.item_parameters and deep_clone(tbl.item_parameters) or {})
            new_tbl._meta = "option"
            new_tbl.name = key
            new_tbl.value = value
            tbl[key] = new_tbl
        end
        return
    end

    for i, sub_tbl in pairs(tbl) do
        if type(sub_tbl) == "table" and sub_tbl._meta then
            if sub_tbl._meta == "option" and value_tbl[sub_tbl.name] ~= nil then
                local value = value_tbl[sub_tbl.name]
                if sub_tbl.type == "multichoice" then
                    if sub_tbl.save_value then
                        local index = table.index_of(sub_tbl.values, value)
                        value = index ~= -1 and index or self:GetOptionDefaultValue(sub_tbl)
                    elseif not sub_tbl.use_value then
                        if value > #sub_tbl.values then
                            value = self:GetOptionDefaultValue(sub_tbl)
                        end
                    end
                end
                sub_tbl.value = value
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
                    sub_tbl.values = sub_tbl.values_tbl and self._mod:StringToValue(sub_tbl.values_tbl) or BeardLib.Utils:RemoveNonNumberIndexes(sub_tbl.values)
                end

                if sub_tbl.value_changed then
                    sub_tbl.value_changed = self._mod:StringToCallback(sub_tbl.value_changed)
                end

                if sub_tbl.converter then
                    sub_tbl.converter = self._mod:StringToCallback(sub_tbl.converter)
                end

                if sub_tbl.enabled_callback then
                    sub_tbl.enabled_callback = self._mod:StringToCallback(sub_tbl.enabled_callback)
                end
                local default_value = self:GetOptionDefaultValue(sub_tbl)
                option_tbl[sub_tbl.name] = sub_tbl
                option_tbl[sub_tbl.name].value = default_value
            elseif sub_tbl._meta == "option_group" then
                option_tbl[sub_tbl.name] = BeardLib.Utils:RemoveAllSubTables(clone(sub_tbl))
                self:InitOptions(sub_tbl, option_tbl[sub_tbl.name])
            elseif sub_tbl._meta == "option_set" then
                if not sub_tbl.not_pre_generated then
                    local tbl = sub_tbl.items and BeardLib.Utils:RemoveNonNumberIndexes(sub_tbl.items)
                    if sub_tbl.items_tbl then
                        tbl = self._mod:StringToValue(sub_tbl.values_tbl)
                    elseif sub_tbl.populate_items then
                        local clbk = self._mod:StringToCallback(sub_tbl.populate_items)
                        tbl = assert(clbk, string.format("Could not find a populate items function %s", tostring(sub_tbl.populate_items)))()
                    end

                    for _, item in pairs(tbl) do
                        local new_tbl = BeardLib.Utils:RemoveAllNumberIndexes(deep_clone(sub_tbl.item_parameters))
                        new_tbl._meta = "option"
                        table.insert(sub_tbl, table.merge(new_tbl, item))
                    end
                end
                option_tbl[sub_tbl.name] = BeardLib.Utils:RemoveAllSubTables(clone(sub_tbl))
                self:InitOptions(sub_tbl, option_tbl[sub_tbl.name])
            end
        end
    end
end

--Only for use by the SetValue function
function OptionModule:_SetValue(tbl, name, value, full_name)
    if tbl.type == "table" then
        tbl.value[name] = value
        if tbl.value_changed then
            tbl.value_changed(full_name, value)
		end
		self:OnValueChanged(full_name, value)
    else
        if tbl[name] == nil then
            BeardLib:log(string.format("[ERROR] Option of name %q does not exist in mod, %s", name, self._mod.Name))
            return
        end
        tbl[name].value = value

        if tbl[name].value_changed then
            tbl[name].value_changed(full_name, value)
		end
		self:OnValueChanged(full_name, value)
    end
end

OptionModule.Set = OptionModule.SetValue

function OptionModule:SetValue(name, value)
    local tbl = self._storage
    if string.find(name, "/") then
        local string_split = string.split(name, "/")

        local option_name = table.remove(string_split)

        for _, part in pairs(string_split) do
            if tbl[part] == nil then
                BeardLib:log(string.format("[ERROR] Option Group of name %q does not exist in mod, %s", name, self._mod.Name))
                return
            end
            tbl = tbl[part]
        end

        self:_SetValue(tbl, option_name, value, name)
    else
        self:_SetValue(tbl, name, value, name)
    end

    if not self._manual_save then
        self:Save()
    end
end

function OptionModule:GetOption(name)
    if string.find(name, "/") then
        local string_split = string.split(name, "/")

        local option_name = table.remove(string_split)

        local tbl = self._storage
        for _, part in pairs(string_split) do
            if tbl[part] == nil then
                if tbl.type ~= "table" then
                    BeardLib:log(string.format("[ERROR] Option of name %q does not exist in mod, %s", name, self._mod.Name))
                end
                return
            end
            tbl = tbl[part]
        end

        return tbl[option_name]
    elseif name == "" then
        return self._storage
    else
        return self._storage[name]
    end
end

-- Short variant
OptionModule.Get = OptionModule.GetValue

function OptionModule:GetValue(name, converted)
    local option = self:GetOption(name)
    if option then
        if converted then
            if option.converter then
                return option.converter(option, option.value)
            elseif option.type == "multichoice" and not option.use_value then
                if type(option.values[option.value]) == "table" then
                    return option.values[option.value].value
                else
                    return option.values[option.value]
                end
            end
        end
        return (type(option) ~= "table" and option) or option.value
    else
        return nil
    end
end

function OptionModule:LoadDefaultValues()
    self:_LoadDefaultValues(self._storage)
end

function OptionModule:_LoadDefaultValues(option_tbl)
    for i, sub_tbl in pairs(option_tbl) do
        if sub_tbl._meta then
            if sub_tbl._meta == "option" then
                option_tbl[sub_tbl.name].value = self:GetOptionDefaultValue(sub_tbl)
            elseif sub_tbl._meta == "option_group" or sub_tbl._meta == "option_set" then
                self:_LoadDefaultValues(option_tbl[sub_tbl.name])
            end
        end
    end
end

function OptionModule:GetDefaultValue(path)
    return self:GetOptionDefaultValue(self:GetOption(path))
end

function OptionModule:GetOptionDefaultValue(option)
    if not option then
        return nil
    end
    local default_value = option.default_value
    if option.type == "table" and default_value == nil then
        return {}
    elseif type(default_value) == "table" then
        default_value._meta = nil
    end

    default_value = type(default_value) == "string" and BeardLib.Utils:normalize_string_value(default_value) or default_value

    return default_value
end

function OptionModule:ResetToDefaultValues(path, shallow, no_save)
    local option_tbl = self:GetOption(path)
    if option_tbl then
        local next_path = path == "" and "" or path .. "/"
        for i, sub_tbl in pairs(option_tbl) do
            if type(sub_tbl) == "table" and sub_tbl._meta then
                if sub_tbl._meta == "option" then
                    local default_value = self:GetOptionDefaultValue(sub_tbl)
                    local sub_tbl_path = next_path..sub_tbl.name
                    if type(sub_tbl.default_value) == "table" then
                        sub_tbl.default_value._meta = nil
                    end
                    self:SetValue(sub_tbl_path, default_value)
                    local item = self._menu_items[sub_tbl_path]
                    if item then
                        local value = self:GetValue(sub_tbl_path)
                        if item.TYPE == "toggle" then
                            item:set_value(value and "on" or "off")
                        else
                            item:set_value(value)
                        end
                    end
                elseif (sub_tbl._meta == "option_group" or sub_tbl._meta == "option_set") and not shallow then
                    self:ResetToDefaultValues(next_path..sub_tbl.name, no_save, true)
                end
            end
        end
        if not no_save then
            self:Save()
        end
    end
end

function OptionModule:PopulateSaveTable(tbl, save_tbl)
    for i, sub_tbl in pairs(tbl) do
        if type(sub_tbl) == "table" and sub_tbl._meta then
            if sub_tbl._meta == "option" then
                local value = sub_tbl.value
                if sub_tbl.type=="multichoice" and sub_tbl.save_value then
                    if type(sub_tbl.values[sub_tbl.value]) == "table" then
                        value = sub_tbl.values[sub_tbl.value].value
                    else
                        value = sub_tbl.values[sub_tbl.value]
                    end
                end
                save_tbl[sub_tbl.name] = value
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
	file:write(json.custom_encode(save_data))
	file:close()
end

function OptionModule:GetParameter(tbl, i)
    if tbl[i] ~= nil then
        if type(tbl[i]) == "function" then
            return tbl[i]()
        else
            return tbl[i]
        end
    end

    return nil
end

function OptionModule:GetOptionMenuID(option_tbl)
    return (self._config.prefix_id or self._mod.Name) .. option_tbl.name
end

function OptionModule:CreateItem(type_name, parent_node, option_tbl, option_path, params)
    local id = self:GetOptionMenuID(option_tbl)

    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name

    local enabled = not self:GetParameter(option_tbl, "disabled")
    if option_tbl.enabled_callback then
        enabled = option_tbl:enabled_callback()
    end

    local merge_data = BeardLib.Utils:RemoveAllNumberIndexes(self:GetParameter(option_tbl, "merge_data") or {})
    params = table.merge(
        table.merge({
            id = self:GetParameter(option_tbl, "name"),
            title = self:GetParameter(option_tbl, "title_id") or id .. "TitleID",
            desc = self:GetParameter(option_tbl, "desc_id") or id .. "DescID",
            node = parent_node,
            enabled = enabled,
            mod = self._mod,
            callback = "OptionModuleGeneric_ValueChanged",
            value = self:GetValue(option_path),
            show_value = self:GetParameter(option_tbl, "show_value"),
            merge_data = {option_key = option_path, module = self},
        }, params)
    , merge_data)

    self._menu_items[option_path] = MenuHelperPlus["Add"..type_name](MenuHelperPlus, params)
end

function OptionModule:CreateSlider(parent_node, option_tbl, option_path)
    self:CreateItem("Slider", parent_node, option_tbl, option_path, {
        min = self:GetParameter(option_tbl, "min"),
        max = self:GetParameter(option_tbl, "max"),
        step = self:GetParameter(option_tbl, "step"),
        decimal_count = self:GetParameter(option_tbl, "decimal_count"),
    })
end

function OptionModule:CreateInput(...)
    self:CreateItem("Input", ...)
end

function OptionModule:CreateToggle(...)
    self:CreateItem("Toggle", ...)
end

function OptionModule:CreateMultiChoice(parent_node, option_tbl, option_path)
    local options = self:GetParameter(option_tbl, "values")
    if not options then
        self:Err("Unable to get an option table for option " .. option_tbl.name)
    end
    self:CreateItem("MultipleChoice", parent_node, option_tbl, option_path, {
        items = options,
        use_value = self:GetParameter(option_tbl, "use_value"),
        localized_items = self:GetParameter(option_tbl, "localized_items"),
    })
end

function OptionModule:CreateMatrix(parent_node, option_tbl, option_path, components)
    local id = self:GetOptionMenuID(option_tbl)

    option_path = option_path == "" and option_tbl.name or option_path .. "/" .. option_tbl.name

    local enabled = not self:GetParameter(option_tbl, "disabled")

    if option_tbl.enabled_callback then
        enabled = option_tbl:enabled_callback()
    end
    local scale_factor = self:GetParameter(option_tbl, "scale_factor") or 1

    local self_vars = {
        option_key = option_path,
        module = self,
        scale_factor = scale_factor,
        opt_type = option_tbl.type
    }

    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = BeardLib.Utils:RemoveAllNumberIndexes(merge_data)
    local base_params = table.merge({
        id = self:GetParameter(option_tbl, "name"),
        title = managers.localization:text(self:GetParameter(option_tbl, "title_id") or id .. "TitleID"),
        node = parent_node,
        mod = self._mod,
        desc = managers.localization:text(self:GetParameter(option_tbl, "desc_id") or id .. "DescID"),
        callback = "OptionModuleVector_ValueChanged",
        min = self:GetParameter(option_tbl, "min") or 0,
        max = self:GetParameter(option_tbl, "max") or scale_factor,
        step = self:GetParameter(option_tbl, "step") or (scale_factor > 1 and 1 or 0.01),
        enabled = enabled,
        show_value = self:GetParameter(option_tbl, "show_value"),
        localized = false,
        localized_help = false,
        merge_data = self_vars
    }, merge_data)
    local value = self:GetValue(option_path)
    local GetComponentValue = function(val, component)
        return type(val[component]) == "function" and val[component](val) or val[component]
    end

    for _, vec in pairs(components) do
        local params = clone(base_params)
        params.id = params.id .. "-" .. vec.id
        params.title = params.title .. " - " .. vec.title
        params.desc = params.desc .. " - " .. vec.title
        params.merge_data.component = vec.id
        params.mod = self._mod
        if vec.max then
            params.max = vec.max
        end
        params.value = GetComponentValue(value, vec.id) * scale_factor
        MenuHelperPlus:AddSlider(params)
    end
end

function OptionModule:CreateColour(...)
    self:CreateItem("ColorButton", ...)
end

function OptionModule:CreateVector(parent_node, option_tbl, option_path)
    self:CreateMatrix(parent_node, option_tbl, option_path, { {id="x", title="X"}, {id="y", title="Y"}, {id="z", title="Z"} })
end

function OptionModule:CreateRotation(parent_node, option_tbl, option_path)
    self:CreateMatrix(parent_node, option_tbl, option_path, { {id="yaw", title="YAW"}, {id="pitch", title="PITCH"}, {id="roll", title="ROLL", max=90} })
end

function OptionModule:CreateOption(parent_node, option_tbl, option_path)
    local switch = {
        number = "Slider",
        string = "Input",
        bool = "Toggle",
        boolean = "Toggle",
        multichoice = "MultiChoice",
        color = "Colour",
        colour = "Colour",
        vector = "Vector",
        rotation = "Rotation",
    }

    if switch[option_tbl.type] then
        self["Create"..switch[option_tbl.type]](self, parent_node, option_tbl, option_path)
    else
        self:Err("No supported type for option " .. tostring(option_tbl.name) .. " in mod " .. self._mod.Name)
    end
end

function OptionModule:CreateDivider(parent_node, tbl)
    local merge_data = self:GetParameter(tbl, "merge_data") or {}
    merge_data = BeardLib.Utils:RemoveAllNumberIndexes(merge_data)
    MenuHelperPlus:AddDivider(table.merge({
        id = self:GetParameter(tbl, "name"),
        node = parent_node,
        mod = self._mod,
        size = self:GetParameter(tbl, "size")
    }, merge_data))
end

function OptionModule:CreateButton(parent_node, option_tbl, option_path)
    local clbk = self:GetParameter(option_tbl, "clicked")
    self:CreateItem("Button", parent_node, option_tbl, option_path, {
        merge_data = {
            callback = self:GetParameter(option_tbl, "reset_button") and "OptionModuleGeneric_ResetOptions" or "OptionModuleGeneric_ButtonPressed",
            option_path = option_path,
            shallow_reset = self:GetParameter(option_tbl, "shallow_reset"),
            clicked = clbk and self._mod:StringToCallback(clbk) or nil
        }
    })
end

function OptionModule:CreateSubMenu(parent_node, option_tbl, option_path)
    option_path = option_path or ""
    local name = self:GetParameter(option_tbl, "name")
    local prefix = self._config.prefix_id or self._mod.Name
    local base_name = name and prefix .. name .. self._name or prefix .. self._name
    local menu_name = self:GetParameter(option_tbl, "node_name") or  base_name .. "Node"

    local merge_data = self:GetParameter(option_tbl, "merge_data") or {}
    merge_data = BeardLib.Utils:RemoveAllNumberIndexes(merge_data)
    local main_node = MenuHelperPlus:NewNode(nil, table.merge({
        name = menu_name
    }, merge_data))

    if option_tbl.build_items == nil or option_tbl.build_items then
        self:InitializeNode(main_node, option_tbl, name and (option_path == "" and name or option_path .. "/" .. name) or "")
    end

    MenuHelperPlus:AddButton({
        id = base_name .. "Button",
        title = self:GetParameter(option_tbl, "title_id") or base_name .. "ButtonTitleID",
        desc = self:GetParameter(option_tbl, "desc_id") or base_name .. "ButtonDescID",
        node = parent_node,
        mod = self._mod,
        next_node = menu_name
    })

    managers.menu:add_back_button(main_node)
end

function OptionModule:InitializeNode(node, option_tbl, option_path)
    option_tbl = option_tbl or self._config.options
    option_path = option_path or ""
    for i, sub_tbl in ipairs(option_tbl) do
        if sub_tbl._meta then
            if sub_tbl._meta == "option" and not sub_tbl.hidden then
                self:CreateOption(node, sub_tbl, option_path)
            elseif sub_tbl._meta == "divider" then
                self:CreateDivider(node, sub_tbl)
            elseif sub_tbl._meta == "button" then
                self:CreateButton(node, sub_tbl, option_path)
            elseif sub_tbl._meta == "option_group" or sub_tbl._meta == "option_set" and (sub_tbl.build_menu == nil or sub_tbl.build_menu) then
                self:CreateSubMenu(node, sub_tbl, option_path)
            end
        end
    end
end

function OptionModule:BuildMenuHook()
    Hooks:Add("MenuManagerSetupCustomMenus", self._mod.Name .. "Build" .. self._name .. "Menu", function(self_menu, nodes)
        self:BuildMenu(nodes.lua_mod_options_menu or nodes.blt_options)
    end)
end

function OptionModule:BuildMenu(node)
    self:CreateSubMenu(node, self._config.options)
end

--Create MenuCallbackHandler callbacks
Hooks:Add("BeardLibCreateCustomNodesAndButtons", "BeardLibOptionModuleCreateCallbacks", function(self_menu)
    function MenuCallbackHandler:OptionModuleGeneric_ButtonPressed(item)
        if item._parameters.clicked then
            item._parameters.clicked(item)
        end
    end

    function MenuCallbackHandler:OptionModuleGeneric_ResetOptions(item)
        local params = item._parameters
        if params then
            params.module:ResetToDefaultValues(params.option_path, params.shallow_reset)
        end
    end

    function MenuCallbackHandler:OptionModuleGeneric_ValueChanged(item)
        local value = item:value()
        if item.TYPE == "toggle" then value = value == "on" end
        OptionModule.SetValue(item._parameters.module, item._parameters.option_key, value)
    end

    function MenuCallbackHandler:OptionModuleVector_ValueChanged(item)
        local cur_val = OptionModule.GetValue(item._parameters.module, item._parameters.option_key)
        local new_value = item:value() / item._parameters.scale_factor
        if item._parameters.opt_type == "colour" or item._parameters.opt_type == "color" then
            cur_val[item._parameters.component] = new_value
        elseif item._parameters.opt_type == "vector" then
            if item._parameters.component == "x" then
                mvector3.set_x(cur_val, new_value)
            elseif item._parameters.component == "y" then
                mvector3.set_y(cur_val, new_value)
            elseif item._parameters.component == "z" then
                mvector3.set_z(cur_val, new_value)
            end
        elseif item._parameters.opt_type == "rotation" then
            local comp = item._parameters.component
            mrotation.set_yaw_pitch_roll(cur_val, comp == "yaw" and new_value or cur_val:yaw(), comp == "pitch" and new_value or cur_val:pitch(), comp == "roll" and new_value or cur_val:roll())
        end

        OptionModule.SetValue(item._parameters.module, item._parameters.option_key, cur_val)
    end
end)