-- DeepObject Class, base class for all classes
-- Enduo(Dynamese)
-- 6.24.2021



local Engine = _G.Deep
local DeepObject = {}
DeepObject.__index = function(obj, index)
    return rawget(DeepObject, index) or Engine[index]
end


-- DeepObject constructor
-- @param instance <Frame>
-- @param container <UIContainer>
-- @returns <DeepObject>
function DeepObject.new()
	return setmetatable({}, DeepObject)
end


-- Retrieves and possibly creates a maid
-- @returns <Maid>
function DeepObject:GetMaid()
    if (self.Maid == nil) then
        self.Maid = self.Classes.Maid.new()
    end

    return self.Maid
end


-- Creates a signal and passes it to our maid
-- @param name <string>
-- @returns <Signal>
function DeepObject:AddSignal(name)
    local newSignal = self.Classes.Signal.new()

    self[name] = newSignal
    self:GetMaid():GiveTask(newSignal)

    return newSignal
end


-- Checks for class descent
-- @param class <string>
-- @returns <boolean>
function DeepObject:IsA(class)
    return self.ClassName == "DeepObject"
        or self.ClassName == class
        or getmetatable(self):IsA(class)
end


function DeepObject:Destroy()
    self:GetMaid():DoCleaning()
    setmetatable(self, nil)
end


return DeepObject