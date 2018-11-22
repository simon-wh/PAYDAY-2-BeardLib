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

function table.search(tbl, search_term)
    local search_terms = {search_term}

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
                if not search_keys.params[term_split[1]] then
                    BeardLib:log(string.format("[ERROR] An error occured while trying to parse the value %s", term_split[2]))
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
                    if i == 1 then
                        if tbl[sub._meta] then
                            tbl[sub._meta] = sub
                        end
                    end

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
    return index, tbl
end

function table.custom_insert(tbl, add_tbl, pos_phrase)
    if not pos_phrase then
        table.insert(tbl, add_tbl)
        return
    end

    if tonumber(pos_phrase) ~= nil then
        table.insert(tbl, pos_phrase, add_tbl)
    else
        local phrase_split = string.split(pos_phrase, ":")
        local i, _ = table.search(tbl, phrase_split[2])

        if not i then
            BeardLib:log(string.format("[ERROR] Could not find table for relative placement. %s", pos_phrase))
            table.insert(tbl, add_tbl)
        else
            i = phrase_split[1] == "after" and i + 1 or i
            table.insert(tbl, i, add_tbl)
        end
    end
end

local special_params = {
    "search",
    "mode",
    "index"
}

function table.script_merge(base_tbl, new_tbl)
    for i, sub in pairs(new_tbl) do
        if type(sub) == "table" then
            if tonumber(i) then
                if sub.search then
                    local mode = sub.mode
                    local index, found_tbl = table.search(base_tbl, sub.search)
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
                                    base_tbl[index] = tbl
                                    break
                                end
                            end
                        elseif mode == "remove" then
                            if type(index) == "number" then
                                table.remove(base_tbl, index)
                            else
                                base_tbl[index] = nil
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
                else
                    table.custom_insert(base_tbl, sub, sub.index)
                    if not base_tbl[sub._meta] then
                        base_tbl[sub._meta] = sub
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