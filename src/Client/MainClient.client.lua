-- !! Wait for builtin replication !!
if (not game:IsLoaded()) then
	game.Loaded:Wait()
end


-- !! Initialize Client !!
local ClientFolder = script.Parent
local CachedGeneralModules = {}
local Blackboard = {} -- Defining here skips indexing Engine
local Engine = {
	LocalPlayer = game:GetService("Players").LocalPlayer;
	EnvironmentFolder = ClientFolder;
	Services = {};
	Modules = {_Cache = CachedGeneralModules};
	Enums = {};
    Classes = {};
	Blackboard = Blackboard;

	DebugLevel = 1;

	_ServiceName = "Deep Engine Client";
}


local mt = {
    __index = Engine;
}


-- Includes the provided module into the Deep Engine
-- @param module to link metatable to Engine
function Engine:Link(module)
	if (getmetatable(module) ~= nil) then
		warn("Attempting to overwrite metatable, suppress with '_DEEPLINKS ~= nil' in table:", module)
	end
	setmetatable(module, mt)
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
	print(self._ServiceName .. "\n", ...)
end
function Engine:Warn(...)
	warn(self._ServiceName .. "\n", ...)
end
function Engine:Log(level, ...)
	if (level <= Engine.DebugLevel) then
		self:Print("DEBUG", ...)
	end
end


-- Loads enumerators
local function LoadEnums()
	for _, enumeratorModule in ipairs(ClientFolder.Enums:GetChildren()) do
		Engine.Enums[enumeratorModule.Name] = require(enumeratorModule)
	end
end


-- Loads services
-- @returns loaded services in ascending priority order
local function LoadServices()
	local ServiceInitPriorityQueue = {}
	
	for _, serviceModule in ipairs(ClientFolder.Services:GetChildren()) do
		local service = require(serviceModule)
		
		Engine:Link(service)
		service._ServiceName = serviceModule.Name
		Engine.Services[serviceModule.Name] = service
		table.insert(ServiceInitPriorityQueue, service)
	end
	
	-- More positive number, earlier turn
	table.sort(ServiceInitPriorityQueue, function(a, b)
		return (a.Priority or 0) > (b.Priority or 0)
	end)
	
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
	
	for _, service in pairs(Engine.Services) do
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
	for _, pluginModule in ipairs(ClientFolder.Plugins:GetChildren()) do
		require(pluginModule)
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
			local module = ClientFolder.Modules:FindFirstChild(key)
			
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
            local classModule = ClientFolder.Classes:FindFirstChild(class)

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
LoadEnums()
local Services = LoadServices()
InitServices(Services)
StartServices(#Services)
_G.DeepEngineOnline = true
Engine.Services.ReadyService:SignalReady()
DoPlugins()


-- Cleanup
for _, child in ipairs(ClientFolder.Parent:GetChildren()) do
	if (child ~= ClientFolder and game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild(child.Name)) then
		child:Destroy()
	end
end