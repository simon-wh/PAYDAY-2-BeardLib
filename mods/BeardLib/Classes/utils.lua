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
    local sqw = w * w
    local sqx = x * x
    local sqy = y * y
    local sqz = z * z

    local normal = math.sqrt(sqw + sqx + sqy + sqz)
    local pole_result = (x * z) + (y * w)

    if (pole_result > (0.5 * normal)) then --singularity at north pole
        local ry = math.pi/2 --heading/yaw?
        local rz = 0 --attitude/roll?
        local rx = 2 * math.atan2(x, w) --bank/pitch?
        return Rotation(rx, ry, rz)
    end
    
    if (pole_result < (-0.5 * normal)) then --singularity at south pole
        local ry = -math.pi/2
        local rz = 0
        local rx = -2 * math.atan2(x, w)
        return Rotation(rx, ry, rz)
    end

    local r11 = 2*(x*y + w*z)
    local r12 = sqw + sqx - sqy - sqz
    local r21 = -2*(x*z - w*y)
    local r31 = 2*(y*z + w*x)
    local r32 = sqw - sqx - sqy + sqz

    local rx = math.atan2( r31, r32 )
    local ry = math.asin ( r21 )
    local rz = math.atan2( r11, r12 )

    return Rotation(rx, ry, rz)



    --[[local yaw = math.atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z))
    local pitch = math.asin(2 * (w * y - z * x))
    local roll = math.atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y))
    
    return Rotation(yaw, pitch, roll)]]--
end