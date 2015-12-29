CloneClass(MenuInput)

function MenuInput.back(self, queue, skip_nodes)
	self.orig.back(self, queue, skip_nodes)
    if self._current_params and self._current_params.back_callback then
        self._current_params.back_callback()
    end
	BeardLib:DestroyInputPanel()
end

Hooks:PreHook(MenuInput, "mouse_pressed", "BeardLibMenuInputMousePressed", function(self, o, button, x, y)
    self.BeardLibmouse_pressed(self, o, button, x, y)

end)

function MenuInput:BeardLibmouse_pressed(o, button, x, y)
	local item = self._logic:selected_item()
	if item and button == Idstring("1") then
		if (item.TYPE == "slider" or item._parameters.input) then
			BeardLib._current_item = item
            local title = item._parameters.text_id
			BeardLib:CreateInputPanel({value_type = item._value and "number" or "string", value = item._value or item._parameters.string_value or "", title = item._parameters.override_title or managers.localization:exists(title) and managers.localization:text(title) or title, callback = callback(BeardLib, BeardLib, "ButtonEnteredCallback")})
			return true
		end
	elseif button == Idstring("0") then
        if self._current_params and self._current_params.back_callback then
			self._current_params.back_callback()
		end
		BeardLib:DestroyInputPanel()
	end
end

function MenuInput.input_slider(self, item, controller)
	self.orig.input_slider(self, item, controller)
	if self:menu_right_input_bool() or self:menu_left_input_bool() then
        if self._current_params and self._current_params.back_callback then
			self._current_params.back_callback()
		end
		BeardLib:DestroyInputPanel()
	end
end

function BeardLib:enter_text(o, s)
	self._input_text = self._input_text .. s
	self._text_input:set_text(self._input_text)
end

function BeardLib:ButtonEnteredCallback()
    if self._current_params.value_type == "string" and self._current_item then
        local parts = string.split(self._current_item._parameters.text_id, "-")
		self._current_item._parameters.help_id = self._input_text
		managers.viewport:resolution_changed()
		self._current_item:trigger()
    elseif tonumber(self._input_text) ~= nil and self._current_params.value_type == "number" and self._current_item then
        self._current_item:set_value( math.clamp(tonumber(self._input_text), self._current_item._min, self._current_item._max) or self._current_item._min )
		managers.viewport:resolution_changed()
		self._current_item:trigger()
    else
        --invalid value
    end
end

function BeardLib:key_press(o, k)
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
        self:ButtonEnteredCallback()
        self._current_params.callback(self._input_text, self._current_params.callback_params)
		self:DestroyInputPanel()
	end
end

function BeardLib:key_release(o, k)
    
end

function BeardLib:CreateInputPanel(Params)
	if self._caret_connected then
        if self._current_params and self._current_params.back_callback then
			self._current_params.back_callback()
		end
		self:DestroyInputPanel()
	end
	self._current_params = Params
	self._input_text = Params.value
    
    local active_menu = managers.menu:active_menu()
    self._ws = active_menu.renderer.ws
    self._panel = active_menu.renderer.safe_rect_panel:child("BeardLibInputPanel") or active_menu.renderer.safe_rect_panel:panel({
        name = "BeardLibInputPanel",
        layer = 40
    
    })
    
	self._ws:connect_keyboard(Input:keyboard())
	self._panel:enter_text(callback(self, self, "enter_text"))
	self._panel:key_press(callback(self, self, "key_press"))
	self._panel:key_release(callback(self, self, "key_release"))
	self.background_box = self._panel:bitmap({
		name = "background_box",
		color = Color.black:with_alpha(0.75),
		w = 350,
		h = 150,
		layer = 0
	})
	self.background_box:set_center(self._panel:center())
	self._text_title = self._panel:text({
		name = "text_title",
		color = Color.white,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size,
		text = "",
        layer = 1
	})
	self._text_title:set_lefttop(self.background_box:lefttop())
	self._text_title:set_text(string.upper(Params.title))
	self._text_input = self._panel:text({
		name = "text_input",
		color = Color.white,
		font = tweak_data.menu.pd2_medium_font,
		font_size = 20,
		text = "",
		w = 300,
		h = 100,
		wrap = true,
		word_wrap = true,
		layer = 1
	})
	self._text_input:set_text(self._input_text)
	self._text_input:set_lefttop(self.background_box:left() + 25, self.background_box:top() + 25 )
	self._caret_connected = true
    managers.menu_component:post_event("menu_enter")
end

function BeardLib:DestroyInputPanel()
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
        self._current_params = nil
	end
	self._rename_highlight = false
end