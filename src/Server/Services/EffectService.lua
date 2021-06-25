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


-- Creates a new effect
-- @param baseID
-- @param effectUID, auto generated default
-- @param pre_dt == 0
-- @param ... effect args
-- @return uid of effect
function EffectService:Make(baseID, pre_dt, ...)
	assert(AssetService:GetAsset(baseID) ~= nil, "Invalid effect " .. baseID)
	local uid = HttpService:GenerateGUID()
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
	
	Network:FireAllClients(packet)
	
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