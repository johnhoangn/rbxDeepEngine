-- Effect Service server
-- Dynamese(Enduo)
-- May 22, 2021

--[[
	
	EffectService:Make(baseID, pre_dt, ...), returns uid
	EffectService:ChangeEffect(effectUID, pre_dt, ...)
	EffectService:StopEffect(effectUID, pre_dt, ...)
	
]]



local EffectService = {}
local Network, HttpService, AssetService


local ActiveEffects


local function MakeEffectPacket(uid, baseID, pre_dt, ...)
    local packet = Network:Pack(
		Network.NetProtocol.Forget,
		Network.NetRequestType.Effect,
		pre_dt or 0,
		baseID,
		uid,
		...
	)
	
	ActiveEffects:Add(uid, {
		BaseID = baseID;
		Args = {
			...
		};
	})

    return packet
end


-- Creates a new effect and sends it to all users
-- @param baseID
-- @param effectUID, auto generated default
-- @param pre_dt == 0
-- @param ... effect args
-- @return uid of effect
function EffectService:Make(baseID, pre_dt, ...)
	assert(AssetService:GetAsset(baseID) ~= nil, "Invalid effect " .. baseID)
	local uid = HttpService:GenerateGUID()
	local packet = MakeEffectPacket(uid, baseID, pre_dt, ...)

	Network:FireAllClients(packet)

	return uid
end


-- Creates a new effect and sends it to all users except one
-- @param exclude <Player>
-- @param baseID
-- @param effectUID, auto generated default
-- @param pre_dt == 0
-- @param ... effect args
-- @return uid of effect
function EffectService:MakeBut(exclude, baseID, pre_dt, ...)
	assert(AssetService:GetAsset(baseID) ~= nil, "Invalid effect " .. baseID)
	local uid = HttpService:GenerateGUID()
	local packet = MakeEffectPacket(uid, baseID, pre_dt, ...)

	Network:FireAllClientsBut(exclude, packet)

	return uid
end


-- Changes an effect
-- @param effectUID
-- @param pre_dt == 0
-- @param ... change args
function EffectService:ChangeEffect(effectUID, pre_dt, ...)
	local effect = ActiveEffects:Get(effectUID)

	assert(effect ~= nil, "Attempt to change invalid effect")
	
	local packet = Network:Pack(
		Network.NetProtocol.Forget, 
		Network.NetRequestType.EffectChange, 
		pre_dt or 0,
		effectUID, 
		...
	)

	Network:FireAllClients(packet)
end


-- Stops an effect
-- @param effectUID
-- @param pre_dt == 0
-- @param ... stop args
function EffectService:StopEffect(effectUID, pre_dt, ...)
	local effect = ActiveEffects:Get(effectUID)

	assert(effect ~= nil, "Attempt to stop invalid effect")

	local packet = Network:Pack(
		Network.NetProtocol.Forget, 
		Network.NetRequestType.EffectStop, 
		pre_dt or 0,
		effectUID, 
		...
	)

	Network:FireAllClients(packet)
end


function EffectService:EngineInit()
	Network = self.Services.Network
	AssetService = self.Services.AssetService
	
	HttpService = self.RBXServices.HttpService
	
	ActiveEffects = self.Classes.IndexedMap.new()
end


function EffectService:EngineStart()
	
end


return EffectService