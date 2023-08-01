---@class Version
---A class for a richer version comparsion
---This replaces simple number comparsion (Version > 4.5) with a class that's able to use versions like 4.5.1
---The class overwrites the __eq, __lt, and __le to allow you compare them as they were regular versions.
---Example:
--[[
    if BeardLib.Version > Version:new("4.6.1") then
        return true
    end
--]]
---Unfortunately, luajit doesn't allow for comparison of tables and numbers/strings unlike regular lua does.
---Solution is to wrap the version like in the eaxmple.
---You can write 1.0, 1.5.1, 1.5.1.1 and so on. For alpha, beta, rc, you can write 1.5.1-beta and if you have multiple of them 1.5.1-beta.1.
Version = Version or class()
Version.type_name = 'Version'
local METADATA_CONVERT = {
	alpha = 1, beta = 2, rc = 3, full = 4
}

local DEFAULT_METADATA = {
	state = METADATA_CONVERT.full, number = 0
}

function Version:init(parse)
	self._value = tostring(parse)
end

function Version:VersionTable(ver)
	if not ver and not self._value then
		return { numbers = { 1 } }
	end

	ver = ver or self
	local str = type_name(ver) == "Version" and ver._value or tostring(ver)
	if string.begins(str, "v") or string.begins(str, "r") then --v1 = 1 / r1 = 1
		str = str:sub(2)
	end
	if string.begins(str, ".") then -- .1 = 0.1
		str = "0"..str -- .1 = 0.1
	end
	local numbers_str, metadata = unpack(string.split(str, "-")) -- Splits 1.0.0-beta.1
	local numbers_tbl = string.split(numbers_str, "%.") -- Splits 1.0.0

	local tbl = {numbers = {}}
	if metadata then
		local name, number = unpack(string.split(metadata, "%.")) --Splits beta.1
		tbl.metadata = {state = self.metadata_convert[name] or 4, number = number or 0}
	end

	for _, v in pairs(numbers_tbl) do
		table.insert(tbl.numbers, tonumber(v))
	end
	
	return tbl
end

---@deprecated
function Version:VersionTables(b)
	return self:VersionTable(), b:VersionTable()
end

function Version:__tostring()
	return self._value
end

function Version:Compare(other, ret_clbk, default_ret)
	local tbl, other_tbl = self:VersionTable(), other:VersionTable()

	local largest_len = math.max(#tbl.numbers, #other_tbl.numbers)

	for i = 1, largest_len do
		local a = tbl.numbers[i] or 0
		local b = other_tbl.numbers[i] or 0
		if a ~= b then
			return ret_clbk and ret_clbk(a, b) or false
		end
	end

	if tbl.metadata or other_tbl.metadata then
		local metadata = tbl.metadata or DEFAULT_METADATA
		local other_metadata = other_tbl.metadata or DEFAULT_METADATA

		if metadata.state ~= other_metadata.state then
			return ret_clbk and ret_clbk(metadata.state, other_metadata.state) or false
		elseif metadata.number ~= other_metadata.number then
			return ret_clbk and ret_clbk(metadata.number, other_metadata.number) or false
		end
	end

	return NotNil(default_ret, true)
end

function Version:__eq(other)
	return self:Compare(other)
end

function Version:__le(other)
	return self:Compare(other, function(a, b)
		return a <= b
	end, true)
end

function Version:__lt(other)
	return self:Compare(other, function(a, b)
		return a < b
	end, false)
end
