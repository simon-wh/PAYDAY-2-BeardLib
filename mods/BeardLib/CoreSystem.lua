getmetatable(PackageManager)._script_data = getmetatable(PackageManager)._script_data or getmetatable(PackageManager).script_data

Hooks:Register("BeardLibSequenceScriptData")
Hooks:Register("BeardLibEnvironmentScriptData")

getmetatable(PackageManager).script_data = function(PackManager, extension, filepath, ...)
	--log("script_data")
	local data, arg1, arg2, arg3, arg4
    
	if (BeardLib and BeardLib.ScriptExceptions and not BeardLib.ScriptExceptions[filepath:key()]) or not BeardLib or not (BeardLib and BeardLib.ScriptExceptions) then
		data, arg1, arg2, arg3, arg4 = (PackManager:_script_data(extension, filepath, ...))
	end
	if extension == Idstring("environment") then
		BeardLib.CurrentEnvKey = filepath:key()
		for i, env_modifier in pairs(BeardLib.EnvMods) do
			if not env_modifier.sorted then
				table.sort(env_modifier, function(a, b) 
					return a.priority < b.priority
				end)
				env_modifier.sorted = true
			end
		end
		Hooks:Call("BeardLibEnvironmentScriptData", PackManager, filepath, data)
	elseif extension == Idstring("sequence_manager") then
		for i, seq_modifier in pairs(BeardLib.sequence_mods) do
			if not seq_modifier.sorted then
				table.sort(seq_modifier, function(a, b) 
					return a.priority < b.priority
				end)
				seq_modifier.sorted = true
			end
		end
		Hooks:Call("BeardLibSequenceScriptData", PackManager, extension, filepath, data)
	elseif extension == Idstring("menu") then
		if MenuHelperPlus and MenuHelperPlus:GetMenuDataFromHashedFilepath(filepath:key()) then
			log("Give NewData")
			data = MenuHelperPlus:GetMenuDataFromHashedFilepath(filepath:key())
		end
	end
	return data, arg1, arg2, arg3, arg4
end