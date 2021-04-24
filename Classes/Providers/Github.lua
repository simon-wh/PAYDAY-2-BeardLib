ModAssetsModule._providers.github = {}
local github = ModAssetsModule._providers.github
github.check_url = "https://api.github.com/repos/$id$/commits/$branch$"
github.download_url = "https://github.com/$id$/archive/$branch$.zip"
github.page_url = "https://github.com/$id$"
github.sha =  nil

function github:check_func()
    local id = self.id
    if not id then
        return
    end
    if self._config.release then
        github.check_url = "https://api.github.com/repos/$id$/releases/latest"
    end
    local upd = Global.beardlib_checked_updates[self.id]
    if upd then
        if type(upd) == "string" and upd ~= tostring(self.version) then
            self._new_version = upd
            self:PrepareForUpdate()
        end
        return
    end

    local check_url = ModCore:GetRealFilePath(github.check_url, self._config)
    dohttpreq(check_url, function(data, id)
        if data then
            data = json.decode(data)
            github.sha = data.sha
            github.version_file = self.version_file
            self._new_version = data.sha or data.tag_name
            local length_acceptable = (string.len(self._new_version) > 0 and string.len(self._new_version) <= 64)

            if length_acceptable and tostring(self._new_version) ~= tostring(self.version) then
                if self._config.release and data.assets[1].browser_download_url then
                    github.download_url = data.assets[1].browser_download_url
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
    if self._config.release then
        download_url = github.download_url
    else
        --save config for callback
        github._config = self._config
        download_url = ModCore:GetRealFilePath(self.provider.download_url, data or self._config)
        table.merge(self._config, {
            done_callback = ModAssetsModule._providers.github.done_callback
        })
    end
    self:log("Downloading assets from url: %s", download_url)
    dohttpreq(download_url, ClassClbk(self, "StoreDownloadedAssets"), self._mod and ClassClbk(BeardLib.Menus.Mods, "SetModProgress", self) or nil)
end

--Callback for updating with the downloaded hash, to not have it show as needing update everytime.
function github:done_callback()
    local dir = github._config.custom_install_directory or github.version_file
    FileIO:WriteTo(dir, github.sha)
end