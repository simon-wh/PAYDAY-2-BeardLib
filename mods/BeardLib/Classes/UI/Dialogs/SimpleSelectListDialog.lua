SimpleSelectListDialog = SimpleSelectListDialog or class(SelectListDialog)
SimpleSelectListDialog.type_name = "SimpleSelectListDialog"
function SimpleSelectListDialog:init(params, menu)
    if self.type_name == SimpleSelectListDialog.type_name then
        params = params and clone(params) or {}
    end
    params.w = 400
    params.h = 500
    params.size = 24

    SimpleSelectListDialog.super.init(self, params, menu)
end

SimpleSelectListDialog._Show = SimpleListDialog._Show

function SimpleSelectListDialog:hide(yes)
    return ListDialog.hide(self, NotNil(yes, false))
end