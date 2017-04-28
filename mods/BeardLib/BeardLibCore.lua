if not _G.BeardLib then
    _G.BeardLib = {}

    local self = BeardLib
	self._mod = nil
    self.Name = "BeardLib"
    self.Version = 2.2 --for compatibility checks
    self.ModPath = ModPath
    self.SavePath = SavePath
    self.sequence_mods = self.sequence_mods or {}

	function self:read_config(file, tbl)
		local file = io.open(ModPath..file)
		local config = ScriptSerializer:from_custom_xml(file:read("*all"))
		for i, var in pairs(config) do
			if type(var) == "string" then
				config[i] = string.gsub(var, "%$(%w+)%$", tbl or self)
			end
		end
		return config
	end

	self.config = self:read_config("Config.xml")
	local _hooks = self.config.hooks
	self.config.hooks = {}
	for _, hook in ipairs(_hooks) do
		self.config.hooks[hook.source] = hook.file
	end
	_hooks = nil
    self.managers = {}

    self.custom_mission_elements = {
        "MoveUnit",
        "TeleportPlayer",
        "Environment",
        "PushInstigator"
    }
    self.modules = {}

    self._updaters = {}
    self._paused_updaters = {}

	function self:init()
		self:LoadClasses()
		self:LoadModules()

		if not file.DirectoryExists(self.config.maps_dir) then
			os.execute("mkdir " .. self.config.maps_dir)
		end

		local languages = {}
		for i, file in pairs(file.GetFiles(self.config.localization_dir)) do
			local lang = path:GetFileNameWithoutExtension(file)
			table.insert(languages, {
				_meta = "localization",
				file = file, --path:GetFileName(file),
				language = lang
			})
		end
        languages.directory = path:GetFileNameWithoutExtension(self.config.localization_dir)
		LocalizationModule:new(self, languages)
		for k, manager in pairs(self.managers) do
			if manager.new then
				self.managers[k] = manager:new()
			end
		end
		--Load mod_overrides adds
		self:RegisterTweak()
	end

	function self:AddUpdater(id, clbk, pasued)
		self._updaters[id] = clbk
		if paused then
			self._paused_updaters[id] = clbk
		end
	end

	function self:RemoveUpdater(id)
		self._updaters[id] = nil
		self._paused_updaters[id] = nil
	end

	function self:LoadClasses()
		for _, clss in ipairs(self.config.classes) do
            local p = self.config.classes_dir .. clss.file
			local obj = loadstring( "--"..p.. "\n" .. io.open(p):read("*all"))()
			if clss.manager and obj then
				self.managers[clss.manager] = obj
			end
		end
	end

	function self:RegisterModule(key, module)
        if not key or type(key) ~= "string" then
            self:log("[ERROR] BeardLib:RegisterModule parameter #1, string expected got %s", key and type(key) or "nil")
        end

		if not self.modules[key] then
			self:log("Registered module with key %s", key)
			self.modules[key] = module
		else
			self:log("[ERROR] Module with key %s already exists", key)
		end
	end

	function self:LoadModules()
		local modules = file.GetFiles(self.config.modules_dir)
		if modules then
			for _, mdle in pairs(modules) do
				dofile(self.config.modules_dir .. mdle)
			end
		end
	end

	function self:RegisterTweak()
		TweakDataHelper:ModifyTweak({
			name_id = "bm_global_value_mod",
			desc_id = "menu_l_global_value_mod",
			color = Color(255, 59, 174, 254) / 255,
			dlc = false,
			chance = 1,
			value_multiplier = 1,
			durability_multiplier = 1,
			--drops = false,
			track = false,
			sort_number = -10,
			--category = "mod"
		}, "lootdrop", "global_values", "mod")

		TweakDataHelper:ModifyTweak({"mod"}, "lootdrop", "global_value_list_index")

		TweakDataHelper:ModifyTweak({
			free = true,
			content = {
				--loot_global_value = "mod",
				loot_drops = {},
				upgrades = {}
			}
		}, "dlc", "mod")
	end

	function self:log(str, ...)
		ModCore.log(self, str, ...)
	end

	-- kept for compatibility with mods designed for older BeardLib versions --
	function self:ReplaceScriptData(replacement, replacement_type, target_path, target_ext, options)
		options = type(options) == "table" and options or {}
		FileManager:ScriptReplaceFile(target_ext, target_path, replacement, table.merge(options, { type = replacement_type, mode = options.merge_mode }))
	end

	function self:update(t, dt)
		for _, manager in pairs(self.managers) do
			if manager.update then
				manager:update(t, dt)
			end
		end
		for _, clbk in pairs(self._updaters) do
			clbk()
		end
	end

	function self:paused_update(t, dt)
		for _, manager in pairs(self.managers) do
			if manager.paused_update then
				manager:paused_update(t, dt)
			end
		end
		for _, clbk in pairs(self._paused_updaters) do
			clbk()
		end
	end
end

if RequiredScript then
    local requiredScript = RequiredScript:lower()
    if BeardLib.config.hooks[requiredScript] then
        dofile( BeardLib.config.hooks_dir .. BeardLib.config.hooks[requiredScript] )
    end
end
