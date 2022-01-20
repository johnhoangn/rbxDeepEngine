-- Single location to put functions that operate on player joining/leaving
-- Enduo(Dynamese)
-- 12.11.21



local PlayerService = { Priority = 950 }


local Players
local JoinTasks, LeaveTasks


function PlayerService:ExecuteJoinTasks(user)
	for _name, joinTask in JoinTasks:KeyIterator() do
		if (joinTask.Processed[user]) then continue end
		--self:Print("Executing", _name, "for", user)
		joinTask.Processed[user] = true
		self.Modules.ThreadUtil.SpawnNow(joinTask.Callback, user)
	end
end


function PlayerService:ExecuteLeaveTasks(user)
	for _, leaveTask in LeaveTasks:KeyIterator() do
		self.Modules.ThreadUtil.SpawnNow(leaveTask, user)
	end
end


function PlayerService:AddJoinTask(callback, name)
	assert(name, "nil name")
	assert(callback, "nil callback")
	assert(JoinTasks:Get(name) == nil, "redundant taskname " .. name)
	JoinTasks:Add(name, {
		Callback = callback;
		Processed = {};
	})

	for _, user in ipairs(Players:GetPlayers()) do
		PlayerService:ExecuteJoinTasks(user)
	end
end


function PlayerService:AddLeaveTask(callback, name)
	assert(name, "nil name")
	assert(callback, "nil callback")
	LeaveTasks:Add(name, callback)
end


function PlayerService:EngineInit()
	JoinTasks = self.Classes.IndexedMap.new()
	LeaveTasks = self.Classes.IndexedMap.new()

	Players = self.RBXServices.Players
end


function PlayerService:EngineStart()
	Players.PlayerAdded:Connect(function(user)
		PlayerService:ExecuteJoinTasks(user)
	end)

	Players.PlayerRemoving:Connect(function(user)
		PlayerService:ExecuteLeaveTasks(user)
	end)

	for _, user in ipairs(self.RBXServices.Players:GetPlayers()) do
		self:ExecuteJoinTasks(user)
	end
end


return PlayerService