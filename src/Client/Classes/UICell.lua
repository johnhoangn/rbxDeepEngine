local Interface
local Mouse
local UIButton = require(script.Parent.UIButton)
local UICell = {}
UICell.__index = UICell
setmetatable(UICell, UIButton)



-- UICell constructor
-- @param instance <Frame>
-- @param container <UIContainer>
-- @returns <UICell>
function UICell.new(instance, container)
    Interface = Interface or UICell.Services.Interface
    Mouse = Mouse or UICell.LocalPlayer:GetMouse()

	local self = UIButton.new(instance, container)

    self._Payload = {}

    -- Move super methods
    self.SUPER_Bind = self.Bind
    self.SUPER_Unbind = self.Unbind
    self.SUPER_Destroy = self.Destroy

    self.Bind = nil
    self.Unbind = nil
    self.Destroy = nil

    self:AddSignal("Changed")
    self:AddSignal("Dragged")
    self:AddSignal("Dropped")

    return setmetatable(self, UICell)
end


-- Assigns a value into payload
-- @param key <string>
-- @param value <any>
-- @param skipSignal <boolean> == nil (false),
--      will withhold from signaling a payload change; useful when
--      changing metadata and don't want to trigger an update
function UICell:Set(key, value, skipSignal)
    self._Payload[key] = value

    if (not skipSignal) then
        self.Changed:Fire(key, value)
    end
end


-- Retrieves a payload value
-- @returns <any>
function UICell:Get(key)
    return self._Payload[key]
end


-- Called when the cell is dragged
function UICell:DragStart()
    Interface:Drag(self)
    self.Dragged:Fire()
end


-- Called when the cell is dropped
function UICell:DragStop()
    Interface:DragStop(self)

    if (self._DragStart ~= nil) then
        self._DragStart:Disconnect()
        self._DragStart = nil

        if (self._Moving ~= nil) then
            self._Moving:Disconnect()
            self._Moving = nil
        end
    end

    self.Dropped:Fire(Interface:GetActiveContainer(), Interface:GetActiveCell())
end


-- Connects events
function UICell:Bind()
    self:SUPER_Bind()

    self.Maid:GiveTask(
        self.Instance.MouseEnter:Connect(function()
            if (not Interface:Obscured(self)) then
                Interface:SetActiveCell(self)
            end
        end)
    )

    self.Maid:GiveTask(
        self.Instance.MouseLeave:Connect(function()
            if (Interface:GetActiveCell() == self and not Interface:Obscured(self)) then
                Interface:SetActiveCell(nil)
            end
        end)
    )

    if (not self.Anchored) then
        self.Maid:GiveTask(
            self.MouseButton1Down:Connect(function()
                if (not Interface:Obscured(self)) then
                    self:DragStart()
                end
            end)
        )
    end
end


-- Disconnects events
function UICell:Unbind()
    self:SUPER_Unbind()
    self:DragStop()
end


function UICell:Destroy()
    self:SUPER_Destroy()
end


return UICell
