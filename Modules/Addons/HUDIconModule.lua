HUDIconModule = HUDIconModule or BeardLib:ModuleClass("HUDIcon", ModuleBase)
HUDIconModule._loose = true

-- Adds an icon to tweak_data.hud_icons

function HUDIconModule:init(...)
    self.required_params = table.add(clone(self.required_params), {"id", "texture"})
	return HUDIconModule.super.init(self, ...)
end

function HUDIconModule:Load()
    local rect = self._config.rect
    local rect_tbl = nil
    if rect then
        rect = string.split(rect, " ")
        rect_tbl = {}
        for _, num in pairs(rect) do
            table.insert(rect_tbl, tonumber(num) or 0)
        end
    end
    TweakDataHelper:ModifyTweak(table.merge({
		texture_rect = rect_tbl,
        custom = true,
    }, self._config), "hud_icons", self._config.id)
end