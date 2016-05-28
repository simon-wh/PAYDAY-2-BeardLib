FrameworkBase = FrameworkBase or class()
FrameworkBase._directory = ""
FrameworkBase._asset_folder_required = false

function FrameworkBase:init()
    self._loaded_configs = {}
    self._config_calls = table.merge(self._config_calls or {}, {
        localization = {func = callback(self, self, "LoadLocalizationConfig"), requires_assets = true}
    })

    self:Load()
end

function FrameworkBase:Load()
    local files = file.GetFiles(self._directory)
    if files then
        for _, config_file in pairs(files) do
            local cfile_split = string.split(config_file, "%.")
            if #cfile_split >= 2 then
                local cfile = io.open(self._directory .. "/" .. config_file, 'r')
                local data

                if cfile_split[#cfile_split] == "xml" then
                    data = ScriptSerializer:from_custom_xml(cfile:read("*all"))
                else
                    data = json.custom_decode(cfile:read("*all"))
                end

                local has_assets = file.DirectoryExists(self._directory .. "/" .. cfile_split[1])

                if not has_assets and self._asset_folder_required then
                    BeardLib:log("[ERROR] Framework Config must have an assets folder. Config: " .. cfile_split[1])
                else
                    self:LoadConfig(cfile_split[1], self._directory .. "/" .. cfile_split[1] .. "/", data, has_assets)
                end
            end
        end
    end
end

function FrameworkBase:LoadConfig(name, path, data, assets)
    self._loaded_configs[name] = {data = data, path = path, assets = assets, name = name}

    for _, sub_data in ipairs(data) do
        local cfg_tbl = self._config_calls[sub_data._meta]
        if cfg_tbl and (not cfg_tbl.requires_assets or cfg_tbl.requires_assets and assets) then
            cfg_tbl.func(name, path, sub_data)
        elseif cfg_tbl and cfg_tbl.requires_assets then
            BeardLib:log(string.format("[ERROR] Config table does not have the required assets. (%s)", sub_data._meta))
        else
            BeardLib:log("[ERROR] No Config call for the subtable: " .. sub_data._meta)
        end
    end
end

local load_localization_file = function(path, directory, file)
    local localiz_path = path .. directory .. "/" .. file
    if io.file_is_readable(localiz_path) then
        BeardLib:log("Loaded: " .. localiz_path)
        LocalizationManager:load_localization_file(localiz_path)
        return true
    else
        BeardLib:log("[ERROR] Localization file is not readable by the lua state! File: " .. localiz_path)
        return false
    end
end

function FrameworkBase:LoadLocalizationConfig(name, path, data)
    Hooks:Add("LocalizationManagerPostInit", name .. "ConfigLocalization", function(loc)
        local file_loaded = false

        for i, def in ipairs(data) do
            if Idstring(def.language):key() == SystemInfo:language():key() then
                if load_localization_file(name, data.directory, def.file) then
                    file_loaded = true
                    break
                end
            end
        end

        if not file_loaded and data.default then
            load_localization_file(path, data.directory, data.default)
        end
	end)
end
