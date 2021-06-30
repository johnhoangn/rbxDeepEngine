-- Default interface manager for DeepEngine
-- Enduo(Dynamese)
-- 6.24.2021

-- If using this manager, GUI elements must be created from or matching the templates provided
-- This manager creates a system similar to modern operating systems' "active" window functionality
--  allowing multiple draggable windows (containers) to be laid on top of eachother and whenever
--  a lower container or its children are interacted with, the entire container will be brought
--  to the front

-- An "Active" container or cell, not to be confused with the "active" windows from the
--  operating system analogy above, is the topmost container or cell that currently houses the mouse

-- This manager also handles draggable "cells" which are common in modern video games,
--  enabling the developer to implement "drag-and-drop" systems with relative ease
--  by having all of that logic already in place

-- Provided UIElements:
--  UISlider
--  UIVSlider
--  UIButton
--  UIToggle
--  UICell
--  UIContainer



local Interface = {}
local MetronomeService, UserInputService, PlayerGui
local MouseInstance


local ActiveContainer, ActiveCell, DraggingElement
local AllContainers, OpenContainers


-- Retrieves top level UI before the ScreenGUI, dangerous
-- @param gui <Frame>
local function GetUI(gui)
    if (gui.Parent == PlayerGui.Screen) then
        return gui
    else
       return GetUI(gui.Parent)
    end
end


-- Wraps UI instances to be implemented into this service
local function BuildContainers()
    -- TODO: Custom container type constructor handling
    for _, element in ipairs(PlayerGui:WaitForChild("Screen"):GetChildren()) do
        if (element:IsA("Frame")) then
            local container = Interface.Classes.UIContainer.new(element)

            assert(not OpenContainers:Contains(element.Name), "Duplicate container name " .. element.Name)
            assert(not AllContainers:Contains(element.Name), "Duplicate container name " .. element.Name)

            OpenContainers:Add(
                element.Name,
                container
            )

            AllContainers:Add(
                element.Name,
                container
            )

            for _, elementDescendant in ipairs(element:GetChildren()) do
                local newChild

                if (elementDescendant:FindFirstChild("UIButton")) then
                    newChild = Interface.Classes.UIButton.new(
                        elementDescendant,
                        container,
                        nil
                    )
                elseif (elementDescendant:FindFirstChild("UISlider")) then
                    newChild = Interface.Classes.UISlider.new(
                        elementDescendant,
                        container,
                        nil -- Leave default value to a GUI Controller
                    )

                elseif (elementDescendant:FindFirstChild("UIVSlider")) then
                    newChild = Interface.Classes.UIVerticalSlider.new(
                        elementDescendant,
                        container,
                        nil -- Leave default value to a GUI Controller
                    )

                elseif (elementDescendant:FindFirstChild("UIToggle")) then
                    newChild = Interface.Classes.UIToggle.new(
                        elementDescendant,
                        container,
                        nil -- Leave default value to a GUI Controller
                    )
                else
                    continue
                end

                container:AddChild(
                    newChild,
                    elementDescendant.Name
                )

                newChild:Bind()
            end

            container:Bind()
            container:GuaranteeBounds()
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

                local container = AllContainers:Get(GetUI(element).Name)

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
-- @param element <UIContainer>
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
-- @param element, <UIElement>
-- @return <boolean>
function Interface:Obscured(element)
    -- Saves some compute
    if (GetUI(element.Instance).ZIndex == OpenContainers.Size) then
        return false
    end

    local elementsHere = PlayerGui:GetGuiObjectsAtPosition(MouseInstance.X, MouseInstance.Y)

	for _, thIsAlem in ipairs(elementsHere) do
        if (not thIsAlem.Visible) then
            continue
        end

        -- First visible element
		if (thIsAlem == element.Instance or thIsAlem:IsDescendantOf(element.Instance)) then
			return false
		else
			return true
		end
	end
end


-- Assigns a container to be active
-- @param container <UIContainer>
function Interface:SetActiveContainer(container)
    ActiveContainer = container
end


-- Assigns a cell to be active
-- @param cell <UICell>
function Interface:SetActiveCell(cell)
    ActiveCell = cell
end


-- Retrieves the container that currently houses the mouse
-- @returns <UIContainer>
function Interface:GetActiveContainer()
    return ActiveContainer
end


-- Retrieves the cell that currently houses the mouse
-- @returns <UICell>
function Interface:GetActiveCell()
    return ActiveCell
end


-- Drops the dragging UIElement
-- @param element <UIElement>
function Interface:DragStop(element)
    assert(DraggingElement == element, "Dropped element was not the active dragging element or multiple drag")

    DraggingElement = nil

    if (element:IsA("UIContainer")) then
        print("Dropped a container")
    elseif (element:IsA("UICell")) then
        print("Dropped a cell")
    end

    self.CellDropped:Fire(element, ActiveContainer, ActiveCell)
end


-- Starts to drag an element
-- @param element <UIElement>
function Interface:Drag(element)
    assert(DraggingElement == nil, "Attempt to double drag")

    DraggingElement = element

    local mouseOrigin = {
        X = MouseInstance.X;
        Y = MouseInstance.Y;
    }

    local maid = self.Classes.Maid.new()
    local dragStopSignal = self.Classes.Signal.new()
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


-- Retrieves all containers, visible or not
-- @returns <HashMap>
function Interface:GetAllContainers()
    return AllContainers:ToMap()
end


-- Retrieves all visible containers
-- @returns <HashMap>
function Interface:GetOpenContainers()
    return OpenContainers:ToMap()
end


-- Retrieves the container identified by name
-- @param name <string>
-- @returns <UIContainer>
function Interface:GetContainer(name)
    local container = AllContainers:Get(name)

    assert(container ~= nil, "No container by " .. name)

    return container
end


-- Places a container at a position
-- @param name <string>
-- @param position <UDIM2>
function Interface:PlaceContainer(name, position)
    local container = self:GetContainer(name)

    container.Instance.Position = position
    container:GuaranteeBounds()
end


function Interface:EngineInit()
    MetronomeService = self.Services.MetronomeService
    UserInputService = self.RBXServices.UserInputService

    PlayerGui = self.LocalPlayer.PlayerGui
    MouseInstance = self.LocalPlayer:GetMouse()

    OpenContainers = self.Classes.IndexedMap.new()
    AllContainers = self.Classes.IndexedMap.new()
    ActiveContainer = nil

    self.DoubleClickWindow = 0.25 -- seconds
    self.DragThresholdSq = 10 ^ 2 -- px, squared

    self.CellDropped = self.Classes.Signal.new()
end


function Interface:EngineStart()
    BuildContainers()
    ListenForWakeups()
end


return Interface