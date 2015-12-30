SequenceData = SequenceData or class(ScriptData)

function SequenceData:init(ID)
    self.super.init(self, ID)
    self._type = "Sequence"
    self._extension = Idstring("sequence_manager")
end

	
function SequenceData:AddSequenceMod(ModID, SequenceName, data)
    if not self:IsModRegistered(ModID) then
		BeardLib:log("ERROR: SequenceMod ID: " .. ModID .. " not registered")
		return
	end
    self._mods[ModID].SequenceMods = self._mods[ModID].SequenceMods or {}
    self._mods[ModID].SequenceMods[SequenceName] = self._mods[ModID].SequenceMods[SequenceName] or {}
    table.merge(self._mods[ModID].SequenceMods[SequenceName], data)
end
	
function SequenceData:AddSequence(ModID, data)
    if not self:IsModRegistered(ModID) then
		BeardLib:log("ERROR: SequenceMod ID: " .. ModID .. " not registered")
		return
	end
    self._mods[ModID].NewSequences = self._mods[ModID].NewSequences or {}
    table.insert(self._mods[ModID].NewSequences, data)
end

function SequenceData:ProcessScriptData(data, path, extension)
    if extension ~= self._extension then
        return
    end
    
    local pathK = path:key()

	local merge_data = self:GetScriptDataMods(pathK, extension:key())
    
	for name, group in pairs(data) do
		if type(group) == "table" then
			BeardLib.CurrentGroupName = name
			for _, mod in pairs(merge_data) do
				if type(mod) == "table" then
					if not mod.use_callback or (mod.use_callback and mod.use_callback()) then
						if mod.NewSequences then
							for i, sequence in pairs(mod.NewSequences) do
								self:ApplyNewSequence(group, sequence)
							end
						end
						if mod.SequenceMods then
							self:ApplySequenceMod(group, mod.SequenceMods)
						end
					end
				end
			end
		end
	end
end
		
function SequenceData:ApplySequenceMod(group_data, SequenceMods)
	for name, sequence in pairs(SequenceMods) do
		local ElementMods, NewElements
        local cSequence = deep_clone(sequence)
        
		if sequence.ElementMods then
			ElementMods = deep_clone(sequence.ElementMods)
			cSequence.ElementMods = nil
		end
        
		if sequence.NewElements then
			NewElements = deep_clone(sequence.NewElements)
			cSequence.NewElements = nil
		end
        
		self:MergeSequence(group_data, name, cSequence, ElementMods, NewElements)
	end
end

function SequenceData:ApplyNewSequence(group_data, sequence_data)
	local top_value = table.maxn(group_data)
	group_data[top_value + 1] = sequence_data
end

function SequenceData:MergeSequence(group_data, name, ElementMods, search_ElementMods, NewElements)
	for name1, sequence in pairs(group_data) do
		if type(sequence) == "table" and sequence.name == name then
			table.merge(sequence, ElementMods)
			self:ApplySequenceModDataMod(sequence, search_ElementMods)
			self:ApplySequenceNewDataMod(sequence, NewElements)
		end
	end
end
    
function SequenceData:ApplySequenceModDataMod(sequence_data, ElementMods)
	if ElementMods then
		for name, data in pairs(sequence_data) do
			if type(data) == "table" and ElementMods[data.name] then
				local search_ElementMods = ElementMods[data.name]
				if type(ElementMods) == "table" then
					table.merge(data, search_ElementMods)
				else
					BeardLib:log("ERROR: Sequence(" .. sequence_data.name .. ") ElementMod must be a table!")
				end
			end
		end
	end
end		
	
function SequenceData:ApplySequenceNewDataMod(sequence_data, NewElements)
	if NewElements then
		local MaxValue = table.maxn(sequence_data)
		for i, data in pairs(NewElements) do
			if tonumber(i) ~= nil then
				MaxValue = MaxValue + 1
				sequence_data[MaxValue] = data
			else
				-- need to add overwrite var check
                if sequence_data[i] then
                    BeardLib:log("Error: " .. i .. " Already exists, continuing with overwrite")
                end
                
				sequence_data[i] = data
			end
		end
	end
end