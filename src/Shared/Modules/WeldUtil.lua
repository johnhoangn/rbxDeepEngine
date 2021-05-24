-- Weld Util
-- Dynamese (Enduo)
-- February 24, 2021



local WeldUtil = {}


-- Welds variatic parts to the first argument
-- @param rootPart part to weld other parts to
-- @param ... any number of parts to weld
function WeldUtil:WeldParts(rootPart, ...)
	assert(rootPart:IsA("BasePart"), "Attempt to weld non BasePart")

	for _, part in ipairs({...}) do
		if (not part:IsA("BasePart")) then continue end

		local constraint = Instance.new("WeldConstraint")

		constraint.Part0 = rootPart
		constraint.Part1 = part
		constraint.Name = part.Name .. ">" .. rootPart.Name
		constraint.Parent = rootPart
	end
end


-- Welds children and optionally grandchildren to the model's primary part
-- @param model the model to weld
-- @param grandChildrenToo whether or not to weld recursively
function WeldUtil:WeldModel(model, grandChildrenToo)
	local rootPart = model.PrimaryPart

	assert(rootPart ~= nil, "Attempt to weld a model lacking a PrimaryPart")

	if (grandChildrenToo) then
		self:WeldParts(rootPart, model:GetDescendants())
	else
		self:WeldParts(rootPart, model:GetChildren())
	end
end


-- Welds an entire model to a single part
-- @param rootPart part to weld the model to
-- @param model to weld to the rootPart, must have a primary part
-- @param welded if the model was already welded, default false, will weld recursively
function WeldUtil:WeldModelToPart(rootPart, model, welded)
	assert(rootPart:IsA("BasePart"), "Attempt to weld non BasePart")
	assert(model.PrimaryPart ~= nil, "Attempt to weld a model lacking a PrimaryPart")

	if (not welded) then
		self:WeldModel(model, true)
	end

	self:WeldParts(rootPart, model.PrimaryPart)
end


return WeldUtil