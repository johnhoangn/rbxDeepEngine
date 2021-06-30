-- UISlider Class, represents a Frame that acts as a slider
-- Left is lower bound
-- Enduo(Dynamese)
-- 6.28.2021



local Interface, UserInputService
local Mouse
local DeepObject = require(script.Parent.DeepObject)
local UISlider = {}
UISlider.__index = UISlider
setmetatable(UISlider, DeepObject)


-- UISlider constructor
-- @param instance <Frame>
-- @param container <UIContainer>
-- @param initialValue == 0.5, <Float> [0, 1]
-- @param lowerBound <float> == 0
-- @param upperBound <float> == 1
-- @return <UISlider>
function UISlider.new(instance, container, initialValue, lowerBound, upperBound)
    Interface = Interface or UISlider.Services.Interface
    UserInputService = UserInputService or UISlider.RBXServices.UserInputService
    Mouse = Mouse or UISlider.LocalPlayer:GetMouse()

	local self = DeepObject.new()

    if (lowerBound ~= nil and upperBound ~= nil) then
        self._LowerBound = lowerBound
    else
        self._LowerBound = 0
    end

    self._Length = (upperBound or 1) - self._LowerBound
    self._Container = container
    self.Instance = instance
    self.Value = initialValue or 0.5

    self:GetMaid()

    self:AddSignal("Sliding")
    self:AddSignal("Slid")

	return setmetatable(self, UISlider)
end


-- Determines where the mouse is relative to the slider
-- @param slider <UISlider>
-- @returns value between [0, 1] <Float>
function UISlider:_SliderValue(slider)
    local width = slider.Instance.UISlider.AbsoluteSize.X
    local left = slider.Instance.UISlider.AbsolutePosition.X
    local mousePos = Mouse.X

    return slider._LowerBound + math.clamp((mousePos - left) / width, 0, 1) * slider._Length
end



-- TODO: Move to UIElement superclass
function UISlider:GetContainer()
    return self._Container
end


-- Overwrites the slider's value
-- @param value <float>
function UISlider:SetValue(value)
    self.Value = math.clamp(value, self._LowerBound, self._LowerBound + self._Length)
    self.Slid:Fire(self.Value)
end


-- Changes the sliders's lower bound
-- @param lowerBound <float>
function UISlider:SetLowerBound(lowerBound)
    local ratio = math.abs((self.Value - self._LowerBound) / self._Length)

    self._Length -= (lowerBound - self._LowerBound)
    self._LowerBound = lowerBound

    assert(self._Length > 0, "Length would be zero with lower bound of " .. lowerBound)

    self.Value = self._Length * ratio + self._LowerBound
end


-- Changes the slider's upper bound
-- @param upperBound <float>
function UISlider:SetUpperBound(upperBound)
    local ratio = math.abs((self.Value - self._LowerBound) / self._Length)

    assert(upperBound > self._LowerBound, "Length would be invalid with upper bound of " .. upperBound)

    self._Length += (upperBound - (self._LowerBound + self._Length))
    self.Value = self._Length * ratio + self._LowerBound
end


-- Hooks up events
function UISlider:Bind()
    self:GetMaid():GiveTask(self.Instance.UISlider.MouseButton1Down:Connect(function()
        if (not Interface:Obscured(self)) then
            local value = self:_SliderValue(self)

            self.Value = value
            self.Sliding:Fire(value)

            self._Moving = Mouse.Move:Connect(function()
                value = self:_SliderValue(self)
                self.Value = value
                self.Sliding:Fire(value)
            end)

            self._Release = UserInputService.InputEnded:Connect(function(iObject)
                if (iObject.UserInputType == Enum.UserInputType.MouseButton1) then
                    self._Moving:Disconnect()
                    self._Release:Disconnect()
                    self._Moving = nil
                    self._Release = nil
                    self.Slid:Fire(self:_SliderValue(self))
                end
            end)
        end
    end))
end


-- Disconnects events
function UISlider:Unbind()
    self.Maid:DoCleaning()

    if (self._Moving ~= nil) then
        self._Moving:Disconnect()
        self._Release:Disconnect()
        self._Moving = nil
        self._Release = nil
    end
end


function UISlider:Destroy()
    self:Unbind()
    self.Instance:Destroy()
end


return UISlider
