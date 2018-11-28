BeardLibModsMenu = BeardLibModsMenu or class() 
function BeardLibModsMenu:init()
    local accent_color = BeardLib.Options:GetValue("MenuColor")
	self._menu = MenuUI:new({
        name = "BeardLibEditorMods",
        layer = 1000,
        offset = 6,
        localized = true,
        animate_toggle = true,
        accent_color = accent_color,
        foreground = accent_color:contrast(),
        animate_colors = true,
        create_items = ClassClbk(self, "CreateItems"),
        use_default_close_key = true
    })
    self._waiting_for_update = {}
end

function BeardLibModsMenu:SetEnabled(enabled)
    self._menu:SetEnabled(enabled)
end

function BeardLibModsMenu:CreateItems(menu)
    self._downloading_string = managers.localization:text("beardlib_downloading")    
    
    self._holder = menu:Menu({
        name = "Main",
		scrollbar = false,
        background_color = Color(0.8, 0.2, 0.2, 0.2),
        highlight_color = menu.foreground:with_alpha(0.1),
        size = 20,
    })
    self._menu._panel:rect({
        name = "title_bg",
        layer = 2,
        color = self._menu.accent_color,
        h = 34,
    })
    local text = self._holder:Divider({
        name = "title",
        text = "beardlib_mods_manager",
        position = {4, 6},
        count_as_aligned = true
    })
    self._holder:Button({
        name = "Close",
        text = "beardlib_close",
        size_by_text = true,
        position = "RightTopOffset-xy",
        on_callback = ClassClbk(self, "SetEnabled", false)
    })
    self._holder:Button({
        name = "UpdateAllMods",
        text = "beardlib_update_all",
        size_by_text = true,
        position = SimpleClbk(self._holder.AlignRight),
        on_callback = ClassClbk(self, "UpdateAllMods"),
    })
    self._holder:Button({
        name = "Settings",
        text = "beardlib_settings",
        size_by_text = true,
        position = SimpleClbk(self._holder.AlignRight),
        on_callback = ClassClbk(self, "OpenSettings"),
    })
    self._holder:TextBox({
        name = "search",
        text = false,
        w = 300,
        focus_mode = true,
        line_color = self._holder.foreground,
        control_slice = 1,
        position = function(item, last_item)
            item:SetPositionByString("Center")
            item:Panel():set_y(item:OffsetY())
        end,
        on_callback = ClassClbk(self, "SearchMods")
    })
    self._list = self._holder:Menu({
        name = "ModList",
        h = self._holder:ItemsHeight() - text:OuterHeight() - (self._holder.offset[2] * 2),
        fit_width = false,
        offset = 4,
		size = 16,
        position = "CenterxBottomOffset-y",
        auto_align = false,
        align_method = "grid",
	})
	local base = BeardLib.Frameworks.base
	self:AddMod(BeardLib, base)
	local done_mods = {}
	for _, framework in pairs(BeardLib.Frameworks) do
		if not framework.hidden then
			for _, mod in pairs(framework._loaded_mods) do
				self:AddMod(mod, framework)
				done_mods[mod] = true
			end
		end
	end
	--Old mods/Lua based
	for _, mod in pairs(BeardLib.Mods) do
		if not done_mods[mod] then
			self:AddMod(mod, base)
		end
	end
    self._list:AlignItems(true)
end

local texutre_ids = Idstring("texture")
local cap = string.capitalize
function BeardLibModsMenu:AddMod(mod, framework)
    local disabled_mods = BeardLib.Options:GetValue("DisabledMods")
    local show_images = BeardLib.Options:GetValue("ShowImages")
    local loc = managers.localization
	local name = mod.Name or "Missing name?"
	local type = framework.type_name or "base"
	local blt_mod = type == "base"
	local color = framework.menu_color
    local s = (self._list:ItemsWidth() / 5) - self._list.offset[1] - 1

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
        w = s,
        h = show_images and s or s / 1.5,
        scrollbar = false,
        auto_align = false,
        auto_foreground = true,
        accent_color = concol,
        highlight_color = concol,
        background_color = color:with_alpha(0.8)
    })
    self._list:SetScrollSpeed(mod_item:Height())
    local text = function(t, opt)
        return mod_item:Divider(table.merge({text_vertical = "top", text = t, localized = false}, opt))
	end
    if show_images then
		local img = mod._config.image
		local auto_color = img == nil
		if not auto_color and mod._config.auto_image_color then
			auto_color = true
		end
        img = img and DB:has(texutre_ids, img:id()) and img or nil
        local image = mod_item:Image({
            name = "Image",
            w = 100,
			h = 100,
			foreground = Color.white,
			auto_foreground = auto_color,
            count_as_aligned = true,
            texture = img or "guis/textures/pd2/none_icon",
            position = "CenterTop"
        })
    end
    local t = text(tostring(name), {name = "Title", size = 20})
    if t:Height() == t.size then
        text("")
	end

	local txt = "beardlib_mod_type_" .. type	
	if loc._custom_localizations[txt] then
		text("Type: "..loc:text("beardlib_mod_type_" .. type))
	else
		text("Type: "..cap(type))
	end

    text("", {name = "Status"})
    local p = mod_item:Toggle({
        name = "Enabled",
        text = false,
        enabled = not blt_mod,
        w = 24,
        h = 24,
        size = 24,
        highlight_color = Color.transparent,
        fit_width = false,
        value = disabled_mods[mod.ModPath] ~= true,
        on_callback = ClassClbk(self, "SetModEnabled", mod),
        position = "TopRightOffset-xy"
    })
    mod_item:Panel():rect({
        name = "DownloadProgress",
        color = color:contrast():with_alpha(0.25),
        w = 0,
    })
    if mod.update_module_data ~= nil then
        mod_item:Button({
            name = "View",
            on_callback = ClassClbk(self, "ViewMod", mod),
            text = "beardlib_visit_page"
        })
    end
    mod_item:Button({
        name = "Download",
        on_callback = ClassClbk(self, "BeginModDownload", mod),
        enabled = false,
        fit_width = false,
        position = "BottomOffset-y",
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

function BeardLibModsMenu:SearchMods(item)
    for _, mod_item in pairs(self._list._my_items) do
        local search = tostring(item:Value()):lower()
        local visible = tostring(mod_item.name):lower():find(search) ~= nil
        if search == " " or search:len() < 1 then
            visible = true
        end
        mod_item:SetVisible(visible)
    end
    self._list:AlignItems()
end

function BeardLibModsMenu:UpdateAllMods()
    local tbl = {}
    for _, mod_item in pairs(self._list._my_items) do
        local download = mod_item:GetItem("Download")
        if download:Enabled() then
            table.insert(tbl, {name = mod_item.name, value = mod_item})
        end
    end
    BeardLib.managers.dialog:SimpleSelectList():Show({force = true, list = tbl, selected_list = tbl, callback = ClassClbk(self, "UpdatesModsByList")})
end

function BeardLibModsMenu:OpenSettings()
    BeardLib.managers.dialog:Simple():Show({
        title = managers.localization:text("beardlib_b_settings"),
        create_items = function(menu)
            local holder = menu:Menu({name = "settings_holder", auto_height = true, localized = true})
            holder:ColorTextBox({
                name = "MenuColor",
                text = "beardlib_menu_color",
                value = BeardLib.Options:GetValue("MenuColor"),
                on_callback = ClassClbk(self, "SetOption")
            })
            holder:Toggle({
                name = "ShowImages",
                text = "beardlib_show_images",
                value = BeardLib.Options:GetValue("ShowImages"),
                on_callback = ClassClbk(self, "SetOption")
            })
            holder:Toggle({
                name = "ImportantNotice",
                text = "beardlib_important_notice",
                help = "beardlib_important_notice_help",
                value = BeardLib.Options:GetValue("ImportantNotice"),
                on_callback = ClassClbk(self, "SetOption")
            })
            if FileIO:Exists("mods/developer.txt") then
                holder:Toggle({
                    name = "DevMode",
                    text = "beardlib_dev_mode",
                    help = "beardlib_dev_mode_help",
                    value = BeardLib.Options:GetValue("DevMode"),
                    on_callback = ClassClbk(self, "SetOption")
                })    
            end
            holder:Button({
                name = "ResetSettings",
                text = "beardlib_reset_settings",
                on_callback = ClassClbk(self, "ResetOptions")
            })
        end
    })
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

function BeardLibModsMenu:SetOption(item)
    BeardLib.Options:SetValue(item:Name(), item:Value())    
end

function BeardLibModsMenu:ResetOptions(item)
    for _, I in pairs(item.parent:Items()) do
        local option = BeardLib.Options:GetOption(I:Name())
        if option then
            I:SetValue(option.default_value, true)
        end
    end
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

function BeardLibModsMenu:SetModFailedWrite(mod)
    local mod_item = self._list:GetItemByLabel(mod)
    if mod_item then
        self:SetModStatus(mod_item, "beardlib_write_failed")
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
        self._list:AlignItems(true)
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