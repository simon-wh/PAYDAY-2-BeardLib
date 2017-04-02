NarrativeModule = NarrativeModule or class(ItemModuleBase)

NarrativeModule.type_name = "narrative"
NarrativeModule._loose = true

function NarrativeModule:init(core_mod, config)
    self.clean_table = table.add(clone(self.clean_table), {
        {
            param = "chain",
            action = {"number_indexes", "remove_metas"}
        },        
        {
            param = "chain",
            shallow = true,
            action = "children_no_number_indexes"
        },        
        {
            param = "crimenet_callouts",
            action = "number_indexes"
        },
        {
            param = "crimenet_videos",
            action = "number_indexes"
        },
        {
            param = "payout",
            action = "number_indexes"
        },
        {
            param = "contract_cost",
            action = "number_indexes"
        },
        {
            param = "experience_mul",
            action = "number_indexes"
        },
        {
            param = "min_mission_xp",
            action = "number_indexes"
        },
        {
            param = "max_mission_xp",
            action = "number_indexes"
        },
        {
            param = "allowed_gamemodes",
            action = "number_indexes"
        }
    })
    if not self.super.init(self, core_mod, config) then
        return false
    end

    return true
end

function NarrativeModule:RegisterHook()
    Hooks:PostHook(NarrativeTweakData, "init", self._config.id .. "AddNarrativeData", function(narr_self)
        local data = {
            name_id = self._config.name_id or "heist_" .. self._config.id .. "_name",
            briefing_id = self._config.brief_id or "heist_" .. self._config.id .. "_brief",
            contact = self._config.contact or "bain",
            jc = self._config.jc or 50,
            chain = self._config.chain,
            dlc = self._config.dlc,
            briefing_event = self._config.briefing_event,
            debrief_event = self._config.debrief_event,
            crimenet_callouts = self._config.crimenet_callouts,
            crimenet_videos = self._config.crimenet_videos,
            payout = self._config.payout or {0.001,0.001,0.001,0.001,0.001},
            contract_cost = self._config.contract_cost or {0.001,0.001,0.001,0.001,0.001},
            experience_mul = self._config.experience_mul or {0.001,0.001,0.001,0.001,0.001},
            contract_visuals = {
                min_mission_xp = self._config.min_mission_xp or {0.001,0.001,0.001,0.001,0.001},
                max_mission_xp = self._config.max_mission_xp or {0.001,0.001,0.001,0.001,0.001}
            },
            allowed_gamemodes = self._config.allowed_gamemodes,
            custom = true
        }
        if self._config.merge_data then
            table.merge(data, BeardLib.Utils:RemoveMetas(self._config.merge_data, true))
        end
        narr_self.jobs[self._config.id] = data
        table.insert(narr_self._jobs_index, self._config.id)
    end)
end

BeardLib:RegisterModule(NarrativeModule.type_name, NarrativeModule)
