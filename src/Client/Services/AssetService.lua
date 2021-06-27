-- AssetService client
-- Dynamese(Enduo)
-- May 9, 2021

--[[

	An asset is a table which maps out an AssetFolder defined 
		physically in Engine.Assets
		
	Try: print(AssetService:GetAsset("FF0"))
		
	A BaseID is an asset's identifier of the form XXYYYY~ 
		where XX is the ClassID (2 characters) 
		and YYYY~ is the AssetID (at least 1 character) 
		this identifier is represented in BASE_16 (Hexadecimal)
		
	A ClassID is an integer from Engine.Enums.AssetClass
	
	An AssetID is a unique-to-the-class integer in the bounds [0, INF)
		where two different assets A and B have AssetIDs 0 and 1
		
	As an Example: Engine.Enums.AssetClass.Template .. 0 -> "FF" .. 0 -> "FF0"
	
	NOTE: When in use, every ID is handled and interpreted in BASE_16
		!!! BUT !!! during creation, the IDs shall be regular BASE_10 integers
	
	ONLY IF DEEMED NECESSARY, :PurgeCache() may be used to clear the 
		asset cache. See :SetPurge() to exempt or include an asset
	
	
	Retrieving an asset:
	AssetService:GetAsset(baseID)
	
	Cache management:
	AssetService:SetPurge(baseID, bool)
	AssetService:PurgeCache(timeSinceLastUse)
	
	Checking if preload is done:
	AssetService:IsLoaded()
	
	Checking downloads status:
	AssetService.DownloadListSize
	
]]



local AssetService = {DownloadListSize = 0}
local Network
local ThreadUtil
local AssetCache, DownloadList


-- Converts a folder and its sub-folders into a table
-- @param root <Folder>
local function CacheAssetHelper(root)
	local tbl = {}
	
	for _, child in ipairs(root:GetChildren()) do
		if (child:IsA("Folder")) then
			tbl[child.Name] = CacheAssetHelper(child)
		elseif (child:IsA("ValueBase")) then
			tbl[child.Name] = child.Value
		else
			tbl[child.Name] = child			
		end
	end
	
	return tbl
end


-- Preloads all assets specified in any list modules at EnvironmentFolder.Preloads
-- Assets preloaded from here will be set to ignore purge
local function Preload()
	for _, preloadList in ipairs(AssetService.EnvironmentFolder.Preloads:GetChildren()) do
		for _, baseID in ipairs(require(preloadList)) do
			ThreadUtil.Spawn(
				AssetService.SetPurge,
				AssetService,
				baseID, 
				false
			)
		end
	end
	
	AssetService.EnvironmentFolder.Preloads:Destroy()
end


-- Retrieves a cached asset or downloads it via baseID
-- @param baseID <string> of the form XXYYYY, XX: ClassID, YYYY: AssetID
-- @return the indexed asset <table>
function AssetService:GetAsset(baseID)
	local cached = AssetCache:Get(baseID)
	
	if (cached ~= nil) then
		cached.LastUsed = tick()
		return cached
		
	elseif (DownloadList:Contains(baseID)) then
		local downloaded = self.Classes.Signal.new()
		local waitForAsset
			
		waitForAsset = self.Downloaded:Connect(function(downloadedID, asset)
			if (downloadedID == baseID) then
				waitForAsset:Disconnect()
				downloaded:Destroy()
				downloaded:Fire(asset)
			end
		end)
		
		return downloaded:Wait()
	else
		DownloadList:Add(baseID, true)
		AssetService.DownloadListSize += 1
		
		local streamID = Network:RequestServer(
			Network.NetRequestType.AssetRequest,
			baseID
		):Wait()
		
		DownloadList:Remove(baseID)
		AssetService.DownloadListSize -= 1
		
		local assetFolder = self.LocalPlayer:WaitForChild(streamID, 30):Clone()
		local asset = CacheAssetHelper(assetFolder)
		local classID = baseID:sub(1, 2)
		local classFolder = self.EnvironmentFolder.Cache:FindFirstChild(classID)
		
		if (classFolder == nil) then
			classFolder = Instance.new("Folder")
			classFolder.Name = classID
			classFolder.Parent = self.EnvironmentFolder.Cache
		end
		
		assetFolder.Name = baseID:sub(3)
		assetFolder.Parent = classFolder
		asset.Folder = assetFolder
		asset.LastUsed = tick()
		asset.Name = assetFolder.AssetName.Value
		assetFolder.AssetName:Destroy()
		AssetCache:Add(baseID, asset)
		self.Downloaded:Fire(baseID, asset)
		
		return asset
	end
end


-- Sets an asset to respect purges or not
-- @param baseID <string>
-- @param value <boolean>
function AssetService:SetPurge(baseID, value)
	self:GetAsset(baseID).IgnorePurge = not value or nil
end


-- Clears the cache of all assets that haven't been used recently
-- @param tolerance == 0 <float>, time in seconds since an asset was used
function AssetService:PurgeCache(tolerance)
	tolerance = tolerance or 0
	
	local now = tick()
	local trash = {}
	
	for baseID, asset in AssetCache:KeyIterator() do
		if (not asset.IgnorePurge and now - asset.LastUsed >= tolerance) then
			table.insert(trash, baseID)
		end
	end
	
	for _, baseID in ipairs(trash) do
		AssetCache:Remove(baseID).Folder:Destroy()
	end
end


-- Checks if the services is done preloading
function AssetService:IsLoaded()
	return self.Preloaded == nil
end


function AssetService:EngineInit()
	Network = self.Services.Network
	
	ThreadUtil = self.Modules.ThreadUtil
	
	AssetCache = self.Classes.IndexedMap.new()
	DownloadList = self.Classes.IndexedMap.new()
	
	self.Preloaded = self.Classes.Signal.new()
	self.Downloaded = self.Classes.Signal.new()
end


function AssetService:EngineStart()
	Preload()
	self.Preloaded:Fire()
	self.Preloaded:Destroy()
	self.Preloaded = nil
end


return AssetService
