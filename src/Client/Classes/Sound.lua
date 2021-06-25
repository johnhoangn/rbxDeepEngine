--[[

	Sound wrapper for SoundService

]]



local DeepObject = require(script.Parent.DeepObject)
local Sound = {}
Sound.__index = Sound
setmetatable(Sound, DeepObject)


local SOUND_PROPERTIES_LIST = {
	"Volume";
	"Pitch";
	"PlaybackSpeed";
	"RollOffMaxDistance";
	"RollOffMinDistance";
	"RollOffMode";
	"TimePosition";
	"PlayOnRemove";
	"Looped";
	"Parent";
}


function Sound.new(soundAsset)
	local realSound = soundAsset:Clone()
	local newSoundWrapper = DeepObject.new()
    
    newSoundWrapper._Sound = realSound
    newSoundWrapper.Stopped = realSound.Stopped
	
	for _, property in ipairs(SOUND_PROPERTIES_LIST) do
		newSoundWrapper[property] = soundAsset[property]
	end
	
	return setmetatable(newSoundWrapper, Sound)
end


-- Applies a set of property edits
-- @param properties to apply
function Sound:Modify(propertiesTable)
	for _, property in ipairs(SOUND_PROPERTIES_LIST) do
		self[property] = propertiesTable[property] or self[property]
	end
end


-- Applies properties to the real sound
-- @param volumeLevel this sound should modify by
function Sound:Apply(volumeLevel)
	self._Sound.Volume = self.Volume * volumeLevel
	
	for _, property in ipairs(SOUND_PROPERTIES_LIST) do
		if (property == "Volume") then continue end
		self._Sound[property] = self[property]
	end
end


function Sound:Play()
	self._Sound:Play()
end


function Sound:Stop()
	self._Sound:Stop()
end


function Sound:Pause()
	self._Sound:Pause()
end


function Sound:Destroy()
	self._Sound:Destroy()
end


return Sound
