ModAssetsModule._providers.github = {}
local github = ModAssetsModule._providers.github
github.check_url = "https://api.github.com/repos/$id$/commits/$branch$"
github.check_url_release = "https://api.github.com/repos/$id$/releases/latest"
github.download_url = "https://github.com/$id$/archive/$branch$.zip"
github.page_url = "https://github.com/$id$"

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
    dohttpreq(check_url, function(data, id)
        if data then
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
function github:done_callback()
    if self.version_file then
        FileIO:WriteTo(self.version_file, self._new_version)
    end
end
