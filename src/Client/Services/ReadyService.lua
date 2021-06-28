-- Ready signaller
-- Dynamese(Enduo)
-- May 17, 2021

--[[

	Used to signal to the server that we are now in a "ready" state
	Ready means to have completely started all systems
	
	Usage:
	ReadyService:SignalReady()
	
]]



local Ready = {}
local Network


-- Tells the server we are ready
function Ready:SignalReady()
	Network:RequestServer(Network.NetRequestType.Ready):Wait()
end


function Ready:EngineInit()
	Network = self.Services.Network
end


function Ready:EngineStart()
end


return Ready