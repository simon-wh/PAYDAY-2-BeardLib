SoundsModule = SoundsModule or class(ModuleBase)
SoundsModule.type_id = "Sounds"
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

function SoundsModule:ReadSounds(data, prev_dir)
	if not XAudio then
		self:log("[ERROR] Sounds module requires the XAudio API!")
		return
	end

	local dir = self:GetPath(data.directory, prev_dir)
	local prefix = data.prefix
	local prefixes = data.prefixes or data.prefix and {data.prefix}
	local load_on_play = data.load_on_play or false
	local unload = data.unload
	local auto_pause = data.auto_pause
	local relative = data.relative
	local dont_store_float = data.dont_store_float
	local stop_id = data.stop_id
	local wait = data.wait
	local volume = data.volume

    for k, v in ipairs(data) do
		if type(v) == "table" then
			local meta = v._meta
			if (meta == redirect_s or meta == Redirect_s) then
				CustomSoundManager:AddRedirect(v.id, v.to, v.prefix or prefix)
			else
				v = table.merge({
					prefix = prefix,
					prefixes = prefixes,
					dont_store_float = dont_store_float,
					auto_pause = auto_pause,
					stop_id = stop_id,
					relative = relative,
					wait = wait,
					volume = volume
				}, v)
				if v.prefix then
					v.prefixes = {v.prefix}
				end
				if (meta == sound_s or meta == Sound_s) and v.id then
					v.path = v.path or v.id..".ogg"
					CustomSoundManager:AddBuffer(table.merge({
						full_path = Path:Combine(dir, v.path),
						load_on_play = load_on_play,
						stop_id = stop_id or v.id.."_stop",
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
				elseif meta == queue_s or meta == Queue_s then
					local queue = {}
					for _, sound in ipairs(v) do
						if type(sound) == "table" and (sound._meta == sound_s or sound._meta == Sound_s) then
							table.insert(queue, sound)
						end
					end
					v.queue = queue
					CustomSoundManager:AddSoundID(v)
				elseif meta == stop or meta == Stop then
					if v.sound_id then
						CustomSoundManager:AddStop(v.id, v.sound_id)
					end
					for _, sound in ipairs(v) do
						if type(sound) == "table" and (sound._meta == sound_s or sound._meta == Sound_s) then
							CustomSoundManager:AddStop(v.id, sound.id)
						end
					end
				end
			end
		end
	end
end

BeardLib:RegisterModule(SoundsModule.type_id, SoundsModule)