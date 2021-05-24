local Engine = _G.Deep
local PacketStatus = Engine.Enums.PacketStatus
local HttpService = Engine.RBXServices.HttpService
local SyncService = Engine.Services.SyncService
local NetPacket = {}


function NetPacket.new(protocol, requestType, ...)
	return {
		PacketStatus.Request;					-- 1 Packet status
		protocol; 								-- 2 Protocol
		SyncService:GetTime();					-- 3 UNIX sent timestamp
		HttpService:GenerateGUID(); 			-- 4 ID
		requestType;							-- 5 Request type
		{...};									-- 6 Body
	}
end


return NetPacket
