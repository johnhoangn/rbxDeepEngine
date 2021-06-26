-- UIContainer Class, represents a Frame directly descendant to the ScreenGUI
-- Enduo(Dynamese)
-- 6.24.2021



local Interface
local DeepObject = require(script.Parent.DeepObject)
local UIContainer = {}
UIContainer.__index = UIContainer
setmetatable(UIContainer, DeepObject)


-- UIContainer constructor, optional x and y coordinates to initialize
-- @param instance, the Frame this container wraps
function UIContainer.new(instance)
    Interface = Interface or UIContainer.Services.Interface

    local self = DeepObject.new()

    self._Children = {}
    self.Instance = instance
    self.Anchored = instance:FindFirstChild("Dragger") == nil

    self:GetMaid()
    self:AddSignal("Dragged")
    self:AddSignal("Dropped")

	return setmetatable(self, UIContainer)
end


-- Will eventually include appendages
function UIContainer:EffectiveSize()
    return self.Instance.AbsoluteSize
end


-- Places the container at the specified X and Y, and
--  also bumps the container within viewport bounds
function UIContainer:GuaranteeBounds()

end


-- Called when the container is dragged
function UIContainer:DragStart()
    assert(not self.Anchored, "Attempt to drag anchored UIContainer")
    Interface:Drag(self)
    self.Dragged:Fire()
end


-- Called when the container is dropped from a drag
function UIContainer:DragStop()
    self.Dropped:Fire(Interface:GetActiveContainer(), Interface:GetActiveCell())
end


-- Binds events and gives them to a maid
function UIContainer:Bind()
    self.Maid:GiveTask(
        self.Instance.MouseEnter:Connect(function()
            if (not Interface:Obscured(self)) then
                Interface:SetActiveContainer(self)
            end
        end)
    )

    self.Maid:GiveTask(
        self.Instance.MouseLeave:Connect(function()
            if (Interface:GetActiveContainer() == self and not Interface:Obscured(self)) then
                Interface:SetActiveContainer(nil)
            end
        end)
    )

    if (not self.Anchored) then
        self.Maid:GiveTask(
            self.Instance.Dragger.MouseButton1Down:Connect(function()
                if (not Interface:Obscured(self)) then
                    self:DragStart()
                end
            end)
        )
    end
end


-- Clears active event bindings
function UIContainer:Unbind()
    self.Maid:DoCleaning()
end


-- Adds a UIElement as child to this container
-- @param element <UIElement>
-- @param name <string>
function UIContainer:AddChild(element, name)
    self._Children[name] = element
end


-- Removes a UIElement from this container
-- @param name <string>
function UIContainer:RemoveChild(name)
    self._Children[name] = nil
end


-- Retrieves a child by name
-- @param name <string>
-- @return <UIElement>
function UIContainer:GetChild(name)
    local child = self._Children[name]

    assert(child ~= nil, "Invalid child " .. name)

    return child
end


-- TODO: Move to UIElement superclass
function UIContainer:Show()
    self.Instance.Visible = true
end


-- TODO: Move to UIElement superclass
function UIContainer:Hide()
    self.Instance.Visible = false
end


-- TODO: Move to UIElement superclass
function UIContainer:GetContainer()
    return self
end


function UIContainer:Destroy()
    for k, _ in pairs(self._Children) do
        self._Children[k] = nil
    end
    self:Unbind()
    self.Instance:Destroy()
end


return UIContainer
