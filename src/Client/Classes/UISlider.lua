-- UISlider Class, represents a Frame that acts as a slider
-- Enduo(Dynamese)
-- 6.24.2021



local Interface
local Mouse
local UISlider = {}
UISlider.__index = UISlider



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
-- @param element <Frame>
-- @param container <UIContainer>
-- @param initialiValue == 0.5, <Float> [0, 1]
-- @return <UISlider>
function UISlider.new(element, container, initialValue)
    Interface = Interface or UISlider.Services.Interface
    Mouse = Mouse or UISlider.LocalPlayer:GetMouse()

	local self = setmetatable({
        Instance = element;
        _Container = container;
        Value = initialValue or 0.5;
    }, UISlider)

    self.Maid = self.Instancer:Make("Maid")
    self.Sliding = self.Instancer:Make("Signal")
    self.Slid = self.Instancer:Make("Signal")

    self.Maid:GiveTask(self.Sliding)
    self.Maid:GiveTask(self.Slid)

    self:Bind()

	return self
end


-- TODO: Move to UIElement superclass
function UISlider:GetContainer()
    return self._Container
end


-- Hooks up events
function UISlider:Bind()
    self.Maid:GiveTask(
        self.Instance.UISlider.MouseButton1Down:Connect(function()
            if (not Interface:Obscured(self)) then
                self.Moving = Mouse.Move:Connect(function()
                    local ratio = SliderValue(self)

                    self.Value = ratio
                    self.Sliding:Fire(ratio)
                end)

                self.Release = Mouse.Button1Up:Connect(function()
                    self.Moving:Disconnect()
                    self.Slid:Fire(SliderValue(self))
                end)
            end
        end)
    )
end


-- Disconnects events
function UISlider:Unbind()
    self.Maid:DoCleaning()
    if (self.Moving) then
        self.Moving:Disconnect()
        self.Moving = nil
        self.Release:Disconnect()
        self.Release = nil
    end
end


function UISlider:Destroy()
    self:Unbind()
    self.Instance:Destroy()
end


return UISlider
