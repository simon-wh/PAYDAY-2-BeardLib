AddFilesModule = AddFilesModule or BeardLib:ModuleClass("AddFiles", ModuleBase)

function AddFilesModule:Load()
    self._directory = self._config.full_directory or Path:CombineDir(self._mod.ModPath, self._config.directory)
    if self._config.auto_generate then
        self:CheckAutoGenerateConfig(self._config.auto_generate)
    end
    BeardLib.Managers.Package:LoadConfig(self._directory, self._config, self._mod)
end

--This sorting is important. Units usually depend on other files and so they must be last.
local SORT_TABLE = {
    texture = 1,
    cooked_physics = 2,
    model = 3,
    object = 4,
    material_config = 5,
    unit = 10
}

---Checks a given auto_generate config and either loads it or generates it.
--- @param config table
function AddFilesModule:CheckAutoGenerateConfig(config)
    local config = self._config.auto_generate
    if type(config) ~= "table" then
        self._config.auto_generate = {}
        config = {}
    end
    local directory = config.full_directory or (config.config and Path:CombineDir(self._mod.ModPath, config.directory)) or self._directory
    local data
    local gen_add = Path:Combine(self._mod.ModPath, config.file or "gen_add.xml")
    if not self._mod:GetSetting("DevelopMode") and FileIO:Exists(gen_add) then
        data = FileIO:ReadScriptData(gen_add, "custom_xml")
    else
        data = self:LoopFiles(directory)
        table.sort(data, function(a, b)
            local sort_value_a = a.path:ends("_husk") and 20 or SORT_TABLE[a._meta] or 1
            local sort_value_b = a.path:ends("_husk") and 20 or SORT_TABLE[b._meta] or 1
            return sort_value_a < sort_value_b
        end)

        local function set_param(key)
            data[key] = config[key] or self._config[key]
        end
        set_param("directory")
        set_param("full_directory")
        set_param("auto_cp")
        set_param("force")
        set_param("reload")
        set_param("unload")
        set_param("load")
        set_param("unload_on_restart")
        set_param("force_if_not_loaded")
        set_param("use_clbk")

        FileIO:WriteScriptData(gen_add, data, "custom_xml")
    end
    BeardLib.Managers.Package:LoadConfig(self._directory, data, self._mod)
end

---Loops through all files of a path and adds them to the files table.
---Uses the module's config to set or ignore files.
--- @param path string
--- @param files? table
--- @return table
function AddFilesModule:LoopFiles(path, files)
    files = files or {}

    local config = self._config.auto_generate
    local ignore = config.ignore
    local set = config.set

    local inner_path = string.gsub(path, string.escape_special(self._directory), "")

    for _, file in pairs(FileIO:GetFiles(path)) do
        local splt = string.split(Path:Combine(inner_path, file), "%.")
        local file_path, typ = splt[1], splt[2]
        local file_path_ext = file_path.."."..typ

        if BeardLib.Constants.FileTypes[typ] == true then
            local ignore_file = false
            --[[
                <ignore>
                    <unit/> <!--Ignores type unit-->
                    <unit path="path/to/file"/> <!--Ignores path + unit -->
                    <table path="path/to/file"/> <!--Ignores path -->
                    <table pattern="path/to/file"/> <!--Ignores all files matching the pattern -->
                </ignore>
            ]]
            --Check ignore table. If it matches, we must ignore this file.
            if type(ignore) == "table" then
                for _, tbl in ipairs(ignore) do
                    if type(tbl) == "table" then
                        --Either a type or path + type
                        if (not tbl._meta or tbl._meta == typ) and (not tbl.path or tbl.path == file_path) and (not tbl.pattern or file_path_ext:find(tbl.pattern)) then
                            ignore_file = true
                        end
                    end
                end
            end
            if not ignore_file then
                --[[
                    <set>
                        <unit val="a"/> <!--Set any unit-->
                        <unit path="path/to/file" val="b"/> <!--Set unit with path-->
                        <table path="path/to/file" val="b"/> <!--Set any file equal to that path-->
                        <table val="b"/> <!--Set any file-->
                        <table pattern="path/to/file" val="c"/> <!--Set any file matching the pattern-->
                    </set>
                ]]
                local data = {_meta = typ, path = file_path} --Prepare data.
                --If we don't need to ignore this file, check if there's anything to set.
                if type(set) == "table" then
                    for _, tbl in ipairs(set) do
                        if type(tbl) == "table" then
                            --Either a type or path + type
                            if (not tbl._meta or tbl._meta == typ) and (not tbl.path or tbl.path == file_path) and (not tbl.pattern or file_path_ext:find(tbl.pattern)) then
                                --We got a match? Alright, let's merge the data.
                                --Just to be safe, let's clone this.
                                local data_to_merge = clone(tbl)
                                --Remove these as they are not allowed.
                                data_to_merge.path = nil
                                data_to_merge._meta = nil
                                data_to_merge.pattern = nil
                                table.merge(data, tbl)
                            end
                        end
                    end
                end

                table.insert(files, data)
            end
        end
    end
    for _, folder in pairs(FileIO:GetFolders(path)) do
        self:LoopFiles(Path:CombineDir(path, folder), files)
    end
    return files
end

function AddFilesModule:Unload()
    BeardLib.Managers.Package:UnloadConfig(self._config)
end