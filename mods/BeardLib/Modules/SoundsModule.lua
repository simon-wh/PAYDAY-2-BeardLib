SoundsModule = SoundsModule or class(ModuleBase)
SoundsModule.type_id = "Sounds"
function SoundsModule:RegisterHook()
	BeardLib.Utils:SetupXAudio()
	self:ReadSounds(self._config)
end

function SoundsModule:ReadSounds(data, prev_dir)
	local dir = self:GetPath(data.directory, prev_dir)
	local prefix = data.prefix
	local load_on_play = data.load_on_play or false
	local unload = data.unload
	local auto_pause = data.auto_pause
	local relative = data.relative
			
    for k, v in pairs(data) do
		if type(v) == "table" then
			if (v._meta == "event" or v._meta == "Event") and v.id then
				v.full_path = v.full_path or Path:Combine(dir, v.path)
				v.stop_id = v.stop_id or v.id.."_stop"
				v.prefix = v.prefix or prefix
				v.load_on_play = v.load_on_play or load_on_play
				v.unload = v.unload or unload
				v.auto_pause = v.auto_pause or auto_pause
				v.relative = v.relative or relative
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