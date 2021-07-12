-- ZeroSpring class, goal is always zero and we "pull" the end away from the goal

-- Dynamese (Enduo)
-- 07.07.2021



local exp = math.exp
local pi = math.pi
local Spring = require(script.Parent.Spring)
local ZeroSpring = setmetatable({}, Spring)
ZeroSpring.__index = ZeroSpring


function ZeroSpring.new(freq, x)
	return setmetatable(Spring.new(freq, x), ZeroSpring)
end


function ZeroSpring:Pull(x)
	self.x += x
end


function ZeroSpring:PullTo(x)
	self.x = x
end


return ZeroSpring