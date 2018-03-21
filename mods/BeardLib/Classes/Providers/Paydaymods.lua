ModAssetsModule._providers.paydaymods = {}
local pdm = ModAssetsModule._providers.paydaymods
pdm.check_url = "http://api.paydaymods.com/updates/retrieve/?mod[0]=$id$"
pdm.download_url = "http://download.paydaymods.com/download/latest/$id$"
function pdm:get_hash()
    if self._config.hash_file then
        return FileIO:exists(self._config.hash_file) and file.FileHash(self._config.hash_file) or nil
    else
        local directory = Application:nice_path(self:GetMainInstallDir(), true)
        return FileIO:exists(directory) and file.DirectoryHash(directory) or nil
    end
end

function pdm:check_func()
    dohttpreq(self._mod:GetRealFilePath(self.provider.check_url, self), function(json_data, http_id)    
        if json_data:is_nil_or_empty() then
            self:log("[Error] Could not connect to the PaydayMods.com API!")
        end
    
        local server_data = json.decode(json_data)
        if server_data then
            for _, data in pairs(server_data) do
                self:log("[Updates] Received update data for '%s'", data.ident)
                if data.ident == self.id then
                    local local_hash = pdm.get_hash(self)
                    self:log("[Updates] Comparing hash data:\nServer: %s\n Local: %s", data.hash, local_hash)
                    if data.hash then
                        if data.hash ~= local_hash then
                            self:PrepareForUpdate()
                            return
                        end
                    end
                end
                return
            end
        end
        self:log("[ERROR] Paydaymods did not return a result for id %s", tostring(self.id))
    end)
end
