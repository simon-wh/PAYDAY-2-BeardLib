-- From: http://stackoverflow.com/questions/7183998/in-lua-what-is-the-right-way-to-handle-varargs-which-contains-nil
function table.pack(...)
    return {n = select("#", ...), ...}
end

function table.merge(og_table, new_table)
    if not new_table then
        return og_table
    end

    for i, data in pairs(new_table) do
        i = type(data) == "table" and data.index or i
        if type(data) == "table" and type(og_table[i]) == "table" then
            og_table[i] = table.merge(og_table[i], data)
        else
            og_table[i] = data
        end
    end
    return og_table
end

function table.map_indices(og_table)
    local tbl = {}
    for i=1, #og_table do
        table.insert(tbl, i)
    end
    return tbl
end

--When you want to merge but don't want to merge things like menu items together.
function table.careful_merge(og_table, new_table)
    for i, data in pairs(new_table) do
        i = type_name(data) == "table" and data.index or i
        if type_name(data) == "table" and type_name(og_table[i]) == "table" then
            og_table[i] = table.merge(og_table[i], data)
        else
            og_table[i] = data
        end
    end
    return og_table
end

function table.add_merge(og_table, new_table)
    for i, data in pairs(new_table) do
        i = (type(data) == "table" and data.index) or i
        if type(i) == "number" and og_table[i] then
            table.insert(og_table, data)
        else
            if type(data) == "table" and og_table[i] then
                og_table[i] = table.add_merge(og_table[i], data)
            else
                og_table[i] = data
            end
        end
    end
    return og_table
end

function table.add(t, items)
    for i, sub_item in ipairs(items) do
        if t[i] then
            table.insert(t, sub_item)
        else
            t[i] = sub_item
        end
    end
    return t
end

--[[
    Does a dynamic search on the table. Table being an XML table containing _meta values.
    To navigate through the table you'd write the `search_term` like this: "meta1/meta2/meta3".
    If you want to find a specific meta with value set to something you can do: "meta1/meta2;param1=true"
    The function returns you first the index of the result, then the table itself and then the table it's contained in.
]]

function table.search(tbl, search_term)
    local search_terms = {search_term}
    local parent_tbl

    if string.find(search_term, "/") then
        search_terms = string.split(search_term, "/")
    end

    local index
    for _, term in pairs(search_terms) do
        local term_parts = {term}
        if string.find(term, ";") then
            term_parts = string.split(term, ";")
        end
        local search_keys = {
            params = {}
        }
        for _, term in pairs(term_parts) do
            if string.find(term, "=") then
                local term_split = string.split(term, "=")
                search_keys.params[term_split[1]] = assert(loadstring("return " .. term_split[2]))()
                if search_keys.params[term_split[1]] == nil then
                    BeardLib:log(string.format("[ERROR] An error occurred while trying to parse the value %s", term_split[2]))
                end
            elseif not search_keys._meta then
                search_keys._meta = term
            end
        end

        local found_tbl = false
        for i, sub in ipairs(tbl) do
            if type(sub) == "table" then
                local valid = true
                if search_keys._meta and sub._meta ~= search_keys._meta then
                    valid = false
                end

                for k, v in pairs(search_keys.params) do
                    if sub[k] == nil or (sub[k] and sub[k] ~= v) then
                        valid = false
                        break
                    end
                end

                if valid then
                    parent_tbl = tbl
                    tbl = sub
                    found_tbl = true
                    index = i
                    break
                end
            end
        end
        if not found_tbl then
            return nil
        end
    end
    return index, tbl, parent_tbl
end

--[[
    A dynamic insert to a table from XML. `tbl` is the table you want to insert to, `val` is what you want to insert, and `pos_phrase`
    is a special string split into 2 parts using a colon. First part is position to insert which is: before, after, and inside.
    Second part is a search for the table you want to insert into basically the same string as in `table.search`.
    So, `pos_phrase` is supposed to look like this: "after:meta1" or "before:meta1" or "before:meta1/meta2", "inside:meta1", etc.
    The function will log a warning if the table search has failed.
--]]

function table.custom_insert(tbl, val, pos_phrase)
    if not pos_phrase then
        table.insert(tbl, val)
        return tbl
    end

    if tonumber(pos_phrase) ~= nil then
        table.insert(tbl, pos_phrase, val)
        return tbl
    else
        local phrase_split = string.split(pos_phrase, ":")
        local i, tbl, parent_tbl = table.search(tbl, phrase_split[2])

        if not i then
            BeardLib:Warn("Could not find table for relative placement. %s", pos_phrase)
        else
            local pos = phrase_split[1]
            if pos == "inside" then
                table.insert(tbl, val)
            else
                i = pos == "after" and i + 1 or i
                table.insert(parent_tbl, i, val)
            end
        end
        return parent_tbl
    end
end

local special_params = {
    "search",
    "mode",
    "insert",
    "index"
}

function table.script_merge(base_tbl, new_tbl)
    for i, sub in pairs(new_tbl) do
        if type(sub) == "table" then
            if tonumber(i) then
                if sub.search then
                    local mode = sub.mode
                    local index, found_tbl, parent_tbl = table.search(base_tbl, sub.search)
                    if found_tbl then
                        if not mode then
                            table.script_merge(found_tbl, sub)
                        elseif mode == "merge" then
                            for i, tbl in pairs(sub) do
                                if type(tbl) == "table" and tonumber(i) then
                                    table.merge(found_tbl, tbl)
                                    break
                                end
                            end
                        elseif mode == "replace" then
                            for i, tbl in pairs(sub) do
                                if type(tbl) == "table" and tonumber(i) then
                                    parent_tbl[index] = tbl
                                    break
                                end
                            end
                        elseif mode == "remove" then
                            if type(index) == "number" then
                                table.remove(parent_tbl, index)
                            else
                                parent_tbl[index] = nil
                            end
                        elseif mode == "insert" then
                            for i, tbl in pairs(sub) do
                                if type(tbl) == "table" and tonumber(i) then
                                    table.insert(found_tbl, tbl)
                                    break
                                end
                            end
                        end
                    end
                elseif sub.insert then --Same as below just fixes inconsistency with the stuff above. Basically, inserts the first table instead of the whole table.
                    for i, tbl in pairs(sub) do
                        if type(tbl) == "table" and tonumber(i) then
                            local parent_tbl = table.custom_insert(base_tbl, tbl, sub.insert)
                            if not parent_tbl[tbl._meta] then
                                parent_tbl[tbl._meta] = tbl
                            end     
                            break
                        end
                    end
                else
                    local parent_tbl = table.custom_insert(base_tbl, sub, sub.index)
                    if not parent_tbl[sub._meta] then
                        parent_tbl[sub._meta] = sub
                    end
                    for _, param in pairs(special_params) do
                        sub[param] = nil
                    end
                end
            end
        elseif not table.contains(special_params, i) then
            base_tbl[i] = sub
        end
    end
end

--allows both key and index to be removed, useful for tables cleaned by XML:Clean
function table.remove_key(tbl, key)
    if type(key) == "number" and #tbl >= key then
        table.remove(tbl, key)
    else
        tbl[key] = nil
    end
end

--like table delete only allows key values(doesn't force table.remove which accepts only indices)
function table.delete_value(tbl, value)
	local key = table.get_key(tbl, value)
	if key then
		table.remove_key(tbl, key)
	end
end