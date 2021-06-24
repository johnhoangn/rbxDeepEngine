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

    self.Maid = self.Instancer:Make("Maid")
    self:Bind()

	return self
end


-- Binds events and gives them to a maid
function UIButton:Bind()
    self.MouseButton1Down = self.Instancer:Make("Signal")
    self.MouseButton2Down = self.Instancer:Make("Signal")

    self.MouseButton1Up = self.Instancer:Make("Signal")
    self.MouseButton2Up = self.Instancer:Make("Signal")

    self.MouseButton1Click = self.Instancer:Make("Signal")
    self.MouseButton2Click = self.Instancer:Make("Signal")

    self.Maid:GiveTask(self.MouseButton1Down)
    self.Maid:GiveTask(self.MouseButton2Down)
    self.Maid:GiveTask(self.MouseButton1Up)
    self.Maid:GiveTask(self.MouseButton2Up)
    self.Maid:GiveTask(self.MouseButton1Click)
    self.Maid:GiveTask(self.MouseButton2Click)

    self.Maid:GiveTask(self.Instance.UIButton.MouseButton1Down:Connect(function(...)
        if (not Interface:Obscured(self)) then
            self.MouseButton1Down:Fire(...)
        end
    end))

    self.Maid:GiveTask(self.Instance.UIButton.MouseButton2Down:Connect(function(...)
        if (not Interface:Obscured(self)) then
            self.MouseButton2Down:Fire(...)
        end
    end))

    self.Maid:GiveTask(self.Instance.UIButton.MouseButton1Up:Connect(function(...)
        if (not Interface:Obscured(self)) then
            self.MouseButton1Up:Fire(...)
        end
    end))

    self.Maid:GiveTask(self.Instance.UIButton.MouseButton2Up:Connect(function(...)
        if (not Interface:Obscured(self)) then
            self.MouseButton2Up:Fire(...)
        end
    end))

    self.Maid:GiveTask(self.Instance.UIButton.MouseButton1Click:Connect(function(...)
        if (not Interface:Obscured(self)) then
            self.MouseButton1Click:Fire(...)
        end
    end))

    self.Maid:GiveTask(self.Instance.UIButton.MouseButton2Click:Connect(function(...)
        if (not Interface:Obscured(self)) then
            self.MouseButton2Click:Fire(...)
        end
    end))
end


-- Clears active event bindings
function UIButton:Unbind()
    self.Maid:DoCleaning()
end


function UIButton:Destroy()
    self:Unbind()
    self.Instance:Destroy()
end

return UIButton
