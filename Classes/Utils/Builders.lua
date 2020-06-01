BeardLib.Builders = {}
_G.builders = BeardLib.Builders

BeardLib.Builders.StringBuilder = {}
_G.string_builder = BeardLib.Builders.StringBuilder
local StringBuilder = BeardLib.Builders.StringBuilder

function StringBuilder:newStringBuilder(string)
    self.string = tostring(string) or ""
    return self
end

function StringBuilder:append(string)
    self.string = self.string .. tostring(string)
    return self
end

--- Inserts characters after an index.
-- Returns self.
-- @param offset: offset to insert at
-- @param string: string to insert
-- @see StringBuilder
function StringBuilder:insert(offset, string)
    self.string = string.sub(self.string, 1, offset - 1)
        .. tostring(string)
        .. string.sub(self.string, offset + 1)

    return self
end

--- Deletes characters within two indexes.
-- Returns self.
-- @param start_index start from this index, must not be nil
-- @param end_index end on this index, can be nil
-- @see StringBuilder
function StringBuilder:delete(start_s, end_s)
    if not start_s then error("starting index can't be nil") end
    end_s = end_s or nil
    local find_str = string.sub(self.string, start_s, end_s)
    self.string = string.gsub(self.string, find_str, "")
    return self
end

--- Get the length of built string.
-- Returns the length of the string, is terminal.
-- @see StringBuilder
function StringBuilder:length()
    return string.length(self.string)
end

function StringBuilder:build()
    return tostring(self.string)
end

-- Usage
--[[ local test = StringBuilder:newStringBuilder("number 15\n")
    :append("burger king foot lettuce\n")
    :append("the last thing you'd want")
    :append(" in your burger king\n")
    :append("is someone's foot fungus")
    :insert(95, "old meme")
    :delete(103)
    :build()

log("BEARDLIB: " .. tostring(test)) ]]