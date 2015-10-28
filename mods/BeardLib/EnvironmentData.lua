--if CoreEnvironmentManager then
	log("EnvironmentManager")
	--EnvironmentManager = CoreEnvironmentManager.EnvironmentManager
	--CloneClass(EnvironmentManager)
	Hooks:Register("BeardLibEnvironmentManagerPostInit")
	BeardLib.EnvMods = BeardLib.EnvMods or {} 
	
	--[[function EnvironmentManager.init(self)
		self.orig.init(self)
		Hooks:Call("BeardLibEnvironmentManagerPostInit", self)
	end
	
	function EnvironmentManager:_load(path)
		local raw_data
		
		for i, env_modifier in pairs(BeardLib.EnvMods) do
			if not env_modifier.sorted then
				table.sort(env_modifier, function(a, b) 
					return a.priority < b.priority
				end)
				env_modifier.sorted = true
			end
		end
		
		if Application:editor() then
			raw_data = PackageManager:editor_load_script_data(ids_extension, path:id())
		else
			raw_data = PackageManager:script_data(ids_extension, path:id())
		end
		Hooks:Call("BeardLibEnvironmentData", self, path, raw_data)
		local env_data = {}
		self:_load_env_data(nil, env_data, raw_data.data)
		return env_data
	end]]--
	
	Hooks:Add("BeardLibEnvironmentScriptData", "BeardLibProcessEnvData", function(PackManager, path, raw_data)
		log("Process Env Data")
		--SaveTable(raw_data, "EnvModBefore.txt")
		BeardLib:ProcessEnvData(path, raw_data, nil)
		--if BeardLib.EnvMods[tostring(path:key())] then
			BeardLib.env_data = {}
			BeardLib:_load_env_data(nil, BeardLib.env_data, raw_data.data)
			if BeardLib.nodes then
				MenuHelper:NewMenu( BeardLib.EnvMenu )
				if BeardLib.nodes[BeardLib.EnvMenu] then
					--BeardLib.nodes[BeardLib.EnvMenu]:clean_items()
					BeardLib.nodes[BeardLib.EnvMenu] = nil
				end
				BeardLib.EnvCreatedMenus = {}
                if BeardLib.EditorEnabled then
                    BeardLib:PopulateEnvMenu()
                end
			end
		--end
		BeardLib.current_env = tostring(path:key())
		--SaveTable(raw_data, "EnvModAfter.txt")
		
	end)
	
	function BeardLib:ProcessEnvData(path, data, name)
		if not BeardLib.EnvMods[tostring(path:key())] then
			return
		end
		
		-- Need to make sure that value tables are okay
		for sub_name, sub_data in ipairs(data) do
			if type(sub_data) == "table" then
				local new_name = (name and (name .. "/") or "") .. sub_name
				if sub_data._meta ~= "param" then
					for i, mod in pairs(BeardLib.EnvMods[tostring(path:key())]) do
						if type(mod) == "table" then
							if not mod.use_callback or (mod.use_callback and mod.use_callback()) then
								if mod.new_param and sub_data._meta and mod.new_param[sub_data._meta] then
									for var_name, values in pairs(mod.new_param[sub_data._meta]) do
										self:CreateNewEnvParam(sub_data, var_name, values)
									end
								end
								if mod.new_group and sub_data._meta and mod.new_group[sub_data._meta] then
									for var_name, values in pairs(mod.new_group[sub_data._meta]) do
										self:CreateNewEnvGroup(sub_data, var_name, values)
									end
								end
								
							end
						end
					end
				end
				if sub_data._meta == "param" then
					for i, mod in pairs(BeardLib.EnvMods[tostring(path:key())]) do
						if type(mod) == "table" then
							if not mod.use_callback or (mod.use_callback and mod.use_callback()) then
								if mod.mod_data and data._meta and mod.mod_data[data._meta] and mod.mod_data[data._meta][sub_data.key] then
									sub_data.value = mod.mod_data[data._meta][sub_data.key]
									-- Need to double check that the multiple values value work okay
								end

								-- Need to move outside of if meta = param
								--if mod.new_data and data._meta and mod.new_data[data._meta] then
									--self:ApplyNewEnvData(data, mod)
								--end
							end
						end
					end
				else
					self:ProcessEnvData(path, sub_data, new_name)
				end
			end
		end
		
	end
	
	--[[function BeardLib:ApplyNewEnvData(data, mod_data)
		for name, metadata in pairs(mod_data.new_data) do
			for var_name, values in pairs(metadata) do
				if type(values) == "table" and values._meta ~= "param" then
					self:CreateNewEnvGroup(data, var_name, values)
				else
					self:CreateNewEnvParam(data, var_name, values)
				end
			end
		end
	end]]--

	function BeardLib:CreateNewEnvGroup(data, valname, values)
		local max_value = table.maxn(data)
		--[[if tonumber(valname) ~= nil then
			data[max_value + 1] = values
		else
			if data[valname] and not values.dont_overwrite then
				data[valname] = values
			elseif not data[valname] then
				data[valname] = values
			end
		end]]--
		data[max_value + 1] = values
		if not data[values._meta] then
			data[values._meta] = values
		end
	end
	
	function BeardLib:CreateNewEnvParam(data, name, values)
		local max_value = table.maxn(data)
		local new_data_table = {
			key = name,
			value = values,
			_meta = "param"
		}
		data[max_value + 1] = new_data_table
	end
	
	function BeardLib:CreateEnvMod(EnvironmentFile, ModID, Data, IsHashed)
		local FilePath = IsHashed and EnvironmentFile or tostring(Idstring(EnvironmentFile):key())
		BeardLib.EnvMods[FilePath] = BeardLib.EnvMods[FilePath] or {}
		BeardLib.EnvMods[FilePath].sorted = false
		BeardLib.EnvMods[FilePath][ModID] = BeardLib.EnvMods[FilePath][ModID] or {}
		BeardLib.EnvMods[FilePath][ModID].new_group = BeardLib.EnvMods[FilePath][ModID].new_group or {}
		BeardLib.EnvMods[FilePath][ModID].new_param = BeardLib.EnvMods[FilePath][ModID].new_param or {}
		BeardLib.EnvMods[FilePath][ModID].mod_data = BeardLib.EnvMods[FilePath][ModID].mod_data or {}
		table.merge(BeardLib.EnvMods[FilePath][ModID], Data)
	end
	
	function BeardLib:AddEnvParamMods(EnvironmentFile, ModID, EnvGroup, Data, IsHashed)
		local FilePath = IsHashed and EnvironmentFile or tostring(Idstring(EnvironmentFile):key())
		if not BeardLib.EnvMods[FilePath][ModID] then
			BeardLib:log("ERROR: Must create env mod before adding Param Modifications (" .. ModID .. ")")
			return
		end
		if BeardLib.EnvMods[FilePath][ModID].mod_data[EnvGroup] then
			table.merge(BeardLib.EnvMods[FilePath][ModID].mod_data[EnvGroup], Data)
		else
			BeardLib.EnvMods[FilePath][ModID].mod_data[EnvGroup] = Data
		end
	end
	
	function BeardLib:AddEnvParamMod(EnvironmentFile, ModID, EnvGroup, param_key, new_param_val, IsHashed)
		local FilePath = IsHashed and EnvironmentFile or tostring(Idstring(EnvironmentFile):key())
		if not BeardLib.EnvMods[FilePath][ModID] then
			BeardLib:log("ERROR: Must create env mod before adding a Param Modification (" .. ModID .. ")")
			return
		end
		BeardLib.EnvMods[FilePath][ModID].mod_data[EnvGroup] = BeardLib.EnvMods[FilePath][ModID].mod_data[EnvGroup] or {}
		BeardLib.EnvMods[FilePath][ModID].mod_data[EnvGroup][param_key] = new_param_val
	end
	
	function BeardLib:AddEnvNewGroup(EnvironmentFile, ModID, EnvGroup, Data, IsHashed)
		local FilePath = IsHashed and EnvironmentFile or tostring(Idstring(EnvironmentFile):key())
		if not BeardLib.EnvMods[FilePath][ModID] then
			BeardLib:log("ERROR: Must create env mod before adding Param Modifications (" .. ModID .. ")")
			return
		end
		BeardLib.EnvMods[FilePath][ModID].new_group[EnvGroup] = BeardLib.EnvMods[FilePath][ModID].new_group[EnvGroup] or {}
		local max_val = table.maxn(BeardLib.EnvMods[FilePath][ModID].new_group[EnvGroup])
		BeardLib.EnvMods[FilePath][ModID].new_group[EnvGroup][max_val + 1] = Data
	end
	
	function BeardLib:AddEnvNewParam(EnvironmentFile, ModID, EnvGroup, key, value, IsHashed)
		local FilePath = IsHashed and EnvironmentFile or tostring(Idstring(EnvironmentFile):key())
		if not BeardLib.EnvMods[FilePath][ModID] then
			BeardLib:log("ERROR: Must create env mod before adding Param Modifications (" .. ModID .. ")")
			return
		end
		BeardLib.EnvMods[FilePath][ModID].new_param[EnvGroup] = BeardLib.EnvMods[FilePath][ModID].new_param[EnvGroup] or {}
		BeardLib.EnvMods[FilePath][ModID].new_param[EnvGroup][key] = value
	end
	
	function BeardLib:_load_env_data(data_path, env_data, raw_data)
		for _, sub_raw_data in ipairs(raw_data) do
			if sub_raw_data._meta == "param" then
				local next_data_path = data_path and data_path .. "/" .. sub_raw_data.key or sub_raw_data.key
				local next_data_path_key = Idstring(next_data_path):key()
				env_data[next_data_path_key] = {value = sub_raw_data.value, path = next_data_path, display_name = raw_data._meta .. "/" .. sub_raw_data.key}
				--self:PopulateMenuNode(raw_data._meta, sub_raw_data, next_data_path_key)
			else
				local next_data_path = data_path and data_path .. "/" .. sub_raw_data._meta or sub_raw_data._meta
				self:_load_env_data(next_data_path, env_data, sub_raw_data)
			end
		end
	end
	
--end