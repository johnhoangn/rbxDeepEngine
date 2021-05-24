local Queue = {}
local Node = {}
Queue.__index = Queue
Node.__index = Node


function Node.new()
	return setmetatable({
		Data = nil;
		Prev = nil;
		Next = nil;
	}, Node)
end


function Queue.new()
	local head = Node.new();
	local tail = Node.new();
	
	head.Next = tail
	tail.Prev = head
	
	return setmetatable({
		Head = head;
		Tail = tail;
		Size = 0;
	}, Queue)
end


-- @return emptiness
function Queue:IsEmpty()
	return self.Head.Next == self.Tail
end


-- Inserts at the end
-- @param data, payload to insert
function Queue:Enqueue(data)
	local newNode = Node.new()
	
	newNode.Data = data
	newNode.Next = self.Tail
	newNode.Prev = self.Tail.Prev
	self.Tail.Prev.Next = newNode
	self.Tail.Prev = newNode
	
	self.Size += 1
end


-- Retrieves the front data
-- @returns front data
function Queue:Peek()
	return self.Head.Next.Data
end


-- Removes and returns the front
-- @return front payload
function Queue:Dequeue()
	assert(not self:IsEmpty(), "UNDERFLOW")
	
	local node = self.Head.Next
	
	node.Next.Prev = node.Prev
	node.Prev.Next = node.Next
	self.Size -= 1
	
	return node.Data
end


-- Searches from the beginning of the queue for the first payload
--	where callback(payload) returns true
-- @param callback search qualifier
-- @return payload
function Queue:FindFirstWhere(callback)
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


-- Pretty-fication
function Queue.__tostring(self)
	local nodes = {}
	local curr = self.Head.Next
	
	while (curr ~= self.Tail) do
		table.insert(nodes, tostring(curr.Data))
		curr = curr.Next
	end
	
	return "Queue Contents:\n" .. table.concat(nodes, ", ")
end


return Queue