EnvironmentData = EnvironmentData or class(ScriptData)

function EnvironmentData:init(ID)
    self.super.init(self, ID)
    self._extension = Idstring("environment")
    self._type = "Environment"
end

function EnvironmentData:AddHooks()
    Hooks:Add("BeardLibPreProcessScriptData", "BeardLibProcessData:" .. self._id, function(PackManager, filepath, extension, data)
        if self._extension and self._extension ~= extension then
            return
        end
        self:ProcessScriptData(data.data, filepath, extension)
    end)
end

function EnvironmentData:AddParamMods(ModID, params)
    if not self:IsModRegistered(ModID, path) then
        BeardLib:log("ERROR: Must create mod before attempting to add modifications (" .. ModID .. ")")
        return
    end
    self._mods[ModID].ParamMods = self._mods[ModID].ParamMods or {}
    self._mods[ModID].ParamMods:merge(params)
end

function EnvironmentData:AddParamMod(ModID, paramPath, newValue)
    if not self:IsModRegistered(ModID, filepath) then
        BeardLib:log("ERROR: Must create mod before attempting to add modifications (" .. ModID .. ")")
        return
    end
    self._mods[ModID].ParamMods = self._mods[ModID].ParamMods or {}
    self._mods[ModID].ParamMods[paramPath] = newValue
end

function EnvironmentData:AddNewGroup(ModID, groupPath, data)
    if not self:IsModRegistered(ModID) then
        BeardLib:log("ERROR: Must create mod before attempting to add modifications (" .. ModID .. ")")
        return
    end
    self._mods[ModID].NewGroups = self._mods[ModID].NewGroups or {}
    self._mods[ModID].NewGroups[groupPath] = data
end

function EnvironmentData:AddNewParam(ModID, groupPath, name, value)
    if not self:IsModRegistered(ModID) then
        BeardLib:log("ERROR: Must create mod before attempting to add modifications (" .. ModID .. ")")
        return
    end
    
    local param = {
        _meta = "param",
        key = name,
        value = value
    }
    
    self._mods[ModID].NewGroups = self._mods[ModID].NewGroups or {}
    self._mods[ModID].NewGroups[groupPath] = param
end

function EnvironmentData:ProcessScriptData(data, path, extension, name)
    local mods = self:GetScriptDataMods(path:key(), extension:key())
    
    BeardLib.env_data = BeardLib.env_data or {}
    BeardLib.env_data[path:key()] = BeardLib.env_data[path:key()] or {}
    
    for _, sub_data in ipairs(data) do
        if sub_data._meta == "param" then
            local next_data_path = name and name .. "/" .. sub_data.key or sub_data.key
            
            if mods then
                for i, mod in pairs(mods) do
                    if not mod.use_callback or (mod.use_callback and mod.use_callback()) then
                        if mod.ParamMods[next_data_path] ~= nil then
                            sub_data.value = mod.ParamMods[next_data_path]
                        end
                    end
                end
            end
            
            local next_data_path_key = next_data_path:key()
            BeardLib.env_data[path:key()][next_data_path_key] = {value = sub_data.value, path = next_data_path, display_name = data._meta .. "/" .. sub_data.key}
        else
            local next_data_path = name and name .. "/" .. sub_data._meta or sub_data._meta
            
            if mods then
                for i, mod in pairs(mods) do
                    if not mod.use_callback or (mod.use_callback and mod.use_callback()) then
                        if mod.NewGroups[next_data_path] ~= nil then
                            self:CreateNewEnvGroup(sub_data, mod.NewGroups[next_data_path])
                        end
                    end
                end
            end
            
            self:ProcessScriptData(sub_data, path, extension, next_data_path)
        end
    end
end


function EnvironmentData:CreateNewEnvGroup(data, newgroup)
    local max_value = table.maxn(data)
    data[max_value + 1] = newgroup
end