Hooks:PostHook(BLTNotificationsGui, "_setup", "BeardLibModsManagerSetup", function(self)
    self._beardlib_updates = self._panel:panel({
        name = "BeardLibModsManagerPanel",
        layer = 110, 
        w = 28,
        h = 28,
        y = 8,
    })
    self._beardlib_updates:set_lefttop(self._downloads_panel:left() - 8, self._downloads_panel:center_y() + 8)
    local icon = self._beardlib_updates:bitmap({
        name = "Icon",
        texture = "guis/textures/menuicons",        
        texture_rect = {93, 2, 32, 32},
        w = 28,
        h = 28,
        color = Color(0, 0.4, 1),
        rotation = 360
    })
    self._beardlib_updates:text({
        name = "UpdatesCount",
        font_size = 16,
        rotation = 360,
        font = tweak_data.menu.pd2_medium_font,
        layer = 10,
        color = tweak_data.screen_colors.title,
        text = "0",
        align = "center",
        vertical = "center"
    }):set_center(icon:center())
end)


Hooks:PostHook(BLTNotificationsGui, "update", "BeardLibModsManagerUpdate", function(self)
    if alive(self._beardlib_updates) then
        local count = self._beardlib_updates:child("UpdatesCount")
        if alive(count) then
            count:set_text(#BeardLib.managers.mods_menu._waiting_for_update)
        end
    end
end)

local mouse_move = BLTNotificationsGui.mouse_moved
function BLTNotificationsGui:mouse_moved(o, x, y)
    if not self._enabled then
        return
    end
    if alive(self._beardlib_updates) then
        local icon = self._beardlib_updates:child("Icon")
        if self._beardlib_updates:inside(x,y) then
            QuickAnim:WorkColor(icon, Color(0, 0.1, 1), nil, 0.1)
            return true, "link"
        else
            QuickAnim:WorkColor(icon, Color(0, 0.4, 1), nil, 0.1)
        end
    end
    return mouse_move(self, x, y)
end

local mouse_press = BLTNotificationsGui.mouse_pressed
function BLTNotificationsGui:mouse_pressed(button, x, y)
    if not self._enabled or button ~= Idstring("0") then
        return
    end
    if alive(self._beardlib_updates) and self._beardlib_updates:inside(x,y) then
        BeardLib.managers.mods_menu:SetEnabled(true)
        return true
    end
    return mouse_press(self, button, x, y)
end