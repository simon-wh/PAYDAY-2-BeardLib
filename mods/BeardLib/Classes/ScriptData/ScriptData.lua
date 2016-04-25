core:import("CoreClass")

ScriptData = ScriptData or CoreClass.class()

function ScriptData:init(id)
    self._id = id
    self._type = "Base"
    self._mods = {}
    self._extension = nil
    self:AddHooks()
end

function ScriptData:AddHooks()
    Hooks:Add("BeardLibPreProcessScriptData", "BeardLibProcessData:" .. self._id, function(PackManager, filepath, extension, data)
        if self._extension and self._extension ~= extension then
            return
        end
        self:ProcessScriptData(data, filepath, extension)
    end)
end

function ScriptData:ProcessScriptData(data, path, extension)
    
end

function ScriptData:CreateMod(data)
    if not data then
        BeardLib:log("[Error] Mod cannot be created without any data")
        return
    end

    local ModID = data.ID
    local pathK = data.file:key()
    local extK = data.extension and data.extension:key() or nil
    
    self._sorted = false

    self._mods[ModID] = self._mods[ModID] or {}
    
    self._mods[ModID].ID = ModID
    self._mods[ModID].priority = data.priority or 0
    self._mods[ModID].file_key = pathK
    self._mods[ModID].extension_key = extK
    self._mods[ModID].use_callback = data.use_callback or nil
    
    table.merge(self._mods[ModID], data)
end

function ScriptData:IsModRegistered(ModID)
    if self._mods[ModID] and self._mods[ModID].file_key then
        return true
    end
    
    return false
end

function ScriptData:GetScriptDataMods(fileKey, extKey)
    local mods = {}
    
    for ID, mod in pairs(self._mods) do
        if mod.file_key == fileKey and (self._extension ~= nil or mod.extension_key == extKey) then
            mods[ID] = mod
        end
    end
    
    table.sort(mods, function(a, b) 
		return a.priority < b.priority
	end)
    
    return mods
end

function ScriptData:GetMod(ModID)
    return self._mods[ModID]
end

function ScriptData:ParseJsonData(section_data)
    if not section_data then 
        return
    end
    local ModID = section_data.ID
    
    if not ModID then
        return
    end
    
    self._mods[ModID] = self._mods[ModID] or {}
    table.merge(self._mods[ModID], section_data)
end

function ScriptData:WriteJsonData(ModID, save_path)
    local file = io.open(save_path, "w+")
    local mod_table = self._mods[ModID]
    local write_tbl = {
        [self._type] = {
            mod_table
        }
    }
    file:write(json.encode_script_data(write_tbl))
end