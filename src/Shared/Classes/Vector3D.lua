-- Vector3D Class
-- Intended to potentially optimize certain components of base Vector3 by
--  storing component vectors in a table rather than userdata

-- Dynamese (Enduo)
-- 07.03.2021


local Vector3D = {}


-- Constructor
-- @param x <float>
-- @param y <float>
-- @param z <float>
-- @returns <Vector3D>
function Vector3D.new(x, y, z)
	local self = setmetatable({
		X = x or 0;
        Y = y or 0;
        Z = z or 0;
	}, Vector3D)

	return self
end


-- Generates a base Vector3 from this Vector3D
-- @returns <Vector3>
function Vector3D:ToVector3()
    return Vector3.new(self.X, self.Y, self.Z)
end


function Vector3D.__index(self, index)
    if (index == "Magnitude") then
        return math.sqrt(self.X^2 + self.Y^2 + self.Z^2)

    elseif (index == "Squared") then
        -- Used to compare relative distances without square-rooting
        return self.X^2 + self.Y^2 + self.Z^2

    elseif (rawget(self[index] == nil)) then
        error(index .. " is not a valid member of " .. "Vector3D")
    end
end


return Vector3D
