Hooks:PostHook(BLTNotificationsGui, "_setup", "BeardLibModsManagerSetup", function(self)
    self._beardlib_accent = BeardLib.Options:GetValue("MenuColor")

    self._beardlib_panel = self._panel:parent():panel({
        layer = 50,
        h = 36,
        y = self._panel:y()-4,
        name = "beardlib_panel"
    })
    self._beardlib_updates = self._beardlib_panel:panel({
        name = "BeardLibModsManagerPanel",
        w = 42,
        h = 28,
        y = 8,
    })
    --self._beardlib_updates:set_position(self._downloads_panel:x() - 8, self._downloads_panel:center_y() + 8)
    local logo = self._beardlib_updates:bitmap({
        name = "logo",
        texture = "guis/textures/beardlib_logo",        
        w = 28,
        h = 28
    })

    local icon = self._beardlib_updates:bitmap({
        name = "Icon",
        texture = "guis/textures/menu_ui_icons",        
        texture_rect = {93, 2, 32, 32},
        color = self._beardlib_accent,
        layer = 5,
        w = 20,
        h = 20,
        y = 8,
        x = logo:right() - 8
    })

    self._beardlib_updates:text({
        name = "UpdatesCount",
        font_size = 16,
        font = tweak_data.menu.pd2_medium_font,
        layer = 10,
        color = self._beardlib_accent:contrast(),
        text = "0",
        align = "center",
        vertical = "center"
    }):set_center(icon:center())
    self._beardlib_achievements = self._beardlib_panel:bitmap({
        name = "CustomAchievments",
        texture = "guis/textures/achievement_trophy_white",        
        w = 28,
        h = 28,
        y = 8,
        x = self._beardlib_updates:right() + 4,
        color = self._beardlib_accent
    })
end)

Hooks:PostHook(BLTNotificationsGui, "close", "BeardLibPanelClose", function(self)
    self._ws:panel():remove(self._beardlib_panel)
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
    
    if alive(self._beardlib_updates) and alive(self._beardlib_achievements) then
        if self._beardlib_achievements:inside(x,y) or self._beardlib_updates:inside(x,y)  then
            return true, "link"
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
    if alive(self._beardlib_achievements) and self._beardlib_achievements:inside(x,y) then
        BeardLib.managers.custom_achievement_menu:SetEnabled(true)
        return true
    end
    return mouse_press(self, button, x, y)
end