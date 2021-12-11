-- SyncRandomService client
-- Requests and manages random generation from the server
--
-- Dynamese (Enduo)
-- 07.22.2021



local SyncRandomService = {Priority = 450}
local Network

local VALIDATION_INTERVAL = 50

local ActiveRandoms


-- Creates and logs the actual generator
-- @param uid <string>
-- @parma seed <number>
local function MakeRandom(uid, seed)
    local rand = {
        Object = Random.new(seed);
        Generated = 0;
    }

    ActiveRandoms:Add(uid, rand)
end


-- Requests a new synchronized random and manages it
-- @returns <string> <float>
function SyncRandomService:NewSyncRandom()
    local uid, seed = Network:RequestServer(Network.NetRequestType.RandomRequest):Wait()
    MakeRandom(uid, seed)
    return uid
end


-- Generates a new number
-- @param uid <string>
-- @returns <float>
function SyncRandomService:NextNumber(uid)
    assert(uid ~= nil, "Missing uid!")

    local rand = ActiveRandoms:Get(uid)
    local number = rand.Object:NextNumber()

    rand.Generated += 1

    return number
end


-- Generate a new integer
-- @param uid <string>
-- @param lower <integer>
-- @param upper <integer>
function SyncRandomService:NextInteger(uid, lower, upper)
    assert(uid ~= nil, "Missing uid!")

    local rand = ActiveRandoms:Get(uid)
    local number = rand.Object:NextInteger(lower, upper)

    rand.Generated += 1

    return number
end


function SyncRandomService:EngineInit()
    Network = self.Services.Network

	ActiveRandoms = self.Classes.IndexedMap.new()
end


function SyncRandomService:EngineStart()
    Network:HandleRequestType(Network.NetRequestType.RandomOverwrite, function(dt, uid, seed)
        ActiveRandoms:Remove(uid)
        MakeRandom(uid, seed)
    end)
end


return SyncRandomService