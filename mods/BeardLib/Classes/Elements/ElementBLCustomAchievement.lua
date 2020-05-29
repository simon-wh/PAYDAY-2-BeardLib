core:import("CoreMissionScriptElement")
ElementBLCustomAchievement = ElementBLCustomAchievement or class(CoreMissionScriptElement.MissionScriptElement)

function ElementBLCustomAchievement:init(...)
    ElementBLCustomAchievement.super.init(self, ...)
end

function ElementBLCustomAchievement:client_on_executed_end_screen(...)
	self:on_executed(...)
end

function ElementBLCustomAchievement:client_on_executed(...)
	self:on_executed(...)
end

function ElementBLCustomAchievement:on_executed(instigator)
    if not self._values.enabled then
	    return
    end
    if self._values.package_id == nil or self._values.achievement_id == nil then
        BeardLib:log("BLCustomAchievement Element is missing data!")
        return
    end
    if not BeardLib.Managers.Achievement:HasPackage(self._values.package_id) then
        BeardLib:log("Package %s does not exist.", self._values.package_id)
        return
    end
    if self._values.amount_increase == 0 then
        local award_achievement = true

        if self._values.award_instigator and type(instigator) == "userdata" and alive(instigator) then
            local local_player = managers.player:local_player()
            award_achievement = alive(local_player) and local_player == instigator

            if not award_achievement then
                if instigator:vehicle_driving() then
                    local seat = instigator:vehicle_driving():find_seat_for_player(local_player)

                    if seat and seat.driving then
                        award_achievement = true
                    end
                end
            end
        end

        if self._values.players_from_start and (managers.statistics:is_dropin() or game_state_machine:current_state_name() == "ingame_waiting_for_players") then
            award_achievement = false
        end

        if award_achievement then
            local package = CustomAchievementPackage:new(self._values.package_id)
            local achievement = package:Achievement(self._values.achievement_id)
            achievement:Unlock()
        end
    else
        local increase_achievement_amount = true

        if self._values.award_instigator and type(instigator) == "userdata" and alive(instigator) then
            local local_player = managers.player:local_player()
            increase_achievement_amount = alive(local_player) and local_player == instigator

            if not increase_achievement_amount then
                if instigator:vehicle_driving() then
                    local seat = instigator:vehicle_driving():find_seat_for_player(local_player)

                    if seat and seat.driving then
                        increase_achievement_amount = true
                    end
                end
            end
        end

        if self._values.players_from_start and (managers.statistics:is_dropin() or game_state_machine:current_state_name() == "ingame_waiting_for_players") then
            increase_achievement_amount = false
        end

        if increase_achievement_amount then
            local package = CustomAchievementPackage:new(self._values.package_id)
            local achievement = package:Achievement(self._values.achievement_id)
            if achievement then
                achievement:IncreaseAmount(self._values.amount_increase or 1)
            end
        end
    end

    ElementBLCustomAchievement.super.on_executed(self, instigator)
end

function ElementBLCustomAchievement:save(data)
    data.save_me = true
    data.enabled = self._values.enabled
end

function ElementBLCustomAchievement:load(data)
    self:set_enabled(data.enabled)
end