local IndexedMap = {}
IndexedMap.__index = function(tbl, index)
	local iType = typeof(index)
	if (iType == "number") then
		return tbl.Storage[index]
	elseif (iType == "instance") then
		return nil
	else
		return IndexedMap[index]
	end
end


function IndexedMap.new()
	return setmetatable({
		Size = 0;
		Storage = {};
		HashMap = {};
	}, IndexedMap)
end


function IndexedMap:IndexOf(key)
	if (key == nil) then return nil end
	
	local bundle = self.HashMap[key]
	
	if (bundle == nil) then
		return -1
	else
		return bundle.Index
	end
end


function IndexedMap:Contains(key)
	if (key == nil) then return false end
	return self:IndexOf(key) ~= -1
end


function IndexedMap:Add(key, data)
	local insertedAt = self.Size + 1
	local bundle = {
		Payload = data;
		Index = insertedAt;
	}
	
	self.HashMap[key] = bundle
	self.Storage[insertedAt] = bundle
	self.Size += 1
end


function IndexedMap:Remove(key)
	local targetBundle = self.HashMap[key]
	
	if (targetBundle == nil) then
		return nil
	end
	
	local replacementBundle = self.Storage[self.Size]
	
	replacementBundle.Index = targetBundle.Index
	
	self.HashMap[key] = nil
	self.Storage[targetBundle.Index] = replacementBundle
	self.Storage[self.Size] = nil
	self.Size -= 1
	
	return targetBundle.Payload
end


function IndexedMap:Get(key)
	if (key == nil) then return nil end
	
	--assert(self:Contains(key), "Map does not contain key: " .. tostring(key))
	local bundle = self.HashMap[key]
	
	if (bundle == nil) then
		return nil
	else
		return bundle.Payload
	end
end


function IndexedMap:GetByIndex(index)
	local bundle = self.Storage[index]

	if (bundle == nil) then
		return nil
	else
		return bundle.Payload
	end
end


function IndexedMap:Iterator()
    local index = 0

	return function()
        index += 1

        local bundle = self.Storage[index]

		if (bundle ~= nil) then
			return index, bundle.Payload
		else
			return nil
		end
    end
end


function IndexedMap:KeyIterator()
	local keys = table.create(self.Size)
	local i = 1
	
	for key, _ in pairs(self.HashMap) do
		keys[i] = key
		i += 1
	end
	
	i = 0
	
	table.sort(keys, function(a, b)
		return a < b
	end)
	
	return function()
		i += 1
		local bundle = self.HashMap[keys[i]]
		
		if (bundle ~= nil) then
			return keys[i], bundle.Payload
		else
			return nil
		end
	end
end


function IndexedMap:ToArray()
	local arr = table.create(self.Size)
	
	for _, elem in self:Iterator() do
		table.insert(arr, elem)
	end
	
	return arr
end


function IndexedMap:HashMap()
	local map = {}
	
	for k, v in pairs(self.HashMap) do
		map[k] = v.Payload
	end
	
	return map
end


return IndexedMap