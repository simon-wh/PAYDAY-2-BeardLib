LevelModule = LevelModule or class(ModuleBase)

LevelModule.type_name = "level"
LevelModule._loose = true

function LevelModule:init(core_mod, config)
    self.super.init(self, core_mod, config)

    self:Load()
end

function LevelModule:Load()
    if Global.level_data and Global.level_data.level_id == self._config.id then
        if self._config.include then
            for i, include_data in ipairs(self._config.include) do
                if include_data.file then
                    local file_split = string.split(include_data.file, "[.]")
                    BeardLib:ReplaceScriptData(BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.include.directory, include_data.file), include_data.type, BeardLib.Utils.Path:Combine("levels/mods/", self._config.id, file_split[1]), file_split[2], {add = true})
                end
            end
        end

        if self._config.add then
            Global.level_data._add = AddFilesModule:new(self._mod, self._config.add)
        end

        if self._config.script_data_mods then
            local script_mods = ScriptReplacementsModule:new(self._mod, self._config.script_data_mods)
            script_mods:post_init()
        end

        if self._config.hooks then
            HooksModule:new(self._mod, self._config.hooks)
        end
    end
end

function LevelModule:RegisterHook()
    Hooks:PostHook(LevelsTweakData, "init", self._config.id .. "AddLevelData", function(l_self)
        l_self[self._config.id] = {
            name_id = self._config.name_id or "heist_" .. self._config.id .. "_name",
            briefing_id = self._config.brief_id or "heist_" .. self._config.id .. "_brief",
            briefing_dialog = self._config.briefing_dialog,
            world_name = "mods/" .. self._config.id,
            ai_group_type = l_self.ai_groups[self._config.ai_group_type] or l_self.ai_groups.default,
            intro_event = self._config.intro_event or "nothing",
            outro_event = self._config.outro_event or "nothing",
            music = self._config.music or "heist",
            custom_packages = self._config.packages,
            cube = self._config.cube,
            ghost_bonus = self._config.ghost_bonus,
            max_bags = self._config.max_bags,
            team_ai_off = self._config.team_ai_off,
            custom = true
        }

        table.insert(l_self._level_index, self._config.id)
    end)

    if self._config.assets then
        Hooks:PostHook(AssetsTweakData, "init", self._config.id .. "AddAssetsData", function(a_self)
            for _, value in ipairs(self._config.assets) do
                if value._meta == "asset" then
                    if a_self[value.name] ~= nil then
                        table.insert(value.exclude and a_self[value.name].exclude_stages or a_self[value.name].stages, self._config.id)
                    else
                        self._mod:log("[ERROR] Asset %s does not exist! (Map: %s)", value.name, name)
                    end
                else
                    if not a_self[value._meta] then
                        a_self[value._meta] = value
                    else
                        self._mod:log("[ERROR] Asset with name: %s already exists! (Map: %s)", value._meta, name)
                    end
                end
            end
        end)
    end
end

BeardLib:RegisterModule(LevelModule.type_name, LevelModule)
