MapFramework = MapFramework or class(FrameworkBase)

function MapFramework:init()
    BeardLib.managers.MapFramework = self
    self._asset_folder_required = true
    self._directory = BeardLib.MapsPath
    self._config_calls = {
        localization = {func = callback(self, self, "LoadLocalizationConfig"), requires_assets = true},
        contact = {func = callback(self, self, "LoadContactConfig")},
        narrative = {func = callback(self, self, "LoadNarrativeConfig")},
        level = {func = callback(self, self, "LoadLevelConfig"), requires_assets = true}
    }
    self.super.init(self)
end

function MapFramework:LoadContactConfig(name, path, data)
    Hooks:PostHook(NarrativeTweakData, "init", data.id .. "AddContactData", function(self)
        self.contacts[data.id] = {
            name_id = data.name_id,
            description_id = data.desc_id,
            package = data.package,
            assets_gui = data.assets_gui and data.assets_gui:id()
        }
    end)
end

function MapFramework:LoadNarrativeConfig(name, path, data)
    Hooks:PostHook(NarrativeTweakData, "init", data.id .. "AddNarrativeData", function(self)
        self.jobs[data.id] = {
            name_id = data.name_id or "heist_" .. data.id .. "_name",
            briefing_id = data.brief_id or "heist_" .. data.id .. "_brief",
            contact = data.contact or "bain",
            jc = data.jc or 50,
            chain = {},
            briefing_event = data.briefing_event,
            debrief_event = data.debrief_event,
            crimenet_callouts = BeardLib.Utils:RemoveNonNumberIndexes(data.crimenet_callouts),
            crimenet_videos = BeardLib.Utils:RemoveNonNumberIndexes(data.crimenet_videos),
            payout = BeardLib.Utils:RemoveNonNumberIndexes(data.payout) or {0.001,0.001,0.001,0.001,0.001},
            contract_cost = BeardLib.Utils:RemoveNonNumberIndexes(data.contract_cost) or {0.001,0.001,0.001,0.001,0.001},
            experience_mul = BeardLib.Utils:RemoveNonNumberIndexes(data.experience_mul) or {0.001,0.001,0.001,0.001,0.001},
            contract_visuals = {
                min_mission_xp = BeardLib.Utils:RemoveNonNumberIndexes(data.min_mission_xp) or {0.001,0.001,0.001,0.001,0.001},
                max_mission_xp = BeardLib.Utils:RemoveNonNumberIndexes(data.max_mission_xp) or {0.001,0.001,0.001,0.001,0.001}
            }
        }
        if data.merge_data then
            table.merge(self.jobs[data.id], data.merge_data)
        end
        for i, level in ipairs(data.chain) do
            self.jobs[data.id].chain[i] = level
        end

        table.insert(self._jobs_index, data.id)
    end)
end

function MapFramework:LoadLevelConfig(name, path, data)
    if Global.level_data and Global.level_data.level_id == data.id then
        if data.include then
            for i, include_data in ipairs(data.include) do
                if include_data.file then
                    local file_split = string.split(include_data.file, "[.]")
                    BeardLib:ReplaceScriptData(path .. (data.include.directory and (data.include.directory .. "/") or "") .. include_data.file, include_data.type, "levels/mods/" .. data.id .. "/" .. file_split[1], file_split[2], true)
                end
            end
        end

        if data.script_data_mods then
            for i, mod_data in ipairs(data.script_data_mods) do
                if mod_data._meta == "mod" then
                    BeardLib:ReplaceScriptData(path .. mod_data.replacement, mod_data.replacement_type, mod_data.target_path, mod_data.target_ext, mod_data.add, mod_data.merge_mode)
                end
            end
        end

        if data.hooks then
            local dest_tbl = _posthooks
            for _, hook in ipairs(data.hooks) do
                if io.file_is_readable(path .. hook.file) then
                    local req_script = hook.source_file:lower()

                    dest_tbl[req_script] = dest_tbl[req_script] or {}
                    table.insert(dest_tbl[req_script], {
                        mod_path = path,
                        script = path .. hook.file
                    })
                else
                    self:log("[ERROR] Level hook file does not exist! File: " .. path .. hook.file)
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
            allowed_gamemodes = BeardLib.Utils:RemoveNonNumberIndexes(data.allowed_gamemodes)
        }

        table.insert(self._level_index, data.id)
    end)
end
