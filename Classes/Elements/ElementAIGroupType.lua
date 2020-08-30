core:import("CoreMissionScriptElement")
ElementAIGroupType = ElementAIGroupType or class(CoreMissionScriptElement.MissionScriptElement)

-- AIGroupType Element
-- Creator: Cpone

function ElementAIGroupType:init(...)
	ElementAIGroupType.super.init(self, ...)
end

ElementAIGroupType.difficulty_function_map = {
	easy = "_set_easy",
	normal = "_set_normal",
	hard = "_set_hard",
	overkill = "_set_overkill",
	overkill_145 = "_set_overkill_145",
	easy_wish = "_set_easy_wish",
	overkill_290 = "_set_overkill_290",
	sm_wish = "_set_sm_wish",
}

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

	local difficulty = Global.game_settings and Global.game_settings.difficulty
	if difficulty then
		local function_name = self.difficulty_function_map[difficulty]

		tweak_data.character[function_name](tweak_data.character)
	end

	ElementAIGroupType.super.on_executed(self, instigator)
end