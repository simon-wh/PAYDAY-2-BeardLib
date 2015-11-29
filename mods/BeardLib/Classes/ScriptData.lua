core:import("CoreClass")

ScriptData = ScriptData or CoreClass.class()

function ScriptData:init(id)
    self._id = id
    self._type = "base"
    self._mods = {}
    self._extension = nil
    self._sorted = false
    self:AddHooks()
end

function ScriptData:AddHooks()
    Hooks:Add("BeardLibPreProcessScriptData", "BeardLibProcessData:" .. self._id, function(PackManager, filepath, extension, data)
        self:ProcessScriptData(data, filepath, extension)
    end)
end

function ScriptData:ProcessScriptData(data, path, extension)
    
end

function ScriptData:CreateMod(ModID, path, data, extension)
    local pathK = path:key()
    
    if self._type ~= nil then
        self._sorted = false
    
        self._mods[pathK] = self._mods[pathK] or {}
        self._mods[pathK][ModID] = self._mods[pathK][ModID] or {}
        
        self._mods[pathK][ModID].name = ModID
        self._mods[pathK][ModID].priority = data.priority or 0
        table.merge(self._mods[pathK][ModID], data)
    else
        local extK = extension:key()
        self._sorted = false
        
        self._mods[pathK] = self._mods[pathK] or {}
        self._mods[pathK][extK] = self._mods[pathK][extK] or {}
        
        self._mods[pathK][extK][ModID] = self._mods[pathK][extK][ModID] or {}
        
        self._mods[pathK][extK][ModID].name = ModID
        self._mods[pathK][extK][ModID].priority = data.priority or 0
        table.merge(self._mods[pathK][extK][ModID], data)
    end
    
end

function ScriptData:IsModRegistered(ModID, path, extension)
    if self._mods[path:key()] and (self._mods[path:key()][ModID] or (self._mods[path:key()][extension:key()] and self._mods[path:key()][extension:key()][ModID])) then
        return true
    end
    
    return false
end

function ScriptData:SortMods()
    for i, path_mod in pairs(self._mods) do
        for i, extension_mod in pairs(path_mod) do
            table.sort(extension_mod, function(a, b) 
                return a.priority < b.priority
            end)
        end
	end
    
    self._sorted = true
end

function ScriptData:ParseJsonData(section_data)

end

function ScriptData:WriteJsonData(ModID)

end