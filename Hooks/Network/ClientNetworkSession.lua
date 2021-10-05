local FAILED_CONNECT = 0

local orig_join_request_reply = ClientNetworkSession.on_join_request_reply
--- This handles 1 of 3 places in which custom maps are downloaded from (via the ingame downloader)
--- When the heist is a vanilla heist, it falls back to the original function without attempting to do anything
--- When the map is already downloaded, this function only corrects the indices based on the IDs that are sent by the xuid parameter.
function ClientNetworkSession:on_join_request_reply(
    reply, my_peer_id, my_character, level_index,
    difficulty_index, one_down, state_index, server_character, user_id,
    mission, job_id_index, job_stage, alternative_job_stage,
    interupt_job_stage_level_index, xuid, ...)

    local params = table.pack(...)

    local function orig(override_reply)
        orig_join_request_reply(self, override_reply or reply, my_peer_id, my_character, level_index,
        difficulty_index, one_down, state_index, server_character, user_id,
        mission, job_id_index, job_stage, alternative_job_stage,
        interupt_job_stage_level_index, xuid, unpack(params, 1, params.n))
    end

    if reply == 1 and string.find(xuid, "|") then
        local split_data = string.split(xuid, "|")
        local job_id, level_id, difficulty, level_name = unpack(split_data)

        local function fix_clbk(success, cancelled)
            if not success then
                if not cancelled then
                    QuickMenuPlus:new(managers.localization:text("mod_assets_error"), managers.localization:text("custom_map_failed"))
                end
                return orig(FAILED_CONNECT)
            end

            job_id_index = tweak_data.narrative:get_index_from_job_id(job_id)
            level_index = tweak_data.levels:get_index_from_level_id(level_id)
            difficulty_index = tweak_data:difficulty_to_index(difficulty)
            if self._ignored_load then
                orig()
                self:ok_to_load_level(unpack(self._ignored_load, 1, self._ignored_load.n))
            end
        end
        local job = tweak_data.narrative.jobs[job_id]
        if job then
            if job.custom then --Run this only with custom maps
                fix_clbk(true)
            end
        else
            local update_data = BeardLib.Utils.Sync:GetUpdateData(split_data)
            if level_name and update_data then
                self._ignore_load = true
                self._last_join_request_t = nil -- Avoid time out
                BeardLib.Utils.Sync:DownloadMap(level_name, job_id, update_data, fix_clbk)
                return
            elseif not level_name then
                QuickMenuPlus:new(managers.localization:text("mod_assets_error"), managers.localization:text("custom_map_host_old_version"))
                return orig(FAILED_CONNECT)
            else
                QuickMenuPlus:new(managers.localization:text("mod_assets_error"), managers.localization:text("custom_map_missing_updater"))
                return orig(FAILED_CONNECT)
            end
        end
    end
    return orig()
end

local orig_load_level = ClientNetworkSession.ok_to_load_level
--- When downloading, we need to actually avoid loading the level as it's called from somewhere else
--- After we finish downloading we call fix_clbk and there we call this function again and pass unpacked self._ignored_load
--- to it and thsi way be able to load the custom hesit that has been just downloaded. 
function ClientNetworkSession:ok_to_load_level(...)
    if self._ignore_load then
        self._ignored_load = table.pack(...)
        self._ignore_load = nil
    else
        self._ignored_load = nil
        orig_load_level(self, ...)
    end
end