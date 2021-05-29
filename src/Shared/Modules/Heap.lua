-- INCOMPLETE


local FLOOR = math.floor


local Heap = {}
Heap.__index = Heap


-- max heap
function Heap.new(scoringFunction)
	return setmetatable({
		Storage = {};
		Size = 0;
		ScoringFunction = scoringFunction;
	}, Heap)
end


function Heap:Add(data)
	local scorer = self.ScoringFunction
	local storage = self.Storage
	
	local newScore = scorer(data)
	local currIndex = self.Size + 1
	
	storage[currIndex] = data
	self.Size += 1
	
	while (currIndex > 1) do
		local parent = FLOOR(currIndex/2)

		if (scorer(storage[parent]) < newScore) then
			storage[parent], storage[currIndex] = storage[currIndex], storage[parent]			
			currIndex = parent
		else
			break
		end
	end
end


function Heap:Remove(data)
	local storage = self.Storage
	local root = table.find(storage, data)
	local scorer = self.ScoringFunction
	local left, right
	
	while (root <= self.Size) do
		local leftIndex = root * 2 + 1
		local rightIndex = root * 2 + 1
		
		left = storage[leftIndex]
		right = storage[rightIndex]
		
		if (left ~= nil and right ~= nil) then
			if (scorer(left) > scorer(right)) then
				storage[root], storage[leftIndex] = storage[leftIndex], storage[root]
				root = leftIndex
				
			else
				storage[root], storage[rightIndex] = storage[rightIndex], storage[root]
				root = rightIndex
			end
			
		elseif (left ~= nil) then
			storage[root], storage[leftIndex] = storage[leftIndex], storage[root]
			root = leftIndex
			
		elseif (right ~= nil) then
			storage[root], storage[rightIndex] = storage[rightIndex], storage[root]
			root = rightIndex
			
		else
			break
		end
	end
	
	self.Size -= 1
end


function Heap:RemoveMax()
	self:Remove(self.Storage[1])
end


function Heap:Update(data)
	
end


function Heap:__tostring()
	local concatTab = {}
	
	for i = 1, self.Size do
		local data = self.Storage[i]
		
		table.insert(concatTab, string.format("%d %s:%s", i, data, self.ScoringFunction(data)))
	end	
	
	return table.concat(concatTab, "\n")
end


return Heap