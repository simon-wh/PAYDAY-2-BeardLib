BeardLibModsMenu = BeardLibModsMenu or BeardLib:MenuClass("Mods")
function BeardLibModsMenu:init(data)
    data = data or {}
    local accent_color = BeardLib.Options:GetValue("MenuColor")
	self._menu = MenuUI:new({
        name = "BeardLibEditorMods",
        layer = 1000,
        offset = 6,
        localized = true,
        enabled = data.enabled,
        animate_toggle = true,
        animate_colors = true,
        accent_color = accent_color,
        foreground = accent_color:contrast(),
        create_items = ClassClbk(self, "CreateItems"),
        use_default_close_key = true
    })
    self._waiting_for_update = {}

    -- Deprecated, try not to use.
    BeardLib.managers.mods_menu = self
end

--DEV ONLY--
function BeardLibModsMenu:Destroy()
    local enabled = self._menu:Enabled()
    self._menu:Destroy()
    return {enabled = enabled}
end

function BeardLibModsMenu:SetEnabled(enabled)
    self._menu:SetEnabled(enabled)
end

function BeardLibModsMenu:CreateItems(menu)
    self._menu = menu
    self._downloading_string = managers.localization:text("beardlib_downloading")

    self._holder = menu:Holder({
        name = "Main",
        background_color = Color(0.8, 0.2, 0.2, 0.2),
        highlight_color = menu.foreground:with_alpha(0.1),
        size = 20,
    })

    self._top = menu:Grid({
        name = "Top",
        background_color = self._menu.accent_color,
        h = 34
    })
    self._top:Image({
        texture = "guis/textures/beardlib_logo",
        position = "Centery",
        count_as_aligned = true,
        size = 32
    })
    self._top:FitDivider({
        name = "title",
        size = 24,
        position = "Centery",
        count_as_aligned = true,
        text = "beardlib_mods_manager"
    })
    local button_holder = self._top:Holder({
        name = "button_holder",
        align_method = "grid_from_right",
        offset = 4,
        w = 500,
        position = "RightTop"
    })
    button_holder:Button({
        name = "Close",
        text = "beardlib_close",
        size_by_text = true,
        on_callback = ClassClbk(self, "SetEnabled", false)
    })
    button_holder:Button({
        name = "UpdateAllMods",
        text = "beardlib_update_all",
        size_by_text = true,
        on_callback = ClassClbk(self, "UpdateAllMods"),
    })
    button_holder:Button({
        name = "Settings",
        text = "beardlib_settings",
        size_by_text = true,
        on_callback = ClassClbk(self, "OpenSettings"),
    })
    button_holder:Button({
        name = "Custom achievements",
        text = "beardlib_achieves_title",
        help = "beardlib_achieves_desc",
        size_by_text = true,
        callback = ClassClbk(BeardLib.Menus.Achievement, "SetEnabled", true)
    })

    self._top:TextBox({
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
    self._list = self._holder:GridMenu({
        name = "ModList",
        h = self._holder:ItemsHeight() - self._top:OuterHeight(),
        fit_width = false,
        offset = 4,
		size = 16,
        scroll_speed = managers.menu:is_pc_controller() and 128 or nil,
        position = "CenterxBottomOffset-y",
        auto_align = false
	})
	local base = BeardLib.Frameworks.Base
	self:AddMod(BeardLib, base)
    local done_mods = {}
    local deprecated = {add = true, map = true, base = true}
	for name, framework in pairs(BeardLib.Frameworks) do
		if not framework.hidden and not deprecated[name] then
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
    local show_images = BeardLib.Options:GetValue("ShowImages")
    local loc = managers.localization
	local name = mod.Name or "Missing name"
	local type = framework.type_name or "Base"
	local blt_mod = type == "Base"
	local color = framework.menu_color
    local s = self._list:ItemsWidth(5) / 5

    if mod._config.color then
        local orig_color = color
        color = BeardLib.Utils:normalize_string_value(mod._config.color)
        if type_name(color) ~= "Color" then
            mod:Err("The color defined is not a valid color!")
            color = orig_color
        end
    end
    local concol = color:contrast():with_alpha(0.1)
    local mod_item = self._list:Holder({
        name = name,
        label = mod,
        w = s,
        h = show_images and s or s / 1.56,
        offset = 4,
        auto_align = false,
        auto_foreground = true,
        align_method = "centered_grid",
        accent_color = concol,
        highlight_color = concol,
        background_color = color:with_alpha(0.8)
    })
    local text = function(n, t, opt)
        return mod_item:Divider(table.merge({name = n, text = t, max_width = mod_item:ItemsWidth(), size_by_text = true, text_offset = 1, offset = 0, localized = false}, opt))
    end
    if show_images then
		local img = mod._config.image
		local auto_color = img == nil
		if not auto_color and mod._config.auto_image_color then
			auto_color = true
		end
        img = img and DB:has(texutre_ids, img:id()) and img or nil
        mod_item:Image({
            name = "Image",
            w = 90,
			h = 90,
            foreground = Color.white,
            alone_in_row = true,
			auto_foreground = auto_color,
            count_as_aligned = true,
            texture = img or "guis/textures/pd2/none_icon",
            position = "CenterTop"
        })
    end
    mod_item:ImageButton({
        name = "Settings",
        size = 24,
        texture = "guis/textures/menu_ui_icons",
        texture_rect = {2, 48, 38, 38},
        on_callback = ClassClbk(self, "OpenModSettings", mod, blt_mod),
        position = "TopRightOffset-xy"
    })

    local txt = "beardlib_mod_type_" .. type

    if not mod:Enabled() then
        text("Disabled", "["..managers.localization:text("beardlib_mod_disabled").."]")
    end

    if loc._custom_localizations[txt] then
		text("Type", "["..loc:text("beardlib_mod_type_" .. type).."]")
	else
		text("Type", "["..cap(type).."]")
    end

    text("Title", tostring(name))

    if mod._config.author then
        text("Author", loc:text("beardlib_mod_by", {author = mod._config.author}))
    end

    text("Status", "", {size_by_text = false, text_align = "center"})

    mod_item:Panel():rect({
        name = "DownloadProgress",
        color = color:contrast():with_alpha(0.3),
        w = 0,
    })

    local updates = mod:GetModules(ModAssetsModule.type_name)
    local main_update = updates[1]
    if main_update and main_update._data and main_update._data.provider and main_update._data.provider.page_url then
        mod_item:Button({
            name = "View",
            on_callback = ClassClbk(self, "ViewMod", mod),
            text = "beardlib_visit_page"
        })
    end

    if #updates > 1 then
        mod_item.multiple = true

        local list = mod_item:Menu({
            name = "List",
            background_color = mod_item.background_color:contrast():with_alpha(0.8),
            auto_foreground = true,
            count_as_aligned = true,
            position = "CenterxBottomOffset-y",
            size = 13,
            h = 90,
        })
        for _, update in pairs(updates) do
            local holder = list:Holder({update = update, inherit_values = {offset = 2}, private = {offset = 0}, align_method = "grid"})
            holder:Divider({text = update._config.custom_name or loc:text("beardlib_update"), localized = update._config.localized or false, size_by_text = true})
            holder:Button({
                name = "Download",
                update = update,
                on_callback = ClassClbk(self, "BeginModDownload", update),
                enabled = false,
                position = "Right",
                help_localized = false,
                show_help_time = 0.5,
                count_as_aligned = true,
                size_by_text = true,
                text = "beardlib_updates_download_now"
            })
            holder:Panel():rect({
                name = "DownloadProgress",
                color = list.background_color:contrast():with_alpha(0.3),
                index = 50,
                w = 0,
            })
        end
    else
        if updates[1] then
            text("Title", loc:text("beardlib_version", {version = tostring(updates[1].version)}), {text_align = "center"})
        end
        mod_item:Button({
            name = "Download",
            on_callback = ClassClbk(self, "BeginModDownload", updates[1]),
            text_align = "center",
            w = 200,
            enabled = false,
            text = "beardlib_updates_download_now"
        })
    end

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
        if title then
            mod_item:GetItem("Title"):SetText(mod.Name or "Missing name?")
        end
    end
end

function BeardLibModsMenu:SearchMods(item)
    for _, mod_item in pairs(self._list:Items()) do
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
    for _, mod_item in pairs(self._list:Items()) do
        local download = mod_item:GetItem("Download")
        if download:Enabled() then
            table.insert(tbl, {name = mod_item.name, value = mod_item})
        end
    end
    BeardLib.Managers.Dialog:SimpleSelectList():Show({force = true, list = tbl, selected_list = tbl, callback = ClassClbk(self, "UpdatesModsByList")})
end

function BeardLibModsMenu:OpenModSettings(mod, blt_mod)
    BeardLib.Managers.Dialog:Simple():Show({
        title = managers.localization:text("beardlib_mod_settings", {mod = mod.Name or "Missing name"}),
        create_items = function(menu)
            local mod_settings = mod:GetSettings()
            local holder = menu:Menu({name = "settings_holder", auto_height = true, localized = true})
            holder:Toggle({
                name = "Enabled",
                enabled = not blt_mod,
                text = "beardlib_mod_enabled",
                help = "beardlib_mod_enabled_help",
                value = mod_settings.Enabled ~= false,
                on_callback = ClassClbk(self, "SetModSetting", mod)
            })
            holder:Toggle({
                name = "DevelopMode",
                text = "beardlib_mod_develop_mode",
                help = "beardlib_mod_develop_mode_help",
                value = mod_settings.DevelopMode,
                on_callback = ClassClbk(self, "SetModSetting", mod)
            })
            holder:Toggle({
                name = "IgnoreUpdates",
                text = "beardlib_mod_ignore_updates",
                help = "beardlib_mod_ignore_updates_help",
                value = mod_settings.IgnoreUpdates,
                on_callback = ClassClbk(self, "SetModSetting", mod)
            })
            if mod.AssetUpdates and mod.AssetUpdates._config.optional_versions then
                holder:ComboBox({
                    name = "OptionalVersion",
                    value = mod:GetSetting("OptionalVersion"),
                    text = "beardlib_mod_optional_version",
                    help = "beardlib_mod_optional_version_help",
                    items_localized = false,
                    free_typing = true, -- this isn't really needed, but string keys.
                    on_callback = ClassClbk(self, "SetModSetting", mod),
                    --Using string keys due to indexes sometimes not being correct, messy
                    items = table.remap(mod.AssetUpdates._config.optional_versions,
                    function (k, _)
                        if type(k) == "string" and k ~= "_meta" then
                            return k, k
                        end

                        return "stable", "stable" --can't be nil and need to add stable as an option anyways.
                    end)
                })
            end
        end
    })
end

function BeardLibModsMenu:SetModSetting(mod, item)
    mod:SetSetting(item:Name(), item:Value())
end

function BeardLibModsMenu:OpenSettings()
    BeardLib.Managers.Dialog:Simple():Show({
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
            holder:Toggle({
                name = "ShowErrorsDialog",
                text = "beardlib_show_errors_dialog",
                help = "beardlib_show_errors_dialog_help",
                value = BeardLib.Options:GetValue("ShowErrorsDialog"),
                on_callback = ClassClbk(self, "SetOption")
            })
            holder:Toggle({
                name = "OptimizedMusicLoad",
                text = "beardlib_optimized_music_load",
                help = "beardlib_optimized_music_load_help",
                value = BeardLib.Options:GetValue("OptimizedMusicLoad"),
                on_callback = ClassClbk(self, "SetOption")
            })
            holder:Toggle({
                name = "DevMode",
                text = "beardlib_dev_mode",
                help = "beardlib_dev_mode_help",
                value = BeardLib.Options:GetValue("DevMode"),
                on_callback = ClassClbk(self, "SetOption")
            })
            holder:Toggle({
                name = "GithubUpdates",
                text = "beardlib_github_updates",
                help = "beardlib_github_updates_help",
                value = BeardLib.Options:GetValue("GithubUpdates"),
                on_callback = ClassClbk(self, "SetOption")
            })
            holder:Toggle({
                name = "LogSounds",
                text = "beardlib_log_sounds",
                help = "beardlib_log_sounds_help",
                value = BeardLib.Options:GetValue("LogSounds"),
                on_callback = ClassClbk(self, "SetOption")
            })
            -- Maybe at some point I'll improve this and make something like a log level but for now we have this.
            holder:Toggle({
                name = "LogInit",
                text = "beardlib_log_init",
                help = "beardlib_log_init_help",
                value = BeardLib.Options:GetValue("LogInit"),
                on_callback = ClassClbk(self, "SetOption")
            })
            if BeardLib.DevMode then
                holder:Button({
                    name = "ErrorsDialog",
                    text = "beardlib_errors_dialog",
                    on_callback = ClassClbk(BeardLib, "ShowErrorsDialog")
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
        if item.value.multiple then
            for _, list_item in pairs(item.value:GetItem("List"):Items()) do
                local download = list_item:GetItem("Download")
                if download:Enabled() then
                    if download:Enabled() then
                        download:SetEnabled(false)
                        download:RunCallback()
                    end
                end
            end
        else
            local download = item.value:GetItem("Download")
            if download:Enabled() then
                download:SetEnabled(false)
                download:RunCallback()
            end
        end
    end
end

function BeardLibModsMenu:SetOption(item)
    BeardLib.Options:SetValue(item:Name(), item:Value())
end

function BeardLibModsMenu:ResetOptions(item)
    for _, I in pairs(item.parent:Items()) do
        local default_value = BeardLib.Options:GetDefaultValue(I:Name())
        if default_value then
            I:SetValue(default_value, true)
        end
    end
end

function BeardLibModsMenu:ViewMod(mod)
    mod.update_module_data.module:ViewMod()
end

function BeardLibModsMenu:BeginModDownload(module)
    self:SetModStatus(self._list:GetItemByLabel(module._mod), "beardlib_waiting")
    module:DownloadAssets()
end

local megabytes = (1024 ^ 2)
function BeardLibModsMenu:SetModProgress(module, id, bytes, total_bytes)
    local mod_item = self._list:GetItemByLabel(module._mod)
    if alive(mod_item) then
        local progress = bytes / total_bytes
        local mb = bytes / megabytes
        local total_mb = total_bytes / megabytes
        local status = mod_item:GetItem("Status")
        status:SetTextLight(string.format(self._downloading_string.."%.2f/%.2fmb(%.0f%%)", mb, total_mb, tostring(progress * 100)))
        self:SetModProgressBar(module, progress, true)
    end
end

function BeardLibModsMenu:SetModProgressBar(module, progress, disable_button)
    local mod_item = self._list:GetItemByLabel(module._mod)
    if mod_item.multiple then
        for _, item in pairs(mod_item:GetItem("List"):Items()) do
            if item.update == module then
                item:Panel():child("DownloadProgress"):set_w(item:Panel():w() * progress)
                local downbtn = item:GetItem("Download")
                if disable_button then
                    downbtn:SetEnabled(false)
                end
            end
        end
    else
        mod_item:Panel():child("DownloadProgress"):set_w(mod_item:Panel():w() * progress)
        local downbtn = mod_item:GetItem("Download")
        if disable_button then
            downbtn:SetEnabled(false)
        end
    end
end

function BeardLibModsMenu:SetModInstallingUpdate(module)
    local mod_item = self._list:GetItemByLabel(module._mod)
    if mod_item then
        self:SetModStatus(mod_item, "beardlib_download_complete")
        self:SetModProgressBar(module, 0)
    end
end

function BeardLibModsMenu:SetModFailedUpdate(module)
    local mod_item = self._list:GetItemByLabel(module._mod)
    if mod_item then
        self:SetModStatus(mod_item, "beardlib_download_failed")
        self:SetModProgressBar(module, 0)
    end
end

function BeardLibModsMenu:SetModFailedWrite(module)
    local mod_item = self._list:GetItemByLabel(module._mod)
    if mod_item then
        self:SetModStatus(mod_item, "beardlib_write_failed")
        self:SetModProgressBar(module, 0)
    end
end

function BeardLibModsMenu:SetModNormal(module)
    local mod_item = self._list:GetItemByLabel(module._mod)
    if mod_item then
        self:SetModStatus(mod_item, "beardlib_updated")
        self:SetModProgressBar(module, 0)
        mod_item:GetItem("Download"):SetEnabled(false)
        self:UpdateTitle(mod)
        if mod_item._on_finish_download_clbk then
            mod_item._on_finish_download_clbk()
            mod_item._on_finish_download_clbk = nil
        end
    end
    table.delete(self._waiting_for_update, mod)
end

function BeardLibModsMenu:SetModStatus(mod_item, status, not_localized)
    if mod_item then
        mod_item:GetItem("Status"):SetText(not_localized and status or managers.localization:text(status))
        mod_item:AlignItems()
    end
end

function BeardLibModsMenu:SetModNeedsUpdate(module, new_version)
    local mod = module._mod
    local mod_item = self._list:GetItemByLabel(mod)
    local loc = managers.localization

    if mod_item then
        self:SetModStatus(mod_item, loc:text(mod_item.multiple and "beardlib_waiting_updates" or "beardlib_waiting_update")..((not mod_item.multiple and new_version) and "("..new_version..")" or ""), true)
        mod_item:SetIndex(mod.Name == "BeardLib" and 1 or 2)
        if mod_item.multiple then
            for _, item in pairs(mod_item:GetItem("List"):Items()) do
                if item.update == module then
                    item:SetIndex(1)
                    local download = item:GetItem("Download")
                    download.help = tostring(new_version)
                    download:SetEnabled(true)
                end
            end
        else
            mod_item:GetItem("Download"):SetEnabled(true)
        end
        self._list:AlignItems(true)
    else
        mod.NeedsUpdate = true
    end
    if not table.contains(self._waiting_for_update, mod) then
        table.insert(self._waiting_for_update, mod)
    end
    self._notif_id = self._notif_id or BLT.Notifications:add_notification({title = loc:text("beardlib_updates_available"), text = loc:text("beardlib_updates_available_desc"), priority = 1})
end

-- Allows you to force start a download, please ask the user beforehand.
function BeardLibModsMenu:ForceDownload(module, clbk)
    local mod = module._mod
    local mod_item = self._list:GetItemByLabel(mod)
    if mod_item then
        mod_item:SetIndex(mod.Name == "BeardLib" and 1 or 2)
        if mod_item.multiple then
            for _, item in pairs(mod_item:GetItem("List"):Items()) do
                if item.update == module then
                    item:SetIndex(1)
                    item:GetItem("Download"):RunCallback()
                    break
                end
            end
        else
            mod_item:GetItem("Download"):RunCallback()
        end
        if clbk then
            mod_item._on_finish_download_clbk = clbk
        end
    end
end