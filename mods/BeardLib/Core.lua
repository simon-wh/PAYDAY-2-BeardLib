if BeardLib then
	return
end

BeardLib = {}
local self = BeardLib

self.Name = "BeardLib"
self.ModPath = ModPath
self.SavePath = SavePath
self.sequence_mods = {}	
self.Frameworks = {}
self.MusicMods = {}
self.managers = {}	
self.modules = {}
self.Items = {}
self.Mods = {}

self._call_next_update = {}
self._paused_updaters = {}
self._updaters = {}

function self:Init()
	Global.beardlib_checked_updates = Global.beardlib_checked_updates or {}

	dofile(ModPath.."Classes/Utils/FileIO.lua")
	self._config = FileIO:ReadConfig(ModPath.."Config.xml", self)
	self.config = self._config

	FileIO:MakeDir(self._config.maps_dir)
	
	self:LoadClasses()
	self:LoadModules()
	self:LoadLocalization()
	
	for name, config in pairs(self._config.load_modules) do
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
	
	self:RegisterTweak()
	self.DevMode = self.Options:GetValue("DevMode")
end

function self:LoadClasses()
	for _, clss in ipairs(self._config.classes) do
		local p = self._config.classes_dir .. clss.file
		self:DevLog("Loading class", tostring(p))
		local obj = loadstring( "--"..p.. "\n" .. io.open(p):read("*all"))()
		if clss.manager and obj then
			self.managers[clss.manager] = obj
		end
	end
end

function self:LoadModules()
	local modules = FileIO:GetFiles(self._config.modules_dir)
	if modules then
		for _, mdle in pairs(modules) do
			dofile(self._config.modules_dir .. mdle)
		end
	end
end

function self:LoadLocalization()
	local languages = {}
	for i, file in pairs(FileIO:GetFiles(self._config.localization_dir)) do
		table.insert(languages, {_meta = "localization", file = file, language = Path:GetFileNameWithoutExtension(file)})
	end
	languages.directory = Path:GetFileNameWithoutExtension(self._config.localization_dir)
	LocalizationModule:new(self, languages)
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

function self:RegisterFramework(name, clss)
	self.Frameworks[name] = clss
end

function self:RegisterModule(key, module)
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
	for id, beardlib_update in pairs(self._updaters) do
		beardlib_update(t, dt)
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
	for id, beardlib_paused_update in pairs(self._paused_updaters) do
		beardlib_paused_update(t, dt)
	end
	for _, call in pairs(self._call_next_update) do
		if not call.only_unpaused then
			call.func(t, dt)
		end
	end
	self._call_next_update = {}
end

function self:DevLog(str, ...)
	if self.DevMode then
		self:log(str, ...)
	end
end

function self:log(...) ModCore.log(self, ...) end
function self:GetPath() return ModCore.GetPath(self) end
function self:GetRealFilePath(...) return ModCore.GetRealFilePath(self, ...) end
function self:RegisterHook(...) return ModCore.RegisterHook(self, ...) end

Hooks:Register("BeardLibAddCustomWeaponModsToWeapons")
Hooks:Register("BeardLibCreateCustomNodesAndButtons")
Hooks:Register("BeardLibPostCreateCustomProjectiles")
Hooks:Register("BeardLibCreateCustomProjectiles")
Hooks:Register("BeardLibCreateCustomWeaponMods")
Hooks:Register("BeardLibPreProcessScriptData")
Hooks:Register("BeardLibCreateCustomWeapons")
Hooks:Register("BeardLibSetupUnloadPackages")
Hooks:Register("BeardLibRequireHook")
Hooks:Register("BeardLibCreateCustomMenus")
Hooks:Register("BeardLibProcessScriptData")
Hooks:Register("BeardLibSetupInitFinalize")
Hooks:Register("GameSetupPauseUpdate")
Hooks:Register("SetupInitManagers")

--Wish I didn't have to do this. But sadly I don't think there's a hook for this.
local OrigRequire = require
BeardLib.OrigRequire = OrigRequire
function require(...)
	Hooks:Call("BeardLibRequireHook", false, ...)
	local res = OrigRequire(...)
	Hooks:Call("BeardLibRequireHook", true, ...)
	return res
end

self:Init()

Hooks:Add("GameSetupPauseUpdate", "BeardLibGameSetupPausedUpdate", ClassClbk(self, "PausedUpdate"))
Hooks:Add("GameSetupUpdate", "BeardLibGameSetupUpdate", ClassClbk(self, "Update"))
Hooks:Add("MenuUpdate", "BeardLibMenuUpdate", ClassClbk(self, "Update"))

Hooks:Add("MenuManagerInitialize", "BeardLibCreateMenuHooks", function(mself)
    managers.menu = managers.menu or mself
    Hooks:Call("BeardLibCreateCustomMenus", mself)
    Hooks:Call("BeardLibMenuHelperPlusInitMenus", mself)
	Hooks:Call("BeardLibCreateCustomNodesAndButtons", mself)
	
    self.managers.dialog:Init()
end)