-- Network controller client
-- Dynamese(Enduo)
-- May 9, 2021

--[[
	Creating packets:
	Network:Pack(protocol, requestType, ...)
	Network:PackSimple(requestType, ...)
	Network:PackRequest(requestType, ...)
	
	Sending packets:
	Network:FireServer(packet, responseHandler)
	
	Receiving packets:
	Network:HandleRequestType(requestType, requestHandler)
	Network:UnhandleRequestType(requestType)

	Oneliner response-type requests:
	Network:RequestServer(requestType, ...):Wait()
]]



local BULK_REQUEST_SIZE = 60
local MAX_BUDGET = 30


local Network = { Priority = 1000 }
local MetronomeService
local NetProtocol, NetRequestType, PacketStatus
local Router
local TableUtil


local Budget = MAX_BUDGET
local AwaitingResponses, RequestHandlers, PendingRequests, SendQueue


-- Cleanly guarantee a positive delta
-- @param stamp
-- @return [0, deltaTime]
local function TimeDelta(stamp)
	return math.max(0, workspace:GetServerTimeNow() - stamp)
end


-- Processes inbound packets
-- @param client
-- @param packet
local function HandleInbound(packet)
	local status = packet[1]
	local protocol = packet[2]
	local timestamp = packet[3]
	local packetID = packet[4]
	local requestType = packet[5]
	local body = packet[6]
	
	-- This packet is a request
	if (status == PacketStatus.Request) then
		local requestHandler = RequestHandlers:Get(requestType)
		
		-- requestHandler == function(deltaTime, ...)
		if (requestHandler ~= nil) then
			-- Simple requests
			if (protocol == NetProtocol.Forget) then
				requestHandler(
					TimeDelta(timestamp), 
					unpack(body)
				)
				
				-- Requests expecting a reply
			elseif (protocol == NetProtocol.Response) then
				local replyPacket = Network:Pack(
					NetProtocol.None, 
					requestType, 
					requestHandler(
						TimeDelta(timestamp), 
						unpack(body)
					)
				)
				
				-- Modify packet for the reply, ID must be the same
				replyPacket[1] = PacketStatus.Response
				replyPacket[4] = packetID
				Network:FireServer(replyPacket)
			end
			
		-- We aren't listening to this request yet, store it in the pending list
		else
            PendingRequests:Enqueue({
                requestType, timestamp, body
            })
		end	
		
	-- This packet is a reply 
	elseif (status == PacketStatus.Response) then
		local responseHandler = AwaitingResponses:Remove(packetID)
		
		-- responseHandler == function(deltaTime, ...)
		if (responseHandler ~= nil) then
			responseHandler(
				TimeDelta(timestamp), 
				unpack(body)
			)
			
		else
			Network:Warn("No response handler", TableUtil.EncodeJSON(packet))
		end
	end
end


-- Send a bulk request packet containing up-to BULK_REQUEST_SIZE packets
--	using only one budget unit
-- This function is hooked up to FrequencyService
local function ProcessSendQueue()
	local batchSize = math.min(BULK_REQUEST_SIZE, SendQueue.Size)
	
	if (batchSize > 0) then
		local batch = table.create(batchSize)
		local now = workspace:GetServerTimeNow()
		
		for i = 1, batchSize do
			local packet = SendQueue:Dequeue()
			packet[3] = now -- Update timestamp
			batch[i] = packet
		end
		
		local bulkPacket = Network:Pack(
			NetProtocol.Forget, 
			NetRequestType.BulkRequest, 
			batch
		)
		
		Network:FireServer(bulkPacket)
	end
end


-- Maintains budget
-- @param dt seconds since last budget reset 
local function BudgetHandler(dt)
	Budget = math.min(math.floor(Budget + MAX_BUDGET/dt), MAX_BUDGET)
end 


-- Send a packet to the server
-- If zero budget, queue the packet
-- If NetProtocol.Response, a responseHandler will be required
-- @param packet
-- @param responseHandler
function Network:FireServer(packet, responseHandler)
	if (Budget > 0) then
		Budget -= 1
		Router:FireServer(packet)
		
	else
		SendQueue:Enqueue(packet)
	end
	
	if (packet[2] == NetProtocol.Response) then
		AwaitingResponses:Add(packet[4], responseHandler)
	end
end


-- Macro for simple one-liner response-type requests
-- The signal, when fired, will OMIT the delta time measurement
-- @param requestType
-- @param ... request arguments
-- @return fulfillment Signal
function Network:RequestServer(requestType, ...)
	local fulfillmentSignal = self.Classes.Signal.new()
	local packet = self:PackRequest(
		NetRequestType.Quick, 
		requestType, 
		...
	)
	
	self:FireServer(packet, function(_deltaTime, ...)
		fulfillmentSignal:Fire(...)
		fulfillmentSignal:Destroy()
	end)
	
	return fulfillmentSignal
end


-- Creates a network packet to send
-- NetPacket class because formatting is shared with the server
-- @param protocol Enum.NetProtocol
-- @param requestType Enum.NetRequestType
-- @param ... request arguments
function Network:Pack(protocol, requestType, ...)
	return self.Classes.NetPacket.new(protocol, requestType, ...)
end


-- :Pack() macros for convenience of not specifying protocol
function Network:PackSimple(requestType, ...)
	-- Pack a simple request
	return self:Pack(NetProtocol.Forget, requestType, ...)
end
function Network:PackRequest(requestType, ...)
	-- Pack a request expecting a response
	return self:Pack(NetProtocol.Response, requestType, ...)
end


-- Listens for packets of requestType
-- Only one listener per requestType
-- Also processes any pending requests of the same type
-- @param requestType
-- @param requestHandler == function(deltaTime, ...)
function Network:HandleRequestType(requestType, requestHandler)
	assert(RequestHandlers:Get(requestType) == nil, 
		"Attempt to overwrite requestHandler for " .. requestType)
	RequestHandlers:Add(requestType, requestHandler)
	
	local now = workspace:GetServerTimeNow()
	local matchingRequests = PendingRequests:RemoveAllWhere(function(data)
        return data[1] == requestType
    end)

    -- match = {requestType, timestamp, body}
	for _, match in ipairs(matchingRequests) do
        requestHandler(
            now - match[2],
            unpack(match[3])
        )
	end
end


-- Stops listening to a requestType
-- @param requestType
function Network:UnhandleRequestType(requestType)
	assert(RequestHandlers:Remove(requestType) ~= nil, 
		"Non-existent requestHandler for " .. requestType)
end


function Network:EngineInit()
	MetronomeService = self.Services.MetronomeService
	
	Router = self.RBXServices.ReplicatedStorage.Router
	
	NetProtocol = self.Enums.NetProtocol
	NetRequestType = self.Enums.NetRequestType
	PacketStatus = self.Enums.PacketStatus
	
	TableUtil = self.Modules.TableUtil
	
	AwaitingResponses = self.Classes.IndexedMap.new()
	RequestHandlers = self.Classes.IndexedMap.new()
	PendingRequests = self.Classes.Queue.new()
	SendQueue = self.Classes.Queue.new()

	self.NetProtocol = NetProtocol
	self.NetRequestType = NetRequestType
	self.PacketStatus = PacketStatus
end


function Network:EngineStart()
	Router.OnClientEvent:Connect(HandleInbound)
	MetronomeService:BindToFrequency(1, ProcessSendQueue)
	MetronomeService:BindToFrequency(1, BudgetHandler)
end


return Network
