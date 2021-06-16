local Interface
local Mouse
local UISlider = {}
UISlider.__index = UISlider



-- Determines where the mouse is relative to the slider
-- @param slider <UISlider>
-- @returns value between [0, 1] <Float>
local function SliderValue(slider)
    local width = slider.Instance.Clickbox.AbsoluteSize.X
    local left = slider.Instance.Clickbox.AbsolutePosition.X
    local mousePos = Mouse.X

    return math.clamp((mousePos - left) / width, 0, 1)
end


-- UISlider constructor
-- @param element <Frame>
-- @param initialiValue == 0.5, <Float> [0, 1]
-- @param container <UIContainer>
-- @return <UISlider>
function UISlider.new(element, initialValue, container)
    Interface = Interface or UISlider.Services.Interface
    Mouse = Mouse or UISlider.LocalPlayer:GetMouse()

	local self = setmetatable({
        Instance = element;
        Container = container;
        Value = initialValue or 0.5;
    }, UISlider)

    self.Maid = self.Instancer:Make("Maid")
    self.Slid = self.Instancer:Make("Signal")

    self.Maid:GiveTask(self.Slid)

	return self
end


-- Hooks up events
function UISlider:Bind()
    self.Maid:GiveTask(
        self.Instance.UISlider.MouseButton1Down:Connect(function()
            self.Sliding = Mouse.Move:Connect(function()
                local ratio = SliderValue(self)

                self.Value = ratio
                self.Slid:Fire(ratio)
            end)
        end)
    )

    self.Maid:GiveTask(
        Mouse.Button1Up:Connect(function()
            self.Sliding:Disconnect()
        end)
    )
end


-- Disconnects events
function UISlider:Unbind()
    self.Maid:DoCleaning()
    if (self.Sliding) then
        self.Sliding:Disconnect()
        self.Sliding = nil
    end
end


function UISlider:Destroy()
    self:Unbind()
    self.Instance:Destroy()
end


return UISlider
