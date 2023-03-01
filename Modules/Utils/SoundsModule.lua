SoundsModule = SoundsModule or BeardLib:ModuleClass("Sounds", ModuleBase)
SoundsModule.auto_load = false

local Managers = BeardLib.Managers

function SoundsModule:init(...)
	if not SoundsModule.super.init(self, ...) then
		return false
	end
	BeardLib.Utils:SetupXAudio()
	self:ReadSounds(self._config)
	return true
end

--:shrug:
local sound_s = "sound"
local Sound_s = "Sound"
local sounds_s = "sounds"
local Sounds_s = "Sounds"
local redirect_s = "redirect"
local Redirect_s = "Redirect"
local queue_s = "queue"
local Queue_s = "Queue"
local stop = "stop"
local Stop = "Stop"
local scan = "scan"
local random = "random"

function SoundsModule:ReadSounds(data, prev_dir)
	if not XAudio then
		self:Err("Sounds module requires the XAudio API!")
		return
	end

	local dir = self:GetPath(data.directory, prev_dir)
	local prefix = data.prefix
	local prefixes = data.prefixes or data.prefix and { data.prefix }
	if prefix == "global" then
		prefix = nil
		prefixes = nil
	end

	local prefixes_strict = data.prefixes_strict or false
	local load_on_play = data.load_on_play or false
	local unload = data.unload
	local auto_pause = data.auto_pause
	local relative = data.relative
	local dont_store_float = data.dont_store_float
	local stop_id = data.stop_id
	local wait = data.wait
	local volume = data.volume
	local min_distance = data.min_distance
	local max_distance = data.max_distance

	if prefixes then
		prefixes._meta = nil
	end

	for k, v in ipairs(data) do
		if type(v) == "table" then
			local meta = v._meta
			v.prefixes = v.prefixes or (v.prefix and { v.prefix } or prefixes)
			if v.prefixes then
				v.prefixes._meta = nil
			end

			v = table.merge({
				prefix = prefix,
				prefixes_strict = prefixes_strict,
				dont_store_float = dont_store_float,
				auto_pause = auto_pause,
				stop_id = stop_id,
				relative = relative,
				wait = wait,
				volume = volume,
				min_distance = min_distance,
				max_distance = max_distance
			}, v)

			if v.subtitle_id then
				v.markers = v.markers or {}
				table.insert(v.markers, 1, {
					position = 0,
					label = v.subtitle_id
				})
			end

			if v.prefix == "global" then
				v.prefix = nil
				v.prefxies = nil
			end

			if (meta == redirect_s or meta == Redirect_s) then
				Managers.Sound:AddRedirect(v)
			elseif (meta == sound_s or meta == Sound_s) and v.id then
				v.path = v.path or v.id .. ".ogg"
				Managers.Sound:AddBuffer(table.merge({
					full_path = Path:Combine(dir, v.path),
					load_on_play = load_on_play,
					stop_id = stop_id or v.id .. "_stop",
					unload = unload,
				}, v))
			elseif (meta == sounds_s or meta == Sounds_s) then
				if not v.dont_inherit then
					v = table.merge({
						load_on_play = load_on_play,
						unload = unload,
					}, v)
				end
				self:ReadSounds(v, dir)
			elseif meta == queue_s or meta == Queue_s or meta == random then
				local queue = {}
				for _, sound in ipairs(v) do
					if type(sound) == "table" and (sound._meta == sound_s or sound._meta == Sound_s) then
						table.insert(queue, sound)
					end
				end
				v.queue = queue
				v.is_random = meta == random
				Managers.Sound:AddSoundID(v)
			elseif meta == stop or meta == Stop then
				if v.sound_id then
					Managers.Sound:AddStop(v.id, v.sound_id)
				end
				for _, sound in ipairs(v) do
					if type(sound) == "table" and (sound._meta == sound_s or sound._meta == Sound_s) then
						Managers.Sound:AddStop(v.id, sound.id)
					end
				end
			elseif meta == scan then
				local scan_dir = self:GetPath(v.directory, dir)
				for _, file in pairs(FileIO:GetFiles(scan_dir)) do
					local splt = string.split(file, "%.")
					local id, ext = splt[1], splt[2]
					if ext == "ogg" then
						local file_path = id .. ".ogg"
						Managers.Sound:AddBuffer(table.merge({
							id = id,
							full_path = Path:Combine(scan_dir, file_path),
							load_on_play = load_on_play,
							stop_id = stop_id or id .. "_stop",
							unload = unload,
						}, v))
					end
				end
			end
		end
	end
end
