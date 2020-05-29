core:import("CoreMissionScriptElement")

--[[
	Element made by: Nepgearsy
]]

XAudioInitializer = XAudioInitializer or class()

function XAudioInitializer:init()
	if not self._initialized then
		if blt.xaudio then
			blt.xaudio.setup()
		else
			log("[ElementXAudio] SuperBLT is not installed properly!")
			return
		end

		self._sound_buffers = {}
    	self._sound_sources = {}
	end

	self._initialized = true
end

function XAudioInitializer:PlaySound(data)
	if not self._sound_sources[data.name] then
        table.insert(self._sound_buffers, data.name)
        table.insert(self._sound_sources, data.name)
    end

    if self._sound_sources[data.name] then
        self._sound_buffers[data.name]:close()
        self._sound_sources[data.name]:close()
        self._sound_sources[data.name] = nil
    end

    local directory = self:GetRootAssetsPath() .. data.custom_dir .. "/"

    self._sound_buffers[data.name] = XAudio.Buffer:new(directory .. data.file_name)
    self._sound_sources[data.name] = XAudio.Source:new(self._sound_buffers[data.name])

    if not data.sound_type then
        data.sound_type = "sfx"
    end

    self._sound_sources[data.name]:set_type(data.sound_type)
    self._sound_sources[data.name]:set_relative(data.is_relative)
    self._sound_sources[data.name]:set_looping(data.is_loop)

    if data.is_3d then
        self._sound_sources[data.name]:set_position(data.position)
    end

    if data.use_velocity then
        self._sound_sources[data.name]:set_velocity(data.position)
    end

    if data.override_volume and data.override_volume > 0 then
        if data.override_volume > 1 then
            data.override_volume = 1
        end

        self._sound_sources[data.name]:set_volume(data.override_volume)
    end
end

function XAudioInitializer:Destroy(id)
	if self._sound_sources[id] then
		self._sound_buffers[id]:close()
        self._sound_sources[id]:close()
        self._sound_sources[id] = nil
    end
end

function XAudioInitializer:SetLooping(state, id)
	if self._sound_sources[id] then
		self._sound_sources[id]:set_looping(state)
	end
end

function XAudioInitializer:SetRelative(state, id)
	if self._sound_sources[id] then
		self._sound_sources[id]:set_relative(state)
	end
end

function XAudioInitializer:SetVolume(volume, id)
	if volume > 1 or volume < 0 then
		volume = 1
	end

	if self._sound_sources[id] then
		self._sound_sources[id]:set_volume(volume)
	end
end

function XAudioInitializer:Available()
	return not not self._initialized
end

function XAudioInitializer:GetRootAssetsPath()
	local CurrentLevel = BeardLib.current_level and BeardLib.current_level._mod
	local ModPath = CurrentLevel.ModPath

	return ModPath .. "assets/"
end

ElementXAudio = ElementXAudio or class(CoreMissionScriptElement.MissionScriptElement)

function ElementXAudio:init(...)
	ElementXAudio.super.init(self, ...)

	self._XA = XAudioInitializer:new()

	self._data = {
		name = "unknown",
		custom_dir = "",
		file_name = "",
		sound_type = "sfx",
		is_relative = false,
		is_loop = false,
		is_3d = false,
		position = "",
		override_volume = -1
	}
end
function ElementXAudio:client_on_executed(...)
	self:on_executed(...)
end

function ElementXAudio:on_executed(instigator)
	if not self._values.enabled then
		self._mission_script:debug_output("Element '" .. self._editor_name .. "' not enabled. Skip.", Color(1, 1, 0, 0))
		return
	end

	if not self._XA:Available() then
		return
	end

	self._data.name = self._id
	self._data.custom_dir = self._values.custom_dir
	self._data.file_name = self._values.file_name
	self._data.sound_type = self._values.sound_type or "sfx"
	self._data.is_relative = self._values.is_relative or false
	self._data.is_loop = self._values.is_loop or false
	self._data.is_3d = self._values.is_3d or false
	self._data.position = self._values.position
	self._data.override_volume = self._values.override_volume or -1

	self._XA:PlaySound(self._data)
	ElementXAudio.super.on_executed(self, instigator)
end

function ElementXAudio:CloseSource(source_id)
	self._XA:Destroy(source_id)
end

function ElementXAudio:SetLooping(state, id)
	self._XA:SetLooping(state, id)
end

function ElementXAudio:SetRelative(state, id)
	self._XA:SetRelative(state, id)
end

function ElementXAudio:SetVolume(volume, id)
	self._XA:SetVolume(volume, id)
end

function ElementXAudio:on_script_activated()
    self._mission_script:add_save_state_cb(self._id)
end

function ElementXAudio:save(data)
    data.save_me = true
    data.enabled = self._values.enabled
end

function ElementXAudio:load(data)
    self:set_enabled(data.enabled)
end

ElementXAudioOperator = ElementXAudioOperator or class(CoreMissionScriptElement.MissionScriptElement)

function ElementXAudioOperator:init(...)
	ElementXAudioOperator.super.init(self, ...)
end

function ElementXAudioOperator:client_on_executed(...)
	self:on_executed(...)
end

function ElementXAudioOperator:on_executed(instigator)
	if not self._values.enabled then
		return
	end

	for _, id in ipairs(self._values.elements) do
		local element = self:get_mission_element(id)

		if element then
			if self._values.operation == "stop" then
				element:CloseSource(id)
			elseif self._values.operation == "set_looping" then
				element:SetLooping(self._values.state, id)
			elseif self._values.operation == "set_relative" then
				element:SetRelative(self._values.state, id)
			elseif self._values.operation == "set_volume" then
				element:SetVolume(self._values.volume_override, id)
			end
		end
	end

	ElementXAudioOperator.super.on_executed(self, instigator)
end
