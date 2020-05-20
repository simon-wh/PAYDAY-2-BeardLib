function KillzoneManager:update(t, dt)
	for _, data in pairs(self._units) do
		if alive(data.unit) then
			if data.type == "sniper" then
				data.timer = data.timer + dt
				if data.timer > data.next_shot then
					local warning_time = 4
					data.next_shot = data.timer + math.rand(warning_time < data.timer and 0.5 or 1)
					local warning_shot = math.max(warning_time - data.timer, 1)
					warning_shot = math.rand(warning_shot) > 0.75
					if warning_shot then
						self:_warning_shot(data.unit)
					else
						self:_deal_damage(data.unit)
					end
				end
			elseif data.type == "gas" then
				data.timer = data.timer + dt
				if data.timer > data.next_gas then
					data.next_gas = data.timer + 0.25
					self:_deal_gas_damage(data.unit)
				end
			elseif data.type == "fire" then
				data.timer = data.timer + dt
				if data.timer > data.next_fire then
					data.next_fire = data.timer + 0.25
					self:_deal_fire_damage(data.unit)
				end
			elseif data.type == "kill" then
				self:_deal_kill_damage(data.unit)		
			end
		end
	end
end

function KillzoneManager:_deal_kill_damage(unit)
	if unit:character_damage():need_revive() then
		return
	end
	local col_ray = {}
	local ray = Rotation(math.rand(360), 0, 0):y()
	ray = ray:with_z(-0.4):normalized()
	col_ray.ray = ray
	local attack_data = {damage = 999999, col_ray = col_ray}
	unit:character_damage():damage_killzone(attack_data)
end

Hooks:PostHook(KillzoneManager, "_add_unit", "BeardLib.AddUnit", function(self, unit, type)
	if type == "kill" then
		local next_fire = 0.1
		self._units[unit:key()] = {
			type = type,
			timer = 0,
			next_fire = next_fire,
			unit = unit
		}
	end
end)