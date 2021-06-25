--[[

    Effect class, improves upon Abyss' FX system since effectModules don't get cloned,
    thus fully taking advantage of Roblox's inbuilt module caching

    Further improvements include re-using cached effect instances

    When an effect finishes its lifecycle, :Reset() is called and it gets cached by a manager 

--]]



local DeepObject = require(script.Parent.DeepObject)
local Effect = {}
Effect.__index = Effect
setmetatable(Effect, DeepObject)


function Effect.new(effectAsset)
    local effectModule = require(effectAsset.EffectModule)
    local baseID = effectAsset.Folder.Parent.Name .. effectAsset.Folder.Name

    -- I *really* don't trust myself to remember all of these methods when creating FX
    assert(typeof(effectModule.Play) == "function", "Missing or Invalid :Play() effect method: " .. baseID)
    assert(typeof(effectModule.Change) == "function", "Missing or Invalid :Change() effect method: " .. baseID)
    assert(typeof(effectModule.Stop) == "function", "Missing or Invalid :Stop() effect method: " .. baseID)
    assert(typeof(effectModule.Reset) == "function", "Missing or Invalid :Reset() effect method: " .. baseID)
    assert(typeof(effectModule.Destroy) == "function", "Missing or Invalid :Destroy() effect method: " .. baseID)

    local self = DeepObject.new()

    self.BaseID = baseID
    self.Model = effectAsset.Model:Clone()
    self.Module = effectModule

    self:AddSignal("OnPlay")
    self:AddSignal("OnStop")

    self.State = Effect.Enums.EffectState.Ready

    return setmetatable(self, Effect)
end


function Effect:Play(...)
    if (self.State ~= self.Enums.EffectState.Stopped) then
        self.State = self.Enums.EffectState.Playing
        self.Module:Play(...)
        self:Stop(...)
    else
        warn("Attempt to play non-ready effect ", self)
    end
end


function Effect:Change(...)
    if (self.State ~= self.Enums.EffectState.Stopped) then
        self.Module:Change(...)
    else
        warn("Attempt to change stopped effect ", self)
    end
end


function Effect:Stop(...)
    if (self.State == self.Enums.EffectState.Playing) then
        self.State = self.Enums.EffectState.Stopped
        self.Module:Stop(...)
        self.OnStop:Fire()
    end
end


function Effect:Reset(...)
    self.Module:Reset(...)
    self.State = self.Enums.EffectState.Ready
end


function Effect:Destroy(...)
    self.Module:Destroy(...)
    self.OnDestroy:Fire()

    self.OnPlay:Destroy()
    self.OnStop:Destroy()
end


return Effect
