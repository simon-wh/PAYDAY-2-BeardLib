BeardLibModsMenu = BeardLibModsMenu or class() 
function BeardLibModsMenu:init()
    local accent_color = Color(0, 0.25, 1)
	self._menu = MenuUI:new({
        name = "BeardLibEditorMods",
        layer = 1000,
        offset = 6,
        show_help_time = 0.1,
        animate_toggle = true,
        auto_foreground = true,
        accent_color = accent_color,
		create_items = callback(self, self, "CreateItems"),
    })
    self._waiting_for_update = {}
end

function BeardLibModsMenu:SetEnabled(enabled)
    local opened = BeardLib.managers.dialog:DialogOpened(self)
    if enabled then
        if not opened then
            BeardLib.managers.dialog:ShowDialog(self)
            self._menu:Enable()
        end
    elseif opened then
        BeardLib.managers.dialog:CloseDialog(self)
        self._menu:Disable()
    end
end

function BeardLibModsMenu:should_close()
    return self._menu:ShouldClose()
end

function BeardLibModsMenu:hide()
    self:SetEnabled(false)
    return true
end

function BeardLibModsMenu:CreateItems(menu)
    self._downloading_string = managers.localization:text("beardlib_downloading")    
    
    self._holder = menu:Menu({
        name = "Main",
        private = {background_color = Color(0.8, 0.2, 0.2, 0.2)},
        items_size = 16,
    })
    self._menu._panel:rect({
        name = "title_bg",
        layer = 2,
        color = Color(0.8, 0, 0.25, 1),
        h = 34,
    })
    local text = self._holder:Divider({
        name = "title",
        text = "beardlib_mods_manager",
        localized = true,
        items_size = 20,
        position = {4, 6},
        count_as_aligned = true
    })
    local close = self._holder:Button({
        name = "Close",
        text = "beardlib_close",
        size_by_text = true,
        localized = true,
        items_size = 20,
        position = function(item)
            item:SetPositionByString("RightTop")
            item:Panel():move(-4, 6)
        end,
        callback = callback(self, self, "SetEnabled", false)
    })
    local upall = self._holder:Button({
        name = "UpdateAllMods",
        text = "beardlib_update_all",
        size_by_text = true,
        localized = true,
        items_size = 20,
        position = function(item)
            item:Panel():set_righttop(close:Panel():left() - 4, close:Panel():y())
        end,
        callback = callback(self, self, "UpdateAllMods", true),
        second_callback = callback(self, self, "UpdateAllMods")
    })
    self._holder:Toggle({
        name = "ImportantNotice",
        text = "beardlib_important_notice",
        value = BeardLib.Options:GetValue("ImportantNotice"),
        size_by_text = true,
        localized = true,
        items_size = 20,
        position = function(item)
            item:Panel():set_righttop(upall:Panel():left() - 4, upall:Panel():y())
        end,
        callback = callback(self, self, "SetShowImportantUpdatesNotice")
    })
    self._holder:TextBox({
        name = "search",
        text = false,
        w = 300,
        line_color = self._holder.foreground,
        control_slice = 1,
        items_size = 20,
        position = function(item)
            item:SetPositionByString("Center")
            item:Panel():set_y(upall:Panel():y())
        end,
        callback = callback(self, self, "SearchMods")
    })
    self._list = self._holder:Menu({
        name = "ModList",
        h = self._holder:ItemsHeight() - text:OuterHeight() - (self._holder.offset[2] * 2) - 10,
        private = {offset = 0},
        position = function(item)
            item:SetPositionByString("CenterBottom")
            item:Panel():move(5, -5)
        end,
        auto_align = false,
        align_method = "grid",
    })
    self:AddMod(BeardLib, "blt")
    for _, mod in pairs(BeardLib.Mods) do
        self:AddMod(mod, "blt")
    end
    for _, mod in pairs(BeardLib.managers.AddFramework._loaded_mods) do
        self:AddMod(mod, "custom")
    end
    for _, mod in pairs(BeardLib.managers.MapFramework._loaded_mods) do
        self:AddMod(mod, "custom_heist")
    end
    self._list:AlignItems(true)
end

function BeardLibModsMenu:AddMod(mod, type)
    local loc = managers.localization
    local disabled_mods = BeardLib.Options:GetValue("DisabledMods")
    local name = mod.Name or "Missing name?"
    local blt_mod = type == "blt"
    local color = blt_mod and Color(0.6, 0, 1) or type == "custom" and Color(0, 0.25, 1) or Color(0.1, 0.6, 0.1)
    local s = (self._list:ItemsWidth() / 5) - self._list:Offset()[1]
    if mod._config.color then
        local orig_color = color
        color = BeardLib.Utils:normalize_string_value(mod._config.color)
        if type_name(color) ~= "Color" then
            mod:log("[ERROR] The color defined is not a valid color!")
            color = orig_color
        end
    end
    local concol = color:contrast():with_alpha(0.1)
    local mod_item = self._list:Menu({
        name = name,
        label = mod,
        w = s - 1,
        h = s - 1,
        scrollbar = false,
        auto_align = false,
        accent_color = concol,
        highlight_color = concol, 
        background_color = color:with_alpha(0.8)
    })
    self._list:SetScrollSpeed(mod_item:Height())
    local o = {}
    local text = function(t, opt)
        opt = opt or o
        return mod_item:Divider(table.merge({
            text_vertical = "top",
            text = t,
        }, opt))
    end
    local img = mod._config.image
    img = img and DB:has(Idstring("texture"), Idstring(mod._config.image)) and img or nil
    mod_item:Image({
        name = "Image",
        w = 100,
        h = 100,
        icon_w = 100,
        icon_h = 100,
        offset = 0,
        foreground = Color.white,
        auto_foreground = mod._config.auto_image_color or not mod._config.image,
        count_as_aligned = true,
        texture = img or "guis/textures/pd2/none_icon",
        position = "CenterTop"
    })
    local t = text(tostring(name), {name = "Title", items_size = 20, offset = {4, 0}})
    if t:Height() == t.items_size then
        text("")
    end
    text("Type: "..loc:text("beardlib_mod_type_" .. type))
    text("", {name = "Status"})
    mod_item:Toggle({
        name = "Enabled",
        text = false,
        enabled = not blt_mod,
        w = 24,
        h = 24,
        items_size = 24,
        highlight_color = Color.transparent,
        offset = 0,
        value = disabled_mods[mod.ModPath] ~= true,
        callback = callback(self, self, "SetModEnabled", mod),
        position = function(item)
            item:SetPositionByString("TopRight")
            item:Panel():move(-4, 1)
        end
    })
    mod_item:Panel():rect({
        name = "DownloadProgress",
        color = color:contrast():with_alpha(0.25),
        w = 0,
    })
    mod_item:Button({
        name = "View",
        callback = callback(self, self, "ViewMod", mod),
        enabled = mod.update_module_data ~= nil,
        items_size = 16,
        localized = true,
        text = "beardlib_visit_page"
    })
    mod_item:Button({
        name = "Download",
        callback = callback(self, self, "BeginModDownload", mod),
        enabled = false,
        items_size = 16,
        localized = true,
        text = "beardlib_updates_download_now"
    })
    
    if mod.NeedsUpdate then
        self:SetModNeedsUpdate(mod)
    else
        self:SetModStatus(mod_item, "beardlib_updated")
    end
    self:UpdateTitle(mod)
end

function BeardLibModsMenu:UpdateTitle(mod)
    local mod_item = self._list:GetItemByLabel(mod)
    if mod_item then
        local title = mod_item:GetItem("Title")
        title:SetText((mod.Name or "Missing name?") ..(mod.update_module_data and "("..mod.update_module_data.module.version..")" or ""))
    end
end

function BeardLibModsMenu:SetModEnabled(mod)
    local disabled_mods = BeardLib.Options:GetValue("DisabledMods")
    local path = mod.ModPath
    if disabled_mods[path] then
        disabled_mods[path] = nil
    else
        disabled_mods[path] = true
    end
    BeardLib.Options:Save()
end

function BeardLibModsMenu:SearchMods(menu, item)
    for _, mod_item in pairs(self._list._my_items) do
        local search = tostring(item:Value()):lower()
        local visible = tostring(mod_item.name):lower():match(search) ~= nil
        if search == " " or search:len() < 1 then
            visible = true
        end
        mod_item:SetVisible(visible)
    end
    self._list:AlignItems()
end

function BeardLibModsMenu:UpdateAllMods(no_dialog)
    local tbl = {}
    for _, mod_item in pairs(self._list._my_items) do
        local download = mod_item:GetItem("Download")
        if download:Enabled() then
            table.insert(tbl, {name = mod_item.name, value = mod_item})
        end
    end

    if no_dialog == true then
        self:UpdatesModsByList(tbl)
    else        
        BeardLib.managers.dialog:SimpleSelectList():Show({force = true, list = tbl, selected_list = tbl, callback = callback(self, self, "UpdatesModsByList")})
    end
end

function BeardLibModsMenu:UpdatesModsByList(list)
    for _, item in pairs(list) do
        local download = item.value:GetItem("Download")
        if download:Enabled() then
            download:SetEnabled(false)
            download:RunCallback()
        end
    end
end

function BeardLibModsMenu:SetShowImportantUpdatesNotice(menu, item)
    BeardLib.Options:SetValue("ImportantNotice", item:Value())    
end

function BeardLibModsMenu:ViewMod(mod)
    mod.update_module_data.module:ViewMod()
end

function BeardLibModsMenu:BeginModDownload(mod)
    self:SetModStatus(self._list:GetItemByLabel(mod), "beardlib_waiting")
    mod.update_module_data.module:DownloadAssets()
end

local megabytes = (1024 ^ 2)
function BeardLibModsMenu:SetModProgress(mod, id, bytes, total_bytes)
    local mod_item = self._list:GetItemByLabel(mod)
    if mod_item and alive(mod_item) then
        local progress = bytes / total_bytes
        local mb = bytes / megabytes
        local total_mb = total_bytes / megabytes
        mod_item:GetItem("Status"):SetTextLight(string.format(self._downloading_string.."%.2f/%.2fmb(%.0f%%)", mb, total_mb, tostring(progress * 100)))
        mod_item:Panel():child("DownloadProgress"):set_w(mod_item:Panel():w() * progress)
        local downbtn = mod_item:GetItem("Download")
        if downbtn:Enabled() then
            downbtn:SetEnabled(false)
        end
    end
end

function BeardLibModsMenu:SetModInstallingUpdate(mod)
    local mod_item = self._list:GetItemByLabel(mod)
    if mod_item then
        self:SetModStatus(mod_item, "beardlib_download_complete")
        mod_item:Panel():child("DownloadProgress"):set_w(0)
    end
end

function BeardLibModsMenu:SetModFailedUpdate(mod)
    local mod_item = self._list:GetItemByLabel(mod)
    if mod_item then
        self:SetModStatus(mod_item, "beardlib_download_failed")
        mod_item:Panel():child("DownloadProgress"):set_w(0)
    end
end

function BeardLibModsMenu:SetModNormal(mod)
    local mod_item = self._list:GetItemByLabel(mod)
    if mod_item then
        self:SetModStatus(mod_item, "beardlib_updated")
        mod_item:Panel():child("DownloadProgress"):set_w(0)
        mod_item:GetItem("Download"):SetEnabled(false)
        self:UpdateTitle(mod)
    end
    table.delete(self._waiting_for_update, mod)
end

function BeardLibModsMenu:SetModStatus(mod_item, status, not_localized)
    if mod_item then
        mod_item:GetItem("Status"):SetText(not_localized and status or managers.localization:text(status))
    end
end

function BeardLibModsMenu:SetModNeedsUpdate(mod, new_version)
    local mod_item = self._list:GetItemByLabel(mod)
    local loc = managers.localization
    
    if mod_item then
        self:SetModStatus(mod_item, loc:text("beardlib_waiting_update")..(new_version and "("..new_version..")" or ""), true)
        mod_item:GetItem("Download"):SetEnabled(true)
        mod_item:SetIndex(mod.Name == "BeardLib" and 1 or 2)
    else
        mod.NeedsUpdate = true
    end
    if not table.has(self._waiting_for_update, mod) then
        table.insert(self._waiting_for_update, mod)
    end
    local loc = managers.localization
    self._notif_id = self._notif_id or BLT.Notifications:add_notification({title = loc:text("beardlib_updates_available"), text = loc:text("beardlib_updates_available_desc"), priority = 1})
end

return BeardLibModsMenu