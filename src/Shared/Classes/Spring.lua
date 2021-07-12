-- Spring class, ripped from Roblox's camera scripts
-- Tweaked for our purposes

-- Dynamese (Enduo)
-- XX.YY.2020



local exp = math.exp
local pi = math.pi
local Spring = {}
Spring.__index = Spring


function Spring.new(freq, x)
	return setmetatable({
		freq = freq, -- Undamped frequency (Hz)
		x = x, -- Current position
		v = 0, -- Current velocity
		goal = x, -- Goal position
        delta = 0
	}, Spring)
end


function Spring:SetGoal(newGoal)
	self.goal = newGoal
end


function Spring:Step(dt)
	local freq = self.freq*2*pi -- Convert from Hz to rad/s
	local x = self.x
	local v = self.v
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

	if math.abs(x1) <= 0.01 then x1 = 0 end

	self.x = x1
	self.v = v1

    self.delta = self.goal - self.x

	return x1
end


return Spring