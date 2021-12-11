--!nocheck
--[[
	To use: local table = require(this)
	(Yes, override table.)

	Written by EtiTheSpirit. Adds custom functions to the `table` value provided by roblox (in normal cases, this would simply modify `table`, but Roblox has disabled that so we need to use a proxy)
	
	CHANGES:
		3 December 2019 @ 11:07 PM CST:
			+ Added table.join
			
			
		21 November 2019 @ 6:50 PM CST:
			+ Added new method bodies to skip/take using Luau's new methods. Drastic speed increases achieved. CREDITS: Halalaluyafail3 (See https://devforum.roblox.com/t/sandboxed-table-system-add-custom-methods-to-table/391177/12?u=etithespirit)
			+ Added table.retrieve as proposed by ^ under the name "table.range" as this name relays what it does a bit better, I think.
			+ Added table.skipAndTake as an alias method.

--]]

local RNG = Random.new()
local Table = {}

for index, value in pairs(table) do
	Table[index] = value
end

-- Returns true if the table contains the specified value.
Table.contains = function (tbl, value)
	return Table.indexOf(tbl, value) ~= nil -- This is kind of cheatsy but it promises the best performance.
end

-- A combo of table.find and table.keyOf -- This first attempts to find the ordinal index of your value, then attempts to find the lookup key if it can't find an ordinal index.
Table.indexOf = function (tbl, value)
	local fromFind = table.find(tbl, value)
	if fromFind then return fromFind end
	
	return Table.keyOf(tbl, value)
end

-- Returns the key of the specified value, or nil if it could not be found. Unlike IndexOf, this searches every key in the table, not just ordinal indices (arrays)
-- This is inherently slower due to how lookups work, so if your table is structured like an array, use table.find
Table.keyOf = function (tbl, value)
	for index, obj in pairs(tbl) do
		if obj == value then
			return index
		end
	end
	return nil
end

-- ONLY SUPPORTS ORDINAL TABLES (ARRAYS). Skips *n* objects in the table, and returns a new table that contains indices (n + 1) to (end of table)
Table.skip = function (tbl, n)
	return table.move(tbl, n+1, #tbl, 1, table.create(#tbl-n))
end

-- ONLY SUPPORTS ORDINAL TABLES (ARRAYS). Takes *n* objects from a table and returns a new table only containing those objects.
Table.take = function (tbl, n)
	return table.move(tbl, 1, n, 1, table.create(n))
end

-- ONLY SUPPORTS ORDINAL TABLES (ARRAYS). Takes the range of entries in this table in the range [start, finish] and returns that range as a table.
Table.range = function (tbl, start, finish)
	return table.move(tbl, start, finish, 1, table.create(finish - start + 1))
end

-- ONLY SUPPORTS ORDINAL TABLES (ARRAYS). An alias that calls table.skip(skip), and then takes [take] entries from the resulting table.
Table.skipAndTake = function (tbl, skip, take)
	return table.move(tbl, skip + 1, skip + take, 1, table.create(take))
end

-- ONLY SUPPORTS ORDINAL TABLES (ARRAYS). Selects a random object out of tbl
Table.random = function (tbl)
	return tbl[RNG:NextInteger(1, #tbl)]
end

-- ONLY SUPPORTS ORDINAL TABLES (ARRAYS). Merges tbl0 and tbl1 together.
Table.join = function (tbl0, tbl1)
	local nt = table.create(#tbl0 + #tbl1)
	local t2 = table.move(tbl0, 1, #tbl0, 1, nt)
	return table.move(tbl1, 1, #tbl1, #tbl0 + 1, nt)
end

-- ONLY SUPPORTS ORDINAL TABLES (ARRAYS). Removes the specified object from this array.
Table.removeObject = function (tbl, obj)
	local index = Table.indexOf(tbl, obj)
	if index then
		table.remove(tbl, index)
	end
end

-- ONLY SUPPORTS ORDINAL TABLES (ARRAYS). Allocates a new table by getting the length of the current table and increasing its capacity by the specified amount.
-- This uses Roblox's table.create function.
Table.expand = function (tbl, byAmount)
	if (byAmount < 0) then
		error("Cannot expand a table by a negative amount of objects.")
	end
	
	local newtbl = table.create(#tbl + byAmount)
	for i = 1, #tbl do
		newtbl[i] = tbl[i]
	end
	return newtbl
end


--[[
	PartCache V4.0 by Xan the Dragon // Eti the Spirit -- RBX 18406183
	Update V4.0 has added Luau Strong Type Enforcement.
	
	Creating parts is laggy, especially if they are supposed to be there for a split second and/or need to be made frequently.
	This module aims to resolve this lag by pre-creating the parts and CFraming them to a location far away and out of sight.
	When necessary, the user can get one of these parts and CFrame it to where they need, then return it to the cache when they are done with it.
	
	According to someone instrumental in Roblox's backend technology, zeuxcg (https://devforum.roblox.com/u/zeuxcg/summary)...
		>> CFrame is currently the only "fast" property in that you can change it every frame without really heavy code kicking in. Everything else is expensive.
		
		- https://devforum.roblox.com/t/event-that-fires-when-rendering-finishes/32954/19
	
	This alone should ensure the speed granted by this module.
		
		
	HOW TO USE THIS MODULE:
	
	Look at the bottom of my thread for an API! https://devforum.roblox.com/t/partcache-for-all-your-quick-part-creation-needs/246641
--]]
local table = Table

-----------------------------------------------------------
-------------------- MODULE DEFINITION --------------------
-----------------------------------------------------------

local PartCacheStatic = {}
PartCacheStatic.__index = PartCacheStatic
PartCacheStatic.__type = "PartCache" -- For compatibility with TypeMarshaller

-- TYPE DEFINITION: Part Cache Instance
export type PartCache = {
	Open: {[number]: BasePart},
	InUse: {[number]: BasePart},
	CurrentCacheParent: Instance,
	Template: BasePart,
	ExpansionSize: number
}

-----------------------------------------------------------
----------------------- STATIC DATA -----------------------
-----------------------------------------------------------					

-- A CFrame that's really far away. Ideally. You are free to change this as needed.
local CF_REALLY_FAR_AWAY = CFrame.new(0, 10e8, 0)

-- Format params: methodName, ctorName
local ERR_NOT_INSTANCE = "Cannot statically invoke method '%s' - It is an instance method. Call it on an instance of this class created via %s"

-- Format params: paramName, expectedType, actualType
local ERR_INVALID_TYPE = "Invalid type for parameter '%s' (Expected %s, got %s)"

-----------------------------------------------------------
------------------------ UTILITIES ------------------------
-----------------------------------------------------------

--Similar to assert but warns instead of errors.
local function assertwarn(requirement: boolean, messageIfNotMet: string)
	if requirement == false then
		warn(messageIfNotMet)
	end
end

--Dupes a part from the template.
local function MakeFromTemplate(template: BasePart, currentCacheParent: Instance): BasePart
	local part: BasePart = template:Clone()
	-- ^ Ignore W000 type mismatch between Instance and BasePart. False alert.
	
	part.CFrame = CF_REALLY_FAR_AWAY
	part.Anchored = true
	part.Parent = currentCacheParent
	return part
end

function PartCacheStatic.new(template: BasePart, numPrecreatedParts: number?, currentCacheParent: Instance?): PartCache
	local newNumPrecreatedParts: number = numPrecreatedParts or 5
	local newCurrentCacheParent: Instance = currentCacheParent or workspace
	
	--PrecreatedParts value.
	--Same thing. Ensure it's a number, ensure it's not negative, warn if it's really huge or 0.
	assert(numPrecreatedParts > 0, "PrecreatedParts can not be negative!")
	assertwarn(numPrecreatedParts ~= 0, "PrecreatedParts is 0! This may have adverse effects when initially using the cache.")
	assertwarn(template.Archivable, "The template's Archivable property has been set to false, which prevents it from being cloned. It will temporarily be set to true.")
	
	local oldArchivable = template.Archivable
	template.Archivable = true
	local newTemplate: BasePart = template:Clone()
	-- ^ Ignore W000 type mismatch between Instance and BasePart. False alert.
	
	template.Archivable = oldArchivable
	template = newTemplate
	
	local object: PartCache = {
		Open = {},
		InUse = {},
		CurrentCacheParent = newCurrentCacheParent,
		Template = template,
		ExpansionSize = 10
	}
	setmetatable(object, PartCacheStatic)
	
	-- Below: Ignore type mismatch nil | number and the nil | Instance mismatch on the table.insert line.
	for _ = 1, newNumPrecreatedParts do
		table.insert(object.Open, MakeFromTemplate(template, object.CurrentCacheParent))
	end
	object.Template.Parent = nil
	
	return object
	-- ^ Ignore mismatch here too
end

-- Gets a part from the cache, or creates one if no more are available.
function PartCacheStatic:GetPart(): BasePart
	assert(getmetatable(self) == PartCacheStatic, ERR_NOT_INSTANCE:format("GetPart", "PartCache.new"))
	
	if #self.Open == 0 then
		warn("No parts available in the cache! Creating [" .. self.ExpansionSize .. "] new part instance(s) - this amount can be edited by changing the ExpansionSize property of the PartCache instance... (This cache now contains a grand total of " .. tostring(#self.Open + #self.InUse + self.ExpansionSize) .. " parts.)")
		for i = 1, self.ExpansionSize, 1 do
			table.insert(self.Open, MakeFromTemplate(self.Template, self.CurrentCacheParent))
		end
	end
	local part = self.Open[#self.Open]
	self.Open[#self.Open] = nil
	table.insert(self.InUse, part)
	return part
end

-- Returns a part to the cache.
function PartCacheStatic:ReturnPart(part: BasePart)
	assert(getmetatable(self) == PartCacheStatic, ERR_NOT_INSTANCE:format("ReturnPart", "PartCache.new"))
	
	local index = table.indexOf(self.InUse, part)
	if index ~= nil then
		table.remove(self.InUse, index)
		table.insert(self.Open, part)
		part.CFrame = CF_REALLY_FAR_AWAY
		part.Anchored = true
	else
		error("Attempted to return part \"" .. part.Name .. "\" (" .. part:GetFullName() .. ") to the cache, but it's not in-use! Did you call this on the wrong part?")
	end
end

-- Sets the parent of all cached parts.
function PartCacheStatic:SetCacheParent(newParent: Instance)
	assert(getmetatable(self) == PartCacheStatic, ERR_NOT_INSTANCE:format("SetCacheParent", "PartCache.new"))
	assert(newParent:IsDescendantOf(workspace) or newParent == workspace, "Cache parent is not a descendant of Workspace! Parts should be kept where they will remain in the visible world.")
	
	self.CurrentCacheParent = newParent
	for i = 1, #self.Open do
		self.Open[i].Parent = newParent
	end
	for i = 1, #self.InUse do
		self.InUse[i].Parent = newParent
	end
end

-- Adds numParts more parts to the cache.
function PartCacheStatic:Expand(numParts: number): ()
	assert(getmetatable(self) == PartCacheStatic, ERR_NOT_INSTANCE:format("Expand", "PartCache.new"))
	if numParts == nil then
		numParts = self.ExpansionSize
	end
	
	for i = 1, numParts do
		table.insert(self.Open, MakeFromTemplate(self.Template, self.CurrentCacheParent))
	end
end

-- Destroys this cache entirely. Use this when you don't need this cache object anymore.
function PartCacheStatic:Dispose()
	assert(getmetatable(self) == PartCacheStatic, ERR_NOT_INSTANCE:format("Dispose", "PartCache.new"))
	for i = 1, #self.Open do
		self.Open[i]:Destroy()
	end
	for i = 1, #self.InUse do
		self.InUse[i]:Destroy()
	end
	self.Template:Destroy()
	self.Open = {}
	self.InUse = {}
	self.CurrentCacheParent = nil
	
	self.GetPart = nil
	self.ReturnPart = nil
	self.SetCacheParent = nil
	self.Expand = nil
	self.Dispose = nil
end

return PartCacheStatic