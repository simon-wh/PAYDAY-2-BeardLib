ModAssetsModule = ModAssetsModule or class(ModuleBase)
ModAssetsModule.type_name = "AssetUpdates"
ModAssetsModule._default_version_file = "version.txt"
ModAssetsModule._providers = {
    modworkshop = {
        check_url = "https://api.modwork.shop/api.php?command=CompareVersion&did=$id$&vid=$version$&steamid=$steamid$&token=Je3KeUETqqym6V8b5T7nFdudz74yWXgU",
        get_files_url = "https://api.modwork.shop/api.php?command=AssocFiles&did=$id$&steamid=$steamid$&token=Je3KeUETqqym6V8b5T7nFdudz74yWXgU",
        download_url = "https://api.modwork.shop/api.php?command=DownloadFile&fid=$fid$&steamid=$steamid$&token=Je3KeUETqqym6V8b5T7nFdudz74yWXgU",
        page_url = "https://modwork.shop/$id$",
        check_func = function(self)
            local id = tonumber(self.id)
            if not id or id <= 0 then
                return
            end
            --optimization, mostly you don't really need to check updates again when going back to menu
            local upd = Global.beardlib_checked_updates[self.id]
            if upd then
                if type(upd) == "string" and upd ~= tostring(self.version) then
                    self._new_version = upd
                    self:PrepareForUpdate()
                end
                return
            end
            local check_url = self._mod:GetRealFilePath(self.provider.check_url, self)
            dohttpreq(check_url, function(data, id)
                if data then
                    data = string.sub(data, 0, #data - 1)
                    if data ~= "false" and data ~= "true" then
                        self._new_version = data
                        Global.beardlib_checked_updates[self.id] = data
                        self:PrepareForUpdate()
                    else
                        Global.beardlib_checked_updates[self.id] = true
                    end
                end
            end)
        end,
        download_file_func = function(self)
            local get_files_url = self._mod:GetRealFilePath(self.provider.get_files_url, self)
            dohttpreq(get_files_url, function(data, id)
                local fid = string.split(data, '"')[1]
                if fid then
                    self:_DownloadAssets({fid = fid, steamid = self.steamid})
                    Global.beardlib_checked_updates[self.id] = nil --check again later for hotfixes.
                end    
            end)
        end
    }
}
ModAssetsModule._providers.lastbullet = clone(ModAssetsModule._providers.modworkshop)

function ModAssetsModule:init(core_mod, config)
    self.required_params = table.add(clone(self.required_params), {"id"})
    if not ModAssetsModule.super.init(self, core_mod, config) then
        return false
    end

    self.steamid = Steam:userid()
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

    self.folder_names = self._config.use_local_dir and {table.remove(string.split(self._mod.ModPath, "/"))} or (type(self._config.folder_name) == "string" and {self._config.folder_name} or BeardLib.Utils:RemoveNonNumberIndexes(self._config.folder_name))
    self.install_directory = (self._config.install_directory and self._mod:GetRealFilePath(self._config.install_directory, self)) or (self._config.use_local_path ~= false and BeardLib.Utils.Path:GetDirectory(self._mod.ModPath)) or BeardLib.config.mod_override_dir
    self.version_file = self._config.version_file and self._mod:GetRealFilePath(self._config.version_file, self) or BeardLib.Utils.Path:Combine(self.install_directory, self.folder_names[1], self._default_version_file)
    self.version = 0
    
    self._update_manager_id = self._mod.Name .. self._name
    self._mod.update_key = (self._config.is_standalone ~= false) and self.id
    self._mod.update_assets_module = self
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
    if FileIO:Exists(self.version_file) then
        local version = io.open(self.version_file):read("*all")
        if version then
            self.version = version
        end
    elseif self._config.version then
        self.version = self._config.version
    else
        self:log("[ERROR] Unable to get version for '%s's assets. File: %s", self._mod.Name, self.version_file)
    end
    if tonumber(self.version) then -- has to be here, xml seems to fuckup numbers.
        self.version = BeardLib.Utils.Math:Round(tonumber(self.version), 4)
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
    BeardLib.managers.mods_menu:SetModNeedsUpdate(self._mod, self._new_version)
    if self._config.important and BeardLib.Options:GetValue("ImportantNotice") then
        local loc = managers.localization
        QuickMenuPlus:new(loc:text("beardlib_mods_manager_important_title", {mod = self._mod.Name}), loc:text("beardlib_mods_manager_important_help"), {{text = loc:text("dialog_yes"), callback = function()
            BeardLib.managers.mods_menu:SetEnabled(true)
        end}, {text = loc:text("dialog_no"), is_cancel_button = true}})
    end
end

function ModAssetsModule:_CheckVersion(force)
    local version_url = self._mod:GetRealFilePath(self.provider.version_api_url, self)
    local loc = managers.localization
    dohttpreq(version_url, function(data, id)
        self:log("Received version '%s' from the server(local is %s)", tostring(data), tostring(self.version))
        if data then
            self._new_version = data
            if self._new_version and self._new_version ~= self.version then
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
        {
            {
                text = managers.localization:text("menu_ok"),
                is_cancel_button = true
            }
        },
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
        self:_DownloadAssets()
    end
end

function ModAssetsModule:ViewMod()
    local url = self._mod:GetRealFilePath(self.provider.page_url, self)
    if Steam:overlay_enabled() then
		Steam:overlay_activate("url", url)
	else
		os.execute("cmd /c start " .. url)
	end
end

function ModAssetsModule:_DownloadAssets(data)
    local download_url = self._mod:GetRealFilePath(self.provider.download_url, data or self)
    self:log("Downloading assets from url: %s", download_url)
    local mods_menu = BeardLib.managers.mods_menu
    dohttpreq(download_url, callback(self, self, "StoreDownloadedAssets", false), callback(mods_menu, mods_menu, "SetModProgress", self._mod))
end

function ModAssetsModule:StoreDownloadedAssets(config, data, id)
    config = config or self._config
    local mods_menu = BeardLib.managers.mods_menu
    local coroutine = mods_menu._menu._ws:panel():panel({})
    coroutine:animate(function() --Same reason as BLT uses it, to update the UI properly.
        wait(0.001)
        if config.install then
            config.install()
        else
            mods_menu:SetModInstallingUpdate(self._mod)
        end
        wait(1)
        
        BeardLib:log("[INFO] Finished downloading assets")

        if string.is_nil_or_empty(data) then
            BeardLib:log("[ERROR] Assets download failed, received data was invalid")
            if config.failed then
                config.failed()
            else
                mods_menu:SetModFailedUpdate(self._mod)
            end
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
        else
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