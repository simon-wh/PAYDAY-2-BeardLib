local F = table.remove(RequiredScript:split("/"))
local Hooks = Hooks

if F == "playerdamage" then
	-- This includes various dynamic music volume multipliers for player states

	Hooks:PostHook(PlayerDamage, "_start_tinnitus", "BeardLibPlayerDamageStartTinnitus", function (self)
		if not self._tinnitus_data then
			return
		end

		managers.music:set_volume_multiplier("flashbanged", 0)
		managers.music:set_volume_multiplier("flashbanged", 1, self._tinnitus_data.duration * 2)
	end)

	Hooks:PostHook(PlayerDamage, "_stop_tinnitus", "BeardLibPlayerDamageStopTinnitus", function (self)
		managers.music:set_volume_multiplier("flashbanged", 1, 1)
	end)

	Hooks:PostHook(PlayerDamage, "on_downed", "BeardLibPlayerDamageOnDowned", function (self)
		managers.music:set_volume_multiplier("downed", 0, self:down_time() * 0.65)
	end)

	Hooks:PostHook(PlayerDamage, "revive", "BeardLibPlayerDamageRevive", function (self)
		managers.music:set_volume_multiplier("downed", 1, 1)
	end)

	Hooks:PostHook(PlayerDamage, "pre_destroy", "BeardLibPlayerDamagePreDestroy", function (self)
		managers.music:set_volume_multiplier("downed", 1, 1)
	end)

	Hooks:PostHook(PlayerDamage, "pause_downed_timer", "BeardLibPlayerDamagePauseDownedTimer", function (self)
		managers.music:set_volume_multiplier("downed", managers.music:volume_multiplier("downed"))
	end)

	Hooks:PostHook(PlayerDamage, "unpause_downed_timer", "BeardLibPlayerDamageUnpauseDownedTimer", function (self)
		if self._downed_timer and self._downed_paused_counter <= 0 then
			managers.music:set_volume_multiplier("downed", 0, math.max(self._downed_timer - self:down_time() * 0.35, 0))
		end
	end)
----------------------------------------------------------------
elseif F == "dialogmanager" then
----------------------------------------------------------------
	-- This includes dynamic music volume multipliers for contractor voice lines

	Hooks:PostHook(DialogManager, "_play_dialog", "BeardLibDialogManagerPlayDialog", function (self)
		managers.music:set_volume_multiplier("dialog", 0.5)
	end)

	Hooks:PostHook(DialogManager, "_stop_dialog", "BeardLibDialogManagerStopDialog", function (self)
		managers.music:set_volume_multiplier("dialog", 1, 1)
	end)
----------------------------------------------------------------
end