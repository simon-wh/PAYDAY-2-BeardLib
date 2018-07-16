core:import("CoreSerialize")
ModCore = ModCore or class()
ModCore._ignored_modules = {}
ModCore._auto_post_init = true

function ModCore:init(config_path, load_modules)
    if not FileIO:Exists(config_path) then
        BeardLib:log("[ERROR] Config file at path '%s' is not readable!", config_path)
        return
    end

	self.ModPath = ModPath
    self.Priority = 1001
	self.SavePath = SavePath
	
    local disabled_mods = BeardLib.Options:GetValue("DisabledMods")
    self._blt_mod = config_path:find(FrameworkBase._format) == 1

    if disabled_mods[ModPath] and not self._blt_mod then
        BeardLib:log("[Info] Mod at path '%s' is disabled!", tostring(ModPath))
        self._disabled = true
	end

    if self._blt_mod then
		local mod = BLT.Mods:GetModOwnerOfFile(ModPath)
		if mod and not mod:IsEnabled() then
			self._disabled = true
			return
		end
	end
	
	self:LoadConfigFile(config_path)
	table.insert(BeardLib.Mods, self)
	
	self.Priority = self.Priority or self._config.priority

	if self._config and not self._config.min_lib_ver or self._config.min_lib_ver <= BeardLib.Version then
		if load_modules == nil or load_modules then
			self:init_modules()
		end
	elseif self._config then
		self:log("[ERROR] BeardLib version %s or above is required to run the mod.", tostring(self._config.min_lib_ver))
		self._disabled = true
        return
	end
end

function ModCore:post_init(ignored_modules)
    if self._disabled then
        return
	end

	for _, module in pairs(self._modules) do
        if (not ignored_modules or not table.contains(ignored_modules, module._name)) then
            local success, err = pcall(function() module:post_init() end)

            if not success then
                self:log("[ERROR] An error occured on the post initialization of %s. Error:\n%s", module._name, tostring(err))
            end
        end
    end

	if self._core_class then
		self._core_class:Init()
	end
	
	local post_init = self._config.post_init_clbk or self._config.post_init
    if post_init then
        local clbk = self:StringToCallback(post_init)
        if clbk then
            clbk()
        end
    end
end

function ModCore:LoadConfigFile(path)
    local file = io.open(path, "r")
    local config = ScriptSerializer:from_custom_xml(file:read("*all"))

    self.Name = config.name or tostring(table.remove(string.split(self.ModPath, "/")))
    if not self._disabled then
        if config.global_key then
            self.global = config.global_key
            if not _G[self.global] then
                rawset( _G, self.global, self)
            end
        end
    end

    self._clean_config = deep_clone(config)
    self._config = config
end

local load_first = {
	["Hooks"] = true,
	["Classes"] = true
}

function ModCore:init_modules()
    if self.modules_initialized or self._disabled then
        return
    end

	self._modules = {}
	
	local order = self._config.load_first or load_first
	
	table.sort(self._config, function(a,b)
		local a_ok = type(a) == "table" and order[a._meta] or false
		local b_ok = type(b) == "table" and order[b._meta] or false
		return a_ok and not b_ok
	end)

	if self._config.core_class then
		self._core_class = dofile(Path:Combine(self.ModPath, self._config.core_class)) or self
	end

    for i, module_tbl in ipairs(self._config) do
        if type(module_tbl) == "table" then
            if not table.contains(self._ignored_modules, module_tbl._meta) then
                local node_class = BeardLib.modules[module_tbl._meta]

                if not node_class and module_tbl._force_search then
                    node_class = CoreSerialize.string_to_classtable(module_tbl._meta)
                end

                if node_class then
                    local success, node_obj, valid = pcall(function() return node_class:new(self, module_tbl) end)
                    if success then
                        if valid == false then
                            self:log("Module with name %s does not contain a valid config. See above for details", node_obj._name)
                        else
                            if not node_obj._loose or node_obj._name ~= node_obj.type_name then
                                if self[node_obj._name] then
                                    self:log("The name of module: %s already exists in the mod table, please make sure this is a unique name!", node_obj._name)
                                end

                                self[node_obj._name] = node_obj
                            end
                            table.insert(self._modules, node_obj)
                        end
                    else
                        self:log("[ERROR] An error occured on initilization of module: %s. Error:\n%s", module_tbl._meta, tostring(node_obj))
                    end
                elseif not self._config.ignore_errors then
                    self:log("[ERROR] Unable to find module with key %s", module_tbl._meta)
                end
            end
        end
    end

	if self._auto_post_init then
		self:post_init()
	end
    self.modules_initialized = true
end

function ModCore:GetRealFilePath(path, lookup_tbl)
    if string.find(path, "%$") then
        return string.gsub(path, "%$(%w+)%$", lookup_tbl or self)
    else
        return path
    end
end

function ModCore:log(str, ...)
    log("[" .. self.Name .. "] " .. string.format(str, ...))
end

function ModCore:StringToTable(str)
    if str == "self" then return self end

    if (string.find(str, "$")) then
        str = string.gsub(str, "%$(%w+)%$", self)
    end

    local global_tbl
    local self_search = "self."
    if string.begins(str, self_search) then
        str = string.sub(str, #self_search + 1, #str)
        global_tbl = self
    end

    return BeardLib.Utils:StringToTable(str, global_tbl)
end

function ModCore:StringToCallback(str, self_tbl)	
	local value = BeardLib.Utils:normalize_string_value(str)
	if type(value) == "function" then
		return value
	else
		local split = string.split(str, ":")
		local func_name = table.remove(split)
		local global_tbl_name = split[1]

		local global_tbl = self:StringToTable(global_tbl_name)
		if global_tbl then
			return callback(self_tbl or global_tbl, global_tbl, func_name)
		else
			return nil
		end
	end
end

function ModCore:RegisterHook(source_file, file, type)
	local path = self:GetPath()
    local hook_file = Path:Combine(path, file)
    local dest_tbl = type == "pre" and (_prehooks or (BLT and BLT.hook_tables.pre)) or (_posthooks or (BLT and BLT.hook_tables.post))
	if dest_tbl then
		if FileIO:Exists(hook_file) then
			local req_script = source_file:lower()
			dest_tbl[req_script] = dest_tbl[req_script] or {}
			table.insert(dest_tbl[req_script], {
				mod_path = path,
				mod = self,
				script = file
			})
		else
			self:log("[ERROR] Failed reading hook file %s of type %s", tostring(hook_file), tostring(type or "post"))
		end
	end
end

function ModCore:Init() end
function ModCore:GetPath() return self.ModPath end
function ModCore:Disabled() return self._disabled end
function ModCore:Enabled() return not self._disabled end

--BLT Keybinds support:

function ModCore:IsEnabled() return self:Enabled()end
function ModCore:WasEnabledAtStart() return self:Enabled()end
function ModCore:GetName() return self.Name end