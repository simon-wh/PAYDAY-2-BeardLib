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
    local new_data = {
        continent = data.continent or "world",
        name = data.path,
        name_id = data.name,
        position = data.position or Vector3(0, 0, 0),
        rotation = data.rotation or Rotation(0, 0, 0),
        unit_id = data.unit_id,
    }
    
    if data.merge_data then
        table.merge(new_data, data.merge_data)
    end
    
    table.insert(self._mods[ModID].NewUnits, new_data)
end

function ContinentData:RemoveUnit(ModID, name)
    if not self:IsModRegistered(ModID) then
		BeardLib:log("ERROR: SequenceMod ID: " .. ModID .. " not registered")
		return
	end
    self._mods[ModID].UnitRemoval = self._mods[ModID].UnitRemoval or {}
    table.insert(self._mods[ModID].UnitRemoval, name)
end

function ContinentData:ProcessScriptData(data, path, extension)
    
    local pathK = path:key()
	local merge_data = self:GetScriptDataMods(pathK, extension:key())
    
	local statics = data.statics
    
    if statics and table.size(merge_data) > 0 then
        for i, static_data in pairs(statics) do
            if static_data.unit_data and static_data.unit_data.name_id then
                for ID, mod in pairs(merge_data) do
                    if not mod.use_callback or (mod.use_callback and mod.use_callback()) then
                        if mod.UnitMods and mod.UnitMods[static_data.unit_data.name_id] then
                            table.merge(static_data.unit_data, mod.UnitMods[static_data.unit_data.name_id])
                        end
                        
                        if mod.UnitRemoval and mod.UnitRemoval[static_data.unit_data.name_id] then
                            statics[i] = nil
                        end
                    end
                end
            end
        end        
        
        for ID, mod in pairs(merge_data) do
            if not mod.use_callback or (mod.use_callback and mod.use_callback()) then
                if mod.NewUnits then
                    for i, new_unit in pairs(mod.NewUnits) do
                        table.insert(statics, {unit_data = new_unit})
                    end
                end
            end
        end
    end
end