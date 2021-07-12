-- ConstrainedSpring class ripped from one of Roblox's camera scripts
-- Tweaked for our purposes

-- Dynamese (Enduo)
-- XX.YY.2020



local clamp = math.clamp
local exp = math.exp
local pi = math.pi
local ConstrainedSpring = {}
ConstrainedSpring.__index = ConstrainedSpring


function ConstrainedSpring.new(freq, x, minValue, maxValue)
	x = clamp(x, minValue, maxValue)
	return setmetatable({
		freq = freq, -- Undamped frequency (Hz)
		x = x, -- Current position
		v = 0, -- Current velocity
		minValue = minValue, -- Minimum bound
		maxValue = maxValue, -- Maximum bound
		goal = x, -- Goal position
        delta = 0
	}, ConstrainedSpring)
end


function ConstrainedSpring:SetGoal(newGoal)
	self.goal = clamp(newGoal, self.minValue, self.maxValue)
end


function ConstrainedSpring:SetValue(x)
    self.x = clamp(x, self.minValue, self.maxValue)
end


function ConstrainedSpring:Step(dt)
	local freq = self.freq*2*pi -- Convert from Hz to rad/s
	local x = self.x
	local v = self.v
	local minValue = self.minValue
	local maxValue = self.maxValue
	local goal = self.goal

	-- Solve the spring ODE for position and velocity after time t, assuming critical damping:
	--   2*f*x'[t] + x''[t] = f^2*(g - x[t])
	-- Knowns are x[0] and x'[0].
	-- Solve for x[t] and x'[t].

	local offset = goal - x
	local step = freq*dt
	local decay = exp(-step)

	local x1 = goal + (v*dt - offset*(step + 1))*decay
	local v1 = ((offset*freq - v)*step + v)*decay

	-- Constrain
	if x1 < minValue then
		x1 = minValue
		v1 = 0
	elseif x1 > maxValue then
		x1 = maxValue
		v1 = 0
	end

	if math.abs(x1) <= 0.1 then x1 = 0 end

	self.x = x1
	self.v = v1

    self.delta = self.goal - x

	return x1
end


return ConstrainedSpring