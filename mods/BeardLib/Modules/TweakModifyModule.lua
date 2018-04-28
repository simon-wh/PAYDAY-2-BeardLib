TweakModifyModule = TweakModifyModule or class(ItemModuleBase)
TweakModifyModule.type_name = "TweakModify"
TweakModifyModule.required_params = {}

function TweakModifyModule:RegisterHook()
	for _, tweak in ipairs(self._config) do
		if type(tweak) == "table" and tweak._meta == "tweak" then
			local path = tweak.path
			if type(path) == "string" then
				path = string.split(path, "/")
			end
			if tweak.overwrite then
				TweakDataHelper:OverwriteTweak(tweak.data, unpack(path))
			else
				TweakDataHelper:ModifyTweak(tweak.data, unpack(path))
			end
		end
	end
end

BeardLib:RegisterModule(TweakModifyModule.type_name, TweakModifyModule)