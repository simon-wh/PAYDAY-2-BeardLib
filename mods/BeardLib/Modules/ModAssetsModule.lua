ModAssetsModule = ModAssetsModule or class(ModuleBase)
ModAssetsModule.type_name = "AssetUpdates"
ModAssetsModule._default_version_file = "version.txt"
ModAssetsModule._providers = {
    modworkshop = {
        version_api_url = "http://manager.modworkshop.net/GetDownloadVersion/$id$.txt",
        download_info_url = "http://manager.modworkshop.net/GetSingleDownload/$id$.json",
        download_api_url = "http://modworkshop.net/mydownloads/downloads/$download$",
        page_url = "http://downloads.modworkshop.net/$id$"
    }
}
ModAssetsModule._providers.modworkshop.download_file_func = function(self)
    local download_info_url = self._mod:GetRealFilePath(self.provider.download_info_url, self)
    dohttpreq(download_info_url,
        function(data, id)
            local ret, d_data = pcall(function() return json.decode(data) end)
            if ret then
                self:_DownloadAssets(d_data[tostring(self.id)])
            else
                self:log("Failed to parse the data received from Modworkshop!")
            end
        end
    )
end
ModAssetsModule._providers.lastbullet = clone(ModAssetsModule._providers.modworkshop)

function ModAssetsModule:init(core_mod, config)
    self.required_params = table.add(clone(self.required_params), {"id"})
    if not ModAssetsModule.super.init(self, core_mod, config) then
        return false
    end

    self.id = self._config.id

    if self._config.provider then
        if self._providers[self._config.provider] then
            self.provider = self._providers[self._config.provider]
        else
            self:log("[ERROR] No provider information for provider: %s", self._config.provider)
            return
        end
    elseif self._config.custom_provider then
        local provider_details = self._config.custom_provider
        if provider_details.update_func then provider_details.update_func = self._mod:StringToCallback(provider_details.update_func, self) end
        if provider_details.download_file_func then provider_details.download_file_func = self._mod:StringToCallback(provider_details.download_file_func, self) end
        self.provider = provider_details
    else
        self:log("[ERROR] No provider can be found for mod assets")
        return
    end

    self.folder_names = self._config.use_local_dir and {table.remove(string.split(self._mod.ModPath, "/"))} or (type(self._config.folder_name) == "string" and {self._config.folder_name} or BeardLib.Utils:RemoveNonNumberIndexes(self._config.folder_name))
    self.install_directory = (self._config.install_directory and self._mod:GetRealFilePath(self._config.install_directory, self)) or (self._config.use_local_path ~= false and BeardLib.Utils.Path:GetDirectory(self._mod.ModPath)) or BeardLib.config.mod_override_dir
    self.version_file = self._config.version_file and self._mod:GetRealFilePath(self._config.version_file, self) or BeardLib.Utils.Path:Combine(self.install_directory, self.folder_names[1], self._default_version_file)
    self._version = 0
    
    self._update_manager_id = self._mod.Name .. self._name
    self._mod.update_key = (self._config.is_standalone ~= false) and self.id
    self:RetrieveCurrentVersion()

    if not self._config.manual_check then
        self:RegisterAutoUpdateCheckHook()
    end

    return true
end

function ModAssetsModule:GetMainInstallDir()
    return BeardLib.Utils.Path:GetDirectory(self.version_file)
end

function ModAssetsModule:RegisterAutoUpdateCheckHook()
    Hooks:Add("MenuManagerOnOpenMenu", self._mod.Name .. self._name .. "UpdateCheck", function( self_menu, menu, index )
        if menu == "menu_main" and not LuaNetworking:IsMultiplayer() then
            self:CheckVersion()
        end
    end)
end

function ModAssetsModule:RetrieveCurrentVersion()
    if io.file_is_readable(self.version_file) then
        local version = io.open(self.version_file):read("*all")
        if tonumber(version) then
            self._version = tonumber(version)
        else
            self:log("[ERROR] Unable to parse version '%s' as a number. File: %s", version, self.version_file)
        end
    elseif tonumber(self._config.version) then
        self._version = tonumber(self._config.version)
    else
        self:log("[ERROR] Unable to get version for '%s's assets. File: %s", self._mod.Name, self.version_file)
    end
end

function ModAssetsModule:CheckVersion(force)
    if not force and not BeardLib.managers.asset_update:CheckUpdateStatus(self._update_manager_id) then
        return
    end

    if self.provider.update_func then
        self.provider.update_func(force)
    else
        self:_CheckVersion(force)
    end
end

function ModAssetsModule:_CheckVersion(force)
    local version_url = self._mod:GetRealFilePath(self.provider.version_api_url, self)
    dohttpreq(version_url, function(data, id)
        self:log("Received data '%s' from the server", tostring(data))
        if tonumber(data) then
            if tonumber(data) > self._version then
                BeardLib.managers.asset_update:RegisterUpdate(callback(self, self, "ShowRequiresUpdatePrompt"))
            elseif force then
                self:ShowNoChangePrompt()
            end
        else
            --self:ShowErrorPrompt()
            self:log("[ERROR] Unable to parse string '%s' as a version number", data)
        end
    end)
end

function ModAssetsModule:ShowNoChangePrompt()
    QuickMenu:new(
        managers.localization:text("mod_assets_no_change"),
        managers.localization:text("mod_assets_no_change_desc"),
        {
            {
                text = managers.localization:text("menu_ok"),
                is_cancel_button = true
            }
        },
        true
    )
end

function ModAssetsModule:ShowErrorPrompt()
    QuickMenu:new(
        managers.localization:text("mod_assets_error"),
        managers.localization:text("mod_assets_error_desc"),
        {
            {
                text = managers.localization:text("menu_ok"),
                is_cancel_button = true
            }
        },
        true
    )
end

function ModAssetsModule:ShowRequiresUpdatePrompt()
    local lookup_tbl = {
        ["mod"] = self._mod.Name,
    }
    QuickMenu:new(
        managers.localization:text("mod_assets_updates_available"),
        managers.localization:text("mod_assets_updates_available_desc", lookup_tbl),
        {
            {
                text = managers.localization:text("mod_assets_updates_download_now"),
                callback = callback(self, self, "DownloadAssets")
            },
            {
                text = managers.localization:text("mod_assets_visit_page"),
                callback = callback(self, self, "ViewMod")
            },
            {
                text = managers.localization:text("mod_assets_updates_ignore"),
                callback = callback(self, self, "IgnoreUpdate")
            },
            {
                text = managers.localization:text("mod_assets_updates_remind_later"),
                callback = callback(self, self, "SetReady")
            }
        },
        true
    )
    --BeardLib.managers.updates_menu:AddUpdate(self)
end

function ModAssetsModule:SetReady()
    BeardLib.managers.asset_update._ready_for_update = true
end

function ModAssetsModule:IgnoreUpdate()
    BeardLib.managers.asset_update:SetUpdateStatus(self._update_manager_id, false)
    self:SetReady()
end

function ModAssetsModule:DownloadAssets()
    if self.provider.download_file_func then
        self.provider.download_file_func(self)
    else
        self:_DownloadAssets()
    end
end

function ModAssetsModule:ViewMod()
    Steam:overlay_activate("url", self._mod:GetRealFilePath(self.provider.page_url, self))
end

function ModAssetsModule:_DownloadAssets(data)
    local download_url = self._mod:GetRealFilePath(self.provider.download_api_url, data or self)
    self:log("Downloading assets from url: %s", download_url)
    managers.menu:show_download_progress(self._mod.Name .. " " .. managers.localization:text("mod_assets_title"))
    dohttpreq(download_url, callback(self, self, "StoreDownloadedAssets", false), LuaModUpdates.UpdateDownloadDialog)
end

function ModAssetsModule:StoreDownloadedAssets(config, data, id)
    config = config or self._config
	local ret, pdata = pcall(function()
        LuaModUpdates:SetDownloadDialogKey("mod_download_complete", true)
    	BeardLib:log("[INFO] Finished downloading assets")

    	if string.is_nil_or_empty(data) then
    		BeardLib:log("[ERROR] Assets download failed, received data was invalid")
    		LuaModUpdates:SetDownloadDialogKey("mod_download_failed", true)
    		return
    	end

    	local temp_zip_path = os.tmpname() .. ".zip"

    	local file = io.open(temp_zip_path, "wb+")
    	if file then
    		file:write(data)
    		file:close()
        else
            self:log("[ERROR] An error occured while trying to store the downloaded asset data")
            return
    	end
        if self._config and not self._config.dont_delete then
            for _, dir in pairs(self.folder_names) do
                local path = BeardLib.Utils.Path:Combine(self.install_directory, dir)
                if _G.file.DirectoryExists(path) then
                    io.remove_directory_and_files(path .. "/")
                end
            end
        end
        unzip(temp_zip_path, config.install_directory or self.install_directory)
        LuaModUpdates:SetDownloadDialogKey("mod_extraction_complete", true)
        os.remove(temp_zip_path)

    	LuaModUpdates._current_download_dialog = nil
        ModAssetsModule:SetReady()
        if config.done_callback then
            config.done_callback()
        end
	end)
	if not ret then
		BeardLib:log("[ERROR] " .. pdata)
	end
end

function ModAssetsModule:BuildMenu(node)
    local main_node = MenuHelperPlus:NewNode(nil, {
        name = self._mod.Name .. self._name .. "Node"
    })

    self:InitializeNode(node)

    MenuHelperPlus:AddButton({
        id = "ModAssetsManagementButton",
        title = "ModAssetsManagementTextID",
        desc = "ModAssetsManagementDescID",
        node = node,
        next_node = menu_name
    })

    managers.menu:add_back_button(main_node)
end

function ModAssetsModule:InitializeNode(node)
    MenuCallbackHandler.ModAssetsToggleAutoUpdates_Changed = function(this, item)
        BeardLib.managers.asset_update:SetUpdateStatus(item._parameters.mod_key, item:value() == "on")
    end

    MenuHelperPlus:AddToggle({
        id = "ModAssetsToggleAutoUpdates",
        title = "ModAssetsToggleAutoUpdatesTextID",
        desc = "ModAssetsToggleAutoUpdatesDescID",
        node = node,
        callback = "ModAssetsToggleAutoUpdates_Changed",
        value = BeardLib.managers.asset_update:CheckUpdateStatus(self._update_manager_id),
        merge_data = { mod_key = self._update_manager_id }
    })

    MenuCallbackHandler.ModAssetsCheckForUpdates = function(this, item)
        self:CheckVersion(true)
    end

    MenuHelperPlus:AddButton({
        id = "ModAssetsCheckUpdates",
        title = "ModAssetsCheckUpdatesTextID",
        desc = "ModAssetsCheckUpdatesDescID",
        node = node,
        callback = "ModAssetsCheckForUpdates",
        enabled = not not managers.menu._is_start_menu,
        merge_data = { mod_key = self._mod.GlobalKey }
    })
end

BeardLib:RegisterModule(ModAssetsModule.type_name, ModAssetsModule)