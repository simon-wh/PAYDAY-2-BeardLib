_G.CustomAchievementManager = {
    _enabled = true,
    achievement_settings = {},
    callbacks = {}
}

function CustomAchievementManager:enabled(chiev)
    if not chiev then
        return self._enabled
    else
        return not not self.achievement_settings[chiev]
    end
end

function CustomAchievementManager:enable(chiev)
    self:set_enabled(true, chiev)
end

function CustomAchievementManager:disable(chiev)
    self:set_enabled(false, chiev)
end

function CustomAchievementManager:set_enabled(enabled, chiev)
    if type(enabled) ~= "bool" then
        BeardLib:log("[WARNING] CustomAchievementManager:set_enabled. Param #1, expected bool, got " .. tostring(type(enabled)))
        return
    end

    if not chiev then
        self._enabled = enabled
    else
        self.achievement_settings[chiev] = enabled
    end
end

function CustomAchievementManager:add_callback(id, func)
    if not id or type(id) ~= "string" then
        BeardLib:log("[ERROR] CustomAchievementManager:add_callback. Param #1, expected string, got " .. tostring(type(id)))
        return
    end

    if self.callbacks[id] then
        BeardLib:log("[WARNING] An achievement callback with id '%s' already exists. Overwriting...", id)
    end

    self.callbacks[id] = func
end

function CustomAchievementManager:remove_callback(id)
    self.callbacks[id] = nil
end

function CustomAchievementManager:check_chiev(id)
    if not self._enabled then
        return true
    end

    for id, clbk in pairs(self.callbacks) do
        if clbk(id) == false then
            return true
        end
    end

    if self.achievement_settings[id] == false then
        return true
    end

    return false
end