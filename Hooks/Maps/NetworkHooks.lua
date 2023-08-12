-- Contains a bunch of hooks to make custom heists work. Mostly networking code.
-- Anything >100 lines of code should be its own file.

local F = table.remove(RequiredScript:split("/"))
local SyncUtils = BeardLib.Utils.Sync
local SyncConsts = BeardLib.Constants.Sync

if F == "crimenetmanager" then
	local orig = CrimeNetGui.check_job_pressed
	function CrimeNetGui:check_job_pressed(x,y, ...)
		for _, job in pairs(self._jobs) do
			if job.mouse_over == 1 and job.update_data then
				self:disable_crimenet()
				BeardLib.Utils.Sync:DownloadMap(job.level_name, job.job_key, job.update_data, function(success)
					self:enable_crimenet()
					self._grabbed_map = false
				end)
				return false
			end
		end
		return orig(self, x,y, ...)
	end

	function CrimeNetGui:change_to_custom_job_gui(job)
		local x = 0
		local num_stars = 0
		local panel = job.side_panel
		local job_name = panel:child("job_name")
		panel:child("contact_name"):set_text(" ")
		panel:child("contact_name"):set_size(0,0)
		panel:child("heat_name"):set_alpha(0)
		if alive(panel) and alive(job_name) then
			job_name:set_text(managers.localization:to_upper_text("custom_map_title", {map = tostring(job.level_name)}))
			self:make_fine_text(job_name)
			job_name:set_x(0)
		end
		local info_name = panel:child("info_name")
		if alive(panel) and alive(info_name) then
			local state = job.state_name or managers.localization:to_upper_text("menu_lobby_server_state_in_lobby")
			info_name:set_text(managers.localization:to_upper_text("custom_map_download_available") .. (state and " / " .. tostring(state) or ""))
			self:make_fine_text(info_name)
			if job.mouse_over ~= 1 then
				info_name:set_righttop(0, job_name:bottom() - 3)
			end
		end
		local difficulty_stars = job.difficulty_id - 2
		local num_difficulties = Global.SKIP_OVERKILL_290 and 5 or 6
		for i = 1, num_difficulties do
			local stars_panel = panel:child("stars_panel")
			stars_panel:clear()
			stars_panel:bitmap({
				texture = "guis/textures/pd2/cn_miniskull",
				x = x,
				w = 12,
				h = 16,
				texture_rect = {0,0,12,16},
				alpha = i > difficulty_stars and 0.5 or 1,
				blend_mode = i > difficulty_stars and "normal" or "add",
				layer = 0,
				color = i > difficulty_stars and Color.black or tweak_data.screen_colors.risk
			})
			stars_panel:set_w(16 * math.min(11, #stars_panel:children()))
			stars_panel:set_h(16)
			x = x + 11
			num_stars = num_stars + 1
		end
		local difficulty_string = managers.localization:to_upper_text(tweak_data.difficulty_name_ids[tweak_data.difficulties[job.difficulty_id]])
		local difficulty_name = panel:child("difficulty_name")
		difficulty_name:set_text(difficulty_string)
		difficulty_name:set_color(difficulty_stars > 0 and tweak_data.screen_colors.risk or tweak_data.screen_colors.text)
		self:make_fine_text(difficulty_name)
		if job.mouse_over ~= 1 then
			difficulty_name:set_righttop(0, info_name:bottom() - 3)
		end
	end
----------------------------------------------------------------
----------------------------------------------------------------
elseif F == "networkpeer" then
	local peer_send_hook = "NetworkPeerSend"
	Hooks:Register(peer_send_hook)

	Hooks:Add(peer_send_hook, "BeardLibCustomHeistFix", function(self, func_name, params)
		if self ~= managers.network:session():local_peer() and SyncUtils:IsCurrentJobCustom() then
			if func_name == "sync_game_settings" or func_name == "sync_lobby_data" then
				SyncUtils:Send(self, SyncConsts.GameSettings, SyncUtils:GetJobString())
			elseif func_name == "lobby_sync_update_level_id" then
				SyncUtils:Send(self, SyncConsts.LobbyLevelId, Global.game_settings.level_id)
			elseif func_name == "sync_stage_settings" then
				local glbl = managers.job._global
				local msg = string.format("%s|%s|%s|%s", Global.game_settings.level_id, tostring(glbl.current_job.current_stage), tostring(glbl.alternative_stage or 0), tostring(glbl.interupt_stage))
				SyncUtils:Send(self, SyncConsts.StageSettings, msg)
			elseif string.ends(func_name,"join_request_reply") then
				if params[1] == 1 then
					params[15] = SyncUtils:GetJobString()
				end
			end
		end
	end)

	Hooks:Add("NetworkReceivedData", SyncConsts.LobbyLevelId, function(sender, id, data)
		if id == SyncConsts.LobbyLevelId then
			local peer = managers.network:session():peer(sender)
			local rpc = peer and peer:rpc()
			if rpc then
				managers.network._handlers.connection:lobby_sync_update_level_id_ignore_once(data)
			end
		end
	end)

	Hooks:Add("NetworkReceivedData", SyncConsts.GameSettings, function(sender, id, data)
		if id == SyncConsts.GameSettings then
			local split_data = string.split(data, "|")
			local level_name = split_data[4]
			local job_id = split_data[1]
			local update_data = BeardLib.Utils.Sync:GetUpdateData(split_data)
			local session = managers.network:session()
			local function continue_sync()
				local peer = session:peer(sender)
				local rpc = peer and peer:rpc()
				if rpc then
					local job_index = tweak_data.narrative:get_index_from_job_id(job_id)
					local level_index = tweak_data.levels:get_index_from_level_id(split_data[2])
					local difficulty_index = tweak_data:difficulty_to_index(split_data[3])
					managers.network._handlers.connection:sync_game_settings(job_index, level_index, difficulty_index, Global.game_settings.one_down, Global.game_settings.weekly_skirmish, rpc)
				end
			end
			local function disconnect()
				if managers.network:session() then
					managers.network:queue_stop_network()
					managers.platform:set_presence("Idle")
					managers.network.matchmake:leave_game()
					managers.network.voice_chat:destroy_voice(true)
					managers.menu:exit_online_menues()
				end
			end
			if tweak_data.narrative.jobs[job_id] == nil then
				if update_data then
					session._ignore_load = true
					BeardLib.Utils.Sync:DownloadMap(level_name, job_id, update_data, function(success)
						if success then
							continue_sync()
							session._ignore_load = nil
							if session._ignored_load then
								session:ok_to_load_level(unpack(session._ignored_load))
							end
						else
							disconnect()
						end
					end)
				else
					disconnect()
					BeardLib.Managers.Dialog:Simple():Show({title = managers.localization:text("mod_assets_error"), message = managers.localization:text("custom_map_cant_download"), force = true})
					return
				end
			end
			continue_sync()
		end
	end)

	Hooks:Add("NetworkReceivedData", SyncConsts.StageSettings, function(sender, id, data)
		if id == SyncConsts.StageSettings then
			local split_data = string.split(data, "|")
			local peer = managers.network:session():peer(sender)
			local rpc = peer and peer:rpc()
			if rpc then
				managers.network._handlers.connection:sync_stage_settings_ignore_once(tweak_data.levels:get_index_from_level_id(split_data[1]),
				tonumber(split_data[2]),
				tonumber(split_data[3]),
				tweak_data.levels:get_index_from_level_id(split_data[4]) or 0,
				rpc)
			else
				log("[ERROR] RPC is nil!")
			end
		end
	end)
----------------------------------------------------------------
elseif F == "clientnetworksession" then
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
----------------------------------------------------------------
elseif F == "connectionnetworkhandler" then
    --Fixes level id being set wrong with custom maps
    function ConnectionNetworkHandler:sync_stage_settings_ignore_once(...)
        self:sync_stage_settings(...)
        self._ignore_stage_settings_once = true
    end

    local orig_sync_stage_settings = ConnectionNetworkHandler.sync_stage_settings
    function ConnectionNetworkHandler:sync_stage_settings(level_id_index, ...)
        if self._ignore_stage_settings_once then
            self._ignore_stage_settings_once = nil
            return
        end
        return orig_sync_stage_settings(self, level_id_index, ...)
    end

    function ConnectionNetworkHandler:lobby_sync_update_level_id_ignore_once(...)
        self:lobby_sync_update_level_id(...)
        self._ignore_update_level_id_once = true
    end

    local orig_lobby_sync_update_level_id = ConnectionNetworkHandler.lobby_sync_update_level_id
    function ConnectionNetworkHandler:lobby_sync_update_level_id(level_id_index, ...)
        if self._ignore_update_level_id_once then
            self._ignore_update_level_id_once = nil
            return
        end
        return orig_lobby_sync_update_level_id(self, level_id_index, ...)
    end
----------------------------------------------------------------
elseif F == "platformmanager" then
    core:module("PlatformManager")
    -- Fixes rich presence to work with custom heists by forcing raw status.
    Hooks:PostHook(WinPlatformManager, "set_rich_presence", "FixCustomHeistStatus", function(self)
        if not Global.game_settings.single_player and Global.game_settings.permission ~= "private" and self._current_presence ~= "Idle" and managers.network and managers.network.matchmake.lobby_handler  then
            local job = managers.job:current_job_data()
            if job and job.custom and Steam then
                Steam:set_rich_presence("steam_display", "#raw_status")
            end
        end
    end)
elseif F == "menumanager" then
	local orig_MenuCallbackHandler_start_job = MenuCallbackHandler.start_job
	local sync_game_settings_id = "BeardLib_sync_game_settings"

	function MenuCallbackHandler:start_job(job_data)
		if not managers.job:activate_job(job_data.job_id) then
			return
		end

		if managers.job:current_level_data().custom or managers.job:current_job_data().custom then
			Global.game_settings.level_id = managers.job:current_level_id()
			Global.game_settings.mission = managers.job:current_mission()
			Global.game_settings.world_setting = managers.job:current_world_setting()
			Global.game_settings.difficulty = job_data.difficulty
			Global.game_settings.one_down = job_data.one_down
			local matchmake_attributes = self:get_matchmake_attributes()
			if Network:is_server() then
				SyncUtils:SyncGameSettings()
				managers.network.matchmake:set_server_attributes(matchmake_attributes)
				managers.menu_component:on_job_updated()
				managers.menu:active_menu().logic:navigate_back(true)
				managers.menu:active_menu().logic:refresh_node("lobby", true)
			else
				managers.network.matchmake:create_lobby(matchmake_attributes)
			end
		else
			orig_MenuCallbackHandler_start_job(self, job_data)
		end
	end

	Hooks:Add("NetworkReceivedData", sync_game_settings_id, function(sender, id, data)
		if id == sync_game_settings_id then
			local split_data = string.split(data, "|")

			managers.network._handlers.connection:sync_game_settings(tweak_data.narrative:get_index_from_job_id(split_data[1]),
			tweak_data.levels:get_index_from_level_id(split_data[2]),
			tweak_data:difficulty_to_index(split_data[3]),
			Global.game_settings.one_down,
			managers.network:session():peer(sender):rpc())
		end
	end)

	Hooks:Add("BaseNetworkSessionOnPeerEnteredLobby", "BaseNetworkSessionOnPeerEnteredLobby_sync_game_settings", function(peer, peer_id)
		SyncUtils:SyncGameSettings(peer_id)
	end)

	Hooks:Add("NetworkManagerOnPeerAdded", "NetworkManagerOnPeerAdded_sync_game_settings", function(peer, peer_id)
		SyncUtils:SyncGameSettings(peer_id)
	end)
----------------------------------------------------------------
end