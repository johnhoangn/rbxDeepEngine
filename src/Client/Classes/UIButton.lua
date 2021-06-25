-- UIButton Class, represents a Frame acting as a button
-- Enduo(Dynamese)
-- 6.24.2021


local Interface
local UIButton = {}
UIButton.__index = UIButton


-- UIButton constructor
-- @param element <Frame>
-- @param container <UIContainer>
-- @returns <UIButton>
function UIButton.new(element, container)
    Interface = Interface or UIButton.Services.Interface

	local self = setmetatable({
        Instance = element;
        Container = container;
        _LastClick1 = 0;
        _LastClick2 = 0;
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

    self.MouseButton1DoubleClick = self.Instancer:Make("Signal")
    self.MouseButton2DoubleClick = self.Instancer:Make("Signal")

    self.Maid:GiveTask(self.MouseButton1Down)
    self.Maid:GiveTask(self.MouseButton2Down)
    self.Maid:GiveTask(self.MouseButton1Up)
    self.Maid:GiveTask(self.MouseButton2Up)
    self.Maid:GiveTask(self.MouseButton1Click)
    self.Maid:GiveTask(self.MouseButton2Click)
    self.Maid:GiveTask(self.MouseButton1DoubleClick)
    self.Maid:GiveTask(self.MouseButton2DoubleClick)

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
            local now = tick()

            self.MouseButton1Click:Fire(...)

            if (now - self._LastClick1 < Interface.DoubleClickWindow) then
                self.MouseButton1DoubleClick:Fire(...)
            end

            self._LastClick1 = now
        end
    end))

    self.Maid:GiveTask(self.Instance.UIButton.MouseButton2Click:Connect(function(...)
        if (not Interface:Obscured(self)) then
            local now = tick()

            self.MouseButton2Click:Fire(...)

            if (now - self._LastClick2 < Interface.DoubleClickWindow) then
                self.MouseButton1DoubleClick:Fire(...)
            end

            self._LastClick2 = now
        end
    end))
end


-- Clears active event bindings
function UIButton:Unbind()
    self.Maid:DoCleaning()

    self.MouseButton1Down = nil
    self.MouseButton2Down = nil

    self.MouseButton1Up = nil
    self.MouseButton2Up = nil

    self.MouseButton1Click = nil
    self.MouseButton2Click = nil

    self.MouseButton1DoubleClick = nil
    self.MouseButton2DoubleClick = nil
end


function UIButton:Destroy()
    self:Unbind()
    self.Instance:Destroy()
end

return UIButton
