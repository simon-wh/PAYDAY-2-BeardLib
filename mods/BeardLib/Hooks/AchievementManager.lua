local orig_AchievmentManager_award = AchievmentManager.award

function AchievmentManager:award(id)
    if CustomAchievementManager:check_chiev(id) then
        return
    end

    orig_AchievmentManager_award(self, id)
end

local orig_AchievmentManager_award_progress = AchievmentManager.award_progress

function AchievmentManager:award_progress(stat, value)
    if CustomAchievementManager:check_chiev(stat) then
        return
    end

    orig_AchievmentManager_award_progress(self, stat, value)
end
