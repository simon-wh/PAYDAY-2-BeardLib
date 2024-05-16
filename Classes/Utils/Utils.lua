local Utils = {}
BeardLib.Utils = Utils

function Utils:RefreshCurrentNode()
    local selected_node = managers.menu:active_menu().logic:selected_node()
    managers.menu:active_menu().renderer:refresh_node(selected_node)
    local selected_item = selected_node:selected_item()
    selected_node:select_item(selected_item and selected_item:name())
    managers.menu:active_menu().renderer:highlight_item(selected_item)
end

function Utils:CheckParamsValidity(tbl, schema)
    local ret = true
    for i = 1, #schema.params do
        local var = tbl[i]
        local sc = schema.params[i]
        if not self:CheckParamValidity(schema.func_name, i, var, sc.type, sc.allow_nil) then
            ret = false
        end
    end
    return ret
end

function Utils:CheckParamValidity(func_name, vari, var, desired_type, allow_nil)
    if (var == nil and not allow_nil) or type(var) ~= desired_type then
        log(string.format("[%s] Parameter #%s, expected %s, got %s", func_name, vari, desired_type, tostring(var and type(var) or nil)))
        return false
    end

    return true
end

function Utils:GetSubValues(tbl, key)
    local new_tbl = {}
    for i, vals in pairs(tbl) do
        if vals[key] then
            new_tbl[i] = vals[key]
        end
    end

    return new_tbl
end

local searchTypes = {
    "Vector3",
    "Rotation",
	"Color",
	"SimpleClbk",
	"ClassClbk",
	"SafeClassClbk",
	"SafeClbk",
    "callback"
}

function Utils:normalize_string_value(value)
    if type(value) ~= "string" then
        return value
    end

	for _, search in pairs(searchTypes) do
		if string.begins(value, search) then
			value = loadstring("return " .. value)()
			break
		end
	end
	return value
end


function Utils:StringToValue(str, global_tbl, silent)
    local global_tbl = global_tbl or _G
    if string.find(str, "%.") then
        local global_tbl_split = string.split(str, "[.]")

        for _, str in pairs(global_tbl_split) do
            global_tbl = rawget(global_tbl, str)
            if not global_tbl then
                if not silent then
                    BeardLib:log("[ERROR] Key " .. str .. " does not exist in the current global table.")
                end
                return nil
            end
        end
    else
        global_tbl = rawget(global_tbl, str)
        if not global_tbl then
            if not silent then
                BeardLib:log("[ERROR] Key " .. str .. " does not exist in the current global table.")
            end
            return nil
        end
    end

    return global_tbl
end

Utils.StringToTable = Utils.StringToValue

--Use Utils.XML functions!
function Utils:RemoveAllSubTables(tbl)
    for i, sub in pairs(tbl) do
        if type(sub) == "table" then
            tbl[i] = nil
        end
    end
    return tbl
end

function Utils:RemoveAllNumberIndexes(tbl, shallow)
	if not tbl then return nil end

    if type(tbl) ~= "table" then
        return tbl
    end

	if shallow then
		for i, sub in ipairs(tbl) do
			tbl[i] = nil
		end
	else
	    for i, sub in pairs(tbl) do
	        if tonumber(i) ~= nil then
	            tbl[i] = nil
	        elseif type(sub) == "table" and not shallow then
	            tbl[i] = self:RemoveAllNumberIndexes(sub)
	        end
	    end
	end
    return tbl
end

function Utils:GetNodeByMeta(tbl, meta, multi)
    if not tbl then return nil end
    local t = {}
    for _, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            if multi then
                table.insert(t, v)
            else
                return v
            end
        end
    end

    return multi and t or nil
end

function Utils:GetIndexNodeByMeta(tbl, meta, multi)
    if not tbl then return nil end
    local t = {}
    for i, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            if multi then
                table.insert(t, i)
            else
                return i
            end
        end
    end

    return multi and t or nil
end

function Utils:CleanCustomXmlTable(tbl, shallow)
    if not tbl then return nil end

    for i, v in pairs(tbl) do
        if type(v) == "table" then
            if tonumber(i) == nil then
                tbl[i] = nil
            elseif not shallow then
                self:CleanCustomXmlTable(v, shallow)
            end
        end
    end

    return tbl
end

function Utils:RemoveNonNumberIndexes(tbl)
	if not tbl then return nil end

    if type(tbl) ~= "table" then
        return tbl
    end

    for i, _ in pairs(tbl) do
        if tonumber(i) == nil then
            tbl[i] = nil
        end
    end

    return tbl
end

function Utils:RemoveMetas(tbl, shallow)
	if not tbl then return nil end
	tbl._meta = nil

	if not shallow then
	    for i, data in pairs(tbl) do
	        if type(data) == "table" then
	            self:RemoveMetas(data, shallow)
	        end
	    end
	end
	return tbl
end
--Use Utils.XML functions!

local encode_chars = {
	["\t"] = "%09",
	["\n"] = "%0A",
	["\r"] = "%0D",
	[" "] = "+",
	["!"] = "%21",
	['"'] = "%22",
	[":"] = "%3A",
	["{"] = "%7B",
	["}"] = "%7D",
	["["] = "%5B",
	["]"] = "%5D",
	[","] = "%2C"
}
function Utils:UrlEncode(str)
	if not str then
		return ""
	end

	return string.gsub(str, ".", encode_chars)
end

function Utils:ModExists(name)
    return self:FindMod(name) ~= nil
end

function Utils:ModLoaded(name)
    local mod = self:FindMod(name)
    return mod and mod:IsEnabled() or false
end

function Utils:FindMod(name)
    for _, mod in pairs(BeardLib.Mods) do
        if mod.Name == name then
            return mod
        end
    end
    return nil
end

function Utils:FindModWithMatchingPath(path)
    for _, mod in pairs(BeardLib.Mods) do
        if path:find(mod.ModPath) ~= nil then
            return mod
        end
    end
    return nil
end

function Utils:FindModWithPath(path)
    for _, mod in pairs(BeardLib.Mods) do
        if mod.ModPath == path then
            return mod
        end
    end
    return nil
end

function Utils:GetMapByJobId(job_id)
    for _, mod in pairs(BeardLib.Mods) do
        if mod._modules then
            for _, module in pairs(mod._modules) do
                if module.type_name == "narrative" and module._config and module._config.id == job_id then
                    return mod
                end
            end
        end
    end
    return nil
end

function Utils:GetNameFromModPath(path)
    return path:match("mods/(.+)/")
end

function NotNil(...)
    local args = {...}
    for k, v in pairs(args) do
        if v ~= nil or k == #args then
            return v
        end
    end
end

--Pretty much CoreClass.type_name with support for tables.
function type_name(value)
    local t = type(value)
    if t == "userdata" or t == "table" and value.type_name then
        return value.type_name
    end
    return t
end

--Safe call
function Utils:SetupXAudio()
    if blt and blt.xaudio then
        blt.xaudio.setup()
    end
end

--- Makes a pagination (table) in the style of 1 .. 3 [4] 5 .. 7
--- Page is the page, pages is how many pages and offset_buttons is how many buttons to put on both sides of the current page.
function Utils:MakePagination(page, pages, offset_buttons)
    -- If this simply follows a pattern of 1 2 3 ... n don't bother.
    if page == 1 then
        local size = offset_buttons*2+3
        if pages <= size then
            return pages > 1 and table.range(1, pages) or {1}
        else
            local ret = table.range(1, size-1)
            table.insert(ret, pages)
            return ret
        end
    end

    local pagination = {page}

    -- We have 2 different offsets so we can handle cases when the page is equal to one of the limits.
    local offset_plus = offset_buttons + (page == pages and 1 or 0)
    local offset_minus = offset_buttons + (page == 1 and 1 or 0)

    for i = 1, offset_plus do
        local insert_page = page + i
        if insert_page >= pages then
            -- We can't go forward, let's try backward.
            insert_page = page - offset_minus - ((offset_plus+1)- i)
        end
        if insert_page > 0 then
            table.insert(pagination, insert_page)
        end
    end

    for i = 1, offset_minus do
        local insert_page = page - i
        if insert_page <= 1 then
            --We can't go backward, let's try forward.
            insert_page = page + offset_plus + ((offset_minus+1)- i)
        end
        if insert_page < pages then
            table.insert(pagination, insert_page)
        end
    end

    -- If we haven't added the limits then let's add them.
    if not table.contains(pagination, 1) then
        table.insert(pagination, 1)
    end
    if not table.contains(pagination, pages) then
        table.insert(pagination, pages)
    end

    -- We surely have it messy so let's sort it correctly.
    table.sort(pagination)

    return pagination
end