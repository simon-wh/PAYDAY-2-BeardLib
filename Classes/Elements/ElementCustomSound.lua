core:import("CoreMissionScriptElement")
ElementCustomSound = ElementCustomSound or class(CoreMissionScriptElement.MissionScriptElement)


-- CustomSound Element
-- Creator: Nepgearsy

-- How it Works

-- PRIMARY CHANNEL   : 		Used for dynamic custom musics. Do not use any of the other channels to use that one.
-- SECONDARY CHANNEL :		Used for voice over lines. Cannot be interrupted by the primary or third channel. Cannot loop. The current sound playing can be overwritten by
--							an other secondary channel sound. The current line playing will just stop.
-- THIRD CHANNEL     : 		Used for background noises such as environment sound. Cannot be interrupted by the primary and secondary channel. Can be looped. Can be stacked
--							with other third channel sounds.

function ElementCustomSound:init(...)
	ElementCustomSound.super.init(self, ...)
	self._volume_based = nil
	self:_check_volume_choice()
end
function ElementCustomSound:client_on_executed(...)
	self:on_executed(...)
end

function ElementCustomSound:_check_and_create_panels()
	--Creates secondary & tertiary panels in case they don't exist yet (or have been destroyed)
	if not managers.menu_component._secondary_panel then
		managers.menu_component._secondary_panel = managers.menu_component._ws:panel():panel()
	end

	if not managers.menu_component._third_panel then
		managers.menu_component._third_panel = managers.menu_component._ws:panel():panel()
	end
end

function ElementCustomSound:_check_volume_choice()
	if self._values.volume_choice == "sfx" then
		local volume = managers.user:get_setting("sfx_volume")
		local percentage = (volume - tweak_data.menu.MIN_SFX_VOLUME) / (tweak_data.menu.MAX_SFX_VOLUME - tweak_data.menu.MIN_SFX_VOLUME)

		self._volume_based = percentage
	else
		self._volume_based = Global.music_manager.volume
	end

	--Volume overriding
	if self._values.volume_override and self._values.volume_override >= 0 then
		self._volume_based = self._volume_based * self._values.volume_override
	end

	return self._volume_based
end

function ElementCustomSound:stop_secondary()

	--Removes the secondary panel from the menu component manager
	if managers.menu_component._secondary_panel and managers.menu_component._ws then
		managers.menu_component._ws:panel():remove(managers.menu_component._secondary_panel)
		managers.menu_component._secondary_panel = nil
	end
end

function ElementCustomSound:play(src)
	managers.music:stop_custom()
	Global.music_manager.source:post_event("stop_all_music")
	managers.music._player = managers.menu_component._main_panel:video({
		name = "music",
		video = src,
		visible = false,
		loop = self._values.loop or false
	})
	managers.music._player:set_volume_gain(self:_check_volume_choice())
end

function ElementCustomSound:play_secondary(src)
	--Removes the secondary panel, terminating all video files contained in it automatically
	if self._values.override_others then
		self:stop_secondary()
		self:_check_and_create_panels()
	end

	self._secondary_player = managers.menu_component._secondary_panel:video({
		name = "secondary_sound",
		video = src,
		visible = false,
		loop = false
	})

	self._secondary_player:set_volume_gain(self:_check_volume_choice())
end

function ElementCustomSound:play_third(src)
	self._third_player = managers.menu_component._third_panel:video({
		name = "third_sound",
		video = src,
		visible = false,
		loop = self._values.third_loop or false
	})
	self._third_player:set_volume_gain(self:_check_volume_choice())
end

function ElementCustomSound:stop()
	managers.music:stop_custom()
	Global.music_manager.source:post_event("stop_all_music")
end

function ElementCustomSound:_check_existence(path)
	if DB:has(Idstring("movie"), path) then
		return true
	end

	return false
end

function ElementCustomSound:on_executed(instigator)
	if not MusicModule then
		return
	end

	if not self._values.enabled then
		return
	end

	if self._values.force_stop then
		self:stop()
		return
	end

	if not self._values.sound_path and not self._values.force_stop then
		self._mission_script:debug_output("Element '" .. self._editor_name .. "' doesn't have a path!", Color(1, 1, 0, 0))
		return
	end

	if not self:_check_existence(self._values.sound_path) then
		self._mission_script:debug_output("Sound path of Element '" .. self._editor_name .. "' doesn't exist! Check again if " .. self._values.sound_path .. " is valid.", Color(1, 1, 0, 0))
		return
	end

	if self._values.instigator_only and instigator ~= managers.player:player_unit() then
		return
	end

	--Check panels and create if required
	self:_check_and_create_panels()

	if not self._values.use_as_secondary and not self._values.use_as_third then
		-- Primary Channel
		self:play(self._values.sound_path)
		self._mission_script:debug_output("Playing Element '" .. self._editor_name .. "'. Primary channel is used.", Color(1, 0.75, 0.75, 0.75))
	end

	if self._values.use_as_secondary then
		-- Secondary Channel
		self:play_secondary(self._values.sound_path)
		self._mission_script:debug_output("Playing Element '" .. self._editor_name .. "'. Secondary channel is used.", Color(1, 0.75, 0.75, 0.75))

		if self._values.use_subtitles then
			local string_id = self._values.subtitle_id or ""
			local duration = self._values.subtitle_duration or 5

			DramaExt:play_subtitle(string_id, duration)
		end
	end

	if self._values.use_as_third then
		-- Third Channel
		self:play_third(self._values.sound_path)
		self._mission_script:debug_output("Playing Element '" .. self._editor_name .. "'. Third channel is used.", Color(1, 0.75, 0.75, 0.75))
	end

	ElementCustomSound.super.on_executed(self, instigator)
end

function ElementCustomSound:on_script_activated()
    self._mission_script:add_save_state_cb(self._id)
end

function ElementCustomSound:save(data)
    data.save_me = true
    data.enabled = self._values.enabled
end

function ElementCustomSound:load(data)
    self:set_enabled(data.enabled)
end
