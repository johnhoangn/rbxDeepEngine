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


local DataService = { NIL_TOKEN = NIL_TOKEN; Priority = 900 }
local Network, Players, ProfileUtil


local ActiveProfiles
local GameProfileStore


-- Loads or creates the client's profile
-- @param client <Player>
local function HandleClientJoin(client)
	local triesLeft = 5
	local profile
	
	while (not profile and triesLeft > 0) do
		profile = GameProfileStore:LoadProfileAsync("Player_" .. client.UserId)

		if (profile ~= nil) then
			profile:AddUserId(client.UserId) -- GDPR compliance
			profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)

			profile:ListenToRelease(function()
				ActiveProfiles[client] = nil
				-- The profile could've been loaded on another Roblox server:
				client:Kick(DataService.Enums.KickMessages.DataLoadViolation)
			end)

			if (client:IsDescendantOf(Players)) then
				-- A profile has been successfully loaded:
				ActiveProfiles[client] = profile
			else
				-- Player left before the profile loaded:
				profile:Release()
			end

			DataService.DataReady:Fire(client)

			-- Replicate
			Network:FireClient(client, Network:Pack(
				Network.NetProtocol.Forget, 
				Network.NetRequestType.DataStream,
				profile.Data
			))
		else
			DataService:Warn("Profile failed to load!", client, "(" .. triesLeft .. ")")
		end

		triesLeft -= 1

		if (not profile) then
			wait(1)
		end
	end


	if (not profile) then
		-- The profile couldn't be loaded possibly due to other
		-- 	Roblox servers trying to load this profile at the same time:
		client:Kick(DataService.Enums.KickMessages.DataLoadViolation) 
	end
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


-- Attempts to get data for client, and will yield for it
-- @param client <Player>
-- @param timeout <number>
function DataService:WaitData(client, timeout)
	local data = self:GetData(client)

	if (not data) then
		local retrieved = self.Classes.Signal.new()
		local ready

		self.Modules.ThreadUtil.Delay(timeout or 5, function()
			if (data == nil) then
				ready:Disconnect()
				retrieved:Fire()
			end
		end)

		ready = self.DataReady:Connect(function(_client)
			if (_client == client) then
				ready:Disconnect()
				data = self:GetData(_client)
				retrieved:Fire()
			end
		end)

		retrieved:Wait()
	end

	return data
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
			assert(root[subDir] ~= nil or root[tonumber(subDir)], 
				string.format(
					"Cannot reach (%s), invalid route (%s)", 
					subDir, 
					routeString
				)
			)
			root = root[subDir] or root[tonumber(subDir)]
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
	if (value == nil) then
		value = NIL_TOKEN
	end

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
	self.DataReady = self.Classes.Signal.new()
	
	GameProfileStore = ProfileUtil.GetProfileStore(
		"PlayerData",
		self.Modules.SaveProfileTemplate
	)
end


function DataService:EngineStart()
	self.Services.PlayerService:AddJoinTask(HandleClientJoin, "DataJoin")
	self.Services.PlayerService:AddLeaveTask(HandleClientLeave, "DataLeave")
end


return DataService