Hooks:PreHook(ClientNetworkSession, "on_join_request_reply", "BeardLib_on_join_request_reply_fix_levels", function(self, reply, my_peer_id, my_character, level_index, difficulty_index, state_index, server_character, user_id, mission, job_id_index, job_stage, alternative_job_stage, interupt_job_stage_level_index, xuid, auth_ticket, sender)
    if reply == 1 then
        local cb = self._cb_find_game
        self._cb_find_game = function(state, ...)
            if (state == "JOINED_LOBBY" or state == "JOINED_GAME") and string.find(xuid, "|") then
                local split_data = string.split(xuid, "|")
                Global.game_settings.level_id = split_data[2]
        		Global.game_settings.difficulty = split_data[3]
                if job_id_index ~= 0 then
        			managers.job:activate_job(split_data[1], job_stage)
        			if alternative_job_stage ~= 0 then
        				managers.job:synced_alternative_stage(alternative_job_stage)
        			end
        			if interupt_job_stage_level_index ~= 0 then
        				local interupt_level = tweak_data.levels:get_level_name_from_index(interupt_job_stage_level_index)
        				managers.job:synced_interupt_stage(interupt_level)
        			end
        			Global.game_settings.world_setting = managers.job:current_world_setting()
        			self._server_peer:verify_job(job_id)
                end
            end
            if cb then
                cb(state, ...)
            else
                log("no cb")
            end
        end
    end
end)
