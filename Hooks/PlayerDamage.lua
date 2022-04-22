Hooks:PostHook(PlayerDamage, "_start_tinnitus", "BeardLibPlayerDamageStartTinnitus", function (self, sound_eff_mul)
	if not self._tinnitus_data then
		return
	end

	managers.music:set_volume_multiplier(0)
	managers.music:set_volume_multiplier(1, self._tinnitus_data.duration * 2)
end)
