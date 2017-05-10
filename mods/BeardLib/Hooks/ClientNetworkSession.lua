Hooks:PreHook(ClientNetworkSession, "on_join_request_reply", "BeardLib_on_join_request_reply_fix_levels", function(self, reply, my_peer_id, my_character, level_index, difficulty_index, state_index, server_character, user_id, mission, job_id_index, job_stage, alternative_job_stage, interupt_job_stage_level_index, xuid, auth_ticket, sender)
    if reply == 1 then
        local cb = self._cb_find_game
        self._cb_find_game = function(state, ...)
            local function orig_cb(state, ...)
                if cb then
                    cb(state, ...)
                else
                    log("no cb")
                end
            end
            if (state == "JOINED_LOBBY" or state == "JOINED_GAME") and string.find(xuid, "|") then
                local split_data = string.split(xuid, "|")
                local function continue_load(params, success)
                    if not success then
                        orig_cb("CANCELLED")
                        return
                    end
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
                    orig_cb(state, unpack(params))
                    self._ignore_load = nil
                    if self._ignored_load then
                        self:ok_to_load_level(unpack(self._ignored_load))
                        self._ignored_load = nil
                    end
                end
                if tweak_data.levels[split_data[2]] then
                    continue_load({...}, true)
                else
                    local update_key = tonumber(split_data[5])
                    local level_name = split_data[4]
                    if level_name and update_key then
                        self._ignore_load = true
                        BeardLib:DownloadMap(level_name, update_key, SimpleClbk(continue_load, {...}))
                    elseif not level_name then
                        QuickMenuPlus:new(managers.localization:text("mod_assets_error"), managers.localization:text("custom_map_host_old_version"))
                        orig_cb("CANCELLED")
                        return
                    else
                        QuickMenuPlus:new(managers.localization:text("mod_assets_error"), managers.localization:text("custom_map_missing_updater"))
                        orig_cb("CANCELLED")
                        return
                    end
                end
            end
        end
    end
end)

local orig_load_level = ClientNetworkSession.ok_to_load_level
function ClientNetworkSession:ok_to_load_level(...)
    if self._ignore_load then
        self._ignored_load = {...}
    else
        orig_load_level(self, ...)
    end
end