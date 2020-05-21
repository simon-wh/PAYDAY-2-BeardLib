AddFilesModule = AddFilesModule or class(ModuleBase)
AddFilesModule.type_name = "AddFiles"

function AddFilesModule:Load()
    self._directory = self._config.full_directory or Path:CombineDir(self._mod.ModPath, self._config.directory)
    if self._config.auto_generate then
        self:GenerateConfig()
    end
    self:LoadPackageConfig(self._directory, self._config)
end

local SORT_TABLE = {
    texture = 1,
    cooked_physics = 2,
    model = 3,
    object = 4,
    material_config = 5,
    unit = 10
}

--Goes through directory given and generates an add.xml for it.
function AddFilesModule:GenerateConfig()
    local config = self._config.auto_generate
    if type(config) ~= "table" then
        self._config.auto_generate = {}
        config = {}
    end
    local directory = config.full_directory or (config.config and Path:CombineDir(self._mod.ModPath, config.directory)) or self._directory
    local data
    local gen_add = Path:Combine(self._mod.ModPath, config.file or "gen_add.xml")
    if not config.dev and FileIO:Exists(gen_add) then
        data = FileIO:ReadScriptData(gen_add, "custom_xml")
    else
        data = self:LoopFiles(directory)
        table.sort(data, function(a, b)
            return (SORT_TABLE[a._meta] or 1) < (SORT_TABLE[b._meta] or 1)
        end)

        data.directory = self._config.full_directory or self._config.directory
        FileIO:WriteScriptData(gen_add, data, "custom_xml")
    end
    self:LoadPackageConfig(self._directory, data)
end

function AddFilesModule:LoopFiles(path, files)
    files = files or {}

    local config = self._config.auto_generate
    local ignore_types = config.ignore_types
    local ignore_paths = config.ignore_paths
    local ignore_patterns = config.ignore_patterns

    local inner_path = string.gsub(path, string.escape_special(self._directory), "")

    for _, file in pairs(FileIO:GetFiles(path)) do
        local splt = string.split(Path:Combine(inner_path, file), "%.")
        local file_path, typ = splt[1], splt[2]

        local ignore = (ignore_types and ignore_types[typ]) or (ignore_files and ignore_files[file_path])
        if ignore_patterns then
            for _, pattern in pairs(ignore_patterns) do
                if file_path:find(pattern) then
                    ignore = true
                end
            end
        end
        if not ignore and BeardLib.Constants.FileTypes[typ] == true then
            table.insert(files, {_meta = typ, path = file_path})
        end
    end
    for _, folder in pairs(FileIO:GetFolders(path)) do
        self:LoopFiles(Path:CombineDir(path, folder), files)
    end
    return files
end

function AddFilesModule:Unload()
    self:UnloadPackageConfig(self._config)
end

AddFilesModule.LoadPackageConfig = CustomPackageManager.LoadPackageConfig
AddFilesModule.UnloadPackageConfig = CustomPackageManager.UnloadPackageConfig
AddFilesModule.AddFileWithCheck = CustomPackageManager.AddFileWithCheck

BeardLib:RegisterModule(AddFilesModule.type_name, AddFilesModule)