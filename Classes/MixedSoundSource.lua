if not XAudio then
	return
end

MixedSoundSource = MixedSoundSource or class(XAudio.Source)
function MixedSoundSource:init(sound_id, queue, engine_source, clbk, cookie)
	MixedSoundSource.super.init(self)
	self._engine_source = engine_source
	self._callback = clbk
	self._sound_id = sound_id
	self._queue = queue
	self._cookie = cookie
	self._closed = false
	self._queue_is_table = type(self._queue) == "table"

	self._marker_status = {}
end

function MixedSoundSource:alive()
	return alive(self._engine_source)
end

-- \o\
function MixedSoundSource:stop()
	if not self:is_closed() then
		MixedSoundSource.super.stop(self)
	end
end

function MixedSoundSource:post_event(sound_id)
	if self._engine_source then
		local pass = self._engine_source:_post_event(sound_id, function(event_ins, instance, event)
			if event == "end_of_event" then
				self:next_in_queue()
			end
		end, nil, "end_of_event")

		if not pass then
			self:next_in_queue()
		end
	end
end

function MixedSoundSource:callback(event_type, label, identifier, position)
	if self._callback then
		--EventInstance is used?
		--Is the order of parameters always like this?
		--What is marker event and how can we implement it in here?
		--This shit is confusing aaa
		-- extra_arg_from_:_because_bad_callbacks,	instance,		event_type,		unit,		sound_source,	label,			identifier,		position -- Unit (What the callbacks make it look like.)
		-- instance,								sound_source,	event_type,		unit,		label,			identifier,		position -- Unit (What it actually is, thanks overkill, very cool.)
		-- instance, 								sound_source,	event_type,		cookie,		label,			identifier,		position -- No Unit

		-- Based on wwise docs. (These only apply to markers.)
		-- Label = Generic String (e.g. "dialog_something")
		-- Identifier = Numerical Identifier (Most of the time this is just some index or something.)
		-- Position = Sample frame position. (i.e. time / 48000) standard wwise sample rate is 48Khz.

		self._callback(nil, self._engine_source, event_type, self._engine_source:get_unit() or self._cookie, label, identifier, position)
	end
end

function MixedSoundSource:next_in_queue()
	self._playing = nil
	if self._queue_is_table then
		if self._queue[2] == nil then
			self:close()
			self:callback("end_of_event")
		else
			table.remove(self._queue, 1)
		end
	else
		self:close()
		self:callback("end_of_event")
	end
end

local sample_rate = 48000 -- Standard WWise 48k sample rate is used to provide a relatively accurate position value for callbacks. ( Current Sample Frame = Time / Sample Rate )
function MixedSoundSource:update(t, dt)
	if self:is_closed() then
		return
	end

	self._single_sound = nil

	MixedSoundSource.super.update(self, t, dt)

	local sound

	if self._playing then
		local engine_source, buffer = self._engine_source, self._buffer
		if engine_source then
			if engine_source:is_relative() or (buffer and buffer.data.relative) then
				self:set_relative(true)
				if buffer and not buffer.data.auto_pause then
					self:set_auto_pause(false)
				end
			else
				local position = engine_source:get_position()
				if position then
					self:set_position(position)
				end
			end
		end
	else
		if self._queue_is_table then
			sound = self._queue[1]
		else
			sound = self._queue
		end
		if not sound then
			self:close()
			self:callback("end_of_event")
			return
		end
	end

	if sound and not self._playing then
		local buffer = sound.buffer
		local wait = buffer and buffer.wait or sound.data.wait
		local volume = buffer and buffer.volume or sound.data.volume

		self._play_t = t
		if wait then
			self._play_t = self._play_t + wait
		end

		self._playing = sound
		self._initial = true
		self._marker_status = {}
		if volume then
			self._source_volume = self._raw_gain
			self:set_volume(volume)
		elseif self._source_volume then
			self:set_volume(self._source_volume)
		end

		if buffer then
			self:set_buffer(buffer, true)
		elseif not wait then
			self:post_event(sound.data.id)
		end
	end

	local state = self:get_state()
	local can_play = self._play_t and self._play_t <= t
	if self._playing and not self._playing.buffer then
		if can_play then
			self:post_event(self._playing.id)
		end
	else
		if self._initial or state == MixedSoundSource.INITIAL then
			if can_play then
				self:play()
				self._initial = nil
			end
		elseif state == MixedSoundSource.STOPPED then
			self:next_in_queue()
		end
	end

	if self._playing and self._playing.buffer and self._playing.buffer.data.markers then
		for index, marker_data in ipairs(self._playing.buffer.data.markers) do
			if not self._marker_status[index] and (t > self._play_t + marker_data.position) then
				self:callback("marker", marker_data.label, index, math.round(marker_data.position / sample_rate))

				self._marker_status[index] = true
			end
		end
	end
end

function MixedSoundSource:engine_source()
	return self._engine_source
end

function MixedSoundSource:queue()
	return self._queue
end

function MixedSoundSource:cookie()
	return self._cookie
end

function MixedSoundSource:sound_id()
	return self._sound_id
end