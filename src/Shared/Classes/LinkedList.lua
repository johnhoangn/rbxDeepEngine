local LinkedList = {}
local Node = {}
LinkedList.__index = LinkedList
Node.__index = Node


function Node.new()
	return setmetatable({
		Data = nil;
		Next = nil;
	}, Node)
end


function LinkedList.new()
	return setmetatable({
		Head = Node.new();
		Size = 0;
	}, LinkedList)
end


function LinkedList:Add(data)
	local newNode = Node.new()
	
	newNode.Data = data
	newNode.Next = self.Head.Next
	self.Head.Next = newNode
	self.Size += 1
end


function LinkedList:Contains(data)
	return self:FindFirstWhere(
		function(nodeData)
			return nodeData == data
		end) ~= nil
end


function LinkedList:FindFirstWhere(callback)
	local curr = self.Head.Next
	
	while (curr ~= nil) do
		if (callback(curr.Data) == true) then
			return curr.Data
		else
			curr = curr.Next
		end
	end
	
	return nil
end


function LinkedList:Iterator()
	local curr = self.Head
	
	return function()
		curr = curr.Next
		if (curr == nil) then
			return nil
		else
			return curr.Data
		end
	end
end


function LinkedList:Remove(data)
	local curr = self.Head
	
	while (curr.Next ~= nil) do
		if (curr.Next.Data == data) then
			curr.Next = curr.Next.Next
			self.Size -= 1
			break
		else
			curr = curr.Next
		end
	end
end


function LinkedList.__tostring(self)
	local nodes = {}
	local curr = self.Head.Next
	
	while (curr ~= nil) do
		table.insert(nodes, tostring(curr.Data))
		curr = curr.Next
	end
	
	return "List Contents:\n" .. table.concat(nodes, ", ")
end


return LinkedList