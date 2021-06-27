local Interface
local UIButton = require(script.Parent.UIButton)
local UIToggle = {}
UIToggle.__index = UIToggle
setmetatable(UIToggle, UIButton)



-- UIToggle constructor
-- @param instance <Frame>
-- @param initialValue == false, <boolean>
-- @param container <UIContainer>
-- @returns <UIToggle>
function UIToggle.new(instance, container, initialValue)
    Interface = Interface or UIToggle.Services.Interface

	local self = UIButton.new(instance, container)

    self.Value = initialValue or false

    -- Move super methods
    self.SUPER_Bind = self.Bind
    self.SUPER_Unbind = self.Unbind
    self.SUPER_Destroy = self.Destroy

    self.Bind = nil
    self.Unbind = nil
    self.Destroy = nil

    self:AddSignal("Toggled")

    return setmetatable(self, UIToggle)
end


-- Sets up events
function UIToggle:Bind()
    self:SUPER_Bind()

    self.Maid:GiveTask(
        self.MouseButton1Click:Connect(function()
            self:Toggle()
        end)
    )
end


-- Disconnects events
function UIToggle:Unbind()
    self:SUPER_Unbind()
    self.Maid:DoCleaning()
end


-- Negates this toggle's value
function UIToggle:Toggle()
    self:SetValue(not self.Value)
end


-- Sets this toggle's value
-- @param value <boolean>
function UIToggle:SetValue(value)
    self.Value = value
    self.Toggled:Fire(value)
end


function UIToggle:Destroy()
    self:Unbind()
    self:SUPER_Destroy()
end


return UIToggle
