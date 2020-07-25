core:import("CoreMissionScriptElement")
ElementAIGroupType = ElementAIGroupType or class(CoreMissionScriptElement.MissionScriptElement)

-- AIGroupType Element
-- Creator: Cpone

function ElementAIGroupType:init(...)
	ElementAIGroupType.super.init(self, ...)
end

local classic_get_group_type = LevelsTweakData.get_ai_group_type
function ElementAIGroupType:on_executed(instigator)
	if not self._values.ai_group_type then return end

	if self._values.ai_group_type == "default" then
		tweak_data.levels.get_ai_group_type = classic_get_group_type
	else
		-- Big brain time, override the ai group type.
		tweak_data.levels.get_ai_group_type = function(td_self)
			return self._values.ai_group_type
		end
	end

	-- Re-initting the character tweak data genuinely seems to be fast enough as well as handling any custom prefix changes overhauls might throw at us.
	tweak_data.character:init(tweak_data)

	ElementAIGroupType.super.on_executed(self, instigator)
end