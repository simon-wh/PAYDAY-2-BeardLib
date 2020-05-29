TweakModifyModule = TweakModifyModule or BeardLib:ModuleClass("TweakModify", ItemModuleBase)
TweakModifyModule.type_name = "TweakModify"
TweakModifyModule.required_params = {}

function TweakModifyModule:RegisterHook()
	local use_clbk = self._config.use_clbk and self._mod:StringToCallback(self._config.use_clbk) or nil
	if use_clbk and not use_clbk(self._config) then
		return
	end

	for _, tweak in ipairs(self._config) do
		if type(tweak) == "table" and tweak._meta == "tweak" then
			local use_clbk = self._config.use_clbk and self._mod:StringToCallback(self._config.use_clbk) or nil
			if not use_clbk or use_clbk(tweak) then
				local path = tweak.path
				if type(path) == "string" then
					path = string.split(path, "/")
				end
				if self._config.normalize or tweak.normalize then
					tweak.data = BeardLib.Utils:normalize_string_value(tweak.data)
				end
				if (self._config.overwrite or tweak.overwrite) or type(tweak.data) ~= "table" then
					TweakDataHelper:OverwriteTweak(tweak.data, unpack(path))
				else
					TweakDataHelper:ModifyTweak(tweak.data, unpack(path))
				end
			end
		end
	end
end