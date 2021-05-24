--[[

	USE THIS DEBRIS INSTEAD OF game:GetService("Debris") 

]]


local Debris = {}
local ThreadUtil


-- Deletes a thing, defined here to avoid anon func memory usage
-- @param instance
local function DeleteInstance(instance)
	instance:Destroy()
end


function Debris:AddItem(instance, t)
	ThreadUtil.Delay(t, DeleteInstance, instance)
end


function Debris:EngineInit()
	ThreadUtil = self.Modules.ThreadUtil
end


function Debris:EngineStart()
	
end


return Debris