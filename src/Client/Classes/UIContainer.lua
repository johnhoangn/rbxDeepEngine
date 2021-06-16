local Interface
local UIContainer = {}
UIContainer.__index = UIContainer



-- UIContainer constructor, optional x and y coordinates to initialize
-- @param instance, the Frame this container wraps
-- @param x == instance.AbsolutePosition.X <Float>
-- @param y == instance.AbsolutePosition.Y <Float>
function UIContainer.new(instance, x, y)
    Interface = Interface or UIContainer.Services.Interface

    local self = setmetatable({
        Instance = instance;
        Position = {
            X = x or instance.AbsolutePosition.X;
            Y = y or instance.AbsolutePosition.Y;
        };
        Anchored = instance:FindFirstChild("Dragger") == nil;
    }, UIContainer)

    self.Maid = self.Instancer:Make("Maid")
    self:Bind()
    self:GuaranteeBounds()

	return self
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
end


-- Called when the container is dropped from a drag
function UIContainer:DragStop()

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


function UIContainer:Open()
    self.Instance.Visible = true
end


function UIContainer:Close()
    self.Instance.Visible = false
end


function UIContainer:GetContainer()
    return self
end


function UIContainer:Destroy()
    self:Unbind()
    self.Instance:Destroy()
end


return UIContainer
