-- Network controller server
-- Dynamese (Enduo)
-- May 9, 2021

--[[

	Creating packets:
	Network:Pack(protocol, requestType, ...)
	
	Sending packets:
	Network:FireClient(client, packet, responseHandler, timeout)
	Network:FireAllClients(packet, responseHandler, timeout)
	Network:FireAllClientsBut(excludedClient, packet, responseHandler, timeout)
	Network:FireClientList(clientList, packet, responseHandler, timeout)
	
	Receiving packets:
	Network:HandleRequestType(requestType, requestHandler)
	Network:UnhandleRequestType(requestType)

	requestHandler's parameters are as follows:
	function(client, deltaTime, ...)
	
	Oneliner clientrequesting
	Network:RequestClient(client, requestType, ...)
]]



local DEFAULT_RESPONSE_TIMEOUT = 300
local RATE_LIMIT = 30


local Network = {}
local SyncService, HttpService, Players, BigBrother
local NetProtocol, NetRequestType, PacketStatus
local Router
local TableUtil, ThreadUtil


local AwaitingResponses, RequestHandlers


-- Cleanly guarantee a positive delta
-- @param stamp
-- @return [0, deltaTime]
local function TimeDelta(stamp)
	local now = SyncService:GetTime()
	-- Damage control for high pingers
	stamp = math.min(stamp, now + 1)
	return math.max(0, now - stamp)
end


-- Processes inbound packets
-- @param client
-- @param packet
local function HandleInbound(client, packet)
	if (packet ~= nil and typeof(packet) == "table") then
		local status = packet[1]
		local protocol = packet[2]
		local timestamp = packet[3]
		local packetID = packet[4]
		local requestType = packet[5]
		local body = packet[6]
				
		-- This packet is a request
		if (status == PacketStatus.Request) then
			-- Quick requests are essentially a regular response-type packet
			--	wrapped in another packet under NetRequestType.Quick
			-- These wrapper-requests do not have a particular handler
			-- 	this clause simply unwraps it
			if (requestType == NetRequestType.Quick) then
				local success, exitCode = pcall(function()
					-- Swap the true requestType in
					packet[5] = packet[6][1]
					TableUtil.FastRemove(packet[6], 1)
					
					return HandleInbound(client, packet)
				end)
				
				if (not success or not exitCode) then
					Network:Warn("Invalid quick request", client, TableUtil.EncodeJSON(packet))
					Network:Warn(exitCode)
					return false
				end
				
			-- Normal requests
			else
				local requestHandler = RequestHandlers:Get(requestType)
				
				-- requestHandler == function(client, deltaTime, ...)
				if (requestHandler ~= nil) then
					-- Simple requests
					if (protocol == NetProtocol.Forget) then
						requestHandler(
							client, 
							TimeDelta(timestamp), 
							unpack(body)
						)
						
						-- Requests expecting a reply
					elseif (protocol == NetProtocol.Response) then
						local replyPacket = Network:Pack(
							NetProtocol.None, 
							requestType, 
							requestHandler(
								client, 
								TimeDelta(timestamp), 
								unpack(body)
							)
						)
						
						-- Modify packet for the reply, ID must be the same
						replyPacket[1] = PacketStatus.Response
						replyPacket[4] = packetID
						Network:FireClient(client, replyPacket)
						
						-- Packets of NetProtocol.None should never reach this branch
						--	because packet.Status ~= PacketStatus.Request when
						--	packet.Protocol == NetProtocol.None
						-- elseif (protocol == NetProtocol.None) then
						
					else
						Network:Warn("Invalid protocol", client, TableUtil.EncodeJSON(packet))
						return false
					end	
					
				else
					Network:Warn("Invalid request", client, TableUtil.EncodeJSON(packet))
					return false
				end	
			end			
			
		-- This packet is a reply 
		elseif (status == PacketStatus.Response) then
			local responseHandlerKey = client.UserId .. packetID
			local responseHandler = AwaitingResponses:Remove(responseHandlerKey)
			
			-- responseHandler == function(responded, client, deltaTime, ...)
			if (responseHandler ~= nil) then
				responseHandler(
					true,
					client,
					TimeDelta(timestamp), 
					unpack(body)
				)
				
			else
				Network:Warn("No response handler", client, TableUtil.EncodeJSON(packet))
				return false
			end
			
		else
			Network:Warn("Invalid packet status", client, TableUtil.EncodeJSON(packet))
			return false
		end
	else
		Network:Warn("Invalid packet", client)
		return false
	end	
	
	return true
end


-- Removes all timed-out responseHandlers specified in array handlerKeys
-- @param handlerKeys, arraylike
local function PurgeResponseHandlers(handlerKeys)
	for _, key in ipairs(handlerKeys) do
		local handler = AwaitingResponses:Remove(key)
		
		if (handler ~= nil) then
			handler(false)
		end
	end
end


-- When a client dumps packets in a bulk request
-- @param client
-- @param bulkPacket
local function HandleBulkRequest(client, bulkPacket)
	local success, returnVal = pcall(function()
		for _, packet in ipairs(bulkPacket[6][1]) do
			ThreadUtil.Spawn(HandleInbound, client, packet)
		end
	end)
	
	if (not success) then
		Network:Warn("Invalid bulk request", client, TableUtil.EncodeJSON(bulkPacket))
	end
end


-- Creates a network packet to send
-- NetPacket class because formatting is shared with the client
-- @param protocol Enum.NetProtocol
-- @param requestType Enum.NetRequestType
-- @param ... request arguments
function Network:Pack(protocol, requestType, ...)
	return self.Classes.NetPacket.new(protocol, requestType, ...)
end


-- Macro to request a single client and expect a return
-- @param client
-- @param requestType
-- @param ... request args
-- @return fulfilled signal
function Network:RequestClient(client, requestType, ...)
	local fulfilled = self.Classes.Signal.new()
	
	self:FireClient(
		client, 
		self:Pack(
			NetProtocol.Response,
			requestType,
			...
		), 
		function(responded, ...)
			fulfilled:Fire(responded, ...)
		end,
		nil
	)
	
	return fulfilled:Wait()
end


-- Macro to tell a client something, not expecting a return
-- @param client
-- @param requestType
-- @param ... request args
function Network:TellClient(client, requestType, ...)
	self:FireClient(
		client, 
		self:Pack(
			NetProtocol.Forget,
			requestType,
			...
		)
	)
end


-- Sends a packet to a set of clients
-- Given a NetProtocol.Response packet, a responseHandler is added to
--	the AwaitingResponses IndexedMap to be called when a client responds
-- @param clientList, arraylike
-- @param packet
-- @param responseHandler == nil, function(responded, client, deltaTime, ...)
-- @param timeout == DEFAULT_RESPONSE_TIMEOUT
function Network:FireClientList(clientList, packet, responseHandler, timeout)
	local responseHandlerKeys = table.create(#clientList)
	
	if (packet.Protocol == NetProtocol.Response) then
		for i, client in ipairs(clientList) do
			local responseHandlerKey = client.UserId .. packet[3]
			
			AwaitingResponses:Add(responseHandlerKey, responseHandler)
			responseHandlerKeys[i] = responseHandlerKey
		end
		
		ThreadUtil.Delay(
			timeout or DEFAULT_RESPONSE_TIMEOUT, 
			PurgeResponseHandlers(responseHandlerKeys)
		)
	end
	
	for _, client in ipairs(clientList) do
		Router:FireClient(client, packet)
	end
end


-- Sends a packet to a designated client
-- @params see :FireClientList
function Network:FireClient(client, packet, responseHandler, timeout)
	self:FireClientList({client}, packet, responseHandler, timeout)
end


-- Sends a packet to all connected clients excluding one client
-- @params see :FireClientList
function Network:FireAllClientsBut(excludedClient, packet, responseHandler, timeout)
	local clientList = Players:GetPlayers()
	
	TableUtil.FastRemoveFirstValue(clientList, excludedClient)
	self:FireClientList(clientList, packet, responseHandler, timeout)
end


-- Sends a packet to all connected clients
-- @params see :FireAllClientsBut
function Network:FireAllClients(packet, responseHandler, timeout)
	self:FireAllClientsBut(nil, packet, responseHandler, timeout)
end


-- Listens for packets of requestType
-- Only one listener per requestType
-- @param requestType
-- @param requestHandler == function(client, deltaTime, ...)
function Network:HandleRequestType(requestType, requestHandler)
    assert(requestHandler ~= nil, "nil request handler")
	assert(RequestHandlers:Get(requestType) == nil, 
		"Attempt to overwrite requestHandler for " .. requestType)
	RequestHandlers:Add(requestType, requestHandler)
end


-- Stops listening to a requestType
-- @parma requestType
function Network:UnhandleRequestType(requestType)
	assert(RequestHandlers:Remove(requestType) ~= nil, 
		"Non-existent requestHandler for " .. requestType)
end


function Network:EngineInit()
	SyncService = self.Services.SyncService
	BigBrother = nil --self.Services.BigBrother
	
	HttpService = self.RBXServices.HttpService
	Router = self.RBXServices.ReplicatedStorage.Router
	Players = self.RBXServices.Players
	
	NetProtocol = self.Enums.NetProtocol
	NetRequestType = self.Enums.NetRequestType
	PacketStatus = self.Enums.PacketStatus
	
	TableUtil = self.Modules.TableUtil
	ThreadUtil = self.Modules.ThreadUtil
	
	AwaitingResponses = self.Classes.IndexedMap.new()
	RequestHandlers = self.Classes.IndexedMap.new()
	
	self.NetProtocol = NetProtocol
	self.NetRequestType = NetRequestType
	self.PacketStatus = PacketStatus
end


function Network:EngineStart()
	Router.OnServerEvent:Connect(HandleInbound)
    
    self:HandleRequestType(NetRequestType.BulkRequest, HandleBulkRequest)

    --
    ThreadUtil.Delay(5, function()
        self:FireClient(Players:GetPlayers()[1], self:Pack(
            NetProtocol.Forget,
            NetRequestType.Test,
            "Hello, world!",
            "foo bar",
            420
        ))
    end)
    --]]
end


return Network
