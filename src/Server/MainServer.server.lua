-- !! Initialize Game Environment !!
local EngineFolder = script.Parent.Parent
local Roblox = EngineFolder.Roblox
local Clients = game:GetService("Players")


assert(EngineFolder.Parent == game:GetService("ServerScriptService"), 
	"Please place the Engine into ServerScriptService!")


-- Block loading
Clients.CharacterAutoLoads = false


-- Distribute Roblox service elements
for _, robloxServiceTarget in ipairs(Roblox:GetChildren()) do
	local service = game:GetService(robloxServiceTarget.Name)
	
	assert(service ~= nil, "Invalid Roblox service: " .. robloxServiceTarget.Name)
	
	for _, child in ipairs(robloxServiceTarget:GetChildren()) do
		child.Parent = service
	end
	
	robloxServiceTarget:Destroy()
end


-- !! Initialize Server !!
local Server = EngineFolder.Server
local Client = EngineFolder.Client
local Shared = EngineFolder.Shared
local CachedGeneralModules = {}
local Blackboard = {} -- Defining here skips indexing Engine
local Engine = {
	Root = EngineFolder;
	EnvironmentFolder = Server;
	Services = {};
	Modules = {_Cache = CachedGeneralModules};
	Enums = {};
    Classes = {};
	Blackboard = Blackboard;
	
	DebugLevel = 1;
	
	_ServiceName = "DGF Server";
}


-- Includes the provided module into the Deep Engine
-- @param module to link metatable to Engine
function Engine:Link(module)
	if (getmetatable(module) ~= nil) then
		warn("Attempting to overwrite metatable, suppress with '_DEEPLINKS ~= nil' in table:", module)
	end
	setmetatable(module, {
		__index = Engine;
	})
end

-- Adds functionality to the Engine such as a Network service,
--	eliminating the extra "Services" layer when indexing 
--	e.g. self.Services.Network -> self.Network
-- @param key
-- @param value
function Engine:ExtendEngine(key, value)
	assert(Engine[key] == nil, "Attempt to overwrite via Engine extension: " .. key)
	Engine[key] = value
end


-- Writes a value to a key at the Engine level (Engine.Blackboard)
-- @param key
-- @param value
function Engine:SetEngineVariable(key, value)
	Blackboard[key] = value
end


-- Retrieves a value stored in Engine.Blackboard[key]
-- @param key
-- @return value
function Engine:GetEngineVariable(key)
	return Blackboard[key]
end


-- Console debugging
function Engine:Print(...)
	print(self._ServiceName .. "\n >>>", ...)
end
function Engine:Warn(...)
	warn(self._ServiceName .. "\n >>>", ...)
end
function Engine:Log(level, ...)
	local logFile = Engine.Root:FindFirstChild("LogFile")
	if (not logFile) then
		logFile = Instance.new("StringValue")
		logFile.Name = "LogFile"
		logFile.Parent = Engine.Root
	end
	if (level <= Engine.DebugLevel) then
		local contents = {...}; for k, v in ipairs(contents) do contents[k] = tostring(v) end
		logFile.Value ..= "[LEVEL " .. level .. "] " .. self._ServiceName .. ": " .. table.concat(contents, " ") .. "\n"
	end
end


-- Clone shared elements into an environment
-- @param environment folder to copy to
local function CopyShared(environment)
	for _, sharedFolder in ipairs(Shared:GetChildren()) do
		local targetFolder = environment[sharedFolder.Name]
		
		for _, sharedChild in ipairs(sharedFolder:GetChildren()) do
			sharedChild:Clone().Parent = targetFolder
		end
	end
end


-- Loads enumerators
local function LoadEnums()
	for _, enumeratorModule in ipairs(Server.Enums:GetChildren()) do
		Engine.Enums[enumeratorModule.Name] = require(enumeratorModule)
	end
end


-- Loads services
-- @returns loaded services in ascending priority order
local function LoadServices()
	local ServiceInitPriorityQueue = {}

	for _, serviceModule in ipairs(Server.Services:GetChildren()) do
		local service = require(serviceModule)
		
		Engine:Link(service)
		service._ServiceName = serviceModule.Name
		service.Priority = service.Priority or 500
		Engine.Services[serviceModule.Name] = service
		table.insert(ServiceInitPriorityQueue, service)
	end

	-- More positive number, earlier turn
	table.sort(ServiceInitPriorityQueue, function(a, b)
        if ((a.Priority or 0) == (b.Priority or 0)) then
            return a._ServiceName < b._ServiceName
        else
		    return (a.Priority or 0) > (b.Priority or 0)
        end
	end)
	
    local serviceInitOrder = {}
    for _, serviceModule in ipairs(ServiceInitPriorityQueue) do
        table.insert(serviceInitOrder, ("%4d - %s"):format(serviceModule.Priority, serviceModule._ServiceName))
    end
    print("\n", table.concat(serviceInitOrder, "\n "))

	return ServiceInitPriorityQueue
end


-- Initializes services
local function InitServices(queue)
	Engine:ExtendEngine("RBXServices", Engine.Modules.RBXServices)
	for _, service in ipairs(queue) do
		service:EngineInit()
	end
end


-- Starts services
-- @param numServices
-- @returns completion Signal
local function StartServices(numServices)
	local completed = Engine.Classes.Signal.new()

	for _name, service in pairs(Engine.Services) do
		Engine.Modules.ThreadUtil.Spawn(function()
			service:EngineStart()
			numServices -= 1
			if (numServices == 0) then
				completed:Fire()
			end
		end)
	end
	
	return completed
end


-- Loads and runs plugins
local function DoPlugins()
	for _, pluginModule in ipairs(Server.Plugins:GetChildren()) do
        Engine.Modules.ThreadUtil.Spawn(function()
		    require(pluginModule)
        end)
	end
end


-- Lazyload setup for general modules
setmetatable(Engine.Modules, {
	__index = function(tbl, key)
		local moduleCache = rawget(tbl, "_Cache")
		local cached = moduleCache[key]
		
		if (cached) then
			return cached
		else
			local module = Server.Modules:FindFirstChild(key)
			
			assert(module ~= nil, "Invalid lazyload module: " .. key)
			
			module = require(module)
			moduleCache[key] = module
			
			if (module._DEEPLINKS == nil) then
				Engine:Link(module)			
				if (module.EngineInit ~= nil) then
					module:EngineInit()
				end
			end
			
			return module
		end
	end,
})


-- Invalid service lookup protection
setmetatable(Engine.Services, {
	__index = function(tbl, key)
		local service = rawget(tbl, key)
		
		if (service == nil) then
			error("Invalid service lookup: " .. key)
		end
		
		return service
	end,
})


-- Invalid enumerator lookup protection
setmetatable(Engine.Enums, {
	__index = function(tbl, key)
		local service = rawget(tbl, key)
		
		if (service == nil) then
			error("Invalid enumerator lookup: " .. key)
		end
		
		return service
	end,
})


-- Class loader
setmetatable(Engine.Classes, {
    __index = function(tbl, class)
        local cached = rawget(tbl, class)

        if (cached ~= nil) then
            return cached
        else
            local classModule = Server.Classes:FindFirstChild(class)

            assert(classModule ~= nil, "Invalid class " .. class)

            classModule = require(classModule)
            classModule.ClassName = class
            
            if (class == "DeepObject") then
                Engine:Link(classModule)
            end

            rawset(tbl, class, classModule)

            return classModule
        end
    end
})


-- This looks cool
_G.Deep = Engine
CopyShared(Server)
LoadEnums()
local Services = LoadServices()
InitServices(Services)
StartServices(#Services):Wait()
_G.DeepEngineOnline = true
DoPlugins()


-- !! Initialize Client Setup !!
CopyShared(Client)
EngineFolder.Preloads.Parent = Client
Client.Parent = game:GetService("StarterPlayer").StarterPlayerScripts
Clients.CharacterAutoLoads = true


local function PrepareWaitingClients()
	for _, client in ipairs(game:GetService("Players"):GetPlayers()) do
		Client:Clone().Parent = client
	end

	wait(2)

	for _, client in ipairs(game:GetService("Players"):GetPlayers()) do
		if (client.Character == nil) then
			client:LoadCharacter()
		end
	end
end


Engine:Print("Ready!")


PrepareWaitingClients()


-- !! Cleanup !!
Roblox:Destroy()
