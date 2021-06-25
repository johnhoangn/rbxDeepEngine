-- FakeCAS
-- Enduo (Dynamese)
-- 8.20.2020
-- Builtin ContextActionService uses a stack to bind actions to an input
--  which forces the developer to unbind an entire action
--  in order to re-enable a different action lower in the stack. To avoid this,
--  FakeCAS uses an action list instead of a stack



local uis = game:GetService('UserInputService')
local cas = {}
local boundEnums = {}
local boundActions = {}



-- Bind an action to input(s)
-- @param actionName <string>
-- @param callback <function>
-- @param input <Enum>
function cas:BindAction(actionName, callback, input)
	local actionsBoundToThisInput = boundEnums[input]

	if not actionsBoundToThisInput then
		boundEnums[input] = {}
		actionsBoundToThisInput = boundEnums[input]
	end

	assert(actionsBoundToThisInput[actionName] == nil, 'duplicate action ' .. actionName)

	actionsBoundToThisInput[actionName] = callback
	boundActions[actionName] = input
end


-- Retrieves the input bound to this action and unbinds it
-- @param action <string>
function cas:UnbindAction(action)
	local input = boundActions[action]

	boundEnums[input][action] = nil
	boundActions[action] = nil
end


-- Listen for input starts and if there are callbacks bound to them, execute
uis.InputBegan:Connect(function(object, proc)
    -- Textbox guard clause
    if (uis:GetFocusedTextBox() ~= nil) then
        return
    end
    
	local kCode, uType = object.KeyCode, object.UserInputType
	local actionsBoundToInput = boundEnums[kCode] or boundEnums[uType]

	if actionsBoundToInput then
		for action, callback in pairs(actionsBoundToInput) do
			callback(action, Enum.UserInputState.Begin, object, proc)
		end
	end
end)


-- Listen for input ends and if there are callbacks bound to them, execute
uis.InputEnded:Connect(function(object, proc)
    -- Textbox guard clause
    if (uis:GetFocusedTextBox() ~= nil) then
        return
    end

	local kCode, uType = object.KeyCode, object.UserInputType
	local actionsBoundToInput = boundEnums[kCode] or boundEnums[uType]

	if actionsBoundToInput then
		for action, callback in pairs(actionsBoundToInput) do
			callback(action, Enum.UserInputState.End, object, proc)
		end
	end
end)


-- Listen for input changes and if there are callbacks bound to them, execute
uis.InputChanged:Connect(function(object, proc)
    -- Textbox guard clause
    if (uis:GetFocusedTextBox() ~= nil) then
        return
    end

	local kCode, uType = object.KeyCode, object.UserInputType
	local actionsBoundToInput = boundEnums[kCode] or boundEnums[uType]

	if actionsBoundToInput then
		for action, callback in pairs(actionsBoundToInput) do
			callback(action, Enum.UserInputState.Change, object, proc)
		end
	end
end)


return cas
