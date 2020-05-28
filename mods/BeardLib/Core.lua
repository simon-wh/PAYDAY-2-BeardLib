if BeardLib then
	return
end

BeardLib = {
	Name = "BeardLib",
	ModPath = ModPath,
	SavePath = SavePath
}

function BeardLib:Init()
	Global.beardlib_checked_updates = Global.beardlib_checked_updates or {}

	self._call_next_update = {}
	self._paused_updaters = {}
	self._updaters = {}
	self._errors = {}
	self._modules = {}
	self.sequence_mods = {}
	self.Frameworks = {}
	self.MusicMods = {}
	self.managers = {}
	self.modules = {}
	self.Items = {}
	self.Mods = {}

	dofile(ModPath.."Classes/Utils/FileIO.lua")
	dofile(ModPath.."Classes/Utils/Utils.lua")
	dofile(ModPath.."Classes/Utils/Path.lua")
	self._config = FileIO:ReadConfig(ModPath.."main.xml", self)
	self.config = self._config

	FileIO:MakeDir(self._config.maps_dir)

	self:LoadClasses()
	self:LoadModules()
	self:LoadLocalization()

	for name, config in pairs(self._config.load_modules) do
		if BeardLib.modules[name] then
			local module = BeardLib.modules[name]:new(self, config)
			self[module._name] = module
			table.insert(self._modules, module)
			module:PostInit()
		end
	end

	self.Version = tonumber(self.AssetUpdates.version)
	self.DevMode = self.Options:GetValue("DevMode")
	self.LogSounds = self.Options:GetValue("LogSounds")
	self.OptimizedMusicLoad = BeardLib.Options:GetValue("OptimizedMusicLoad")

	self:MigrateModSettings()

	for k, manager in pairs(self.managers) do
		if manager.new then
			self.managers[k] = manager:new()
		else
			self.managers[k] = manager
		end
	end

	self:RegisterTweak()
end

function BeardLib:LoadClasses(config, prev_dir)
	config = config or self._config.classes
	local dir = Path:CombineDir(prev_dir or self._config.classes_dir, config.directory)
    for _, c in ipairs(config) do
		if c._meta == "class" then
			self:DevLog("Loading class", tostring(p))
			dofile(Path:Combine(dir, c.file))
		elseif c._meta == "classes" then
			self:LoadClasses(c, dir)
        end
    end
end

function BeardLib:LoadModules(dir)
	dir = dir or self._config.modules_dir
	local modules = FileIO:GetFiles(dir)
	if modules then
		for _, mdle in pairs(modules) do
			dofile(Path:Combine(dir, mdle))
		end
		local folders = FileIO:GetFolders(dir)
		for _, cat in pairs(folders) do
			self:LoadModules(Path:CombineDir(dir, cat))
		end
	end
end

function BeardLib:LoadLocalization()
	local languages = {}
	for _, file in pairs(FileIO:GetFiles(self._config.localization_dir)) do
		table.insert(languages, {_meta = "localization", file = file, language = Path:GetFileNameWithoutExtension(file)})
	end
	languages.directory = Path:GetFileNameWithoutExtension(self._config.localization_dir)
	LocalizationModule:new(self, languages)
end

function BeardLib:AddUpdater(id, clbk, paused)
	self._updaters[id] = clbk
	if paused then
		self._paused_updaters[id] = clbk
	end
end

function BeardLib:RemoveUpdater(id)
	self._updaters[id] = nil
	self._paused_updaters[id] = nil
end

function BeardLib:CallOnNextUpdate(func, only_unpaused, only_paused)
	table.insert(self._call_next_update, {func = func, only_unpaused = only_unpaused, only_paused = only_paused})
end

function BeardLib:RegisterFramework(name, clss)
	self.Frameworks[name] = clss
end

function BeardLib:RegisterManager(key, manager)
	self.managers[key] = manager
end

function BeardLib:RegisterModule(key, module)
	if not key or type(key) ~= "string" then
		self:log("[ERROR] BeardLib:RegisterModule parameter #1, string expected got %s", key and type(key) or "nil")
	end

	if not self.modules[key] then
		self:DevLog("Registered module with key %s", key)
		self.modules[key] = module
	else
		self:log("[ERROR] Module with key %s already exists", key)
	end
end

function BeardLib:RegisterTweak()
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
		content = {loot_drops = {}, upgrades = {}}
	}, "dlc", "mod")
end

-- kept for compatibility with mods designed for older BeardLib versions --
function BeardLib:ReplaceScriptData(replacement, replacement_type, target_path, target_ext, options)
	options = type(options) == "table" and options or {}
	FileManager:ScriptReplaceFile(target_ext, target_path, replacement, table.merge(options, { type = replacement_type, mode = options.merge_mode }))
end

function BeardLib:Update(t, dt)
	for _, manager in pairs(self.managers) do
		if manager.Update then
			manager:Update(t, dt)
		end
	end
	for _, beardlib_update in pairs(self._updaters) do
		beardlib_update(t, dt)
	end
	for _, call in pairs(self._call_next_update) do
		if not call.only_paused then
			call.func(t, dt)
		end
	end
	self._call_next_update = {}
end

function BeardLib:PausedUpdate(t, dt)
	for _, manager in pairs(self.managers) do
		if manager.Update then
			manager:Update(t, dt, true)
		end
	end
	for _, beardlib_paused_update in pairs(self._paused_updaters) do
		beardlib_paused_update(t, dt)
	end
	for _, call in pairs(self._call_next_update) do
		if not call.only_unpaused then
			call.func(t, dt)
		end
	end
	self._call_next_update = {}
end

function BeardLib:DevLog(str, ...)
	if false then
		self:log(str, ...)
	end
end

function BeardLib:ModError(mod, str, ...)
	self._errors[mod.ModPath] = self._errors[mod.ModPath] or {}
	table.insert(self._errors[mod.ModPath], string.format(str, ...))
end

function BeardLib:ShowErrorsDialog()
	local loc = managers.localization
	BeardLib.managers.dialog:Simple():Show({
		force = true,
		w = 1100,
		full_bg_color = Color.black:with_alpha(0.9),
		title = loc:text("beardlib_found_errors"),
		create_items = function(menu)
			menu:TextBox({name = loc:text("beardlib_search"), lines = 1, on_callback = function(item)
				local list = menu:GetItem("MessageScroll")
				for _, group in pairs(list:Items()) do
					local search = item:Value()
					local visible = search == "" or group.text:lower():find(search:lower()) ~= nil
					group:SetVisible(visible)
				end
			end})
			menu:QuickText(loc:text("beardlib_errors_tip"))
		end,
		create_items_contained = function(scroll)
			for mod_path, err_list in pairs(BeardLib._errors) do
				if mod_path == BeardLib.ModPath then
					mod_path = "BeardLib/Mix of mods"
				end
				local mod = scroll:Group({text = "Mod: "..mod_path, private = {background_color = Color.red:with_alpha(0.8), highlight_color = false}, offset = {16, 2}})
				for _, err in pairs(err_list) do
					mod:QuickText(err)
				end
			end
		end
	})
end

--Migrate old data (<4.0) to BeardLib 4.0'S ModSettings.
function BeardLib:MigrateModSettings()
    local disabled_mods = self.Options:GetValue("DisabledMods")
	local ignored_updates = self.Options:GetValue("IgnoredUpdates")
	local mod_settings = self.Options:GetValue("ModSettings")

	local migrated = false
	if disabled_mods and table.size(disabled_mods) > 0 then
		for mod_path, value in pairs(disabled_mods) do
			if mod_path ~= "_meta" then
				if type(mod_settings[mod_path]) ~= "table" then
					mod_settings[mod_path] = {}
				end
				mod_settings[mod_path].Enabled = not value
				migrated = true
			end
		end
		self.Options:SetValue("DisabledMods", {})
	end
	if ignored_updates and table.size(ignored_updates) > 0 then
		for mod_path, value in pairs(ignored_updates) do
			if mod_path ~= "_meta" then
				if type(mod_settings[mod_path]) ~= "table" then
					mod_settings[mod_path] = {}
				end
				mod_settings[mod_path].IgnoreUpdates = value
				migrated = true
			end
		end
		self.Options:SetValue("IgnoredUpdates", {})
	end
	if migrated then
		self.Options:SetValue("ModSettings", mod_settings)
		self.Options:Save()
	end
end

Hooks:Register("BeardLibAddCustomWeaponModsToWeapons")
Hooks:Register("BeardLibCreateCustomNodesAndButtons")
Hooks:Register("BeardLibPostCreateCustomProjectiles")
Hooks:Register("BeardLibCreateCustomProjectiles")
Hooks:Register("BeardLibCreateCustomWeaponMods")
Hooks:Register("BeardLibPreProcessScriptData")
Hooks:Register("BeardLibCreateCustomWeapons")
Hooks:Register("BeardLibCreateCustomPlayerStyles")
Hooks:Register("BeardLibCreateCustomPlayerStyleVariants")
Hooks:Register("BeardLibSetupUnloadPackages")
Hooks:Register("GameSetupPrePausedUpdate")
Hooks:Register("BeardLibRequireHook")
Hooks:Register("BeardLibCreateCustomMenus")
Hooks:Register("BeardLibProcessScriptData")
Hooks:Register("BeardLibSetupInitFinalize")
Hooks:Register("GameSetupPauseUpdate")
Hooks:Register("SetupInitManagers")
Hooks:Register("SetupPreUpdate")

--Wish I didn't have to do this. But sadly I don't think there's a hook for this.
local OrigRequire = require
BeardLib.OrigRequire = OrigRequire
function require(...)
	Hooks:Call("BeardLibRequireHook", false, ...)
	local res = OrigRequire(...)
	Hooks:Call("BeardLibRequireHook", true, ...)
	return res
end

BeardLib:Init()

Hooks:Add("GameSetupPauseUpdate", "BeardLibGameSetupPausedUpdate", ClassClbk(BeardLib, "PausedUpdate"))
Hooks:Add("GameSetupUpdate", "BeardLibGameSetupUpdate", ClassClbk(BeardLib, "Update"))
Hooks:Add("MenuUpdate", "BeardLibMenuUpdate", ClassClbk(BeardLib, "Update"))

Hooks:Add("MenuManagerInitialize", "BeardLibCreateMenuHooks", function(self)
    managers.menu = managers.menu or self
    Hooks:Call("BeardLibCreateCustomMenus", self)
    Hooks:Call("BeardLibMenuHelperPlusInitMenus", self)
	Hooks:Call("BeardLibCreateCustomNodesAndButtons", self)

    BeardLib.managers.dialog:Init()
end)

Hooks:Add("MenuManagerOnOpenMenu", "BeardLibShowErrors", function(self, menu)
	if menu == "menu_main" and not LuaNetworking:IsMultiplayer() then
		if not BeardLib.Options:GetValue("ShowErrorsDialog") then
			return
		end
		if table.size(BeardLib._errors) > 0 then
			BeardLib:ShowErrorsDialog()
		end
	end
end)