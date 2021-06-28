-- Soundservice client
-- Dynamese(Enduo)
-- May 13, 2021

--[[

	Making sounds:
	SoundService:Make(soundClass, baseID, propertiesTable == nil)
	
	Playing sounds:
	local sound = SoundService:Make(soundClass, baseID, propertiesTable == nil); sound:Play()
	SoundService:PlaySound(soundClass, baseID, propertiesTable == nil)
	SoundService:PlayEffect(baseID, propertiesTable == nil)
	
	Volume control:
	SoundService:SetSoundClassVolume(soundClass, volume)
	SoundService:GetSoundClassVolume(soundClass)
	
]]



local SoundService = {}
local Network, AssetService, HttpService
local SoundClass


local ActiveSounds, VolumeMultipliers


-- Server notified client about a sound playing/existing
-- @param deltaTime <float> it took to get here
-- @param soundClass <string>
-- @param baseID <string>
-- @param soundID <string>
-- @param propertiesTable <table>
local function ReplicateSound(deltaTime, soundClass, baseID, soundID, propertiesTable)
	local sound = SoundService:Make(soundClass, baseID, soundID, propertiesTable)
	
	-- rOLlBaCk nEtCoDe
	sound.TimePosition += deltaTime
	
	-- Auto-delete non-looping sounds 
	if (not sound.Looped) then
		sound.Stopped:Connect(function()
			sound:Destroy()
			ActiveSounds[soundClass]:Remove(soundID)
		end)
	end
	
	sound:Play()
end


-- Server notified client about a sound stopping
-- @param deltaTime <float> it took to get here
-- @param soundID <string>
function ReplicateSoundStop(deltaTime, soundID)
	for _, sounds in pairs(ActiveSounds) do
		if (sounds:Contains(soundID)) then
			sounds:Get(soundID)
			sounds:Remove(soundID)
			break
		end
	end
end


-- Server notified client about a sound changing
-- @param deltaTime <float> it took to get here
-- @param soundID <string> to change
-- @param propertiesTable <table>
function ReplicateSoundChange(deltaTime, soundID, propertiesTable)
	local sound = ActiveSounds:Get(soundID)
	
	if (sound ~= nil) then
		for property, value in pairs(propertiesTable) do
			sound[property] = value
		end
	end
end


-- Makes a sound instance
-- @param soundClass <string>, to classify the sound
-- @param baseID <string>
-- @param propertiesTable <table> == nil
-- @return <Sound> (Wrapper)
function SoundService:Make(soundClass, baseID, soundID, propertiesTable)
	local soundAsset = AssetService:GetAsset(baseID)
	local sound = self.Instancer.Sound.new(soundAsset.Sound)

    soundID = soundID or HttpService:GenerateGUID()

	if (propertiesTable ~= nil) then
		sound:Modify(sound, propertiesTable)
	else
		sound.Parent = script
	end

	-- We need to call apply since it depends on our current volume multipliers
	sound:Apply(self:GetSoundClassVolume(soundClass))
	ActiveSounds[soundClass]:Add(soundID, sound)

	return sound
end


-- Makes and plays a sound then deletes it when it ends
-- @params see :Make()
function SoundService:PlaySound(soundClass, baseID, propertiesTable)
	local sound = self:Make(soundClass, baseID, propertiesTable)
	
	sound.Stopped:Connect(function()
		sound:Destroy()
		ActiveSounds[soundClass]:Remove(sound)
	end)
	
	sound:Play()
end


-- Macro to play an effect, auto-deleting
-- @param baseID <string>
-- @param propertiesTable <table> == nil
function SoundService:PlayEffect(baseID, propertiesTable)
	self:PlaySound(SoundClass.Effect, baseID, propertiesTable)
end


-- Adjusts the volume of all existing sounds of soundClass
-- Sets the volume multiplier for new sounds
-- @param soundClass <string>
-- @param volume <float>
function SoundService:SetSoundClassVolume(soundClass, volume)
	for _, sound in ActiveSounds[soundClass]:Iterator() do
		sound.Volume = sound.BaseVolume.Value * volume
		sound:Apply(volume)
	end
	
	VolumeMultipliers[soundClass] = volume
end


-- @returns <float> volume multiplier for soundClass
function SoundService:GetSoundClassVolume(soundClass)
	return VolumeMultipliers[soundClass]
end


function SoundService:EngineInit()
	Network = self.Services.Network
	AssetService = self.Services.AssetService
	HttpService = self.RBXServices.HttpService
	
	SoundClass = self.Enums.SoundClass
	
	ActiveSounds = {}
	VolumeMultipliers = {}
	
	for _, soundClass in pairs(SoundClass) do
		ActiveSounds[soundClass] = self.Classes.IndexedMap.new()
		VolumeMultipliers[soundClass] = 0.75 -- TODO: Default to user defined settings
	end
	
	self.SoundClass = SoundClass
end


function SoundService:EngineStart()
	Network:HandleRequestType(Network.NetRequestType.Sound, ReplicateSound)
	Network:HandleRequestType(Network.NetRequestType.SoundStop, ReplicateSoundStop)
	Network:HandleRequestType(Network.NetRequestType.SoundChange, ReplicateSoundChange)
	
	-- Test
	-- self:PlayEffect("000")
end


return SoundService