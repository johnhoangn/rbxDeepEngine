-- UIButton Class, represents a Frame acting as a button
-- Enduo(Dynamese)
-- 6.24.2021



local Interface
local DeepObject = require(script.Parent.DeepObject)
local UIButton = {}
UIButton.__index = UIButton
setmetatable(UIButton, DeepObject)


-- UIButton constructor
-- @param instance <Frame>
-- @param container <UIContainer>
-- @returns <UIButton>
function UIButton.new(instance, container)
    Interface = Interface or UIButton.Services.Interface

	local self = DeepObject.new()

    self._LastClick1 = 0
    self._LastClick2 = 0
    self._ClickBox = instance:FindFirstChild("UIButton")
        or instance:FindFirstChild("UIToggle")
    self.Instance = instance
    self.Container = container

    self:GetMaid()

    self:AddSignal("MouseButton1Down")
    self:AddSignal("MouseButton2Down")

    self:AddSignal("MouseButton1Up")
    self:AddSignal("MouseButton2Up")

    self:AddSignal("MouseButton1Click")
    self:AddSignal("MouseButton2Click")

    self:AddSignal("MouseButton1DoubleClick")
    self:AddSignal("MouseButton2DoubleClick")

	return setmetatable(self, UIButton)
end


-- Binds events and gives them to a maid
function UIButton:Bind()
    self.Maid:GiveTask(self._ClickBox.MouseButton1Down:Connect(function(...)
        if (not Interface:Obscured(self)) then
            self.MouseButton1Down:Fire(...)
        end
    end))

    self.Maid:GiveTask(self._ClickBox.MouseButton2Down:Connect(function(...)
        if (not Interface:Obscured(self)) then
            self.MouseButton2Down:Fire(...)
        end
    end))

    self.Maid:GiveTask(self._ClickBox.MouseButton1Up:Connect(function(...)
        if (not Interface:Obscured(self)) then
            self.MouseButton1Up:Fire(...)
        end
    end))

    self.Maid:GiveTask(self._ClickBox.MouseButton2Up:Connect(function(...)
        if (not Interface:Obscured(self)) then
            self.MouseButton2Up:Fire(...)
        end
    end))

    self.Maid:GiveTask(self._ClickBox.MouseButton1Click:Connect(function(...)
        if (not Interface:Obscured(self)) then
            local now = tick()

            self.MouseButton1Click:Fire(...)

            if (now - self._LastClick1 < Interface.DoubleClickWindow) then
                self.MouseButton1DoubleClick:Fire(...)
            end

            self._LastClick1 = now
        end
    end))

    self.Maid:GiveTask(self._ClickBox.MouseButton2Click:Connect(function(...)
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


-- Retrieves the container holding this button
-- @returns <UIContainer>
function UIButton:GetContainer()
    return self._Container
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
