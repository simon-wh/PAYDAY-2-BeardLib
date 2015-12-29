ContinentData = ContinentData or class(ScriptData)

function ContinentData:init(ID)
    self.super.init(self, ID)
    self._type = "Continent"
    self._extension = Idstring("continent")
end

	
function ContinentData:AddUnitMod(ModID, UnitName, data)
    if not self:IsModRegistered(ModID) then
		BeardLib:log("ERROR: SequenceMod ID: " .. ModID .. " not registered")
		return
	end
    self._mods[ModID].UnitMods = self._mods[ModID].UnitMods or {}
    self._mods[ModID].UnitMods[UnitName] = self._mods[ModID].UnitMods[UnitName] or {}
    table.merge(self._mods[ModID].UnitMods[UnitName], data)
end
	
function ContinentData:AddUnit(ModID, data)
    if not self:IsModRegistered(ModID) then
		BeardLib:log("ERROR: SequenceMod ID: " .. ModID .. " not registered")
		return
	end
    self._mods[ModID].NewUnits = self._mods[ModID].NewUnits or {}
    --implement different unit vars
    local new_data = {
        
    }
    
    table.merge(new_data, data)
    
    table.insert(self._mods[ModID].NewUnits, new_data)
end

function ContinentData:ProcessScriptData(data, path, extension)
    if extension ~= self._extension then
        return
    end
    
    local pathK = path:key()

	local merge_data = self:GetScriptDataMods(pathK, extension:key())
    
	local statics = data.statics
    
    if statics then
        log("Statics present")
        for i, static_data in pairs(statics) do
            if static_data.unit_data and static_data.unit_data.name_id then
                for ID, mod in pairs(merge_data) do
                    if mod.UnitMods and mod.UnitMods[static_data.unit_data.name_id] then
                        table.merge(static_data.unit_data, mod.UnitMods[static_data.unit_data.name_id])
                    end
                end
            end
        end        
        
        for ID, mod in pairs(merge_data) do
            if mod.NewUnits then
                for i, new_unit in pairs(mod.NewUnits) do
                    table.insert(statics, {unit_data = new_unit})
                end
            end
        end
    end
end