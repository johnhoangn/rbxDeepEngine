-- DataService server
-- Dynamese(Enduo)
-- May 24, 2021

--[[

	DataService:GetData(client)
	DataService:SetKey(client, routeString, key, value, doNotReplicate)
	DataService:SetKeys(client, routeString, changeDictionary, doNotReplicate)
	DataService:DeleteKey(client, routeString, key, doNotReplicate)
	DataService:DeleteKeys(client, routeString, keyList, doNotReplicate)
	
	NOTE: :DeleteKey and :DeleteKeys are logically equivalent to setting 
		key(s) to NIL_TOKEN but are less efficient with the additional calls
	
	NOTE: In a routeString, the first subdir must be a direct child of Profile.Data:
		DataService:SetKey(
			client, 					-- Who
			"Settings.CameraSettings", 	-- RouteString
			"RenderDistance", 			-- Key
			352, 						-- Value
			false						-- Withhold replication?
		)
	
]]



-- Used when removing a key, since attempting to assign nil via changeDictionary
-- 	results in the desired deletion key not having a value -> a no-op 
--	e.g. changeDictionary = { keyToRemove = nil }
local NIL_TOKEN = "\n"


local DataService = { NIL_TOKEN = NIL_TOKEN }
local Network, Players, ProfileUtil


local ActiveProfiles
local GameProfileStore


-- Loads or creates the client's profile
-- @param client <Player>
local function HandleClientJoin(client)
	local profile = GameProfileStore:LoadProfileAsync(
		"Player_" .. client.UserId,
		"ForceLoad"
	)
	
	if profile ~= nil then
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		
		profile:ListenToRelease(function()
			ActiveProfiles[client] = nil
			-- The profile could've been loaded on another Roblox server:
			client:Kick()
		end)
		
		if client:IsDescendantOf(Players) == true then
			-- A profile has been successfully loaded:
			ActiveProfiles[client] = profile
			
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
		
	else
		-- The profile couldn't be loaded possibly due to other
		-- 	Roblox servers trying to load this profile at the same time:
		client:Kick() 
	end
	
	-- Replicate
	Network:FireClient(client, Network:Pack(
		Network.NetProtocol.Forget, 
		Network.NetRequestType.DataStream,
		profile.Data
	))
end


-- Removes a client's profile upon leave
-- @param client <Player>
local function HandleClientLeave(client)
	local profile = ActiveProfiles[client]
	if profile ~= nil then
		profile:Release()
	end
end 


-- Retrieves the data table for a client
-- @param client <Player>
function DataService:GetData(client)
    local profile = ActiveProfiles[client]
	return profile ~= nil and profile.Data or nil
end


-- Changes values defined under the Data table located at routeString
-- @param client <Player>
-- @param routeString <string>
-- @param changeDictionary <table> { key1 = value1; key2 = value2; }
-- @param doNotReplicate <boolean> == false, withholds updating client
function DataService:SetKeys(client, routeString, changeDictionary, doNotReplicate)
	local root = self:GetData(client)
	
	-- Incase it was unloaded by the time we try to change keys
	if (root ~= nil) then
		for subDir in string.gmatch(routeString, "%w+") do
			assert(root[subDir] ~= nil, 
				string.format(
					"Cannot reach (%s), invalid route (%s)", 
					subDir, 
					routeString
				)
			)
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
		
		-- Replicate?
		if (not doNotReplicate) then
			Network:FireClient(
				client, 
				Network:Pack(
					Network.NetProtocol.Forget, 
					Network.NetRequestType.DataChange, 
					routeString, 
					changeDictionary
				)
			)
		end
	end
end


-- Changes a single value defined at key under routeString
-- @param routeString <string>
-- @param key <string>
-- @param value <any>
-- @param doNotReplicate <boolean> == false
function DataService:SetKey(client, routeString, key, value, doNotReplicate)
	self:SetKeys(
		client, 
		routeString, 
		{
			[key] = value;
		},
		doNotReplicate or false
	)
end


-- Macro to remove a key via NIL_TOKEN
-- @param client <Player>
-- @param routeString <string>
-- @param key <string>
-- @param doNotReplicate <boolean> == false
function DataService:DeleteKey(client, routeString, key, doNotReplicate)
	self:SetKey(
		client, 
		routeString, 
		key, 
		NIL_TOKEN, 
		doNotReplicate or false
	)
end


-- Macro to remove a list of keys
-- @param client <Player>
-- @param routeString <string>
-- @param keyList <table>
-- @param doNotReplicate <boolean> == false
function DataService:DeleteKeys(client, routeString, keyList, doNotReplicate)
	local changeDictionary = table.create(#keyList)
	
	for _, key in ipairs(keyList) do
		changeDictionary[key] = NIL_TOKEN
	end
	
	self:SetKeys(
		client, 
		routeString, 
		changeDictionary,
		doNotReplicate or false
	)
end


function DataService:EngineInit()
	Network = self.Services.Network
	Players = self.RBXServices.Players
	ProfileUtil = self.Modules.SaveProfileUtil
	
	ActiveProfiles = {}
	
	GameProfileStore = ProfileUtil.GetProfileStore(
		"PlayerData",
		self.Modules.SaveProfileTemplate
	)
end


function DataService:EngineStart()
	Players.PlayerAdded:Connect(HandleClientJoin)
	Players.PlayerRemoving:Connect(HandleClientLeave)

	-- Process already joined players
	for _, unHandledPlayer in ipairs(Players:GetPlayers()) do
		if (self:GetData(unHandledPlayer) == nil) then
			HandleClientJoin(unHandledPlayer)
		end
	end
end


return DataService