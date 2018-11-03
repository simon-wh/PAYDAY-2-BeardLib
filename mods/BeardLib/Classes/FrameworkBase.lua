FrameworkBase = FrameworkBase or class()
local Framework = FrameworkBase
local BMM = BLTModManager

Framework._directory = BMM and BMM.Constants and BMM.Constants.mods_directory or "mods/"
Framework._format = Path:Combine(Framework._directory, "%s", "main.xml")
Framework._mod_core = ModCore
Framework.main_file_name = "main.xml"
Framework.auto_init_modules = true
Framework.type_name = "base"
Framework.menu_color = Color(0.6, 0, 1)

Framework._ignore_folders = {["base"] = true, ["BeardLib"] = true, ["downloads"] = true, ["logs"] = true, ["saves"] = true}
Framework._ignore_detection_errors = true

function Framework:init()
	BeardLib:RegisterFramework(self.type_name, self)
	self._ignored_configs = {}
	self._loaded_mods = {}
	self._sorted_mods = {}
	self._waiting_to_load = {}

	Hooks:Add("BeardLibRequireHook", self.type_name.."_framework_require", function(post, file)
		self:CheckModQueue(post, file)
	end)

	self:Load()
end

function Framework:CheckModQueue(post, file)
	if #self._waiting_to_load == 0 or post == nil or file == nil then
		return
	end
	local shortened = file
	for part, _ in string.gmatch(file, "%w+") do
		shortened = part
	end
	shortened = shortened:lower()

	local next_queue = {}
	local load = {}
	local pre = not post
	for _, mod in pairs(self._waiting_to_load) do
		local config = mod._config
		if (post and config.post_hook == shortened) or (pre and config.pre_hook == shortened) then
			table.insert(load, mod)
		else
			table.insert(next_queue, mod)
		end
	end

	for _, mod in pairs(load) do
		mod:pre_init_modules(self.auto_init_modules)
	end

	self._waiting_to_load = next_queue
end

function Framework:Load()
	self:FindMods()
	self:SortMods()
	self:InitMods()
end

function Framework:FindMods()
	local dirs = FileIO:GetFolders(self._directory)
    if dirs then
        for _, dir in pairs(dirs) do
            if not self._ignore_folders[dir] then
                local p = path:CombineDir(self._directory, dir)
                local main_file = path:Combine(p, self.main_file_name)
                if FileIO:Exists(main_file) then
					if not self._loaded_mods[dir] then
                        self:LoadMod(dir, p, main_file)
                    end
                elseif not self._ignore_detection_errors and not self._ignored_configs[main_file] then
                    self:log("Could not read %s", main_file)
                    self._ignored_configs[main_file] = true
                end
            end
        end
	end
end

function Framework:SortMods()
	table.sort(self._sorted_mods, function(a,b)
        return a.Priority > b.Priority
	end)
	table.sort(self._waiting_to_load, function(a,b)
        return a.Priority > b.Priority
	end)
end

function Framework:InitMods()
	for _, mod in pairs(self._sorted_mods) do
		local config = mod._config
		if not config.post_hook and not config.pre_hook then
			mod:pre_init_modules(self.auto_init_modules)
			self:log("Initialized Mod: %s", mod.ModPath)
		end
	end
end

function Framework:RegisterHooks()
	self:SortMods()
    for _, mod in pairs(self._sorted_mods) do
        if not mod._disabled and mod._modules then
            for _, module in pairs(mod._modules) do
                if module.DoRegisterHook and not module.Registered then
                    local success, err = pcall(function() module:DoRegisterHook() end)
                    module.Registered = true
                    if not success then
                        self:log("[ERROR] An error occured on the hook registration of %s. Error:\n%s", module._name, tostring(err))
                    end
                end
            end
        end
    end
end

local cap = string.capitalize
function Framework:log(s, ...)
	BeardLib:log("["..cap(self.type_name).." Framework] " .. s, ...)
end

function Framework:DevLog(s, ...)
	BeardLib:DevLog("["..cap(self.type_name).." Framework] " .. s, ...)
end

function Framework:GetModByDir(dir)
    return self._loaded_mods[dir]
end

function Framework:GetModByName(name)
	if self._loaded_mods then
		for _, mod in pairs(self._loaded_mods) do
			if mod.Name == name then
				return mod
			end
		end
	end
    return nil
end

function Framework:LoadMod(dir, path, main_file)
	rawset(_G, "ModPath", path)
	local success, mod = pcall(function() return self._mod_core:new(main_file, false) end)
	if success then
		self:DevLog("Loaded Config: %s", path)
		local framework = mod._config and mod._config.framework and BeardLib.Frameworks[mod._config.framework] or self
		if framework then
			framework:AddMod(dir, mod)
		end
	else
		self:log("[ERROR] An error occured on initilization of mod %s. Error:\n%s", dir, tostring(mod))
	end
end

function Framework:AddMod(dir, mod)
	self._loaded_mods[dir] = mod
	table.insert(self._sorted_mods, mod)
	local config = mod._config
	if config and (config.post_hook or config.pre_hook) then
		table.insert(self._waiting_to_load, mod)
	end
end

function Framework:RemoveMod(dir)
	self._loaded_mods[dir] = nil
end

return Framework