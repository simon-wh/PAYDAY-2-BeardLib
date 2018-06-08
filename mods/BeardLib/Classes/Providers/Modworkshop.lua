ModAssetsModule._providers.modworkshop = {}
local mws = ModAssetsModule._providers.modworkshop
mws.check_url = "https://api.modwork.shop/api.php?command=CompareVersion&did=$id$&vid=$version$&token=Je3KeUETqqym6V8b5T7nFdudz74yWXgU"
mws.get_files_url = "https://api.modwork.shop/api.php?command=AssocFiles&did=$id$&token=Je3KeUETqqym6V8b5T7nFdudz74yWXgU"
mws.download_url = "https://api.modwork.shop/api.php?command=DownloadFile&fid=$fid$&token=Je3KeUETqqym6V8b5T7nFdudz74yWXgU"
mws.page_url = "https://modwork.shop/$id$"
function mws:check_func()
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
    local check_url = ModCore:GetRealFilePath(mws.check_url, self)
    dohttpreq(check_url, function(data, id)
        if data then
            data = string.sub(data, 0, #data - 1)
            if data ~= "false" and data ~= "true" and string.len(data) > 0 then
                self._new_version = data
                Global.beardlib_checked_updates[self.id] = data
                self:PrepareForUpdate()
            else
                Global.beardlib_checked_updates[self.id] = true
            end
        end
    end)
end

function mws:download_file_func()
    local get_files_url = ModCore:GetRealFilePath(mws.get_files_url, self)
    dohttpreq(get_files_url, function(data, id)
        local fid = string.split(data, '"')[1]
        if fid then
            self:_DownloadAssets({fid = fid})
            if self.id then
                Global.beardlib_checked_updates[self.id] = nil --check again later for hotfixes.
            end
        else
            self:DownloadFailed()
        end
    end)
end

--support for old mods
ModAssetsModule._providers.lastbullet = clone(ModAssetsModule._providers.modworkshop)