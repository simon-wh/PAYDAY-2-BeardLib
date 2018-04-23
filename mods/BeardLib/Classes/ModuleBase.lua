ModuleBase = ModuleBase or class()
ModuleBase.type_name = "ModuleBase"
ModuleBase.required_params = {}
function ModuleBase:init(core_mod, config)
    self._mod = core_mod
    self._name = config.name or self.type_name
    if config.file ~= nil then
        local file_path = self._mod:GetRealFilePath(BeardLib.Utils.Path:Combine(self._mod.ModPath, config.file))
        self._config = table.merge(config, FileIO:ReadScriptData(file_path, config.file_type or "custom_xml", config.clean_file))
    else
        self._config = config
    end

    for _, param in pairs(self.required_params) do
        if BeardLib.Utils:StringToTable(param, self._config, true) == nil then
            self:log("[ERROR] Parameter '%s' is required!", param)
            return false
        end
    end

    return true
end

function ModuleBase:post_init()
	local post_init = self._config.post_init_clbk or self._config.post_init
    if post_init then
        local clbk = self._mod:StringToCallback(post_init)
        if clbk then
            clbk()
        end
    end
end

function ModuleBase:log(str, ...)
    self._mod:log(string.format("[%s] ", self._name) .. str, ...)
end

function ModuleBase:GetPath(directory, prev_dir)
	if prev_dir then
		return Path:CombineDir(prev_dir, directory)
	else
		return Path:CombineDir(self._mod.ModPath, directory)
	end
end

ItemModuleBase = ItemModuleBase or class(ModuleBase)
ItemModuleBase.type_name = "ItemModuleBase"
ItemModuleBase.required_params = {"id"}
ItemModuleBase.clean_table = {}
ItemModuleBase.defaults = {global_value= "mod", dlc= "mod"}
ItemModuleBase._loose = true
local remove_last = function(str)
    local tbl = string.split(str, "%.")

    return table.remove(tbl), #tbl > 0 and table.concat(tbl, ".")
end

function ItemModuleBase:init(core_mod, config)
    if not ModuleBase.init(self, core_mod, config) then
        return false
    end
    self:do_clean_table(self._config)
    return true
end

function ItemModuleBase:do_clean_table(config)
    for _, clean in pairs(self.clean_table) do
        local i, search_string = remove_last(clean.param)
        local tbl = search_string and BeardLib.Utils:StringToTable(search_string, config, true) or config
        if tbl and tbl[i] then
            for _, action in pairs(type(clean.action) == "table" and clean.action or {clean.action}) do
                if action == "no_subtables" then
                    tbl[i] = BeardLib.Utils:RemoveAllSubTables(tbl[i])
                elseif action == "no_number_indexes" then
                    tbl[i] = BeardLib.Utils:RemoveAllNumberIndexes(tbl[i], clean.shallow)
                elseif action == "number_indexes" then
                    tbl[i] = BeardLib.Utils:RemoveNonNumberIndexes(tbl[i])
                elseif action == "remove_metas" then
                    tbl[i] = BeardLib.Utils:RemoveMetas(tbl[i], clean.shallow)
                elseif action == "normalize" then
                    tbl[i] = BeardLib.Utils:normalize_string_value(tbl[i])
                elseif action == "children_no_number_indexes" then
                    for _, v in pairs(tbl[i]) do
                        v = BeardLib.Utils:RemoveAllNumberIndexes(v, clean.shallow)
                    end
                elseif type(action) == "function" then
                    action(tbl[i])
                end
            end
        end
    end
end

function ItemModuleBase:RegisterHook() end