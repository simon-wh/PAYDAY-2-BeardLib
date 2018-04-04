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

function SoundsModule:ReadSounds(data, prev_dir)
	if not XAudio then
		self:log("[ERROR] Sounds module requires the XAudio API!")
		return
	end

	local dir = self:GetPath(data.directory, prev_dir)
	local prefix = data.prefix
	local load_on_play = data.load_on_play or false
	local unload = data.unload
	local auto_pause = data.auto_pause
	local relative = data.relative
	local dont_store_float = data.dont_store_float

    for k, v in pairs(data) do
		if type(v) == "table" then
			if (v._meta == "sound" or v._meta == "Sound") and v.id then
				CustomSoundManager:AddBuffer(table.merge({
					full_path = Path:Combine(dir, v.path),
					dont_store_float = dont_store_float,
					load_on_play = load_on_play,
					auto_pause = auto_pause,
					stop_id = v.id.."_stop",
					relative = relative,
					prefix = prefix,
					unload = unload,
				}, v))
			elseif (v._meta == "redirect" or v._meta == "Redirect") then
				CustomSoundManager:AddRedirect(v.id, v.to, v.prefix or prefix)
			elseif (v._meta == "sounds" or v._meta == "Sounds") then
				self:ReadSounds(v, dir)
			end
		end
	end
end

function SoundsModule:GetPath(directory, prev_dir)
	if prev_dir then
		return Path:Combine(prev_dir, directory)
	else
		return Path:Combine(self._mod.ModPath, directory)
	end
end

BeardLib:RegisterModule(SoundsModule.type_id, SoundsModule)