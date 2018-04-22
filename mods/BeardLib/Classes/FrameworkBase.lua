FrameworkBase = FrameworkBase or class()
local Framework = FrameworkBase
local BMM = BLTModManager

Framework._directory = BMM and BMM.Constants and BMM.Constants.mods_directory or "mods/"
Framework._mod_core = ModCore
Framework.main_file_name = "main.xml"
Framework.auto_init_modules = true
Framework.type_name = "base"

Framework._ignore_folders = {"base", "BeardLib", "downloads", "logs", "saves"}
Framework._ignore_detection_errors = true
Framework._ignored_configs = {}
Framework._loaded_mods = {}

function Framework:init()
    self:Load()
end

function Framework:Load()
    local dirs = FileIO:GetFolders(self._directory)
    if dirs then
        for _, dir in pairs(dirs) do
            if not table.contains(self._ignore_folders, dir) then
                local p = path:Combine(self._directory, dir)
                local main_file = path:Combine(p, self.main_file_name)
                if FileIO:Exists(main_file) then
                    if not self._loaded_mods[dir] then
                        self:LoadMod(dir, p, main_file)
                    end
                elseif not self._ignore_detection_errors and not self._ignored_configs[main_file] then
                    BeardLib:log("[Warning] Could not read %s", main_file)
                    self._ignored_configs[main_file] = true
                end
            end
        end
    end
end

function Framework:RegisterHooks()
    table.sort(self._loaded_mods, function(a,b)
        return a.Priority < b.Priority
    end)
    for _, mod in pairs(self._loaded_mods) do
        if not mod._disabled and mod._modules then
            for _, module in pairs(mod._modules) do
                if module.RegisterHook and not module.Registered then
                    local success, err = pcall(function() module:RegisterHook() end)
                    module.Registered = true
                    if not success then
                        BeardLib:log("[ERROR] An error occured on the hook registration of %s. Error:\n%s", module._name, tostring(err))
                    end
                end
            end
        end
    end
end

function Framework:GetModByDir(dir)
    return self._loaded_mods[dir]
end

function Framework:GetModByName(name)
    for _, mod in pairs(self._loaded_mods) do
        if mod.Name == name then
            return mod
        end
    end
    return nil
end

local cap = string.capitalize
function Framework:LoadMod(dir, path, main_file)
	rawset(_G, "ModPath", path)
	local success, node_obj = pcall(function() return self._mod_core:new(main_file, self.auto_init_modules) end)
	if success then
		BeardLib:log("[%s Framework] Loaded Config: %s", cap(self.type_name), path)
		self:AddMod(dir, node_obj)
	else
		BeardLib:log("[ERROR] An error occured on initilization of Mod %s. Error:\n%s", dir, tostring(node_obj))
	end
end

function Framework:AddMod(dir, mod)
	self._loaded_mods[dir] = mod
end

BeardLib:RegisterFramework(Framework.type_name, Framework)
return Framework