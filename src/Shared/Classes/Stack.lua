local Object = _G.tools.extend(script, 'Object')
local Stack = setmetatable({}, Object)
Stack.__index = Stack


function Stack.new()
	return setmetatable(Object.new({
		Storage = {};
		Size = 0;
	}), Stack)
end


function Stack:Push(data)
	self.Size += 1
	self.Storage[self.size] = data
end


function Stack:Pop()
	assert(self.Size > 0, "UNDERFLOW")
	self.size -= 1
	
	return self.Storage[self.Size + 1]
end


function Stack:Peek()
	return self.Storage[self.Size]
end


function Stack.__tostring(self)
	return "Stack Contents:\n" .. table.concat(self.Storage, ", ")
end


return Stack