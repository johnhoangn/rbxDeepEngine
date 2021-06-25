-- Ready status manager
-- Dynamese(Enduo)
-- May 17, 2021

--[[

	Used to yield certain actions until user(s) are system-ready
	
	Usage:
	ReadyService:WaitReady(user)
	ReadyService:IsReady(user)
	
]]


local ReadyService = {}
local Players, Network


local Readied


-- Watches for a user's ready signal
-- @param user
-- @param dt
local function ReceiveReady(user, dt)
	Readied:Add(user, true)
	ReadyService.UserReadied:Fire(user)
end


-- Yields the thread until the user readies, or timeout
-- @param user
-- @param timeout == nil
-- @return user readied
function ReadyService:WaitReady(user, timeout)
	if (self:IsReady(user)) then
		return true
	else
		local readiedSignal = self.Classes.Signal.new()

		self.UserReadied:Connect(function(readiedUser)
			if (readiedUser == user) then
				readiedSignal:Fire(true)
				readiedSignal:Destroy()
			end
		end)

		if (timeout ~= nil) then
			self.Modules.ThreadUtil.Delay(timeout, function()
				readiedSignal:Fire(false)
			end)
		end

		return readiedSignal:Wait()
	end
end


-- @param user
-- @return if user is ready
function ReadyService:IsReady(user)
	return Readied:Contains(user)
end


function ReadyService:EngineInit()
	Players = self.RBXServices.Players
	Network = self.Services.Network
	
	Readied = self.Classes.LinkedList.new()
	
	self.UserReadied = self.Classes.Signal.new()
end


function ReadyService:EngineStart()
	Players.PlayerRemoving:Connect(function(user)
		Readied:Remove(user)
	end)
	
	self.Services.Network:HandleRequestType(Network.NetRequestType.Ready, ReceiveReady)
end


return ReadyService