--- Example: <AssetUpdates provider="modworkshop" version="1.0" id="12345"/> with ID being the ID in the mod page URL. 
--- Version belongs to the mod.
ModAssetsModule._providers.modworkshop = {
    version_api_url = "https://api.modworkshop.net/mods/$id$/version",
    download_url = "https://api.modworkshop.net/mods/$id$/download",
    page_url = "https://modworkshop.net/mod/$id$"
}

--- Example: <AssetUpdates provider="modworkshop_file" id="123" version="1.0" mod_id="12345"/> with ID being the file ID in the site.
--- Version belongs to the file.
ModAssetsModule._providers.modworkshop_file = {
    version_api_url = "https://api.modworkshop.net/files/$id$/version",
    download_url = "https://api.modworkshop.net/files/$id$/download",
    page_url = "https://modworkshop.net/mod/$mod_id$"
}

--support for old mods
ModAssetsModule._providers.lastbullet = clone(ModAssetsModule._providers.modworkshop)

ModAssetsModule._providers.payday2concepts = {
    version_api_url = "http://payday2maps.net/crimenet/checkversion/$id$.txt",
    download_url = "http://payday2maps.net/crimenet/downloads/$id$.zip",
    version_is_number = true
}

ModAssetsModule._providers.github = {
    check_url = "https://api.github.com/repos/$id$/commits/$branch$",
    check_url_release = "https://api.github.com/repos/$id$/releases/latest",
    download_url = "https://github.com/$id$/archive/$branch$.zip",
    page_url = "https://github.com/$id$"
}
local github = ModAssetsModule._providers.github

function github:check_func()
    local id = self.id
    if not id then
        return
    end

    -- If we cloned the mod ignore this procedure entirely. We are most likely developers/know how to use git.
    if self._mod and FileIO:Exists(self._mod.ModPath .. ".git/") then
        return
    end

    local check_url = self.config.release and github.check_url_release or github.check_url
    local upd = Global.beardlib_checked_updates[self.id]

    if upd then
        if type(upd) == "string" and upd ~= tostring(self.version) then
            self._new_version = upd
            self:PrepareForUpdate()
        end
        return
    end

    local check_url = ModCore:GetRealFilePath(check_url, self.config)
    dohttpreq(check_url, function(data, id, request_info)
        if request_info.querySucceeded and data then
            data = json.decode(data)
            if data.message == "Not Found" then
                self:Err("GitHub provider not setup properly. Check if the branch and ID are correct")
                return
            end
            self._new_version = data.sha or data.tag_name
            --if file is empty, assume it's a fresh install of latest release.
            if self.version_file and not FileIO:Exists(self.version_file) or self.version_file and FileIO:ReadFrom(self.version_file) == "" then
                FileIO:WriteTo(self.version_file, self._new_version)
                Global.beardlib_checked_updates[self.id] = true
                return
            end

            local length_acceptable = (string.len(self._new_version) > 0 and string.len(self._new_version) <= 64)

            if length_acceptable and tostring(self._new_version) ~= tostring(self.version) then
                if self.config.release and data.assets[1].browser_download_url then
                    self._github_download_url = data.assets[1].browser_download_url
                end
                Global.beardlib_checked_updates[self.id] = data
                self:PrepareForUpdate()
            else
                Global.beardlib_checked_updates[self.id] = true
            end
        end
    end)
end

function github:download_file_func(data)
    local download_url
    --Avoid adding the callback if release, hash doesn't need to be updated.
    if self.config.release then
        download_url = self._github_download_url
    else
        download_url = ModCore:GetRealFilePath(github.download_url, data or self.config)
        table.merge(self.config, {
            done_callback = SimpleClbk(github.done_callback, self)
        })
    end
    self:log("Downloading assets from url: %s", download_url)
    dohttpreq(download_url, ClassClbk(self, "StoreDownloadedAssets"), self._mod and ClassClbk(BeardLib.Menus.Mods, "SetModProgress", self) or nil)
end

--Callback for updating with the downloaded hash, to not have it show as needing update everytime.
function github:done_callback(folder_dir)
    if self.version_file then
        FileIO:WriteTo(folder_dir .. "/" .. "version.txt", self._new_version)
    end
end
