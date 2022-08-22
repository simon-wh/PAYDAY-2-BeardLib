--[[
    Maintenance by Sora [Sora#5529 Discord]
--]]

AchievementsModule = AchievementsModule or BeardLib:ModuleClass("Achievements", ItemModuleBase)

function AchievementsModule:RegisterHook()
    self._package_id = self._config.id
    self._package_name = self._config.name
    self._package_icon = self._config.icon or "guis/textures/achievement_package_default"
    self._package_banner = self._config.banner
    self._package_desc = self._config.desc

    Hooks:PostHook(AchievementsTweakData, "init", self._package_id .. "_custom_achievement_data", function(a_self, tweak_data)
        if not a_self.custom_achievements then
            a_self.custom_achievements = {}
            a_self.custom_achievements_packages = {}
        end

        if not a_self.custom_achievements[self._package_id] then
            a_self.custom_achievements[self._package_id] = {}
            a_self.custom_achievements_packages[self._package_id] = {
                id = self._package_id,
                icon = self._package_icon,
                name = self._package_name,
                desc = self._package_desc,
                banner = self._package_banner
            }
        end

        for _, achievement in ipairs(self._config) do
            if type(achievement) == "table" then

                local achievement_data = {
                    id = achievement.id or self:Err("No ID provided for an achievement..."),
                    name_id = achievement.name_id or achievement.id .. "_name",
                    desc_id = achievement.desc_id or achievement.id .. "_desc",
                    obj_id = achievement.objective_id or achievement.id .. "_objective",
                    icon = achievement.icon or "guis/textures/achievement_trophy_white",
                    icon_rect = achievement.icon_rect or nil,
                    rank = achievement.rank or 1,
                    amount = achievement.amount or 0,
                    weapon_id = achievement.weapon_id or nil,
                    map_id = achievement.map_id or nil,
                    difficulty = achievement.difficulty or nil,
                    goal = achievement.goal or achievement.weapon_id and "kills" or achievement.map_id and "completion",
                    unit = achievement.unit or nil,
                    reward_type = achievement.reward_type,
                    reward_amount = achievement.reward_amount or 0,
                    hidden_achievement = achievement.hidden_achievement or false
                }

                if a_self.custom_achievements[self._package_id][achievement_data.id] then
                    self:Err("Cannot add ".. achievement_data.id .. " to package" .. self._package_id .. ". This ID already exists.")
                    return
                end

                a_self.custom_achievements[self._package_id][achievement_data.id] = achievement_data

                if achievement.icon then
                    BeardLib.Managers.Achievement:AddToIconSpoofer({achievement_data.icon})
                end
            end
        end
    end)

    -- Very ugly workaround. But it seems HudIconsTweakData is loaded before AchievementTweakData. bah. It works as it is, all that matter.
    Hooks:PostHook(HudIconsTweakData, "init", "custom_achievement_icon_data", function(i_self)
        BeardLib:AddDelayedCall("custom_icons_wait_initialization", 2, function()
            for _, icon_tables in ipairs(BeardLib.Managers.Achievement._achievement_icons_spoofer) do
                for _, icon_path in pairs(icon_tables) do
                    if i_self[icon_path] then
                        return
                    end

                    i_self[icon_path] = {
                        texture = icon_path
                    }
                end
            end
        end)
    end)
end