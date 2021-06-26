-- UISlider Class, represents a Frame that acts as a slider
-- Enduo(Dynamese)
-- 6.24.2021



local Interface
local Mouse
local DeepObject = require(script.Parent.DeepObject)
local UISlider = {}
UISlider.__index = UISlider
setmetatable(UISlider, DeepObject)


-- Determines where the mouse is relative to the slider
-- @param slider <UISlider>
-- @returns value between [0, 1] <Float>
local function SliderValue(slider)
    local width = slider.Instance.UISlider.AbsoluteSize.X
    local left = slider.Instance.UISlider.AbsolutePosition.X
    local mousePos = Mouse.X

    return math.clamp((mousePos - left) / width, 0, 1)
end


-- UISlider constructor
-- @param instance <Frame>
-- @param container <UIContainer>
-- @param initialiValue == 0.5, <Float> [0, 1]
-- @return <UISlider>
function UISlider.new(instance, container, initialValue)
    Interface = Interface or UISlider.Services.Interface
    Mouse = Mouse or UISlider.LocalPlayer:GetMouse()

	local self = DeepObject.new()

    self._Container = container
    self.Instance = instance
    self.Value = initialValue or 0.5

    self:GetMaid()

    self:AddSignal("Sliding")
    self:AddSignal("Slid")

	return setmetatable(self, UISlider)
end


-- TODO: Move to UIElement superclass
function UISlider:GetContainer()
    return self._Container
end


-- Hooks up events
function UISlider:Bind()
    self._DragStart = self.Instance.UISlider.MouseButton1Down:Connect(function()
        if (not Interface:Obscured(self)) then
            local ratio = SliderValue(self)

            self.Value = ratio
            self.Sliding:Fire(ratio)

            self._Moving = Mouse.Move:Connect(function()
                ratio = SliderValue(self)
                self.Value = ratio
                self.Sliding:Fire(ratio)
            end)

            self._Release = Mouse.Button1Up:Connect(function()
                self._Moving:Disconnect()
                self._Release:Disconnect()
                self._Moving = nil
                self._Release = nil
                self.Slid:Fire(SliderValue(self))
            end)
        end
    end)
end


-- Disconnects events
function UISlider:Unbind()
    self.Maid:DoCleaning()

    if (self._DragStart ~= nil) then
        self._DragStart:Disconnect()
        self._DragStart = nil
        
        if (self._Moving ~= nil) then
            self._Moving:Disconnect()
            self._Release:Disconnect()
            self._Moving = nil
            self._Release = nil
        end
    end
end


function UISlider:Destroy()
    self:Unbind()
    self.Instance:Destroy()
end


return UISlider
