InputDialog = InputDialog or class(MenuDialog)

function InputDialog:init(params, menu)
    self.super.init(self, table.merge(params or {}, {
        w = 420,
        offset = 8,
        automatic_height = true,
        items_size = 20,
        auto_align = true
    }), menu)
end

function InputDialog:Show(params)
	table.merge(params, {
		yes = params.yes or "Apply",
		no = params.no or "Cancel",
	})
    if not self.super.Show(self, params) then
        return
    end
    self._text = self._menu:TextBox(table.merge({
        name = "Text",
        text = "",
        index = params.title and "After|Title" or 1,
        marker_highlight_color = Color.transparent,
        line_color = Color.transparent,
        control_slice = 1,
        textbox_align = "center",
        filter = params.filter,
        value = params.text
    }, params.merge_text or {}))
	self._enter = BeardLib.Utils.Input:Trigger("enter", callback(self, self, "hide", true))
end

function InputDialog:run_callback(clbk)
    if clbk then
        clbk(self._text:Value(), self._menu)
    end
end

function InputDialog:hide(...)
	BeardLib.Utils.Input:RemoveTrigger(self._enter)
	return self.super.hide(self, ...)
end