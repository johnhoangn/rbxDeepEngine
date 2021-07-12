-- ConstrainedZeroSpring class, goal is always zero and we "pull" the end away from the goal

-- Dynamese (Enduo)
-- 07.07.2021



local exp = math.exp
local pi = math.pi
local ConstrainedSpring = require(script.Parent.ConstrainedSpring)
local ConstrainedZeroSpring = setmetatable({}, ConstrainedSpring)
ConstrainedZeroSpring.__index = ConstrainedZeroSpring


function ConstrainedZeroSpring.new(freq, x, min, max)
	return setmetatable(ConstrainedSpring.new(freq, x, min, max), ConstrainedZeroSpring)
end


function ConstrainedZeroSpring:Pull(x)
    self:SetValue(self.x + x)
end


function ConstrainedZeroSpring:PullTo(x)
	self:SetValue(x)
end


return ConstrainedZeroSpring