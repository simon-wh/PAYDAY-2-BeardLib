EnvironmentEditorManager = EnvironmentEditorManager or class()

function EnvironmentEditorManager:init()
    self._handlers = {}
    self.NodeName = "EnvironmentEditorNode"
end

function EnvironmentEditorManager:BuildNode(main_node)
    MenuCallbackHandler.EnvironmentEditorExit = function(this, item)
        if BeardLib.path_text then
            BeardLib.path_text:set_visible(false)
        end
    end

    MenuHelperPlus:NewNode(nil, {
        name = self.NodeName,
        menu_components = managers.menu._is_start_menu and "player_profile menuscene_info news game_installing" or nil,
        back_callback = "EnvironmentEditorExit",
        merge_data = {
            area_bg = "half"
        }
    })
    
    MenuCallbackHandler.BeardLibOpenEnvMenu = function(this, item)
        self:PopulateEnvMenu()
    end
    
    MenuHelperPlus:AddButton({
        id = "BeardLibEnvMenu",
        title = "BeardLibEnvMenu",
        callback = "BeardLibOpenEnvMenu",
        node = main_node,
        next_node = self.NodeName,
    })
    
    MenuCallbackHandler.EnvEditorClbk = function(this, item)
        self:SetValue(self._active_environment, item._parameters.path_key, item:value(), item._parameters.path, true)
    end
    
    MenuCallbackHandler.EnvEditorVectorXClbk = function(this, item)
        self:SetValue(self._active_environment, item._parameters.path_key, item:value(), item._parameters.path, true, "x")
    end
    
    MenuCallbackHandler.EnvEditorVectorYClbk = function(this, item)
        self:SetValue(self._active_environment, item._parameters.path_key, item:value(), item._parameters.path, true, "y")
    end
    
    MenuCallbackHandler.EnvEditorVectorZClbk = function(this, item)
        self:SetValue(self._active_environment, item._parameters.path_key, item:value(), item._parameters.path, true, "z")
    end
    
    MenuCallbackHandler.EnvEditorStringClbk = function(this, item)
        local split = string.split(item._parameters.path, "/")
        if split[#split] == "underlay" then
            if not managers.dyn_resource:has_resource(Idstring("scene"), Idstring(item._parameters.help_id), managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
                managers.dyn_resource:load(Idstring("scene"), Idstring(item._parameters.help_id), managers.dyn_resource.DYN_RESOURCES_PACKAGE, nil)
            end
        end
        
        self:SetValue(self._active_environment, item._parameters.path_key, item._parameters.help_id, item._parameters.path, true)
    end
end

function EnvironmentEditorManager:GetHandler(file_key)
    return self._handlers[file_key] and self._handlers[file_key] or nil
end

function EnvironmentEditorManager:AddHandlerValue(file_key, path_key, value, path)
    local handler = self:GetHandler(file_key)
    if not handler then
        handler = EnvironmentEditorHandler:new(file_key)
        self._handlers[file_key] = handler
    end
    
    handler:AddValue(path_key, value, path)
end

function EnvironmentEditorManager:SetActiveEnvironment(file_key)
    self._active_environment = file_key or self._active_environment or nil
end

function EnvironmentEditorManager:SetValue(file_key, path_key, value, path, editor, vtype)
    if not file_key then
        file_key = self._active_environment
    end

    local handler = self:GetHandler(file_key)
    if not handler then
        BeardLib:log("[ERROR] Handler does not exist " .. tostring(file_key))
        return
    end
    
    handler:SetValue(path_key, value, path, editor, vtype)
end

function EnvironmentEditorManager:ApplyValue(path_key, data)
    if managers.viewport and managers.viewport:viewports() then
        for _, viewport in pairs(managers.viewport:viewports()) do
            if viewport and viewport._env_handler and viewport:get_environment_path():key() == self._active_environment then
                local editorHandler = self:GetHandler(self._active_environment)
                local handler = viewport._env_handler
                local value = viewport:get_environment_value(path_key)
                local val_to_save = data.value
                
                if CoreClass.type_name(value) == "Vector3" then
                    local new_value
                    if CoreClass.type_name(data.value) == "number" then
                        new_value = Vector3(data.vtype == "x" and data.value or value.x, data.vtype == "y" and data.value or value.y, data.vtype == "z" and data.value or value.z)
                    else
                        new_value = Vector3(data.value.x or value.x, data.value.y or value.y, data.value.z or value.z)
                    end
                    handler:editor_set_value(path_key, new_value)
                    val_to_save = new_value
                else
                    handler:editor_set_value(path_key, data.value)
                end
                
                if data.editor then
                    editorHandler._current_data[path_key] = {path = data.path, value = val_to_save}
                end
            end
        end
    end
end

function EnvironmentEditorManager:update(t, dt)
    local viewport = managers.menu_scene and managers.menu_scene._vp or managers.player and managers.player:player_unit() and managers.player:player_unit():camera() and managers.player:player_unit():camera()._vp or nil
    if viewport then
        self._active_environment = viewport:get_environment_path():key()
    end
    self:ApplyValues()
end

function EnvironmentEditorManager:paused_update(t, dt)
    self:ApplyValues()
end

function EnvironmentEditorManager:ApplyValues()
    local handler = self:GetHandler(self._active_environment)
    if handler and table.size(handler._apply_data) > 0 then
        for key, data in pairs(handler._apply_data) do
            setup:add_end_frame_clbk(function()
                self:ApplyValue(key, data)
                handler._apply_data[key] = nil
            end)
        end
    end 
end


function EnvironmentEditorManager:FilenameEnteredCallback(success, value)
    if success then
        self.current_filename = value		
        managers.system_menu:show_keyboard_input({text = "GeneratedMod" .. self._active_environment, title = "Environment Mod ID", callback_func = callback(self, self, "MODIDEnteredCallback")})
    end
end

function EnvironmentEditorManager:MODIDEnteredCallback(success, value)
    if success then
        local handler = self:GetHandler(self._active_environment)
        local JsonData = {
            Environment = {
                {
                    file_key = self._active_environment,
                    ParamMods = handler._current_data,
                    ID = value
                }
            }
        }
        local fileName = self.current_filename
        local file = io.open(fileName, "w+")
        file:write(json.custom_encode(JsonData))
        file:close()
    end
end

EnvironmentEditorManager.KeyMinMax = {
	[("ambient_scale"):key()] = {min = -0.99, max = 0.99},
	[("ambient_color_scale"):key()] = {min = -50, max = 50},
	[("sun_range"):key()] = {min = 1, max = 150000},
	[("fog_min_range"):key()] = {min = -500, max = 1000},
	[("fog_max_range"):key()] = {min = -500, max = 4000},
	[("ambient_falloff_scale"):key()] = {min = -20, max = 20},
	[("sky_bottom_color_scale"):key()] = {min = -50, max = 50},
	[("sky_top_color_scale"):key()] = {min = -50, max = 50},
	[("sun_ray_color_scale"):key()] = {min = -100, max = 100},
	[("color2_scale"):key()] = {min = -15, max = 15},
	[("color0_scale"):key()] = {min = -15, max = 15},
	[("color1_scale"):key()] = {min = -15, max = 15},
    [("sky_orientation/rotation"):key()] = {min = 0, max = 360}
}

function EnvironmentEditorManager:AddEditorButton(node, key, path, value)
	local path_split = string.split(path, "/")
    local button_name = path_split[#path_split]
    
	if tonumber(value) ~= nil then
		MenuHelperPlus:AddSlider({
			min = self.KeyMinMax[key] and self.KeyMinMax[key].min or -300,
			max = self.KeyMinMax[key] and self.KeyMinMax[key].max or 300,
			step = 0.01,
			show_value = true,
			id = path,
			title = button_name,
			desc = "",
			callback = "EnvEditorClbk",
			localized = false,
			node = node,
			value = value,
            merge_data = {
                path = path,
                path_key = key
            }
		})
	elseif value.x then
		MenuHelperPlus:AddSlider({
			min = self.KeyMinMax[key] and self.KeyMinMax[key].min or -1,
			max = self.KeyMinMax[key] and self.KeyMinMax[key].max or 1,
			step = 0.01,
			show_value = true,
			id = path .. "-x",
			title = button_name .. "-R",
			desc = "",
			callback = "EnvEditorVectorXClbk",
			localized = false,
			node = node,
			value = value.x,
            merge_data = {
                path = path,
                path_key = key
            }
		})
		MenuHelperPlus:AddSlider({
			min = self.KeyMinMax[key] and self.KeyMinMax[key].min or -1,
			max = self.KeyMinMax[key] and self.KeyMinMax[key].max or 1,
			step = 0.01,
			show_value = true,
			id = path .. "-y",
			title = button_name .. "-G",
			desc = "",
			callback = "EnvEditorVectorYClbk",
			localized = false,
			node = node,
			value = value.y,
            merge_data = {
                path = path,
                path_key = key
            }
		})
		MenuHelperPlus:AddSlider({
			min = self.KeyMinMax[key] and self.KeyMinMax[key].min or -1,
			max = self.KeyMinMax[key] and self.KeyMinMax[key].max or 1,
			step = 0.01,
			show_value = true,
			id = path .. "-z",
			title = button_name .. "-B",
			desc = "",
			callback = "EnvEditorVectorZClbk",
			localized = false,
			node = node,
			value = value.z,
            merge_data = {
                path = path,
                path_key = key
            }
		})
	else
		MenuHelperPlus:AddButton({
			id = path,
			title = button_name,
			desc = value,
			callback = "EnvEditorStringClbk",
			node = node,
			localized = false,
			localized_help = false,
            merge_data = {
                string_value = value,
                path = path,
                path_key = key,
                input = true
            }
		})
	end
end

function EnvironmentEditorManager:PopulateEnvMenu()
    local node = MenuHelperPlus:GetNode(nil, self.NodeName)
    if node then
        node:clean_items()
        
        MenuCallbackHandler.SaveEnvtable = function(this, item)
            managers.system_menu:show_keyboard_input({text = "EnvModification" .. tostring(self._active_environment) .. ".txt", title = "Environment Mod Filename", callback_func = callback(self, self, "FilenameEnteredCallback")})
        end
        MenuHelperPlus:AddButton({
            id = "EnvEditorSave",
            title = "BeardLibSaveEnvTable_title",
            callback = "SaveEnvtable",
            node = node
        })
        
        MenuCallbackHandler.ResetEnvEditor = function(this, item)
            local handler = self:GetHandler(self._active_environment)
            if handler then
                handler._current_data = {}
                for key, params in pairs(handler:GetEditorValues()) do
                    self:SetValue(self._active_environment, key, params.value)
                end
            end
            
            self:PopulateEnvMenu()
            local selected_node = managers.menu:active_menu().logic:selected_node()
            managers.menu:active_menu().renderer:refresh_node(selected_node)
            local selected_item = selected_node:selected_item()
            selected_node:select_item(selected_item and selected_item:name())
            managers.menu:active_menu().renderer:highlight_item(selected_item)
        end
        MenuHelperPlus:AddButton({
            id = "EnvEditorReset",
            title = "BeardLibResetEnv_title",
            callback = "ResetEnvEditor",
            node = node
        })
        
        local viewport = managers.menu_scene and managers.menu_scene._vp or managers.player and managers.player:player_unit() and managers.player:player_unit():camera() and managers.player:player_unit():camera()._vp or nil
        
        if viewport and self._active_environment and self:GetHandler(viewport._env_handler:get_path():key()) then     
            local viewport_path = viewport._env_handler:get_path()
            local envHandler = self:GetHandler(viewport_path:key())
            
            local gui_class = managers.menu:active_menu().renderer
        
            BeardLib.path_text = BeardLib.path_text or gui_class.safe_rect_panel:child("BeardLibPathText") or gui_class.safe_rect_panel:text({
                name = "BeardLibPathText",
                text = "",
                font =  tweak_data.menu.pd2_medium_font, 
                font_size = 25,
                layer = 20,
                color = Color.yellow
            })
            BeardLib.path_text:set_visible(true)
            BeardLib.path_text:set_text(viewport_path)
            local x, y, w, h = BeardLib.path_text:text_rect()
            BeardLib.path_text:set_size(w, h)
            BeardLib.path_text:set_position(0, 0)
            
            for key, params in pairs(envHandler:GetEditorValues()) do
                local value = params.value or viewport:get_environment_value(key)
                local parts = string.split(params.path, "/")
                local menu_id = "BeardLib_" .. table.concat(parts, "/", 1, #parts - 1)
                local new_node = MenuHelperPlus:GetNode(nil, menu_id)
                
                if not node:item(menu_id .. "button") then
                    MenuHelperPlus:AddButton({
                        id = menu_id .. "button",
                        title = table.concat(parts, "/", 1, #parts - 1),
                        next_node = menu_id,
                        node = node,
                        localized = false
                    })
                    if new_node then
                        new_node:clean_items()
                        managers.menu:add_back_button(new_node)
                    end
                end
                
                if not new_node then
                    new_node = MenuHelperPlus:NewNode(nil, {
                        name = menu_id,
                        merge_data = {
                            hide_bg = true
                        }
                    })
                    managers.menu:add_back_button(new_node)
                end
                
                
                if value then
                    self:AddEditorButton(new_node, key, params.path, value)
                end
            end
        end
        
        managers.menu:add_back_button(node)
    end
end
