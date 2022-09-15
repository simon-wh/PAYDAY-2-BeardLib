ModAssetsModule = ModAssetsModule or BeardLib:ModuleClass("AssetUpdates", ModuleBase)
ModAssetsModule._default_version_file = "version.txt"
ModAssetsModule._providers = {}
ModAssetsModule._loose = true

--Load the providers
local providers_dir = BeardLib.config.classes_dir.."/Providers/"
local providers = FileIO:GetFiles(providers_dir)
if providers then
    for _, provider in pairs(providers) do
        dofile(providers_dir..provider)
    end
end

function ModAssetsModule:Load()
    self.config = self._config

    if self._config.optional_versions and self._mod:GetSetting("OptionalVersion") ~= "stable" then
        for _, v in ipairs(self._config.optional_versions) do
            if self._mod:GetSetting("OptionalVersion") == v._meta then
                self.config = v
            end
        end
    end

    self.id = self.config.id

    if self.config.provider then
        if self._providers[self.config.provider] then
            self.provider = self._providers[self.config.provider]
        else
            self:Err("No provider information for provider: %s", self.config.provider)
            return
        end
    elseif self.config.custom_provider then
        local provider_details = self.config.custom_provider
        if provider_details.check_func then provider_details.check_func = self._mod:StringToCallback(provider_details.check_func, self) end
        if provider_details.download_file_func then provider_details.download_file_func = self._mod:StringToCallback(provider_details.download_file_func, self) end
        self.provider = provider_details
    else
        self:Err("No provider can be found for mod assets")
        return
    end

	local path = self._mod:GetPath()
    self.ModPath = path

	if self.config.folder_name and self.config.use_local_dir ~= true then
		local folder = self.config.folder_name
		self.folder_names = (type(folder) == "string" and {folder} or BeardLib.Utils:RemoveNonNumberIndexes(folder))
	else
		self.folder_names = {table.remove(string.split(path, "/"))}
	end

	if self.config.install_directory and self.config.use_local_path ~= true then
		local dir = self.config.install_directory
        self.install_directory = ModCore:GetRealFilePath(dir, self) or BeardLib.config.mod_override_dir
	else
		self.install_directory = Path:GetDirectory(path)
	end

    if self.config.version_file then
		self.version_file = ModCore:GetRealFilePath(self.config.version_file, self)
	elseif not self.config.version then
		self.version_file = Path:Combine(self.install_directory, self.folder_names[1], self._default_version_file)
	end

    self.version = 0

    self._update_manager_id = self._mod.ModPath .."-".. self._name

    local download_url = self.config.download_url or (self.config.custom_provider and self.config.custom_provider.download_url) or nil
    self._data = {
        id = (self.config.is_standalone ~= false) and self.id,
        module = self,
        provider = not download_url and self.config.provider,
        download_url = download_url
    }

    self._mod.update_module_data = self._data --OLD DO NOT USE!

    self:RetrieveCurrentVersion()

    if not self.config.manual_check then
        self:RegisterAutoUpdateCheckHook()
    end
end

function ModAssetsModule:GetMainInstallDir()
    return Path:Combine(self.install_directory, self.folder_names[1])
end

function ModAssetsModule:RegisterAutoUpdateCheckHook()
    self._module_index = self._mod:GetModuleIndex(self)
    Hooks:Add("MenuManagerOnOpenMenu", self._update_manager_id .. "UpdateCheck"..self._module_index, function(self_menu, menu, index)
        if menu == "menu_main" and not LuaNetworking:IsMultiplayer() then
            self:CheckVersion()
        end
    end)
end

function ModAssetsModule:RetrieveCurrentVersion()
    if self.version_file and FileIO:Exists(self.version_file) then
        local version = FileIO:ReadFrom(self.version_file)
        if version then
            self.version = version
        end
    elseif self.config.version then
        self.version = self.config.version
    end
    if tonumber(self.version) then -- has to be here, xml seems to fuckup numbers.
        self.version = math.round_with_precision(tonumber(self.version), 4)
    end
end

function ModAssetsModule:CheckVersion(force)
    if not force and self._mod:GetSettings("IgnoreUpdates") == true then
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
    BeardLib.Menus.Mods:SetModNeedsUpdate(self, self._new_version)
    if self.config.important and BeardLib.Options:GetValue("ImportantNotice") then
        local loc = managers.localization
        QuickMenuPlus:new(loc:text("beardlib_mods_manager_important_title", {mod = self._mod.Name}), loc:text("beardlib_mods_manager_important_help"), {{text = loc:text("dialog_yes"), callback = function()
            BeardLib.Menus.Mods:SetEnabled(true)
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
        if data and (not self.provider.version_is_number or tonumber(data)) and tostring(data):len() <= 64 then --Limiting versions to 64 characters so errors won't show as versions
            local version_check = not self.config.version_is_number or ((tonumber(self.version) and tonumber(data)) and tonumber(self.version) < tonumber(data))
            if version_check then
                self._new_version = data
                if self._new_version and tostring(self._new_version) ~= tostring(self.version) then
                    self:PrepareForUpdate()
                elseif force then
                    self:ShowNoChangePrompt()
                end
            end
        else
            self:Err("Unable to parse string '%s' as a version number", data)
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
    dohttpreq(download_url, ClassClbk(self, "StoreDownloadedAssets"), self._mod and ClassClbk(BeardLib.Menus.Mods, "SetModProgress", self) or nil)
end

function ModAssetsModule:StoreDownloadedAssets(data, id)
    local config = self.config
    local mods_menu = BeardLib.Menus.Mods
    local coroutine = mods_menu._menu._ws:panel():panel({})
    coroutine:animate(function()
        wait(0.001)
        if config.install then
            config.install()
        elseif self._mod then
            mods_menu:SetModInstallingUpdate(self)
        end
        wait(1)

        BeardLib:log("[INFO] Finished downloading assets")

        if string.is_nil_or_empty(data) then
            BeardLib:log("[ERROR] Assets download failed, received data was invalid")
            if config.failed then
                config.failed()
            elseif self._mod then
                mods_menu:SetModFailedUpdate(self)
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
            self:log("[ERROR] An error occurred while trying to store the downloaded asset data")
            return
        end

        if self.config and not self.config.dont_delete and type(self.folder_names) == "table" then
            for _, dir in pairs(self.folder_names) do
                local path = Path:Combine(self.install_directory, dir)
                if not FileIO:CanWriteTo(path) then
                    if config.failed_write then
                        config.failed_write()
                    elseif config.failed then
                        config.failed()
                    elseif self._mod then
                        mods_menu:SetModFailedWrite(self)
                    end
                    return
                end
                if FileIO:Exists(path) then
                    FileIO:Delete(path)
                end
            end
        end

        local dir = config.custom_install_directory or self.install_directory
        if not dir then
            FileIO:MakeDir(dir)
        end
        unzip(temp_zip_path, dir)

        FileIO:Delete(temp_zip_path)

        if config.done_callback then
            config.done_callback()
        end
        self.version = self._new_version
        if config.finish then
            config.finish()
        elseif self._mod then
            mods_menu:SetModNormal(self)
        end
        if alive(coroutine) then
            coroutine:parnet():remove(coroutine)
        end
    end)
end

DownloadCustomMap = DownloadCustomMap or class(ModAssetsModule)
function DownloadCustomMap:init()
    self.config = {custom_install_directory = BeardLib.Frameworks.Map._directory, dont_delete = true}
end

function DownloadCustomMap:DownloadFailed()
    BeardLib.Managers.Dialog:Simple():Show({title = managers.localization:text("mod_assets_error"), message = managers.localization:text("custom_map_failed_download"), force = true})
    if self.failed_map_downloaed then
        self.failed_map_downloaed()
    end
end

function DownloadCustomMap:_DownloadAssets(data)
    local download_url = ModCore:GetRealFilePath(self.provider.download_url, data or self)
    local dialog = BeardLib.Managers.Dialog:Download()
    dialog:Show({title = (managers.localization:text("beardlib_downloading")..self.level_name) or "No Map Name", force = true})
    table.merge(self.config, {
        done_callback = self.done_map_download,
        install = ClassClbk(dialog, "SetInstalling"),
        failed = function()
            if self.failed_map_downloaed then
                self.failed_map_downloaed()
            end
            dialog:SetFailed()
        end,
        finish = ClassClbk(dialog, "SetFinished"),
    })
    dohttpreq(download_url, ClassClbk(self, "StoreDownloadedAssets"), ClassClbk(dialog, "SetProgress"))
end