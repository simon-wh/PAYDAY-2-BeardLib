function table.merge(og_table, new_table)
	for i, data in pairs(new_table) do
		if type(data) == "table" and og_table[i] then
			og_table[i] = table.merge(og_table[i], data)
		else
			og_table[i] = data
		end
	end
	return og_table
end