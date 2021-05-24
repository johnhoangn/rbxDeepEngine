-- Instancer to manage WBH specific classes
-- Dynamese (Enduo)
-- February 20, 2021



local ClassInstances = {} -- Behaves like tags on non builtin types
local Heap = {Size = 0}
local Instancer = {}
local HttpService, CustomClass


-- Instantiates a new object
-- @param className
-- @param variatic
function Instancer:Make(className, ...)
	local class = CustomClass[className]
	
	assert(class ~= nil, "Invalid class: " .. className)
	
	local newInstance = class.new(...)
	
    return newInstance
end


-- Helper for Object:IsA()
-- @param instance to check class descent of
-- @param isA class to check class descent from
-- @return true if instance is of class descent
function Instancer:ClassDescent(instance, isA)
    local className = instance.ClassName
    local extends = CustomClass[className].Extends

    while (extends ~= nil) do
        if (className == isA) then
            return true
        else
            className = extends
            extends = CustomClass[extends].Extends
        end
    end

    return false
end


-- Retrieves all instances of a class
-- @param class the class of instances to retrieve as {InstanceID, instance} pairs
-- @return instances of class
function Instancer:GetInstancesOf(class)
    assert(CustomClass[class] ~= nil, "Invalid class " .. tostring(class))

    -- if the class has never been instantiated yet, the table will be nil
    return ClassInstances[class] or {}
end


function Instancer:EngineInit()
	local ClassFolder = self.EnvironmentFolder.Classes
	
	HttpService = self.RBXServices.HttpService
	CustomClass = setmetatable({}, {
		__index = function(tbl, class)
			local cached = rawget(tbl, class)
			
			if (cached ~= nil) then
				return cached
			else
				local classModule = ClassFolder:FindFirstChild(class)
				
				assert(classModule ~= nil, "Invalid class " .. class)
				classModule = require(classModule)				
				rawset(tbl, class, classModule)
				self:Link(classModule)
				
				return classModule
			end
		end,
	})
end


return Instancer