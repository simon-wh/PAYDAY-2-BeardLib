core:import("CoreMissionScriptElement")
ElementVehicleSpawner = ElementVehicleSpawner or class(CoreMissionScriptElement.MissionScriptElement)
local orig_on_executed = ElementVehicleSpawner.on_executed
local unit_ids = Idstring("unit")
function ElementVehicleSpawner:on_executed(...)
	if not PackageManager:has(unit_ids, Idstring(self._vehicles[self._values.vehicle] or "")) then
		return
	end
	return orig_on_executed(self, ...)
end