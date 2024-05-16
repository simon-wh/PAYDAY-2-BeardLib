ModAssetsModule = ModAssetsModule or BeardLib:ModuleClass("AssetUpdates", ModuleBase)
ModAssetsModule._default_version_file = "version.txt"
ModAssetsModule._providers = {}
ModAssetsModule._loose = true
BeardLib:RegisterModule("AutoUpdates", ModAssetsModule)

--Load the providers
dofile(BeardLib.config.classes_dir.."Providers.lua")

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
    local version
    if self.version_file and FileIO:Exists(self.version_file) then
        version = FileIO:ReadFrom(self.version_file)
    elseif self.config.version then
        version = self.config.version
    end
    if tonumber(version) then -- has to be here, xml seems to fuckup numbers.
        version = math.round_with_precision(tonumber(version), 4)
    end

    if self.config.semantic_version then
        self.version = Version:new(version)
    else
        self.version = version
    end
end

function ModAssetsModule:CheckVersion(force)
    if not force and self._mod:GetSetting("IgnoreUpdates") == true then
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
    dohttpreq(version_url, function(data, id, request_info)
        if not request_info.querySucceeded or self.provider.version_is_number and not tonumber(data) then
            self:Err("Unable to parse version of mod %s. Provider %s, Id: %s", self._mod.Name, self.config.provider, self.id)
            return
        end

        local is_new_version = false
        local current_version_number = tonumber(self.version)
        local new_version_number = tonumber(data)
        if self.config.semantic_version then
            self._new_version = Version:new(data)
            is_new_version = self._new_version > self.version
        elseif current_version_number then -- if both versions can be converted into a number, compare numbers
            is_new_version = current_version_number < new_version_number
        else
            is_new_version = tostring(self.version) ~= tostring(data)
        end

        if is_new_version then
            self._new_version = data
            self:PrepareForUpdate()
        elseif force then
            self:ShowNoChangePrompt()
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
	if managers.network and managers.network.account and managers.network.account:is_overlay_enabled() then
		managers.network.account:overlay_activate("url", url)
	else
		os.execute("cmd /c start " .. url)
	end
end

function ModAssetsModule:_DownloadAssets(data)
    local download_url = ModCore:GetRealFilePath(self.provider.download_url, data or self)
    self:log("Downloading assets from url: %s", download_url)
    dohttpreq(download_url, ClassClbk(self, "StoreDownloadedAssets"), self._mod and ClassClbk(BeardLib.Menus.Mods, "SetModProgress", self) or nil)
end

function ModAssetsModule:StoreDownloadedAssets(data, id, request_info)
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

        if not request_info.querySucceeded or string.is_nil_or_empty(data) then
            BeardLib:log("[ERROR] Assets download failed, received data was invalid")
            if config.failed then
                config.failed()
            elseif self._mod then
                mods_menu:SetModFailedUpdate(self)
            end
            return
        end

        local temp_zip_path = Application:nice_path(BLTModManager.Constants:DownloadsDirectory() .. id .. ".zip")
        local temp_extract_path = Application:nice_path(BLTModManager.Constants:DownloadsDirectory() .. id)
        local file = io.open(temp_zip_path, "wb+")

        -- Write downloaded data to file
        if file then
            file:write(data)
            file:close()
        else
            self:log("[ERROR] An error occurred while trying to store the downloaded asset data")
            return
        end

        -- Create temporary extract dir, extract there and delete zip
        if FileIO:DirectoryExists(temp_extract_path) then
            FileIO:Delete(temp_extract_path)
        end
        FileIO:MakeDir(temp_extract_path)
        unzip(temp_zip_path, temp_extract_path)
        FileIO:Delete(temp_zip_path)

        -- Check if extraction succeeded
        local extracted_folders = FileIO:GetFolders(temp_extract_path)
        local extracted_files = FileIO:GetFiles(temp_extract_path)
        if not extracted_folders[1] and not extracted_files[1] then
            BeardLib:log("[ERROR] Assets extraction failed")
            if config.failed then
                config.failed()
            elseif self._mod then
                mods_menu:SetModFailedWrite(self)
            end
            return
        end

        -- Delete old mod
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

        -- Create install dir if needed
        local dir = config.custom_install_directory or self.install_directory
        if not FileIO:DirectoryExists(dir) then
            FileIO:MakeDir(dir)
        end

        -- Move extracted assets from temp dir to install dir and delete temp dir
        for _, v in pairs(extracted_folders) do
            FileIO:MoveTo(Application:nice_path(temp_extract_path .. "/" .. v), Application:nice_path(dir .. "/" .. v))
        end
        for _, v in pairs(extracted_files) do
            FileIO:MoveTo(Application:nice_path(temp_extract_path .. "/" .. v), Application:nice_path(dir .. "/" .. v))
        end
        FileIO:Delete(temp_extract_path)

        if config.done_callback then
            --Provide the directory of extracted folder
            config.done_callback(dir .. "/" .. extracted_folders[1])
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

        if self.id then
            Global.beardlib_checked_updates[self.id] = nil --check again later for hotfixes.
        end
    end)
end

DownloadCustomMap = DownloadCustomMap or class(ModAssetsModule)
function DownloadCustomMap:init()
    self.config = {custom_install_directory = BeardLib.Frameworks.Base._directory, dont_delete = true}
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