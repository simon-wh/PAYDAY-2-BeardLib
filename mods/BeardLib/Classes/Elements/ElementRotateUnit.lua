--Based of ElementMoveUnit

core:import("CoreMissionScriptElement")
ElementRotateUnit = ElementRotateUnit or class(CoreMissionScriptElement.MissionScriptElement)
function ElementRotateUnit:init(...)
	self._units = {}
	ElementRotateUnit.super.init(self, ...)
end

function ElementRotateUnit:on_script_activated()
	for _, id in pairs(self._values.unit_ids) do
		local unit = managers.worlddefinition:get_unit_on_load(id)
		if unit then
			table.insert(self._units, unit)
		end
	end
	self._has_fetched_units = true
end

function ElementRotateUnit:client_on_executed(...)
	self:on_executed(...)
end

function ElementRotateUnit:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if not self._values.end_rot then
		BeardLib:log("[ERROR] Rotateunit must have an end rotation defined!")
		return
	end

	if #self._units == 0 and alive(instigator) then
		self:register(instigator)
	else
		for _, unit in pairs(self._units) do
			self:register(unit)
		end
	end
end

function ElementRotateUnit:register(unit)
	if self._values.remember_unit_rot then
		unit:unit_data().orig_rot = unit:unit_data().orig_rot or mrotation.copy(unit:rotation())
	end

	local start_rot = self._values.use_unit_rot and unit:unit_data().orig_rot or unit:rotation() or self._values.rotation
	local end_rot = self._values.end_rot
	--[[
	broken :/
	if not end_rot and self._values.offset then
		end_rot = mrotation.copy(start_rot)
		mrotation.multiply(end_rot, self._values.offset)
		end_rot = end_rot:inverse()
	end
	]]
	managers.game_play_central:add_rotate_unit(unit, start_rot, end_rot, self._values.speed, ClassClbk(self, "done_callback", unit))
end

function ElementRotateUnit:done_callback(instigator)
	ElementRotateUnit.super.on_executed(self, instigator)
end

function ElementRotateUnit:save(data)
	data.save_me = true
	data.enabled = self._values.enabled
end

function ElementRotateUnit:load(data)
	if not self._has_fetched_units then
		self:on_script_activated()
	end
	self:set_enabled(data.enabled)
end
