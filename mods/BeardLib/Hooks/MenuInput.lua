Hooks:PreHook(MenuInput, "mouse_pressed", "BeardLibMenuInputMousePressed", function(self, o, button, x, y)
    self.BeardLib_mouse_pressed(self, o, button, x, y)
end)

function MenuInput:BeardLib_mouse_pressed(o, button, x, y)
	local item = self._logic:selected_item()
	if item and button == Idstring("1") then
		if (item.TYPE == "slider" or item._parameters.input) then
			self._current_item = item
            local title = item._parameters.text_id
            managers.system_menu:show_keyboard_input({
                title = item._parameters.override_title or item._parameters.localize ~= false and managers.localization:text(title) or title, 
                text = tostring(item._value) or item._parameters.string_value or "",
                filter = item._value and "number" or "string",
                callback_func = callback(self, self, "ValueEnteredCallback")
            })
			return true
		end
	end
end

function MenuInput:ValueEnteredCallback(success, value)
    if success and self._current_item then
        if self._current_item._value then
            self._current_item:set_value( math.clamp(tonumber(value), self._current_item._min, self._current_item._max) or self._current_item._min )
        else
            self._current_item._parameters.help_id = value
        end
            
        managers.viewport:resolution_changed()
        self._current_item:trigger()
    end
end