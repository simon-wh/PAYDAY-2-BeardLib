if not _G.BeardLib then
	dofile(ModPath.."Classes/Utils/FileIO.lua")
	
    _G.BeardLib = {}
	local self = BeardLib		
    self.Name = "BeardLib"
    self.ModPath = ModPath
    self.SavePath = SavePath	
	self.sequence_mods = {}	
	self.MusicMods = {}
	self.managers = {}	
    self.modules = {}
	self.Items = {}
	self.Mods = {}
	self._paused_updaters = {}
	self._updaters = {}
	self._call_next_update = {}

	self.config = FileIO:ReadConfig(ModPath.."Config.xml", self)
	self._config = self.config
	local hooks = self.config.hooks
	self.config.hooks = {}
	for _, hook in ipairs(hooks) do
		self.config.hooks[hook.source] = hook.file
	end
	hooks = nil

	function self:Init()
		self:LoadClasses()
		self:LoadModules()
		FileIO:MakeDir(self.config.maps_dir)

		Global.beardlib_checked_updates = Global.beardlib_checked_updates or {}
		
		local languages = {}
		for i, file in pairs(FileIO:GetFiles(self.config.localization_dir)) do
			local lang = Path:GetFileNameWithoutExtension(file)
			table.insert(languages, {_meta = "localization", file = file, language = lang})
		end
        languages.directory = Path:GetFileNameWithoutExtension(self.config.localization_dir)
		LocalizationModule:new(self, languages)

		for name, config in pairs(self.config.load_modules) do
			if BeardLib.modules[name] then
				local module = BeardLib.modules[name]:new(self, config)
				self[module._name] = module
				module:post_init()
			end
		end
		self.Version = tonumber(self.AssetUpdates.version)
		
		for k, manager in pairs(self.managers) do
			if manager.new then
				self.managers[k] = manager:new()
			else
				self.managers[k] = manager
			end
		end
		--Load mod_overrides adds
		self:RegisterTweak()
		
		self.DevMode = self.Options:GetValue("DevMode")
	end

	function self:AddUpdater(id, clbk, paused)
		self._updaters[id] = clbk
		if paused then
			self._paused_updaters[id] = clbk
		end
	end

	function self:RemoveUpdater(id)
		self._updaters[id] = nil
		self._paused_updaters[id] = nil
	end

	function self:CallOnNextUpdate(func, only_unpaused, only_paused)
		table.insert(self._call_next_update, {func = func, only_unpaused = only_unpaused, only_paused = only_paused})
	end

	function self:LoadClasses()
		for _, clss in ipairs(self.config.classes) do
			local p = self.config.classes_dir .. clss.file
			log("[BeardLib] Loading class", tostring(p))
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
		local modules = FileIO:GetFiles(self.config.modules_dir)
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
			track = false,
			sort_number = -10,
		}, "lootdrop", "global_values", "mod")

		TweakDataHelper:ModifyTweak({"mod"}, "lootdrop", "global_value_list_index")

		TweakDataHelper:ModifyTweak({
			free = true,
			content = {
				loot_drops = {},
				upgrades = {}
			}
		}, "dlc", "mod")
	end

	function self:DevLog(str, ...)
		if self.DevMode then
			self:log(str, ...)
		end
	end

	function self:log(str, ...)
		ModCore.log(self, str, ...)
	end

	function self:GetRealFilePath(...)
		return ModCore.GetRealFilePath(self, ...)
	end
	
	-- kept for compatibility with mods designed for older BeardLib versions --
	function self:ReplaceScriptData(replacement, replacement_type, target_path, target_ext, options)
		options = type(options) == "table" and options or {}
		FileManager:ScriptReplaceFile(target_ext, target_path, replacement, table.merge(options, { type = replacement_type, mode = options.merge_mode }))
	end

	function self:Update(t, dt)
		for _, manager in pairs(self.managers) do
			if manager.update then
				manager:update(t, dt)
			end
		end
		for id, clbk in pairs(self._updaters) do
			clbk(t, dt)
		end
		for _, call in pairs(self._call_next_update) do
			if not call.only_paused then
				call.func(t, dt)
			end
		end
		self._call_next_update = {}
	end

	function self:PausedUpdate(t, dt)
		for _, manager in pairs(self.managers) do
			if manager.update then
				manager:update(t, dt)
			end
		end
		for id, clbk in pairs(self._paused_updaters) do
			clbk(t, dt)
		end
		for _, call in pairs(self._call_next_update) do
			if not call.only_unpaused then
				call.func(t, dt)
			end
		end
		self._call_next_update = {}
	end
end

if RequiredScript then
    local requiredScript = RequiredScript:lower()
    if BeardLib.config.hooks[requiredScript] then
        dofile(BeardLib.config.hooks_dir .. BeardLib.config.hooks[requiredScript])
    end
end