ScriptDataProcessorBase = ScriptDataProcessorBase or class()

Hooks:Register("ScriptDataProcessorBasePostInit")

function ScriptDataProcessorBase:init(ID)
    self._id = id or "default"
    self:CreateScriptDataHooks()
    self._mods = {}
end

function ScriptDataProcessorBase:CreateScriptDataHooks()
    Hooks:Add("BeardLibProcessScriptData", "BeardLibProcessScriptDataBase|" .. self._id, function(PackManager, extension, filepath, data)
        self:ProcessScriptData(PackManager, extension, filepath, data)
    end)
end

function ScriptDataProcessorBase:ProcessScriptData(PackManager, extension, filepath, data)
    for name, group in pairs(data) do
		if type(group) == "table" then
			for _, mod in pairs(merge_data) do
				if type(mod) == "table" then
					if not mod.use_callback or (mod.use_callback and mod.use_callback()) then
						if mod.new_data then
							for i, sequence in pairs(mod.new_data) do
								self:ApplyNewSequence(group, sequence)
							end
						end
						if mod.mod_data then
							self:ApplySequenceMod(group, mod.mod_data)
						end
					end
				end
			end
		end
	end
end

function ScriptDataProcessorBase:GetModData(filepath, extension)
    
    
end

function ScriptDataProcessorBase:CreateMod(filepath, extension, mod_id)
    self._mods[extension] = self._mods[extension] or {}
    self._mods[extension][filepath] = self._mods[extension][filepath] or {}
    self._mods[extension][filepath][mod_id] = self._mods[extension][filepath][mod_id] or {}
end

function ScriptDataProcessorBase:RemoveMod(filepath, extension, mod_id)
    if self._mods[extension] and self._mods[extension][filepath] and self._mods[extension][filepath][mod_id] then
        self._mods[extension][filepath][mod_id] = nil
    end
end

function ScriptDataProcessorBase:AddVariableMod()
    
end
	
BeardLib.sequence_mods = BeardLib.sequence_mods or {}
	
Hooks:Add("BeardLibSequenceScriptData", "BeardLibProcessSequenceData", function(PackManager, data_type, data_name, data) 
	BeardLib:ProcessSequenceData(data, data_name)
end)
	
function BeardLib:MergeSequence(group_data, name, mod_data, search_mod_data, new_data)
	for name1, sequence in pairs(group_data) do
		if type(sequence) == "table" and sequence.name == name then
			table.merge(sequence, mod_data)
			log("merging sequence")
			self:ApplySequenceModDataMod(sequence, search_mod_data)
			self:ApplySequenceNewDataMod(sequence, new_data)
		end
	end
end

function BeardLib:ProcessSequenceData(data, name)
	local merge_data = BeardLib.sequence_mods[tostring(name:key())]
	if not merge_data then
		return
	end
	--SaveTable(data, "BeforeModtable.txt")
	log("Mod exists")
	for name, group in pairs(data) do
		if type(group) == "table" then
			BeardLib.CurrentGroupName = name
			for _, mod in pairs(merge_data) do
				if type(mod) == "table" then
					if not mod.use_callback or (mod.use_callback and mod.use_callback()) then
						if mod.new_data then
							for i, sequence in pairs(mod.new_data) do
								self:ApplyNewSequence(group, sequence)
							end
						end
						if mod.mod_data then
							self:ApplySequenceMod(group, mod.mod_data)
						end
					end
				end
			end
		end
	end
	--SaveTable(data, "AfterModtable.txt")
end
		
function BeardLib:ApplySequenceMod(group_data, sequence_mod_data)
	for name, sequence in pairs(sequence_mod_data) do
		local mod_data
		local new_data
		if sequence.mod_data then
			mod_data = deep_clone(sequence.mod_data)
			sequence.mod_data = nil
		end
		if sequence.new_data then
			new_data = deep_clone(sequence.new_data)
			sequence.new_data = nil
		end
		self:MergeSequence(group_data, name, sequence, mod_data, new_data)
		--[[for name1, group_sequence in pairs(group_data) do
			if type(group_sequence) == "table" and group_sequence.name == name then
				self:ApplyModDataMod(group_sequence, mod_data)
				self:ApplyNewDataMod(group_sequence, new_data)
			end
		end]]--
	end
end
	
function BeardLib:ApplySequenceModDataMod(sequence_data, mod_data)
	if mod_data then
		for name, data in pairs(sequence_data) do
			if type(data) == "table" and mod_data[data.name] then
				local search_mod_data = mod_data[data.name]
				if type(search_mod_data) == "table" then
					table.merge(data, search_mod_data)
				else
					BeardLib:log("ERROR: Sequence(" .. sequence_data.name .. "Mod) Mod Data must be a table!")
				end
			end
		end
	end
end		
	
function BeardLib:ApplySequenceNewDataMod(sequence_data, new_data)
	if new_data then
		local MaxValue = table.maxn(sequence_data)
		for i, data in pairs(new_data) do
			if tonumber(i) ~= nil then
				MaxValue = MaxValue + 1
				sequence_data[MaxValue] = data
			else
				-- need to add overwrite var check
				sequence_data[i] = data
			end
		end
	end
end	
	
function BeardLib:ApplyNewSequence(group_data, sequence_data)
	local top_value = table.maxn(group_data)
	group_data[top_value + 1] = sequence_data
end
	
function BeardLib:CreateSequenceMod(SequenceFile, ModID, Data)
	BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())] = BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())] or {}
	BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())].sorted = false
	BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID] = BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID] or {}
	BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID].priority = 0
	BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID].mod_data = BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID].mod_data or {}
	BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID].new_data = BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID].new_data or {}
	table.merge(BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID], Data)
end
	
function BeardLib:AddSequenceMod(SequenceFile, ModID, SequenceName, Data)
	if not BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())] and not BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID] then
		BeardLib:log("ERROR: SequenceMod ID: " .. ModID .. " not registered")
		return
	end
	if BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID].mod_data[SequenceName] then
		table.merge(BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID].mod_data[SequenceName], Data)
	else
		BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID].mod_data[SequenceName] = Data
	end
end
	
function BeardLib:AddSequence(SequenceFile, ModID, SequenceName, Data)
	if not BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())] and not BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID] then
		BeardLib:log("ERROR: SequenceMod ID: " .. ModID .. " not registered")
		return
	end
	BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID].new_data[#BeardLib.sequence_mods[tostring(Idstring(SequenceFile):key())][ModID].new_data + 1] = Data
end