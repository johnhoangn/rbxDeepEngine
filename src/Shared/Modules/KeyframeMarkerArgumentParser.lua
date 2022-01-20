-- Wow this is a long filename
-- Parses keyframemarker params defined in the Roblox animator utility
-- e.g. Marker = "Sound"; Param = "SoundClass = Effect, AssetID = 12"
-- Dynamese(enduo)
-- 12.23.2021


local Parser = {}


function Parser:Parse(str)
	local split = str:split(",")
	local args = {}

	for _, pair in ipairs(split) do
		pair = pair:split(" = ")
		args[pair[1]] = pair[2]
	end

	return args
end


return Parser