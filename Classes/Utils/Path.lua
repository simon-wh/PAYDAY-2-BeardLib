Path = {}

path = Path
BeardLib.Utils.Path = Path

Path._separator_char = "/"

function Path:GetDirectory(path)
	if not path then return nil end
	local split = string.split(self:Normalize(path), self._separator_char)
	table.remove(split)
	return table.concat(split, self._separator_char)
end

function Path:GetFileName(str)
	if string.ends(str, self._separator_char) then
		return nil
	end
	str = self:Normalize(str)
	return table.remove(string.split(str, self._separator_char))
end

function Path:GetFilePathNoExt(str)
    if string.find(str, "%.") then
        local split = string.split(str, "%.")
        table.remove(split)
        str = table.concat(split, ".")
    end
    return str
end

function Path:GetFileNameWithoutExtension(str)
    local filename = self:GetFileName(str)
    if not filename then
        return nil
    end

    if string.find(filename, "%.") then
        local split = string.split(filename, "%.")
        table.remove(split)
        filename = table.concat(split, ".")
    end
    return filename
end

Path.GetFileNameNoExt = Path.GetFileNameWithoutExtension

function Path:GetFileExtension(str)
	local filename = self:GetFileName(str)
	if not filename then
		return nil
	end
    local ext = ""
	if string.find(filename, "%.") then
		local split = string.split(filename, "%.")
		ext = split[#split]
	end
	return ext
end

function Path:Normalize(str)
	if not str then return nil end

	--Clean seperators
	str = string.gsub(str, ".", {
		["\\"] = self._separator_char,
	})

	str = string.gsub(str, "([%w+]/%.%.)", "")
	return str
end

function Path:CombineDir(...)
	local s = self:Combine(...)
	if not string.ends(s, "/") then
		s = s .. "/"
	end
	return s
end

function Path:Combine(start, ...)
	local paths = {...}
	local final_string = start
    for _, path_part in pairs(paths) do
        path_part = tostring(path_part)
		if string.begins(path_part, ".") then
			path_part = string.sub(path_part, 2, #path_part)
		end
		if not string.ends(final_string, self._separator_char) and not string.begins(path_part, self._separator_char) then
			final_string = final_string .. self._separator_char
		end
		final_string = final_string .. path_part
	end

	return self:Normalize(final_string)
end
