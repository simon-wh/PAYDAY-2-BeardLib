core:import("CoreMissionScriptElement")
--Checks if the unit is loaded to avoid a crash
ElementInteraction = ElementInteraction or class(CoreMissionScriptElement.MissionScriptElement)
local orig_init = ElementInteraction.init
function ElementInteraction:init(...)
	if not PackageManager:has(Idstring("unit"), Idstring("units/dev_tools/mission_elements/point_interaction/interaction_dummy")) then
		return ElementInteraction.super.init(self, ...)
	end
	return orig_init(self, ...)
end