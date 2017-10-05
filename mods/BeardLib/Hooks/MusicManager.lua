if not MusicManager.playlist then
	return
end

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
	if alive(self._player) then
		self._player:parent():remove(self._player)
	end
end

local orig_post = CoreMusicManager.post_event
function CoreMusicManager:post_event(name, ...)
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

local orig_stop = MusicManager.track_listen_stop
function MusicManager:track_listen_stop(...)
	local current_event = self._current_event
	local current_track = self._current_track
	orig_stop(self, ...)
	local success
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

function MusicManager:attempt_play(track, event, stop)
	if stop then
		self:stop_custom()
	end
	local source
	local start_source
	if track and track ~= self._current_custom_track then
		self._current_custom_track = nil
	end
	for _, sound in pairs(BeardLib.MusicMods) do
		if source then
			break
		end
		if sound.id == track or sound.id == event then
			if self._current_custom_track ~= sound.id or sound.id == event then
				source = sound.source
				self._current_custom_track = sound.id
			else
				BeardLib:log("[Music] Attempting to play a track that is already playing?")
			end
		end
		if event and self._current_custom_track == sound.id then
			for k,v in pairs(sound) do
				local short_event = string.split(event, "_")[3]
				if type(v) == "table" and v._meta == "event" and v.name == short_event then
					start_source = type(v.start_source) == "string" and DB:has(Idstring("movie"), v.start_source) and v.start_source
					source = v.source
				end
			end
		end
	end
	if source then
		if DB:has(Idstring("movie"), source) and managers.menu_component._main_panel then
			self._switch_at_end = start_source and source
			self:play(start_source or source)
		else
			BeardLib:log("[ERROR] Trying to play from unloaded source '%s'", tostring(source))
		end
	else
		BeardLib:log("Could not find any source for track %s and event %s current custom track is %s", tostring(track), tostring(event), tostring(self._current_custom_track))
	end
	return source ~= nil
end

function MusicManager:play(src)
	self:stop_custom()
	Global.music_manager.source:post_event("stop_all_music")
    self._player = managers.menu_component._main_panel:video({
        name = "music",
        video = src,
        visible = false,
        loop = not self._switch_at_end,
    })
 	self._player:set_volume_gain(Global.music_manager.volume)
end

--Hooks
Hooks:PostHook(MusicManager, "init", "BeardLibMusicManagerInit", function(self)
	for _, music in pairs(BeardLib.MusicMods) do
		if music.heist then
			table.insert(tweak_data.music.track_list, {track = music.id})
		end
		if music.menu then
			table.insert(tweak_data.music.track_menu_list, {track = music.id})
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
	if alive(self._player) then
		self._player:set_volume_gain(volume)
	end	
end)

Hooks:Add("GameSetupUpdate", "BeardLibMusicUpdate", function()
	local music = managers.music
	if music and alive(music._player) then
	 	music._player:set_volume_gain(Global.music_manager.volume)
        if music._switch_at_end and (music._player:current_frame() >= music._player:frames()) then
            music:play(music._switch_at_end)
        end
	end
end)

Hooks:Add("GameSetupPauseUpdate", "BeardLibMusicPausedUpdate", function()
	local music = managers.music
	if music and alive(music._player) then
	 	music._player:set_volume_gain(0)
		music._player:goto_frame(music._player:current_frame()) --Force because the pause function is kinda broken :/
	end
end)