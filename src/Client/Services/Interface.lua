local Interface = {}
local Network, MetronomeService, UserInputService, PlayerGui
local MouseInstance


local ActiveContainer, ActiveCell, DraggingElement
local AllContainers, OpenContainers


-- Retrieves top level container, dangerous
-- @param element
local function GetContainer(element)
    if (element.Parent == PlayerGui.Screen) then
        return element
    else
       return GetContainer(element.Parent)
    end
end


-- Wraps UI instances to be implemented into this service
local function BuildContainers()
    -- TODO: Custom container type constructor handling
    for _, element in ipairs(PlayerGui:WaitForChild("Screen"):GetChildren()) do
        if (element:IsA("Frame")) then
            local container = Interface.Instancer:Make("UIContainer", element)

            OpenContainers:Add(
                element,
                container
            )

            AllContainers:Add(
                element,
                container
            )
        end
    end
end


-- "Wakeups" are when the mouse interacts with an inactive container
local function ListenForWakeups()
    UserInputService.InputBegan:Connect(function(object)
        if (object.UserInputType == Enum.UserInputType.MouseButton1
            or object.UserInputType == Enum.UserInputType.MouseButton2) then

            local elementsHere = PlayerGui:GetGuiObjectsAtPosition(MouseInstance.X, MouseInstance.Y)

            for _, element in ipairs(elementsHere) do
                if (not element.Visible) then
                    continue
                end

                local container = AllContainers:Get(GetContainer(element))

                if (container == nil) then
                    continue
                end

                -- Discovered not-obscured-where-the-mouse-is container
                if (not Interface:Obscured(container)) then
                    Interface:BringToFront(container)
                    break
                end
            end
        end
    end)
end


-- Brings an element to the front and drops everything else, that
--  was above it, down one
-- @param element
function Interface:BringToFront(element)
    local hole = element.Instance.ZIndex

    -- We're already at the top
    if (hole == OpenContainers.Size) then
        return
    end

    -- For every open container, if its ZIndex is greater than our
    --  current element's ZIndex, decrement it by 1 to fill the gap
    for _, listElement in OpenContainers:Iterator() do
        if (listElement == element) then
            element.Instance.ZIndex = OpenContainers.Size

        elseif (listElement.Instance.ZIndex > hole) then
            listElement.Instance.ZIndex -= 1
        end
    end
end


-- Checks if a UI element is obscured at Mouse.X/Y
-- @param element, UIElement class
-- @return boolean
function Interface:Obscured(element)
    -- Saves some compute
    if (element.Instance.ZIndex == OpenContainers.Size) then
        return false
    end

    local elementsHere = PlayerGui:GetGuiObjectsAtPosition(MouseInstance.X, MouseInstance.Y)

	for _, thisElem in ipairs(elementsHere) do
        if (not thisElem.Visible) then
            continue
        end

        -- First visible element
		if (thisElem == element.Instance or thisElem:IsDescendantOf(element.Instance)) then
			return false
		else
			return true
		end
	end
end


-- Assigns a container to be active
-- @param container
function Interface:SetActiveContainer(container)
    ActiveContainer = container
end


-- Assigns a cell to be active
-- @param cell
function Interface:SetActiveCell(cell)
    ActiveCell = cell
end


-- Retrieves the container that currently houses the mouse
function Interface:GetActiveContainer()
    return ActiveContainer
end


-- Retrieves the cell that currently houses the mouse
function Interface:GetActiveCell()
    return ActiveCell
end


-- Drops the dragging element
-- @param element
function Interface:DragStop(element)
    assert(DraggingElement == element, "Dropped element was not the active dragging element or multiple drag")

    element:DragStop()
    DraggingElement = nil

    if (element:IsE("UIContainer")) then
        print("Dropped a container")
    elseif (element:IsE("UIButton")) then
        print("Dropped a button")
    end
end


-- Starts to drag an element
-- @param element
function Interface:Drag(element)
    assert(DraggingElement == nil, "Attempt to double drag")

    DraggingElement = element

    local mouseOrigin = {
        X = MouseInstance.X;
        Y = MouseInstance.Y;
    }

    local maid = self.Instancer:Make("Maid")
    local dragStopSignal = self.Instancer:Make("Signal")
    local taskID = MetronomeService:BindToFrequency(60, function(dt)
        local deltaX = MouseInstance.X - mouseOrigin.X
        local deltaY = MouseInstance.Y - mouseOrigin.Y
        local deltaDisp = math.sqrt( (deltaX)^2 + (deltaY)^2 )

        if (deltaDisp > 0) then
            element.Instance.Position += UDim2.new(0, deltaX, 0, deltaY)
            mouseOrigin.X += deltaX
            mouseOrigin.Y += deltaY
        end
    end)

    maid:GiveTask(dragStopSignal)
    maid:GiveTask(function()
        MetronomeService:Unbind(taskID)
    end)
    maid:GiveTask(
        -- Potentially move to an input manager
        UserInputService.InputEnded:Connect(function(iObject)
            if (iObject.UserInputType == Enum.UserInputType.MouseButton1) then
                dragStopSignal:Fire()
            end
        end)
    )

    dragStopSignal:Connect(function()
        self:DragStop(element)
        maid:Destroy()
    end)
end


function Interface:EngineInit()
	Network = self.Services.Network
    MetronomeService = self.Services.MetronomeService
    UserInputService = self.RBXServices.UserInputService

    PlayerGui = self.LocalPlayer.PlayerGui
    MouseInstance = self.LocalPlayer:GetMouse()

    OpenContainers = self.Instancer:Make("IndexedMap")
    AllContainers = self.Instancer:Make("IndexedMap")
    ActiveContainer = nil
end


function Interface:EngineStart()
    BuildContainers()
    ListenForWakeups()
end


return Interface