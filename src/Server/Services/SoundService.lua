local SoundService = {}
local HttpService, Network, Players


local ActiveSounds


-- Players a sound to a select group of users
-- @param clientList
-- @param soundClass
-- @param baseID
-- @param propertiesTable
-- @return soundID
function SoundService:PlaySoundUsers(clientList, soundClass, baseID, propertiesTable)
	local soundID = HttpService:GenerateGUID()
	
	ActiveSounds:Add(soundID, {
		soundClass, 
		baseID, 
		propertiesTable
	})
	
	local packet = Network:Pack(
		Network.NetProtocol.Forget, 
		Network.NetRequestType.Sound,
		soundClass, 
		baseID, 
		propertiesTable
	)
	
	Network:FireClientsList(clientList, packet)
	
	return soundID
end


-- Macro to play sounds to everyone
-- @params see :PlaySoundUsers
-- @return soundID
function SoundService:PlaySound(soundClass, baseID, propertiesTable)
	return self:PlaySoundUsers(Players:GetPlayers(), soundClass, baseID, propertiesTable)
end


-- Macro to play sounds to everyone
-- @params see :PlaySoundUsers
-- @return soundID
function SoundService:PlaySoundUser(user, soundClass, baseID, propertiesTable)
	return self:PlaySoundUsers({user}, soundClass, baseID, propertiesTable)
end


-- Changes a sound for everyone (if they're playing it locally)
-- @param soundID
-- @param propertiesTable
function SoundService:ChangeSound(soundID, propertiesTable)
	local packet = Network:Pack(
		Network.NetProtocol.Forget, 
		Network.NetRequestType.SoundChange,
		soundID, 
		propertiesTable
	)

	Network:FireClientsList(Players:GetPlayers(), packet)
end


-- Stops a sound for everyone (if they're playing it locally)
-- @param soundID
function SoundService:StopSound(soundID)
	if (ActiveSounds:Contains(soundID)) then
		ActiveSounds:Remove(ActiveSounds)
		
		local packet = Network:Pack(
			Network.NetProtocol.Forget, 
			Network.NetRequestType.SoundStop, 
			soundID
		)

		Network:FireAllClients(packet)
	end
end


function SoundService:EngineInit()
	Network = self.Services.Network
	
	Players = self.RBXServices.Players
	HttpService = self.RBXServices.HttpService

	ActiveSounds = self.Classes.IndexedMap.new()
end


function SoundService:EngineStart()
end


return SoundService