SequenceData = SequenceData or class(ScriptData)

function SequenceData:init(ID)
    self.super.init(self, ID)
    self._type = "sequence"
    self._extension = Idstring("sequence_manager")
end

function SequenceData:CreateMod(ModID, path, data, extension)
    self.super.CreateMod(self, ModID, path, data, extension)
    local pathK = path:key()
    
    self._mods[pathK][ModID].SequenceMods = self._mods[pathK][ModID].SequenceMods or {}
    self._mods[pathK][ModID].NewSequences = self._mods[pathK][ModID].NewSequences or {}
end
	
function SequenceData:AddSequenceMod(ModID, SequenceFile, SequenceName, data)
    local seqK = SequenceFile:key()
    
    if not self:IsModRegistered() then
		BeardLib:log("ERROR: SequenceMod ID: " .. ModID .. " not registered")
		return
	end
    
	if self._mods[seqK][ModID].SequenceMods[SequenceName] then
		table.merge(self._mods[seqK][ModID].SequenceMods[SequenceName], Data)
	else
		self._mods[seqK][ModID].SequenceMods[SequenceName] = Data
	end
end
	
function SequenceData:AddSequence(ModID, Data, SequenceFile)
    local seqK = SequenceFile:key()
    
    if not self:IsModRegistered() then
		BeardLib:log("ERROR: SequenceMod ID: " .. ModID .. " not registered")
		return
	end
    
    local new_sequence = {}
    
    new_sequence:merge(Data)
    
    table.insert(self._mods[seqK][ModID].NewSequences, new_sequence)
	--self._mods[seqK][ModID].new_data[(#self._mods[seqK][ModID].new_data) + 1] = Data
end

function SequenceData:ProcessScriptData(data, path, extension)
    if extension ~= self._extension then
        return
    end

    if not self._sorted then
        self:SortMods()
    end
    
    local pathK = path:key()

	local merge_data = self._mods[pathK]
	if not merge_data then
		return
	end
    
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

function SequenceData:SortMods()
    for i, seq_modifier in pairs(self._mods) do
        table.sort(seq_modifier, function(a, b) 
			return a.priority < b.priority
		end)
	end
    self._sorted = true
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