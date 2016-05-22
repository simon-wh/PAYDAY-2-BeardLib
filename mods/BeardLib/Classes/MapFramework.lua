MapFramework = MapFramework or class()

function MapFramework:init()
    BeardLib.managers.MapFramework = self
    self._config_calls = {
        ["localization"] = callback(self, self, "LoadLocalizationConfig"),
        ["contact"] = callback(self, self, "LoadContactConfig"),
        ["narrative"] = callback(self, self, "LoadNarrativeConfig"),
        ["level"] = callback(self, self, "LoadLevelConfig")
    }

    self._maps = {}
    self:LoadMaps()
end

function MapFramework:LoadMaps()
    local files = file.GetFiles(BeardLib.MapsPath)
    if files then
        for _, config_file in pairs(files) do
            local cfile_split = string.split(config_file, "%.")
            local cfile = io.open(BeardLib.MapsPath .. "/" .. config_file, 'r')
            local data

            if file.DirectoryExists(BeardLib.MapsPath .. "/" .. cfile_split[1]) then
                data = ScriptSerializer:from_custom_xml(cfile:read("*all"))
                self:LoadMapConfig(cfile_split[1], data)
            else
                BeardLib:log("[ERROR] Map must have an assets folder. Map: " .. cfile_split[1])
            end
        end
    end
end

function MapFramework:LoadMapConfig(name, data)
    self._maps[name]  = data

    --[[if not tweak_data then
        BeardLib:log("[ERROR] Tweak Data has not been intialized before this map was attempted to be loaded")
    else]]
        for _, sub_data in ipairs(data) do
            if self._config_calls[sub_data._meta] then
                self._config_calls[sub_data._meta](name, sub_data)
            end
        end
    --end
end

local load_localization_file = function(key, directory, file)
    local localiz_path = BeardLib.MapsPath .. "/" .. key .. "/" .. directory .. "/" .. file
    if io.file_is_readable(localiz_path) then
        BeardLib:log("Loaded: " .. localiz_path)
        LocalizationManager:load_localization_file(localiz_path)
        return true
    else
        BeardLib:log("[ERROR] Localization file is not readable by the lua state! File: " .. localiz_path)
        return false
    end
end

function MapFramework:LoadLocalizationConfig(name, data)
    Hooks:Add("LocalizationManagerPostInit", name .. "LevelLocalization", function(loc)
        local file_loaded = false

        for i, def in ipairs(data) do
            if Idstring(def.language):key() == SystemInfo:language():key() then
                if load_localization_file(name, data.directory, def.file) then
                    file_loaded = true
                    break
                end
            end
        end

        if not file_loaded and data.default then
            load_localization_file(name, data.directory, data.default)
        end
	end)
end

function MapFramework:LoadContactConfig(name, data)
    Hooks:PostHook(NarrativeTweakData, "init", data.id .. "AddContactData", function(self)
        self.contacts[data.id] = {
            name_id = data.name_id,
            description_id = data.desc_id,
            package = data.package,
            assets_gui = data.assets_gui and data.assets_gui:id()
        }
    end)
end

function MapFramework:LoadNarrativeConfig(name, data)
    Hooks:PostHook(NarrativeTweakData, "init", data.id .. "AddNarrativeData", function(self)
        self.jobs[data.id] = {
            name_id = data.name_id or "heist_" .. data.id .. "_name",
            briefing_id = data.brief_id or "heist_" .. data.id .. "_brief",
            contact = data.contact or "bain",
            jc = data.jc or 50,
            chain = {},
            briefing_event = data.briefing_event,
            debrief_event = data.debrief_event,
            crimenet_callouts = data.crimenet_callouts,
            crimenet_videos = data.crimenet_videos,
            payout = data.payout or {0.001,0.001,0.001,0.001,0.001},
            contract_cost = BeardLib.Utils:RemoveNonNumberIndexes(data.contract_cost) or {0.001,0.001,0.001,0.001,0.001},
            experience_mul = BeardLib.Utils:RemoveNonNumberIndexes(data.experience_mul) or {0.001,0.001,0.001,0.001,0.001},
            contract_visuals = {
                min_mission_xp = BeardLib.Utils:RemoveNonNumberIndexes(data.min_mission_xp) or {0.001,0.001,0.001,0.001,0.001},
                max_mission_xp = BeardLib.Utils:RemoveNonNumberIndexes(data.max_mission_xp) or {0.001,0.001,0.001,0.001,0.001}
            }
        }

        for i, level in ipairs(data.chain) do
            self.jobs[data.id].chain[i] = level
        end

        table.insert(self._jobs_index, data.id)
    end)
end

function MapFramework:LoadLevelConfig(name, data)
    if Global.level_data and Global.level_data.level_id == data.id then
        if data.include then
            for i, include_data in ipairs(data.include) do
                if include_data.file then
                    local file_split = string.split(include_data.file, "[.]")
                    BeardLib:ReplaceScriptData(BeardLib.MapsPath .. "/" .. name .. "/" .. include_data.file, include_data.type, "levels/mods/" .. data.id .. "/" .. file_split[1], file_split[2], true)
                end
            end
        end

        if data.script_data_mods then
            for i, mod_data in ipairs(data.script_data_mods) do
                if mod_data._meta == "mod" then
                    BeardLib:ReplaceScriptData(BeardLib.MapsPath .. "/" .. name .. "/" .. mod_data.replacement, mod_data.replacement_type, mod_data.target_path, mod_data.target_ext, mod_data.add, mod_data.merge_mode)
                end
            end
        end
    end
    Hooks:PostHook(LevelsTweakData, "init", data.id .. "AddLevelData", function(self)

        self[data.id] = {
            name_id = data.name_id or "heist_" .. data.id .. "_name",
            briefing_id = data.brief_id or "heist_" .. data.id .. "_brief",
            briefing_dialog = data.briefing_dialog,
            world_name = "mods/" .. data.id,
            ai_group_type = self.ai_groups[data.ai_group_type] or self.ai_groups.default,
            intro_event = data.intro_event or "nothing",
            outro_event = data.outro_event or "nothing",
            music = music or "heist",
            custom_packages = data.packages,
            cube = data.cube,
            ghost_bonus = data.ghost_bonus,
            max_bags = data.max_bags,
            allowed_gamemodes = data.allowed_gamemodes
        }

        table.insert(self._level_index, data.id)
    end)
end
