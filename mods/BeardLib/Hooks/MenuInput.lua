CloneClass(MenuInput)

function MenuInput.init(self, logic, ...)
	self.orig.init(self, logic, ...)
	self:register_callback("mouse_pressed", "BeardLibMenuMousePressed", callback(self, self, "BeardLibmouse_pressed"))
end

function MenuInput.back(self, queue, skip_nodes)
	self.orig.back(self, queue, skip_nodes)
	BeardLib:DestroyInputPanel()
end

function MenuInput.mouse_pressed(self, o, button, x, y)
	if button == Idstring("0") then
		BeardLib:DestroyInputPanel()
	end

	return self.orig.mouse_pressed(self, o, button, x, y)
	
end

function MenuInput:BeardLibmouse_pressed(o, button, x, y)
	log("Mouse Pressed")
	local item = self._logic:selected_item()
	if item then
		--self._item_input_action_map[item.TYPE](item, self._controller)
		if button == Idstring("1") and (item.TYPE == "slider" or item._parameters.callback_name[1] == "BeardLibEnvStringClbk") then
			BeardLib._current_item = item
			local parts = string.split(item._parameters.text_id, "-")
			BeardLib:CreateInputPanel({value = item._value or parts[2] or "", title = parts[1], callback = callback(BeardLib, BeardLib, "ButtonEnteredCallback")})
			return true
		end
	end	
	if button == Idstring("0") then
		BeardLib:DestroyInputPanel()
		return true
	end
	return false
end

function MenuInput.input_slider(self, item, controller)
	self.orig.input_slider(self, item, controller)
	if self:menu_right_input_bool() or self:menu_left_input_bool() then
		BeardLib:DestroyInputPanel()
	end
end

function BeardLib:enter_text(o, s)
	
	self._input_text = self._input_text .. s
	log(self._input_text)
	self._text_input:set_text(self._input_text)
end

function BeardLib:ButtonEnteredCallback()
	if tonumber(self._input_text) ~= nil then
		self._current_item:set_value( math.clamp(tonumber(self._input_text), self._current_item._min, self._current_item._max) or self._current_item._min )
		managers.viewport:resolution_changed()
		self._current_item:trigger()
	else
		local parts = string.split(self._current_item._parameters.text_id, "-")
		self._current_item._parameters.text_id = parts[1] .. "-" .. self._input_text
		managers.viewport:resolution_changed()
		self._current_item:trigger()
	end
end

function BeardLib:key_press(o, k)
	--log(tostring(k))
	local n = utf8.len(self._input_text)
	if k == Idstring("backspace") then
		self._input_text = utf8.sub(self._input_text, 0, math.max(n - 1, 0))
		self._text_input:set_text(self._input_text)
	elseif k == Idstring("esc") then
		if self._current_params.back_callback then
			self._current_params.back_callback()
		end
		self:DestroyInputPanel()
	elseif k == Idstring("enter") then
		self:DestroyInputPanel()
		self._current_params.callback()
	end
end

function BeardLib:key_release(o, k)
	--log(tostring(k))
end

--function BeardLib:CreateInputPanel(item)
function BeardLib:CreateInputPanel(Params)
	if not self._setup_workspace then
		self:SetupWorkspace()
		self._setup_workspace = true
	end
	
	if self._caret_connected then
		self:DestroyInputPanel()
	end
	self._current_params = Params
	--self._current_item = item
	--local parts = string.split(item._parameters.text_id, "-")
	--self._input_text = item._value or parts[2] or ""
	self._input_text = Params.value
	self._ws:connect_keyboard(Input:keyboard())
	self._panel:enter_text(callback(self, self, "enter_text"))
	self._panel:key_press(callback(self, self, "key_press"))
	self._panel:key_release(callback(self, self, "key_release"))
	self.background_box = self._panel:bitmap({
		name = "background_box",
		color = Color.black:with_alpha(0.75),
		w = 350,
		h = 150,
		--[[align = "center",
		vertical = "center",
		valign = "center",]]--
		visible = true,
		layer = 0
	})
	self.background_box:set_center(self._panel:center())
	self._text_title = self._panel:text({
		name = "text_title",
		color = Color.white,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size,
		text = "",
		--[[w = 200,
		h = 200,
		visible = true,
		wrap = true,
		word_wrap = true]]--
	})
	self._text_title:set_lefttop(self.background_box:lefttop())
	self._text_title:set_text(Params.title)
	self._text_input = self._panel:text({
		name = "text_input",
		color = Color.white,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size + 5,
		text = "",
		w = 300,
		h = 100,
		visible = true,
		wrap = true,
		word_wrap = true,
		layers = 10
	})
	--log(self._input_text)
	self._text_input:set_text(self._input_text)
	self._text_input:set_lefttop(self.background_box:left() + 25, self.background_box:top() + 25 )
	--self._rename_caret:animate(self.blink)
	self._caret_connected = true
	--self:update_info_text()
end

function BeardLib:DestroyInputPanel()
	--managers.blackmarket:set_crafted_custom_name(self._renaming_item.category, self._renaming_item.slot, self._renaming_item.custom_name)
	self._renaming_item = nil
	self._rename_info_text = nil
	
	if self._caret_connected then
		self._ws:disconnect_keyboard()
		self._panel:enter_text(nil)
		self._panel:key_press(nil)
		self._panel:key_release(nil)
		self._panel:remove(self.background_box)
		self._panel:remove(self._text_input)
		self._panel:remove(self._text_title)
		self._text_title = nil
		self.background_box = nil
		self._text_input = nil
		self._caret_connected = nil
	end
	--self._current_params = nil
	--managers.menu_component:post_event("menu_enter")
	self._rename_highlight = false
	--self:reload()
end