if (not game:IsLoaded()) then
	game.Loaded:Wait()
end


local LocalPlayer = game:GetService("Players").LocalPlayer
local ClientEnvironment = LocalPlayer.PlayerScripts:FindFirstChild("Client") or LocalPlayer:WaitForChild("Client")
local EngineLoaded = Instance.new("BindableEvent")
local Engine


-- Assure the engine is in the right place
if (ClientEnvironment.Parent == LocalPlayer) then
	ClientEnvironment.Parent = LocalPlayer.PlayerScripts
end


-- Busywaiting is gross but necessary here
coroutine.wrap(function()
	while (not _G.DeepEngineOnline) do
		wait(1) 
	end
	
	Engine = _G.Deep
	EngineLoaded:Fire()
end)()


-- Loading screen logic below here
if (Engine == nil) then
	EngineLoaded.Event:Wait()
end


Engine:Print("Ready!")