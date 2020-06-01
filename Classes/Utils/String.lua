function string.pretty2(str)
    str = tostring(str)
    return str:gsub("([^A-Z%W])([A-Z])", "%1 %2"):gsub("([A-Z]+)([A-Z][^A-Z$])", "%1 %2")
end

function string.key(str)
    local ids = Idstring(str)
    local key = ids:key()
    return tostring(key)
end

function string.escape_special(str)
    return str:gsub("([^%w])", "%%%1")
end

function prnt(...)
    local s = ""
    for _, v in pairs({...}) do
        s = s .. "  " .. tostring(v)
    end
    log(s)
end

function prntf(s, ...)
    local strs = {}
    for _, v in pairs({...}) do
        table.insert(strs, tostring(v))
    end
    log(string.format(s, unpack(strs)))
end