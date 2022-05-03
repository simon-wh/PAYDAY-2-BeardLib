if not MusicManager.playlist then
	return
end

BeardLib.Managers.Sound:CreateSourceHook("BeardLibCustomMenuTrackFix", function(name, source)
	if name == "HUDLootScreen" or name == "cleanup" then
		source:pre_hook("FixCustomTrack", function(event)
			managers.music:attempt_play(nil, event)
		end)
	end
end)

function MusicManager:check_playlist(is_menu)
    local playlist = is_menu and self:playlist_menu() or self:playlist()
    local tracklist = is_menu and tweak_data.music.track_menu_list or tweak_data.music.track_list
    for i, track in pairs(playlist) do
        local exists
        for _, v in pairs(tracklist) do
            if v.track == track then
                exists = true
            end
        end
        if not exists then
            playlist[i] = nil
            managers.savefile:setting_changed()
        end
    end
    if not is_menu then
        self:check_playlist(true)
    end
end

function MusicManager:stop_custom()
	local source = self._xa_source
	self._xa_source = nil
	if source then
		source:close()
	end
	if alive(self._player) then
		self._player:parent():remove(self._player)
	end
end

local orig_post = MusicManager.post_event
function MusicManager:post_event(name, ...)
	if name and Global.music_manager.current_event ~= name then
		if not self._skip_play then
			if not self:attempt_play(nil, name, true) then
				return orig_post(self, name, ...)
			end
		end
		Global.music_manager.current_event = name
	end
end

local orig_check = MusicManager.check_music_switch
function MusicManager:check_music_switch(...)
	local switches = tweak_data.levels:get_music_switches()
	if switches and #switches > 0 then
		Global.music_manager.current_track = switches[math.random(#switches)]
		if not self:attempt_play(Global.music_manager.current_track) then
			return orig_check(self, ...)
		end
	end
end

local orig_stop_all = MusicManager.stop_listen_all
function MusicManager:stop_listen_all(...)
	if self._current_music_ext or self._current_event then
		self:stop_custom()
	end

	local success = false
	if self._current_music_ext and Global.music_manager.current_music_ext then
		if self:attempt_play(Global.music_manager.current_music_ext) then
			success = true
		end
	end

	if self._current_event and Global.music_manager.current_event then
		if self:attempt_play(nil, Global.music_manager.current_event) then
			success = true
		end
	end

	if self._current_track and Global.music_manager.current_track then
		if success then
			self:attempt_play(Global.music_manager.current_track)
		end
	end

	-- If we succeed avoid calling the original function, just stop the tracks
	if success then
		Global.music_manager.source:post_event("stop_all_music")
		self._current_event = nil
		self._current_track = nil
		self._skip_play = nil	
	else
		return orig_stop_all(self, ...)
	end
end

local orig_stop = MusicManager.track_listen_stop
function MusicManager:track_listen_stop(...)
	local current_event = self._current_event
	local current_track = self._current_track
	orig_stop(self, ...)
	local success = false
	if current_event then
		self:stop_custom()
		if Global.music_manager.current_event then
			if self:attempt_play(nil, Global.music_manager.current_event) then
				success = true
			end
		end
	end
	if current_track and Global.music_manager.current_track then
		if self:attempt_play(Global.music_manager.current_track) then
			success = true
		end
	end
	if success then
		Global.music_manager.source:stop()
	end
end

function MusicManager:pick_track_index(tracks)
	if not tracks or #tracks <= 1 then
		return 1
	end
	local total_w = 0
	for _,v in pairs(tracks) do
		total_w = total_w + (v.weight or 1)
	end
	local roll = math.random(total_w)
	local index = 0
	while roll > 0 do
		index = index + 1
		roll = roll - (tracks[index].weight or 1)
	end
	return index
end

local movie_ids = Idstring("movie")
function MusicManager:attempt_play(track, event, stop)
	if event == "music_uno_fade_reset" then
		return
	end
	if stop then
		self:stop_custom()
	end
	local next_music
	local next_event
	if track and track ~= self._current_custom_track then
		self._current_custom_track = nil
	end
	for id, music in pairs(BeardLib.MusicMods) do
		if next_music then
			break
		end
		if event == id or track == id or self._current_custom_track == id then
			if music.tracks and (self._current_custom_track ~= id or id == event) then
				next_music = music
				self._current_custom_track = id
			end
			if music.events and event then
				-- Try finding the right event to play
				for modded_event, event_tbl in pairs(music.events) do
					if event == modded_event or event:ends(modded_event) then
						next_music = music
						next_event = event_tbl
						self._current_custom_track = id
					end
				end
			end
		end
	end
	if next_music then
		local next = next_event or next_music
		local track_index = self:pick_track_index(next.tracks)
		local next_track = next.tracks and next.tracks[track_index]
		local source = next_track and (next_track.start_source or next_track.source)
		if next_music.xaudio then
			if not source then
				BeardLib:Err("No buffer found to play for music '%s'", tostring(self._current_custom_track))
				return
			end
		else
			if not source or not DB:has(movie_ids, source:id()) then
				BeardLib:Err("Source file '%s' is not loaded, music id '%s'", tostring(source), tostring(self._current_custom_track))
				return true
			end
		end
		local volume = next_track.volume or next.volume or next_music.volume
		self._switch_at_end = (next_track.start_source or next.allow_switch) and {
			tracks = next.tracks,
			track_index = next_track.start_source and track_index or self:pick_track_index(next.tracks),
			allow_switch = next.allow_switch,
			xaudio = next_music.xaudio,
			volume = volume
		}
		self:play(source, next_music.xaudio, volume)
		return true
	end
	return next_music ~= nil
end

function MusicManager:play(src, use_xaudio, custom_volume)
	self:stop_custom()
	Global.music_manager.source:post_event("stop_all_music")
	--Uncomment if unloading is ever needed
	--[[if type(src) == "table" and src.module and self._last_module and self._last_module ~= src.module then
		self._last_buffer.module:UnloadBuffers()
	end]]
	if use_xaudio then
		if XAudio then
			if type(src) == "table" and src.module then
				if not src.buffer then
					src.module:LoadBuffers()
				end
				if not src.buffer then
					BeardLib:log("Something went wrong while trying to play the source")
					return
				end
				src = src.buffer
				self._last_module = src.module
			else
				self._last_module = nil
			end
			self._xa_volume = custom_volume or 1
			self._xa_source = XAudio.Source:new(src)
			self._xa_source:set_type("music")
			self._xa_source:set_relative(true)
			self._xa_source:set_looping(not self._switch_at_end)
			self._xa_source:set_volume(self._xa_volume * self._volume_mul)
		else
			BeardLib:log("XAudio was not found, cannot play music.")
		end
	elseif managers.menu_component._main_panel then
		self._player = managers.menu_component._main_panel:video({
			name = "music",
			video = src,
			visible = false,
			loop = not self._switch_at_end,
		})
		self._player_volume = custom_volume or 1
		self._player:set_volume_gain(self._player_volume * Global.music_manager.volume * self._volume_mul)
	end
end

function MusicManager:volume_multiplier(id)
	return self._volume_mul_data[id] and self._volume_mul_data[id].current or 1
end

function MusicManager:set_volume_multiplier(id, volume, fade)
	local current = (not fade or fade <= 0) and volume or self._volume_mul_data[id] and self._volume_mul_data[id].current or 1
	self._volume_mul_data[id] = {
		current = current,
		a = current,
		b = volume,
		fade = fade or 0,
		t = TimerManager:game():time()
	}
end

function MusicManager:custom_update(t, dt, paused)
	if not paused then
		self._volume_mul = 1
		for id, volume_data in pairs(self._volume_mul_data) do
			if not volume_data.done then
				local lerp_t = volume_data.fade > 0 and math.clamp((t - volume_data.t) / volume_data.fade, 0, 1) or 1
				volume_data.current = math.clamp(math.lerp(volume_data.a, volume_data.b, lerp_t), 0, 1)
				if lerp_t >= 1 then
					if volume_data.b == 1 then
						self._volume_mul_data[id] = nil
					else
						volume_data.done = true
					end
				end
			end
			self._volume_mul = self._volume_mul * volume_data.current
		end
	end

	local gui_ply = alive(self._player) and self._player or nil
	if gui_ply then
		gui_ply:set_volume_gain(self._player_volume * Global.music_manager.volume * self._volume_mul)
	elseif self._xa_source then
		self._xa_source:set_volume(self._xa_volume * self._volume_mul)
	end

	if paused then
		--xaudio already pauses itself.
		if gui_ply then
			gui_ply:set_volume_gain(0)
			gui_ply:goto_frame(gui_ply:current_frame()) --Force because the pause function is kinda broken :/
		end
	elseif self._switch_at_end then
		if (self._xa_source and self._xa_source:is_closed()) or (gui_ply and gui_ply:current_frame() >= gui_ply:frames()) then
			local switch = self._switch_at_end
			local source = switch.tracks[switch.track_index].source
			local volume = switch.tracks[switch.track_index].volume or switch.volume
			if switch.allow_switch then
				switch.track_index = self:pick_track_index(switch.tracks)
				switch.volume = volume
			else
				self._switch_at_end = nil
			end
			self:play(source, switch.xaudio, volume)
		end
	end
end

--Hooks
Hooks:PostHook(MusicManager, "init", "BeardLibMusicManagerInit", function(self)
	self._volume_mul = 1
	self._volume_mul_data = {}

	self._player_volume = 1
	self._xa_volume = 1

	for id, music in pairs(BeardLib.MusicMods) do
		if music.heist then
			table.insert(tweak_data.music.track_list, {track = id})
		end
		if music.menu then
			table.insert(tweak_data.music.track_menu_list, {track = id})
		end
		if music.stealth then
			table.insert(tweak_data.music.track_ghost_list, {track = id})
		end
	end
end)

Hooks:PostHook(MusicManager, "load_settings", "BeardLibMusicManagerLoadSettings", function(self)
	self:check_playlist()
end)

Hooks:PostHook(MusicManager, "track_listen_start", "BeardLibMusicManagerTrackListenStart", function(self, event, track)
	self:stop_custom()
	local success
	if track and self:attempt_play(track) then
		success = true
	end
	if self:attempt_play(nil, event) then
		success = true
	end
	if success then
		Global.music_manager.source:stop()
	end
end)

Hooks:PostHook(MusicManager, "set_volume", "BeardLibMusicManagerSetVolume", function(self, volume)
	--xaudio sets its own volume
	if alive(self._player) then
		self._player:set_volume_gain(self._player_volume * volume * self._volume_mul)
	end
end)

Hooks:Add("MenuUpdate", "BeardLibMusicMenuUpdate", function(t, dt)
	if managers.music then
		managers.music:custom_update(t, dt)
	end
end)

Hooks:Add("GameSetupUpdate", "BeardLibMusicUpdate", function(t, dt)
	if managers.music then
		managers.music:custom_update(t, dt)
	end
end)

Hooks:Add("GameSetupPauseUpdate", "BeardLibMusicPausedUpdate", function(t, dt)
	if managers.music then
		managers.music:custom_update(t, dt, true)
	end
end)
