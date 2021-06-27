-- DataService client
-- Dynamese(Enduo)
-- May 24, 2021

--[[

	DataService:GetCache()

	This service's sole purpose is to cache and update said 
		cache when the server tells us to. If another service
		needs to modify any data, they will communicate with their
		respective server-service which will then call server-sided
		DataService:SetKey() or DataService:SetKeys() which will
		then inform client-sided DataService of changes to update
		
	Client-sided-service modification of the cache is ill-advised 
		unless the situation strictly requires it
		e.g. changing a camera offset slider value from 1 to 5 smoothly 
			with the camera updating real-time, followed by a final
			Settings:Set("CameraOffset", 5) when the slider is released

]]



local NIL_TOKEN = "%n"


local DataService = { NIL_TOKEN = NIL_TOKEN }


local Network
local DataCache


-- Receives, caches our data, and disconnects the initial data stream handler
-- @param dt <float>
-- @param data <table>
local function ReceiveData(dt, data)
	DataCache = data
	-- We don't need this anymore
	Network:UnhandleRequestType(Network.NetRequestType.DataStream)
end


-- Receives changes to a certain directory
-- @param dt <float>
-- @param routeString to the directory <string>
-- @param changeDictionary <table>
local function ReceiveChange(dt, routeString, changeDictionary)
	local root = DataCache
	
	for subDir in string.gmatch(routeString, "%w+") do
		root = root[subDir]
	end
	
	-- Apply
	for k, v in pairs(changeDictionary) do
		if (v == NIL_TOKEN) then
			root[k] = nil
		else
			root[k] = v
		end
	end
end 


-- Cache getter
-- @returns <table>
function DataService:GetCache()
	return DataCache
end


function DataService:EngineInit()
	Network = self.Services.Network
end


function DataService:EngineStart()
	Network:HandleRequestType(Network.NetRequestType.DataStream, ReceiveData)
	Network:HandleRequestType(Network.NetRequestType.DataChange, ReceiveChange)
	-- DataChange is handled AFTER DataStream so 
	--	I REALLY HOPE WE DON'T CHANGE DATA WHEN WE HAVE NO CACHE 
end


return DataService