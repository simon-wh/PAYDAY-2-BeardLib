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

function string.key(str)
    local ids = Idstring(str)
    local key = ids:key()
    return tostring(key)
end

function math.EulerToQuarternion(x, y, z)
    local quad = {
        math.cos(z / 2) * math.cos(y / 2) * math.cos(x / 2) + math.sin(z / 2) * math.sin(y / 2) * math.sin(x / 2),
        math.sin(z / 2) * math.cos(y / 2) * math.cos(x / 2) - math.cos(z / 2) * math.sin(y / 2) * math.sin(x / 2),
        math.cos(z / 2) * math.sin(y / 2) * math.cos(x / 2) + math.sin(z / 2) * math.cos(y / 2) * math.sin(x / 2),
        math.cos(z / 2) * math.cos(y / 2) * math.sin(x / 2) - math.sin(z / 2) * math.sin(y / 2) * math.cos(x / 2),
    }
    return quad
end

function math.QuaternionToEuler(x, y, z, w)
    local yaw = math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z))
    local pitch = math.asin(2 * (w * y - z * x))
    local roll = math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y))
    
    return Rotation(yaw, pitch, roll)
end