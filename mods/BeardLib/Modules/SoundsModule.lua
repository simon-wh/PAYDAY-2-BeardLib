SoundsModule = SoundsModule or class(ModuleBase)
SoundsModule.type_id = "Sounds"
function SoundsModule:RegisterHook()
	BeardLib.Utils:SetupXAudio()
	self:ReadSounds(self._config)
end

function SoundsModule:ReadSounds(data, prev_dir)
	local dir = self:GetPath(data.directory, prev_dir)
	local prefix = data.prefix

    for k, v in pairs(data) do
		if type(v) == "table" then
			if (v._meta == "event" or v._meta == "Event") and v.id then
				v.stop_id = v.stop_id or v.id.."_stop"
				v.prefix = v.prefix or prefix
				CustomSoundManager:AddBuffer(Path:Combine(dir, v.path), v)
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