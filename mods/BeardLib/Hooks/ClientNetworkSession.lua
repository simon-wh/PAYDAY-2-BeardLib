--Why so many parameters aaa
Hooks:PreHook(ClientNetworkSession, "on_join_request_reply", "BeardLib_on_join_request_reply_fix_levels", function(self, r, pid, char, lix, dix, od, si, sc, uid, ms, jix, js, alt_js, int_js, xuid, at, s)
    if r == 1 then
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
                        QuickMenuPlus:new(managers.localization:text("mod_assets_error"), managers.localization:text("custom_map_failed"))
                        orig_cb("CANCELLED")
                        return
                    end
                    if jix ~= 0 then
                        managers.job:activate_job(split_data[1], js)
                        if alt_js ~= 0 then
                            managers.job:synced_alternative_stage(alt_js)
                        end
                        if int_js ~= 0 then
                            local interupt_level = tweak_data.levels:get_level_name_from_index(int_js)
                            managers.job:synced_interupt_stage(interupt_level)
                        end
                        Global.game_settings.world_setting = managers.job:current_world_setting()
                        self._server_peer:verify_job(job_id)
                    end
                    orig_cb(state, unpack(params))
                    Global.game_settings.level_id = split_data[2]
                    Global.game_settings.difficulty = split_data[3]
                    self._ignore_load = nil
                    if self._ignored_load then
                        self:ok_to_load_level(unpack(self._ignored_load))
                    end
                end
                local level_name = split_data[4]
                local job_id = split_data[1]
                if tweak_data.narrative.jobs[job_id] then
                    continue_load({...}, true)
                else
                    local update_data = BeardLib.Utils:GetUpdateData(split_data)
                    if level_name and update_data then
                        self._ignore_load = true
                        BeardLib.Utils:DownloadMap(level_name, job_id, update_data, SimpleClbk(continue_load, {...}))
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
			else
				orig_cb(state, ...)
            end
        end
    end
end)

local orig_load_level = ClientNetworkSession.ok_to_load_level
function ClientNetworkSession:ok_to_load_level(...)
    if self._ignore_load then
        self._ignored_load = {...}
        self._ignore_load = nil
    else
        self._ignored_load = nil
        orig_load_level(self, ...)
    end
end