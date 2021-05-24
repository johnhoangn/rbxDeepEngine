local Heap = {}
Heap.__index = Heap


function Heap.new(sortingCallback)
	return setmetatable({
		Sorter = sortingCallback;
		Root = nil;
	}, Heap)
end


function Heap:Add(data)
	
end


function Heap:RemoveMax(data)
	
end





return Heap
