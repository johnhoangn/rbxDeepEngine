local InputService = {Priority = 100}


local UserInputService
local InputHooks
local ActionInputMap


local function DoInput(object, proc)
	local hooks = InputHooks:Get(object.KeyCode) or InputHooks:Get(object.UserInputType)
	
	if (hooks ~= nil) then
		for _, hook in hooks:KeyIterator() do
			if (hook.Filter and object.UserInputState ~= hook.Filter) then continue end
			hook.Callback(object, proc)
		end
	end
end


function InputService:BindAction(inputEnum, actionName, actionCallback, stateFilter)
	if (not InputHooks:Get(inputEnum)) then
		InputHooks:Add(inputEnum, self.Classes.IndexedMap.new())
	end

	assert(not InputHooks:Get(inputEnum):Contains(actionName), 
		string.format("Attempt to double bind action %s on same input %s", actionName, inputEnum.Name))

	ActionInputMap:Add(actionName, inputEnum)
	InputHooks:Get(inputEnum):Add(actionName, {
		Callback = actionCallback;
		Filter = stateFilter;
	})
end


function InputService:UnbindAction(actionName)
	InputHooks:Get(ActionInputMap:Get(actionName)):Remove(actionName)
end


function InputService:EngineInit()
	UserInputService = self.RBXServices.UserInputService
	InputHooks = self.Classes.IndexedMap.new()
	ActionInputMap = self.Classes.IndexedMap.new()

	UserInputService.InputBegan:Connect(DoInput)
	UserInputService.InputChanged:Connect(DoInput)
	UserInputService.InputEnded:Connect(DoInput)
end


function InputService:EngineStart()
end


return InputService