Hooks:PreHook(MenuInput, "mouse_pressed", "BeardLibMenuInputMousePressed", function(self, o, button, x, y)
    self:BeardLib_mouse_pressed(o, button, x, y)
end)

function MenuInput:BeardLib_mouse_pressed(o, button, x, y)
	local item = self._logic:selected_item()
	if item and button == Idstring("1") then
		if (item.TYPE == "slider" or item._parameters.input) then
			self._current_item = item
            local title = item._parameters.text_id
            BeardLib.managers.dialog:Input():Show({
                title = item._parameters.override_title or item._parameters.localize ~= false and managers.localization:text(title) or title, 
                text = tostring(item._value) or item._parameters.string_value or "",
                filter = item._value and "number",
                force = true,
                callback = callback(self, self, "ValueEnteredCallback")
            })
			return true
		end
	end
end

function MenuInput:ValueEnteredCallback(value)
    if self._current_item then
        if self._current_item._value then
            self._current_item:set_value(math.clamp(tonumber(value), self._current_item._min, self._current_item._max) or self._current_item._min )
        else
            self._current_item._parameters.help_id = value
        end
            
        managers.viewport:resolution_changed()
        self._current_item:trigger()
    end
end

local o_back = MenuInput.back
function MenuInput:back(...)
    if BeardLib.IgnoreBackOnce then
        BeardLib.IgnoreBackOnce = nil
        return false
    end
    return o_back(self, ...)
end

local o_mouse_moved = MenuInput.mouse_moved
function MenuInput:mouse_moved(...)
    local mc = managers.mouse_pointer._mouse_callbacks
    local last = mc[#mc]
    if not last or type_name(last.parent) ~= "MenuUI" then
        return o_mouse_moved(self, ...)
    end
end