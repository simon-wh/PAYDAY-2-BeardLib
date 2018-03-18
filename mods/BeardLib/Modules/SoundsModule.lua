SoundsModule = SoundsModule or class(ModuleBase)
SoundsModule.type_id = "Sounds"
function SoundsModule:RegisterHook()
	BeardLib.Utils:SetupXAudio()
	
	local dir = self._config.directory
	if dir then
		dir = Path:Combine(self._mod.ModPath, dir)
	else
		dir = self._mod.ModPath
	end

    for k, v in pairs(self._config) do
		if type(v) == "table" and (v._meta == "event" or v._meta == "Event") and v.id then
			local stop_id = v.stop_id or v.id.."_stop"
            CustomSoundManager:AddBuffer(Path:Combine(dir, v.path), v.id, stop_id, v.loop)
		end
	end
end

BeardLib:RegisterModule(SoundsModule.type_id, SoundsModule)