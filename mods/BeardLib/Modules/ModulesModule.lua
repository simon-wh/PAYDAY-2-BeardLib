ModulesModule = ModulesModule or class(ModuleBase)
ModulesModule.type_name = "Modules"

function ModulesModule:Load(config, prev_dir)
	config = config or self._config
	local dir = self:GetPath(config.directory, prev_dir)
	for _, moodule in ipairs(config) do
		if moodule._meta == "module" then
			local module_path = dir and Path:Combine(dir, moodule.file) or moodule.file
			
			local mod_path = self._mod:GetPath()
			local hook_file = Path:Combine(mod_path, module_path)
			
			dofile(hook_file)
			local hook_object_name = moodule.name
			local hook_type_name = moodule.type_name

			if hook_object_name then
				if hook_type_name then
					if _G[hook_object_name] then
						_G[hook_object_name].type_name = hook_type_name
						BeardLib:RegisterModule(hook_type_name, _G[hook_object_name])
					else
						BeardLib:log("[ERROR] '%s' tried to create module '%s' with a global class that doesn't exist!", self._mod.Name, hook_object_name )
					end
				else
					BeardLib:log("[ERROR] '%s' tried to create module '%s' without a 'type_name'!", self._mod.Name, hook_object_name )
				end
			else
				BeardLib:log("[ERROR] '%s' tried to create module with no 'name' specified!", self._mod.Name )
			end
		elseif moodule._meta == "modules" then
			self:Load(hook, dir)
		end
	end
end

function ModulesModule:GetPath(directory, prev_dir)
	if prev_dir then
		return Path:CombineDir(prev_dir, directory)
	else
		return directory
	end
end

BeardLib:RegisterModule(ModulesModule.type_name, ModulesModule)