core:import("CoreMissionScriptElement")
ElementMoveUnit = ElementMoveUnit or class(CoreMissionScriptElement.MissionScriptElement)
function ElementMoveUnit:init(...)
	self._units = {}
	self.super.init(self, ...)
end
function ElementMoveUnit:on_script_activated()
	for _, id in pairs(self._values.unit_ids) do
		local unit = managers.worlddefinition:get_unit_on_load(id)
		if unit then
			table.insert(self._units, unit)
		end
	end
	self._has_fetched_units = true
end
function ElementMoveUnit:client_on_executed(...)
	self:on_executed(...)
end
function ElementMoveUnit:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if #self._units == 0 then
		managers.game_play_central:add_move_unit(instigator, self._values.position, self._values.speed, {x = self._values.change_x, y = self._values.change_y, z = self._values.change_z}, callback(self, self, "done_callback", instigator))
	else		
		for _, unit in pairs(self._units) do
			managers.game_play_central:add_move_unit(unit, self._values.position, self._values.speed, {x = self._values.change_x, y = self._values.change_y, z = self._values.change_z}, callback(self, self, "done_callback", instigator))
		end
	end
end
function ElementMoveUnit:done_callback(instigator)
	ElementMoveUnit.super.on_executed(self, instigator)
end
function ElementMoveUnit:save(data)
	data.save_me = true
	data.enabled = self._values.enabled
end
function ElementMoveUnit:load(data)
	if not self._has_fetched_units then
		self:on_script_activated()
	end
	self:set_enabled(data.enabled)
end
