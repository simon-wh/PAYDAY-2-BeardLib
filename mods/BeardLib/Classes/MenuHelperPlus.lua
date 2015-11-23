_G.MenuHelperPlus = _G.MenuHelperPlus or {}

function MenuHelperPlus:NewMenu(Params)
	self.Menus = self.Menus or {}
	local CallbackHandler = CoreSerialize.string_to_classtable(Params.CallbackHandler or "MenuCallbackHandler")
	self.Menus[Params.Id] = {
		menu_data = {
			_meta = "menues",
			[1] = {
				_meta = "menu",
				id = Params.Id,
				[1] = {
					_meta = "default_node",
					name = Params.InitNode.Name
				},
				[2] = {
					_meta = "node",
					align_line = Params.InitNode.AlignLine or 0.75,
					back_callback = Params.InitNode.BackCallback,
					gui_class = Params.InitNode.GuiClass or "MenuNodeMainGui",
					menu_components = Params.InitNode.MenuComponents or "",
					modifier = Params.InitNode.Modifier,
					name = Params.InitNode.Name,
					refresh = Params.InitNode.Refresh,
					topic_id = Params.InitNode.TopicId
				}
			}
		},
		register_data = {
			name = Params.Name,
			id = Params.Id,
			content_file = Params.FakePath,
			callback_handler = CallbackHandler,
			input = Params.Input or "MenuInput",
			renderer = Params.Renderer or "MenuRenderer"
		},
		FakePath = Params.FakePath
	}
	BeardLib.ScriptExceptions[Idstring(Params.FakePath):key()] = true
	
	if Params.InitNode.Legends then
		for i, legend in pairs(Params.InitNode.Legends) do
			self:CreateAndInsertLegendData(self.Menus[Params.Id].menu_data[1][2], legend)
		end
	end
	
	if Params.InitNode.MergeData then
		table.merge(self.Menus[Params.Id].menu_data[1][2], Params.InitNode.MergeData)
	end
	
	if Params.MergeData then
		table.merge(self.Menus[Params.Id].menu_data, Params.MergeData)
	end
	
	--[[BeardLib.AddedMenus[Idstring("gamedata/menus/editor_menu"):key()] = {
		{
			_meta = "menu",
			id = "editor_menu",
			[1] = {
				_meta = "default_node",
				name = "editor_main"
			},
			[2] = {
				[1] = {
					_meta = "default_item",
					name = "resume_game"
				},
				[2] = {
					_meta = "item",
					callback = "exit_freeflight_menu",
					name = "resume_game",
					text_id = "menu_resume_game"
				},
				_meta = "node",
				align_line = 0.75,
				back_callback = "resume_game",
				gui_class = "MenuNodeMainGui",
				menu_components = "",
				modifier = "PauseMenu",
				name = "editor_main",
				--refresh = "PauseMenu",
				topic_id = "menu_ingame_menu"
			}
		}
	}
	MenuCallbackHandler.exit_freeflight_menu = function(this, item)
		managers.menu:close_menu("menu_editor")
	end
	local menu_editor = {
		name = "menu_editor",
		id = "editor_menu",
		content_file = "gamedata/menus/editor_menu",
		callback_handler = MenuCallbackHandler:new(),
		input = "MenuInput",
		renderer = "MenuRenderer"
	}
	menu_manager:register_menu(menu_editor)]]--
end

function MenuHelperPlus:AddNode(MenuName, Params)
	local RegisteredMenu = managers.menu._registered_menus[MenuName]
	if not RegisteredMenu then
		return
	end
	local nodes = RegisteredMenu.logic._data._nodes
	
	local arugements = {
		_meta = "node",
		align_line = Params.AlignLine or 0.75,
		back_callback = Params.BackCallback,
		gui_class = Params.GuiClass or "MenuNodeGui",
		menu_components = Params.MenuComponents or "",
		modifier = Params.Modifier,
		name = Params.Name,
		refresh = Params.Refresh,
		stencil_align = Params.StencilAlign or "right",
		stencil_image = Params.StencilImage or "bg_creategame",
		topic_id = Params.TopicID,
		type = Params.Type,
		update = Params.Update,
		scene_state = Params.SceneState
	}
	if Params.MergeData then
		table.merge(arugements, Params.MergeData)
	end
	
	if Params.Legends then
		for i, legend in pairs(Params.Legends) do
			self:CreateAndInsertLegendData(arugements, legend)
		end
	end
	
	local NodeClass = "CoreMenuNode.MenuNode"
	if type then
		NodeClass = type
	end
	local node_class = CoreSerialize.string_to_classtable(NodeClass)
	local new_node = node_class:new(arugements)
		
	local callback_handler = CoreSerialize.string_to_classtable(Params.CallbackOverwrite or RegisteredMenu.callback_handler or "MenuCallbackHandler")
	new_node:set_callback_handler(callback_handler:new())
	
	nodes[new_node.name] = new_node
end

function MenuHelperPlus:AddLegend(MenuID, NodeName, Params)
	local menu = self.Menus[MenuID]
	
	if not menu then
		return
	end
	
	menu.nodes[NodeName] = menu.nodes[NodeName] or {}
	local max_val = table.maxn(menu.nodes[NodeName])
	menu.nodes[NodeName][max_val + 1] = Params
end

function MenuHelperPlus:CreateAndInsertLegendData(NodeData, Params)
	local max_val = table.maxn(NodeData)
	NodeData[max_val + 1] = {
		_meta = "legend",
		name = Params.Name,
		pc = Params.PC or false,
		visible_callback = Params.VisibleCallback or nil
	}
end

function MenuHelperPlus:AddButton(Params)
	local RegisteredMenu = managers.menu._registered_menus[Params.Menu]
	if not RegisteredMenu then
		log("Not reg data")
		return
	end
	local nodes = RegisteredMenu.logic._data._nodes
	local node = nodes[Params.Node]
	
	local data = {
		type = "CoreMenuItem.Item",
	}

	local params = {
		name = Params.Id,
		text_id = Params.Title,
		help_id = Params.Desc,
		callback = Params.Callback,
		back_callback = Params.BackCallback,
		disabled_color = Params.DisabledColour or Color(0.25, 1, 1, 1),
		next_node = Params.NextNode,
		localize = Params.Localize,
	}

	if Params.MergeData then
		table.merge(params, Params.MergeData)
	end
	
	local item = node:create_item(data, params)

	if Params.Enabled ~= nil then
		item:set_enabled( Params.Enabled )
	end

	node:add_item(item)
end

function MenuHelperPlus:AddDivider(Params)
	local RegisteredMenu = managers.menu._registered_menus[Params.Menu]
	if not RegisteredMenu then
		return
	end
	local nodes = RegisteredMenu.logic._data._nodes
	local node = nodes[Params.Node]
	
	local data = {
		type = "MenuItemDivider",
		size = Params.Size or 8,
		no_text = Params.NoText or true,
	}

	local params = {
		name = Params.id,
	}
	
	if Params.MergeData then
		table.merge(params, Params.MergeData)
	end
	
	local item = node:create_item( data, params )
	node:add_item(item)

end

function MenuHelperPlus:AddToggle(Params)
	local RegisteredMenu = managers.menu._registered_menus[Params.Menu]
	if not RegisteredMenu then
		return
	end
	local nodes = RegisteredMenu.logic._data._nodes
	local node = nodes[Params.Node]
	
	local data = {
		type = "CoreMenuItemToggle.ItemToggle",
		{
			_meta = "option",
			icon = "guis/textures/menu_tickbox",
			value = "on",
			x = 24,
			y = 0,
			w = 24,
			h = 24,
			s_icon = "guis/textures/menu_tickbox",
			s_x = 24,
			s_y = 24,
			s_w = 24,
			s_h = 24
		},
		{
			_meta = "option",
			icon = "guis/textures/menu_tickbox",
			value = "off",
			x = 0,
			y = 0,
			w = 24,
			h = 24,
			s_icon = "guis/textures/menu_tickbox",
			s_x = 0,
			s_y = 24,
			s_w = 24,
			s_h = 24
		}
	}

	local params = {
		name = Params.Id,
		text_id = Params.Title,
		help_id = Params.Desc,
		callback = Params.Callback,
		disabled_color = Params.DisabledColour or Color( 0.25, 1, 1, 1 ),
		icon_by_text = Params.IconByText or false,
		localize = Params.Localize,
	}
	
	if Params.MergeData then
		table.merge(params, Params.MergeData)
	end
	
	local item = menu:create_item(data, params)
	item:set_value(Params.Value and "on" or "off")

	if Params.Enabled ~= nil then
		item:set_enabled(Params.Enabled)
	end
	
	node:add_item(item)
end

function MenuHelperPlus:AddSlider(Params)
	local RegisteredMenu = managers.menu._registered_menus[Params.Menu]
	if not RegisteredMenu then
		return
	end
	local nodes = RegisteredMenu.logic._data._nodes
	local node = nodes[Params.Node]
	
	local data = {
		type = "CoreMenuItemSlider.ItemSlider",
		min = Params.Min or 0,
		max = Params.Max or 10,
		step = Params.Step or 1,
		show_value = Params.ShowValue or false
	}

	local params = {
		name = Params.Id,
		text_id = Params.Title,
		help_id = Params.Desc,
		callback = Params.Callback,
		disabled_color = Params.DisabledColour or Color( 0.25, 1, 1, 1 ),
		localize = Params.Localize,
	}

	if Params.MergeData then
		table.merge(params, Params.MergeData)
	end
	
	local item = node:create_item(data, params)
	item:set_value( math.clamp(Params.value, data.min, data.max) or data.min )
	
	if Params.Enabled ~= nil then
		item:set_enabled( Params.Enabled )
	end

	node:add_item(item)
end

function MenuHelperPlus:AddMultipleChoice(Params)
	local RegisteredMenu = managers.menu._registered_menus[Params.Menu]
	if not RegisteredMenu then
		return
	end
	local nodes = RegisteredMenu.logic._data._nodes
	local node = nodes[Params.Node]
	
	local data = {
		type = "MenuItemMultiChoice"
	}
	for k, v in ipairs( Params.Items or {} ) do
		table.insert( data, { _meta = "option", text_id = v, value = k } )
	end
	
	local params = {
		name = Params.Id,
		text_id = Params.Title,
		help_id = Params.Desc,
		callback = Params.Callback,
		filter = true,
		localize = Params.Localize,
	}
	
	if Params.MergeData then
		table.merge(params, Params.MergeData)
	end
	
	local item = node:create_item(data, params)
	item:set_value( Params.Value or 1 )

	if Params.Enabled ~= nil then
		item:set_enabled(Params.Enabled)
	end

	node:add_item(item)
end

function MenuHelperPlus:AddKeybinding(Params)
	local RegisteredMenu = managers.menu._registered_menus[Params.Menu]
	if not RegisteredMenu then
		return
	end
	local nodes = RegisteredMenu.logic._data._nodes
	local node = nodes[Params.Node]
	
	local data = {
		type = "MenuItemCustomizeController",
	}

	local params = {
		name = Params.Id,
		text_id = Params.Title,
		help_id = Params.Desc,
		connection_name = Params.ConnectionName,
		binding = Params.Binding,
		button = Params.Button,
		callback = Params.Callback,
		localize = Params.Localize,
		localize_help = Params.HelpLocalize,
		is_custom_keybind = true,
	}

	if Params.MergeData then
		table.merge(params, Params.MergeData)
	end
	
	local item = node:create_item(data, params)

	node:add_item(item)
end

function MenuHelperPlus:GetMenus()
	return self.Menus
end

function MenuHelperPlus:GetMenuDataFromFilepath(FilePath)
	for ID, Data in pairs(self.Menus) do
		if Data.FakePath == FilePath then
			return Data.menu_data
		end
	end
	return nil
end

function MenuHelperPlus:GetMenuDataFromHashedFilepath(HashedFilePath)
	if self.Menus then
		for ID, Data in pairs(self.Menus) do
			if Idstring(Data.FakePath):key() == HashedFilePath then
				return Data.menu_data
			end
		end
	end
	return nil
end

Hooks:Register("BeardLibMenuHelperPlusInitMenus")

Hooks:Add( "BeardLibMenuHelperPlusInitMenus", "MenuHelperPlusCreateMenus", function(menu_manager) 
	for ID, Menu in pairs(MenuHelperPlus:GetMenus()) do
		menu_manager:register_menu(Menu.register_data)
	end
end)

--[[function MenuHelperPlus:BuildMenu(MenuID)
	local menu = self.Menus[MenuID]
	
	if not menu then
		return
	end
	
	local data = {
		_meta = "menues"
		[1] = {
			_meta = "menu",
			id = MenuID,
			[1] = {
				_meta = "default_node",
				name = menu.params.default_node
			}
		}
	}
	if menu.nodes then
		local i = 1
		for name, node in pairs(menu.nodes) do
			i = i + 1
			local nd = node
			nd._meta = "node"
			
			data[1][i] = nd
		end
	end
end]]--