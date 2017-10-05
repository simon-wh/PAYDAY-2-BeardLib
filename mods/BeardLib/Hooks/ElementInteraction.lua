core:import("CoreMissionScriptElement")
--Checks if the unit is loaded to avoid a crash
ElementInteraction = ElementInteraction or class(CoreMissionScriptElement.MissionScriptElement)
local orig_init = ElementInteraction.init
local unit_ids = Idstring("unit")
local norm_ids = Idstring("units/dev_tools/mission_elements/point_interaction/interaction_dummy")
local nosync_ids = Idstring("units/dev_tools/mission_elements/point_interaction/interaction_dummy_nosync")
function ElementInteraction:init(...)
	if not PackageManager:has(unit_ids, norm_ids) or not PackageManager:has(unit_ids, nosync_ids) then
		return ElementInteraction.super.init(self, ...)
	end
	return orig_init(self, ...)
end