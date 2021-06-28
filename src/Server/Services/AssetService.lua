-- AssetService server
-- Dynamese(Enduo)
-- May 12, 2021

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
	
	
	Retrieving an asset:
	AssetService:GetAsset(baseID)
	
]]



local AssetService = {}
local Network, HttpService
local ClassNames = {}
local Hexadecimal
local AssetCache, AssetsRoot


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


-- Reverses the asset class enum for lookup
local function InitReverseClassNames()
	for className, classID in pairs(AssetService.Enums.AssetClass) do
		ClassNames[classID] = className
	end
end


-- Converts all asset folders' names into hexadecimal
local function HexifyAssets()
	for _, classFolder in ipairs(AssetsRoot:GetChildren()) do
		local classID = AssetService.Enums.AssetClass[classFolder.Name]
		
		classFolder.Name = Hexadecimal.new(classID, 2)
		
		for _, asset in ipairs(classFolder:GetChildren()) do
			local assetName = Instance.new("StringValue")
			
			assetName.Name = "AssetName"
			assetName.Value = asset.Name
			assetName.Parent = asset.Shared
			asset.Name = Hexadecimal.new(asset.AssetID.Value)
		end
	end
end


-- Retrieves the actual name of a class
-- @param classID <string>, HEX
local function GetClassName(classID)
	return ClassNames[tonumber(classID, 16)]
end


-- Defined here so interpreter doesn't do it at runtime
-- (if instead done as anon func in StreamAsset())
local function CleanupStreamAsset(assetFolder)
	assetFolder:Destroy()
end


-- Streams an asset to a client
-- @param client <Player>
-- @param deltaTime <float> the request took to get here
-- @param baseID <string>
local function StreamAsset(client, deltaTime, baseID)
	local streamID = HttpService:GenerateGUID()
	local asset = AssetService:GetAsset(baseID)
	
	assert(not asset.FORBIDDEN, "Attempt to stream forbidden asset: " .. baseID)
	
	local assetFolder = asset.Folder.Client:Clone()

	assetFolder.Name = streamID
	assetFolder.Parent = client
	
	AssetService.Modules.ThreadUtil.Delay(10, CleanupStreamAsset, assetFolder)
	
	return streamID 
end


-- Retrieves an asset by baseID
-- @param baseID <string>, XXYYYY
-- @returns <table> asset
function AssetService:GetAsset(baseID)
	local cached = AssetCache:Get(baseID)
	
	if (cached) then
		return cached
	else
		local classID = baseID:sub(1, 2)
		local assetID = baseID:sub(3)
		local assetFolder = AssetsRoot[classID][assetID]
		
		for _, sharedElement in ipairs(assetFolder.Shared:GetChildren()) do
			sharedElement:Clone().Parent = assetFolder.Client
			sharedElement.Parent = assetFolder.Server
		end
		
		assetFolder.Shared:Destroy()
		
		local asset = CacheAssetHelper(assetFolder.Server)
		
		asset.Folder = assetFolder
		AssetCache:Add(baseID, asset)
		
		return asset
	end
end


function AssetService:EngineInit()
	HttpService = self.RBXServices.HttpService
	Network = self.Services.Network
	
	Hexadecimal = AssetService.Modules.Hexadecimal
	
	AssetsRoot = self.Root.Assets
	
	AssetCache = self.Classes.IndexedMap.new()
	
	InitReverseClassNames()
	HexifyAssets()
end


function AssetService:EngineStart()
	Network:HandleRequestType(Network.NetRequestType.AssetRequest, StreamAsset)
end


return AssetService
