CustomAchievementManager = CustomAchievementManager or class()
-- Support multiple user on same PC, tracking each progress
CustomAchievementManager._achievements_folder = SavePath .. "CustomAchievements/" ..tostring(Steam:userid()).."/"
CustomAchievementManager._achievement_icons_spoofer = {}
CustomAchievementManager._ranks = {
    [1] = {
        name = "Bronze",
        color = "CD7F32"
    },
    [2] = {
        name = "Silver",
        color = "C0C0C0"
    },
    [3] = {
        name = "Gold",
        color = "FFD700"
    },
    [4] = {
        name = "Platinum",
        color = "42d9f4"
    },
    [0] = {
        name = "Hidden Rank",    -- Don't define the rank 0 yourself, that's used by me.
        color = "000000"
    }
}

function CustomAchievementManager:init()
    if not tweak_data then
        Hooks:Add("SetupInitManagers", "PostInitTweakData_CustomAchievementManager", function()
            self:init()
        end)

        return
    end

    self._tweak_data = tweak_data.achievement.custom_achievements or {}
    self:_setup_achievements()
end

function CustomAchievementManager:_get_rank_details(rank_id)
    return self._ranks[rank_id]
end

function CustomAchievementManager:_add_to_icon_spoofer(params)
    table.insert(self._achievement_icons_spoofer, params)
end

function CustomAchievementManager:_has_package(package_id)
    if self._tweak_data[package_id] then
        return true
    end

    return false
end

function CustomAchievementManager:_has_any_package()
    if self:_number_of_packages() > 0 then
        return true
    end

    return false
end

-- Use CustomAchievementPackage when possible.
function CustomAchievementManager:_has_achievement(package_id, achievement_id)
    if self._tweak_data[package_id][achievement_id] then
        return true
    end

    return false
end

function CustomAchievementManager:_setup_achievements()
    -- I --     Make the base directory.
    FileIO:MakeDir(CustomAchievementManager._achievements_folder)

    -- II --    Read Packages, create folders.
    for package_id, _ in pairs(self._tweak_data) do
        local package_path = CustomAchievementManager._achievements_folder .. "/" .. tostring(package_id)

        FileIO:MakeDir(package_path)

        -- III --   Create achievement file by packages.
        local package = CustomAchievementPackage:new(package_id)

        for achievement_id, achievement_data in pairs(package:_fetch_achievements()) do
            if achievement_id ~= "icon" then    -- Prevent adding package icon param to achievements.
                local achievement_path = package_path .. "/" .. achievement_id .. ".json"
                if not FileIO:Exists(achievement_path) then

                    local achievement_progress_config = {
                        completed = false,
                        amount = 0,
                        date_unlocked = 0
                    }

                    local content = json.custom_encode(achievement_progress_config)
                    FileIO:WriteTo(achievement_path, content, "w+")
                end
            end
        end
    end
end

function CustomAchievementManager:_fetch_packages()
    if not self:_has_any_package() then
        return {}
    end

    local packages = {}

    for _, package in ipairs(FileIO:GetFolders(self._achievements_folder)) do
        table.insert(packages, package)
    end

    return packages
end

function CustomAchievementManager:_number_of_packages()
    local nb = 0
    local tweak = tweak_data.achievement.custom_achievements or {}

    for _, package in pairs(tweak) do
        nb = nb + 1
    end

    return nb
end

function CustomAchievementManager:_number_of_achievements()
    local nb = 0
    local tweak = tweak_data.achievement.custom_achievements or {}

    for package, _ in pairs(tweak) do
        for _, achievement in pairs(tweak[package]) do
            if type(achievement) == "table" then
                nb = nb + 1
            end
        end
    end

    return nb
end

function CustomAchievementManager:_completed_achievements_total()
    local nb = 0

    if not self._tweak_data then -- i hate this game
        self._tweak_data = tweak_data and tweak_data.achievement and tweak_data.achievement.custom_achievements or {}
    end
    
    for package_id, _ in pairs(self._tweak_data or {}) do
        local package = CustomAchievementPackage:new(package_id)

        for achievement_id, _ in pairs(package:_fetch_achievements()) do
            local config = package:_get_config_of(achievement_id)
            --log("config is " .. tostring(config))
            if type(config) == "table" then
                local achievement = CustomAchievement:new(config, package_id)
                --log(tostring(achievement:_get_name()) .. " unlock state: " .. tostring(achievement:_is_unlocked()))
                if achievement:_is_unlocked() then
                    nb = nb + 1
                end
            end
        end
    end

    return nb
end

function CustomAchievementManager:_get_all_completed_ranks()
    local t = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0
    }

    local tweak = tweak_data.achievement.custom_achievements or {}

    for package_id, _ in pairs(tweak) do
        local package = CustomAchievementPackage:new(package_id)

        for achievement_id, _ in pairs(package:_fetch_achievements()) do
            local config = package:_get_config_of(achievement_id)
            
            if type(config) == "table" then
                local achievement = CustomAchievement:new(config, package_id)

                if achievement:_is_unlocked() then
                    t[achievement:_get_rank_id()] = t[achievement:_get_rank_id()] + 1
                end
            end
        end
    end

    return t
end

CustomAchievementPackage = CustomAchievementPackage or class()

function CustomAchievementPackage:init(package_id)
    local tweak = tweak_data.achievement.custom_achievements_packages[self._package_id]
    self._package_id = package_id
    self._achievements = tweak_data.achievement.custom_achievements[self._package_id]
    self._name_id = tweak_data.achievement.custom_achievements_packages[self._package_id].name or self._package_id .. "_name"
    self._desc_id = tweak_data.achievement.custom_achievements_packages[self._package_id].desc
    self._icon = tweak_data.achievement.custom_achievements_packages[self._package_id].icon or "guis/textures/achievement_package_default"
    self._banner = tweak_data.achievement.custom_achievements_packages[self._package_id].banner
end

function CustomAchievementPackage:_get_name()
    return managers.localization:text(self._name_id)
end

function CustomAchievementPackage:_get_desc()
    if not self._desc_id then
        return ""
    end

    return managers.localization:text(self._desc_id)
end

function CustomAchievementPackage:_get_icon()
    return self._icon
end

function CustomAchievementPackage:_get_banner()
    return self._banner
end

function CustomAchievementPackage:_fetch_achievements()
    return self._achievements
end

function CustomAchievementPackage:_manual_achievement_addition(achievement_id, config)
    if tweak_data and tweak_data.achievement then
        tweak_data.achievement.custom_achievements[self._package_id][achievement_id] = config
        BeardLib.managers.custom_achievement:_setup_achievements()
    end
end

function CustomAchievementPackage:_get_config_of(achievement_id)
    return self._achievements[achievement_id]
end

function CustomAchievementPackage:_has_achievement(achievement_id)
    if self._achievements[achievement_id] then
        return true
    end

    return false
end

function CustomAchievementPackage:_achievement(achievement_id)
    if not self:_has_achievement(achievement_id) then
        return BeardLib:log("[CustomAchievementPackage] [ERROR] '%s' does not exist for the achievement package '%s'", achievement_id, self._package_id)
    end

    return CustomAchievement:new(self:_get_config_of(achievement_id), self._package_id)
end

function CustomAchievementPackage:_generate_achievement_table()
    local achievement_table = {}
    achievement_table[self._package_id] = {}
    local fetched_achievements = self:_fetch_achievements()
    achievement_table[self._package_id] = fetched_achievements
    return achievement_table[self._package_id]
end

function CustomAchievementPackage:_get_completed_achievements()
    local nb = 0

    for achievement_id, _ in pairs(self:_fetch_achievements()) do
        local config = self:_get_config_of(achievement_id)
        
        if type(config) == "table" then
            local achievement = CustomAchievement:new(config, self._package_id)

            if achievement:_is_unlocked() then
                nb = nb + 1
            end
        end
    end

    return nb
end

-- Useful for "complete all achievements" achievement.
function CustomAchievementPackage:_all_achievements_completed_except_one()
    local nb = self:_get_total_achievements() - 1

    if self:_get_completed_achievements() == nb then
        return true
    end

    return false
end

function CustomAchievementPackage:_get_total_achievements()
    local nb = 0

    for achievement_id, _ in pairs(self:_fetch_achievements()) do
        local config = self:_get_config_of(achievement_id)
        
        if type(config) == "table" then
            nb = nb + 1
        end
    end

    return nb
end

CustomAchievement = CustomAchievement or class()

CustomAchievement._MAX_EXP_AMOUNT = 10000000
CustomAchievement._MAX_MONEY_AMOUNT = 50000000
CustomAchievement._MAX_OFFSHORE_AMOUNT = 100000000
CustomAchievement._MAX_CC_AMOUNT = 1000

CustomAchievement.limits = {
    xp = CustomAchievement._MAX_EXP_AMOUNT,
    cc = CustomAchievement._MAX_CC_AMOUNT,
    cash = CustomAchievement._MAX_MONEY_AMOUNT,
    offshore = CustomAchievement._MAX_OFFSHORE_AMOUNT
}

CustomAchievement.valid_rewards = {
    "xp",
    "cc",
    "cash",
    "offshore"
}

function CustomAchievement:init(config, package)
    if type(config) ~= "table" then
        return
    end

    self._progress_file = CustomAchievementManager._achievements_folder .. "/" .. tostring(package) .. "/" .. tostring(config.id) .. ".json"

    self._package_id = package
    self._id = config.id
    self._name_id = config.name_id or "no_name_id"
    self._desc_id = config.desc_id or "no_desc_id"
    self._obj_id = config.obj_id or "no_obj_id"
    self._rank = config.rank or 1
    self._icon_path = config.icon
    self._amount = config.amount
    self._hidden_details = config.hidden_achievement or false
    self._reward_type = config.reward_type
    self._reward_amount = config.reward_amount

    self._saved_amount = 0          --  In Progression File
    self._unlocked = false          --  In Progression File
    self._timestamp_unlocked = 0    --  In Progression File

    self:_load_progress()
end

function CustomAchievement:_get_name()
    if self:_is_hidden() and not self:_is_unlocked() then
        return "Hidden Achievement"
    end

    return managers.localization:text(self._name_id)
end

function CustomAchievement:_get_desc()
    if self:_is_hidden() and not self:_is_unlocked() then
        return "Details will be revealed once the achievement is unlocked."
    end

    return managers.localization:text(self._desc_id)
end

function CustomAchievement:_get_objective()
    if self:_is_hidden() and not self:_is_unlocked() then
        return "???"
    end

    return managers.localization:text(self._obj_id)
end

function CustomAchievement:_get_icon()
    if self:_is_hidden() and not self:_is_unlocked() then
        return "guis/textures/achievement_trophy_white"
    end

    return self._icon_path
end

function CustomAchievement:_get_unlock_timestamp()
    return self._timestamp_unlocked
end

function CustomAchievement:_get_rank_name()
    local rank_id = self:_is_hidden() and 0 or self._rank

    local rank = CustomAchievementManager:_get_rank_details(rank_id)
    return rank.name
end

function CustomAchievement:_get_rank_color()
    local rank_id = self:_is_hidden() and 0 or self._rank

    local rank = CustomAchievementManager:_get_rank_details(rank_id)
    return rank.color
end

function CustomAchievement:_is_default_icon()
    if self:_is_hidden() or self._icon_path == "guis/textures/achievement_trophy_white" then
        return true
    end

    return false
end

function CustomAchievement:_package()
    if not self._package_id then
        return BeardLib:log("[CustomAchievementPackage] [ERROR] Achievement '%s' lacking package id. Did you invoked the CustomAchievement class with the package ID?", self._id)
    end

    return CustomAchievementPackage:new(self._package_id)
end

function CustomAchievement:_load_progress()
    local progress_data = json.custom_decode(FileIO:ReadFrom(self._progress_file))
    
    self._saved_amount = progress_data.amount
    self._unlocked = progress_data.completed
    self._timestamp_unlocked = progress_data.date_unlocked
end

function CustomAchievement:_save_progress()
    local data = {
        amount = self._saved_amount,
        completed = self._unlocked,
        date_unlocked = self._timestamp_unlocked
    }

    FileIO:WriteTo(self._progress_file, json.custom_encode(data), "w+")
end

function CustomAchievement:_increase_amount(amt, to_max)
    if self:_is_unlocked() then
        return
    end

    if to_max then
        self._saved_amount = self._amount
        self:_save_progress()
        self:_check_completion()
        return
    end

    self._saved_amount = self._saved_amount + amt

    if (self._saved_amount > self._amount) then
        self._saved_amount = self._amount
    end

    self:_save_progress()
    self:_check_completion()
end

function CustomAchievement:_check_completion()
    if self:_is_unlocked() then
        return
    end

    if self._saved_amount >= self._amount then
        self:_unlock()
    end
end

function CustomAchievement:_unlock()
    if self:_is_unlocked() then
        return
    end

    self._unlocked = true
    self._timestamp_unlocked = os.time()

    if HudChallengeNotification then
        HudChallengeNotification.queue(
            managers.localization:to_upper_text("hud_achieved_popup"), 
            managers.localization:to_upper_text(self._name_id), 
            self._icon_path or "placeholder_circle"
        )
    end

    self:_give_reward()
    self:_increase_amount(nil, true)
    self:_save_progress()
end

function CustomAchievement:_lock()
    self._unlocked = false
    self._timestamp_unlocked = 0
    self:_save_progress()
end

function CustomAchievement:_get_reward_type()
    return tostring(self._reward_type)
end

function CustomAchievement:_get_reward_amount()
    return self._reward_amount
end

function CustomAchievement:_give_reward()
    if not self._reward_type then
        return
    end

    local continue = false
    
    -- Sanity checks
    for _, v in pairs(CustomAchievement.valid_rewards) do
        if self._reward_type == v then
            continue = true
        end
    end

    if continue then
        if self._reward_amount > CustomAchievement.limits[self._reward_type] then
            self._reward_amount = CustomAchievement.limits[self._reward_type]
        end

        if self._reward_amount < 0 then
            self._reward_amount = 0
        end

        if self._reward_type == "xp" then
            managers.experience:debug_add_points(self._reward_amount, false)

        elseif self._reward_type == "cc" then
            local current_cc = Application:digest_value(managers.custom_safehouse._global.total)
            local new_cc = current_cc + self._reward_amount

            Global.custom_safehouse_manager.total = Application:digest_value(new_cc, true)

        elseif self._reward_type == "cash" then
            managers.money:_add_to_total(self._reward_amount, {no_offshore = true})

        elseif self._reward_type == "offshore" then
            managers.money:add_to_offshore(self._reward_amount)

        end
    end
end

function CustomAchievement:_is_unlocked()
    return self._unlocked
end

function CustomAchievement:_sanitize_max_rewards(amount)
    if amount > CustomAchievement.limits[self._reward_type] then
        amount = CustomAchievement.limits[self._reward_type]
    end

    if amount < 0 then
        amount = 0
    end

    return amount
end

function CustomAchievement:_has_amount_value()
    if self._amount > 0 then
        return true
    end

    return false
end

function CustomAchievement:_amount_value()
    return self._amount
end

function CustomAchievement:_current_amount_value()
    return self._saved_amount
end

function CustomAchievement:_is_hidden()
    if self:_is_unlocked() then
        return false
    end

    return self._hidden_details
end

function CustomAchievement:_has_reward()
    return self._reward_type and true or false
end

function CustomAchievement:_get_rank_id()
    if self:_is_hidden() and not self:_is_unlocked() then
        return 0
    end

    return self._rank
end

return CustomAchievementManager
