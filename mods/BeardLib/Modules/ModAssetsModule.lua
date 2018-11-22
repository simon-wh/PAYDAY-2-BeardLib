ModAssetsModule = ModAssetsModule or class(BasicModuleBase)
ModAssetsModule.type_name = "AssetUpdates"
ModAssetsModule._default_version_file = "version.txt"
ModAssetsModule._providers = {}
--Load the providers
local providers_dir = BeardLib.config.classes_dir.."/Providers/"
local providers = FileIO:GetFiles(providers_dir)
if providers then
    for _, provider in pairs(providers) do
        dofile(providers_dir..provider)
    end
end

function ModAssetsModule:Load()
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
        if provider_details.check_func then provider_details.check_func = self._mod:StringToCallback(provider_details.check_func, self) end
        if provider_details.download_file_func then provider_details.download_file_func = self._mod:StringToCallback(provider_details.download_file_func, self) end
        self.provider = provider_details
    else
        self:log("[ERROR] No provider can be found for mod assets")
        return
    end

	local path = self._mod:GetPath()
	
	if not self._config.use_local_dir and self._config.folder_name then
		local folder = self._config.folder_name
		self.folder_names = (type(folder) == "string" and {folder} or BeardLib.Utils:RemoveNonNumberIndexes(folder))
	else
		self.folder_names = {table.remove(string.split(path, "/"))} 
	end

	if not self._config.use_local_path and self.install_directory then
		local dir = self._config.install_directory
		self.install_directory = ModCore:GetRealFilePath(dir, self) or BeardLib.config.mod_override_dir
	else
		self.install_directory = Path:GetDirectory(path)
	end

	if self._config.version_file then
		self.version_file = ModCore:GetRealFilePath(self._config.version_file, self)
	elseif not self._config.version then
		self.version_file = Path:Combine(self.install_directory, self.folder_names[1], self._default_version_file)
	end

    self.version = 0
    
    self._update_manager_id = self._mod.Name .. self._name
    local download_url = self._config.downlad_url or (self._config.custom_provider and self._config.custom_provider.download_url) or nil
    self._mod.update_module_data = {
        id = (self._config.is_standalone ~= false) and self.id,
        module = self,
        provider = not download_url and self._config.provider,
        download_url = download_url
    }
    self:RetrieveCurrentVersion()

    if not self._config.manual_check then
        self:RegisterAutoUpdateCheckHook()
    end
end

function ModAssetsModule:GetMainInstallDir()
    return Path:Combine(self.install_directory, self.folder_names[1])
end

function ModAssetsModule:RegisterAutoUpdateCheckHook()
    Hooks:Add("MenuManagerOnOpenMenu", self._mod.Name .. self._name .. "UpdateCheck", function( self_menu, menu, index )
        if menu == "menu_main" and not LuaNetworking:IsMultiplayer() then
            self:CheckVersion()
        end
    end)
end

function ModAssetsModule:RetrieveCurrentVersion()
    if self.version_file and FileIO:Exists(self.version_file) then
        local version = io.open(self.version_file):read("*all")
        if version then
            self.version = version
        end
    elseif self._config.version then
        self.version = self._config.version
    end
    if tonumber(self.version) then -- has to be here, xml seems to fuckup numbers.
        self.version = math.round_with_precision(tonumber(self.version), 4)
    end
end

function ModAssetsModule:CheckVersion(force)
    if not force and not BeardLib.managers.asset_update:CheckUpdateStatus(self._update_manager_id) then
        return
    end

    if self.provider.check_func then
        self.provider.check_func(self, force)
    else
        self:_CheckVersion(force)
    end
end

function ModAssetsModule:PrepareForUpdate()
    if not self._mod then
        return
    end
    BeardLib.managers.mods_menu:SetModNeedsUpdate(self._mod, self._new_version)
    if self._config.important and BeardLib.Options:GetValue("ImportantNotice") then
        local loc = managers.localization
        QuickMenuPlus:new(loc:text("beardlib_mods_manager_important_title", {mod = self._mod.Name}), loc:text("beardlib_mods_manager_important_help"), {{text = loc:text("dialog_yes"), callback = function()
            BeardLib.managers.mods_menu:SetEnabled(true)
        end}, {text = loc:text("dialog_no"), is_cancel_button = true}})
    end
end

function ModAssetsModule:_CheckVersion(force)
    if not self.provider.version_api_url then
        return 
    end
    local version_url = ModCore:GetRealFilePath(self.provider.version_api_url, self)
    local loc = managers.localization
    dohttpreq(version_url, function(data, id)
        self:log("Received version '%s' from the server(local is %s)", tostring(data), tostring(self.version))
        if data and (not self.provider.version_is_number or tonumber(data)) then
            self._new_version = data
            if self._new_version and tostring(self._new_version) ~= tostring(self.version) then
                self:PrepareForUpdate()
            elseif force then
                self:ShowNoChangePrompt()
            end
        else
            self:log("[ERROR] Unable to parse string '%s' as a version number", data)
        end
    end)
end

function ModAssetsModule:ShowNoChangePrompt()
    QuickMenu:new(
        managers.localization:text("beardlib_no_change"),
        managers.localization:text("beardlib_no_change_desc"),
        {{
            text = managers.localization:text("menu_ok"),
            is_cancel_button = true
        }},
        true
    )
end

function ModAssetsModule:SetReady()
    BeardLib.managers.asset_update._ready_for_update = true
end

function ModAssetsModule:DownloadAssets()
    if self.provider.download_file_func then
        self.provider.download_file_func(self)
    else
        return self:_DownloadAssets()
    end
end

function ModAssetsModule:DownloadFailed()
    if self.provider.download_failed_func then
        self.provider.download_failed_func(self)        
    end
end

function ModAssetsModule:ViewMod()
    local url = ModCore:GetRealFilePath(self.provider.page_url, self)
    if Steam:overlay_enabled() then
		Steam:overlay_activate("url", url)
	else
		os.execute("cmd /c start " .. url)
	end
end

function ModAssetsModule:_DownloadAssets(data)
    local download_url = ModCore:GetRealFilePath(self.provider.download_url, data or self)
    self:log("Downloading assets from url: %s", download_url)
    dohttpreq(download_url, ClassClbk(self, "StoreDownloadedAssets", false), self._mod and ClassClbk(BeardLib.managers.mods_menu, "SetModProgress", self._mod) or nil)
end

function ModAssetsModule:StoreDownloadedAssets(config, data, id)
    config = config or self._config
    local mods_menu = BeardLib.managers.mods_menu
    local coroutine = mods_menu._menu._ws:panel():panel({})
    coroutine:animate(function()
        wait(0.001)
        if config.install then
            config.install()
        elseif self._mod then
            mods_menu:SetModInstallingUpdate(self._mod)
        end
        wait(1)
        
        BeardLib:log("[INFO] Finished downloading assets")

        if string.is_nil_or_empty(data) then
            BeardLib:log("[ERROR] Assets download failed, received data was invalid")
            if config.failed then
                config.failed()
            elseif self._mod then
                mods_menu:SetModFailedUpdate(self._mod)
            end
            return
        end
        
        --Without the "nice path" some games have trouble saving the temp file.
        local temp_zip_path = Application:nice_path(os.tmpname() .. ".zip") 
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
                local path = Path:Combine(self.install_directory, dir)
                if not FileIO:CanWriteTo(path) then
                    if config.failed_write then
                        config.failed_write()
                    elseif config.failed then
                        config.failed()
                    elseif self._mod then
                        mods_menu:SetModFailedWrite(self._mod)
                    end
                    return
                end
                if FileIO:Exists(path) then
                    FileIO:Delete(path)
                end
            end
        end
        unzip(temp_zip_path, config.install_directory or self.install_directory)
        FileIO:Delete(temp_zip_path)

        ModAssetsModule:SetReady()
        if config.done_callback then
            config.done_callback()
        end
        self.version = self._new_version        
        if config.finish then
            config.finish()
        elseif self._mod then
            mods_menu:SetModNormal(self._mod)
        end
        if alive(coroutine) then
            coroutine:parnet():remove(coroutine)
        end
    end)
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
        merge_data = {mod_key = self._update_manager_id}
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
        merge_data = {mod_key = self._mod.GlobalKey}
    })
end

DownloadCustomMap = DownloadCustomMap or class(ModAssetsModule)
function DownloadCustomMap:init() end

function DownloadCustomMap:DownloadFailed()
    BeardLibEditor.managers.Dialog:Show({title = managers.localization:text("mod_assets_error"), message = managers.localization:text("custom_map_failed_download"), force = true})
    if self.failed_map_downloaed then
        self.failed_map_downloaed()
    end
end

function DownloadCustomMap:_DownloadAssets(data)
    local download_url = ModCore:GetRealFilePath(self.provider.download_url, data or self)
    local dialog = BeardLib.managers.dialog.download
    dialog:Show({title = managers.localization:text("beardlib_downloading")..self.level_name or "No Map Name", force = true})				
    dohttpreq(download_url, ClassClbk(self, "StoreDownloadedAssets", {
        install_directory = BeardLib.config.maps_dir, 
        done_callback = self.done_map_download,
        install = ClassClbk(dialog, "SetInstalling"),
        failed = function()
            if self.failed_map_downloaed then
                self.failed_map_downloaed()
            end
            dialog:SetFailed()
        end,
        finish = ClassClbk(dialog, "SetFinished"),
    }), ClassClbk(dialog, "SetProgress"))
end

BeardLib:RegisterModule(ModAssetsModule.type_name, ModAssetsModule)