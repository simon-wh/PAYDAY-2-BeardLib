KillzoneManager.type_upd_funcs.kill = function (obj, t, dt, data)
	if not data.killed then
		data.timer = data.timer + dt
		if data.next_fire < data.timer then
			data.killed = true
			obj:_kill_unit(data.unit)
		end
	end
end

Hooks:PostHook(KillzoneManager, "_add_unit", "BeardLib.AddUnit", function(self, unit, zone_type, element_id)
	if zone_type == "kill" then
		local u_key = unit:key()
		self._units[u_key] = self._units[u_key] or {}
		self._units[u_key][zone_type] = self._units[u_key][zone_type] or {}
		self._units[u_key][zone_type][element_id] = {
			type = zone_type,
			timer = 0,
			next_fire = 0.1,
			unit = unit
		}
	end
end)
