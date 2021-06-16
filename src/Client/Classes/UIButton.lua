local Interface
local UIButton = {}
UIButton.__index = UIButton


-- UIToggle constructor
-- @param element <Frame>
-- @param container <UIContainer>
-- @returns <UIToggle>
function UIButton.new(element, container)
    Interface = Interface or UIButton.Services.Interface

	local self = setmetatable({
        Instance = element;
        Container = container;
    }, UIButton)

    self.MouseButton1Down = self.Instance.MouseButton1Down
    self.MouseButton1Up = self.Instance.MouseButton1Up
    self.MouseButton1Click = self.Instance.MouseButton1Click

    self.MouseButton2Down = self.Instance.MouseButton2Down
    self.MouseButton2Up = self.Instance.MouseButton2Up
    self.MouseButton2Click = self.Instance.MouseButton2Click

	return self
end


function UIButton:Destroy()
    self.Instance:Destroy()
end

return UIButton
