InputDialog = InputDialog or class(MenuDialog)
InputDialog.type_name = "InputDialog"
function InputDialog:init(params, menu)
    params = params or {}
    params = deep_clone(params)
    self._is_input = true
    self.super.init(self, table.merge(params, {
        offset = 8,
        auto_height = true,
        items_size = 20,
    }), menu)
    self._default_width = 500
end

function InputDialog:_Show(params)
	table.merge(params, {
		yes = params.yes or "Apply",
		no = params.no or "Cancel",
	})
    if not self.super._Show(self, params) then
        return
    end
    self._check_value = params.check_value
    local body = self._menu:Menu({
        name = "TextBody",
        background_color = self._menu.background_color:contrast():with_alpha(0.25),
        index = params.title and "After|Title" or 1,
        auto_height = true,
        scroll_color = self._menu.text_color,
        scrollbar = true,
        max_height = 500,
    })
    self._text = body:TextBox(table.merge({
        name = "Text",
        text = "",
        offset = 0,
        marker_highlight_color = false,
        line_color = Color.transparent,
        control_slice = 1,
        filter = params.filter,
        value = params.text
    }, params.merge_text or {}))
    self:show_dialog()
end

function InputDialog:run_callback(clbk)
    if clbk then
        clbk(self._text:Value(), self._menu)
    end
    self._text = nil
end

function InputDialog:hide(yes, ...)
    if yes == true and self._check_value and not self._check_value(self._text:Value()) then
        return
    end
    self._check_value = nil
	return self.super.hide(self, yes, ...)
end