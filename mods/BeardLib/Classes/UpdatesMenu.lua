UpdatesMenu = UpdatesMenu or class()
function UpdatesMenu:init()
	self._main_menu = MenuUI:new({
        layer = 300,
        marker_highlight_color = Color(0.26, 0.52, 0.93),
        create_items = callback(self, self, "CreateMenu"),
    --    visible = true
	})
end

function UpdatesMenu:CreateMenu(menu)
    self._menu = menu:Menu({
        name = "UpdatesMenu",
        scrollbar = false,
        debug = true,
        w = menu._panel:w() - 250,
        h = menu._panel:h() - 250,
        background_color = Color(0.2, 0.2, 0.2),
        background_alpha = 0.75,
        items_size = 20,
        position = "Center"
    })
    local close = self._menu:Button({text = "mod_assets_close", localized = true, callback = callback(menu, menu, "disable"), size_by_text = true, position = "TopRight"})
    self._menu:Button({text = "mod_assets_update_all", localized = true, callback = callback(menu, menu, "disable"), size_by_text = true, position = function(item)
        item:Panel():set_righttop(close:Panel():lefttop())
    end})
    self._mods = self._menu:DivGroup({name = "Mods", automatic_height = false, h = self._menu.h})
end

function UpdatesMenu:AddUpdate(module)
    local name = module._mod.Name
    local Holder = self._mods:DivGroup({
        name = name,
        text = string.pretty2(name),
        border_color = self._main_menu.marker_highlight_color,
        border_left = true,
        background_visible = false
    })
    local Actions = Holder:Menu({
        name = "Actions",
        automatic_height = true,
        count_height = true,
        offset = {0, Holder.offset[2]},
        background_visible = false,
        position = "Right",
        w = 200,
    })
    Actions:Button({
        text = "mod_assets_updates_download_now",
        callback = callback(module, module, "DownloadAssets"),
        localized = true,
    })  
    Actions:Button({
        text = "mod_assets_visit_page",
        callback = callback(module, module, "ViewMod"),
        localized = true,
    })
    Actions:Button({
        text = "mod_assets_updates_ignore",
        callback = callback(module, module, "IgnoreUpdate"),
        localized = true,
    })    
    Actions:Button({
        text = "mod_assets_updates_remind_later",
        callback = callback(module, module, "SetReady"),
        localized = true,
    })
end

return UpdatesMenu