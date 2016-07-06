NarrativeModule = NarrativeModule or class(ModuleBase)

NarrativeModule.type_name = "narrative"
NarrativeModule._loose = true

function NarrativeModule:init(core_mod, config)
    self.super.init(self, core_mod, config)
end

function NarrativeModule:RegisterHook()
    Hooks:PostHook(NarrativeTweakData, "init", self._config.id .. "AddNarrativeData", function(narr_self)
        narr_self.jobs[self._config.id] = {
            name_id = self._config.name_id or "heist_" .. self._config.id .. "_name",
            briefing_id = self._config.brief_id or "heist_" .. self._config.id .. "_brief",
            contact = self._config.contact or "bain",
            jc = self._config.jc or 50,
            chain = {},
            briefing_event = self._config.briefing_event,
            debrief_event = self._config.debrief_event,
            crimenet_callouts = BeardLib.Utils:RemoveNonNumberIndexes(self._config.crimenet_callouts),
            crimenet_videos = BeardLib.Utils:RemoveNonNumberIndexes(self._config.crimenet_videos),
            payout = BeardLib.Utils:RemoveNonNumberIndexes(self._config.payout) or {0.001,0.001,0.001,0.001,0.001},
            contract_cost = BeardLib.Utils:RemoveNonNumberIndexes(self._config.contract_cost) or {0.001,0.001,0.001,0.001,0.001},
            experience_mul = BeardLib.Utils:RemoveNonNumberIndexes(self._config.experience_mul) or {0.001,0.001,0.001,0.001,0.001},
            contract_visuals = {
                min_mission_xp = BeardLib.Utils:RemoveNonNumberIndexes(self._config.min_mission_xp) or {0.001,0.001,0.001,0.001,0.001},
                max_mission_xp = BeardLib.Utils:RemoveNonNumberIndexes(self._config.max_mission_xp) or {0.001,0.001,0.001,0.001,0.001}
            },
            allowed_gamemodes = BeardLib.Utils:RemoveNonNumberIndexes(self._config.allowed_gamemodes),
            custom = true
        }
        if self._config.merge_data then
            table.merge(narr_self.jobs[self._config.id], self._config.merge_data)
        end
        for i, level in ipairs(self._config.chain) do
            narr_self.jobs[self._config.id].chain[i] = level
        end

        table.insert(narr_self._jobs_index, self._config.id)
    end)
end

return NarrativeModule
