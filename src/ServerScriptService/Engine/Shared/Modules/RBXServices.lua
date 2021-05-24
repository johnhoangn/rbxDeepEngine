-- RBX Services
-- Dynamese (Enduo)
-- February 20, 2021



local RBXServices = {_DEEPLINKS = false}


return setmetatable(RBXServices, {
	__index = function(tbl, serviceName)
		local loaded = rawget(tbl, serviceName)
		
		if (loaded ~= nil) then
			return loaded
		else
			local service = game:GetService(serviceName)
			
			assert(service ~= nil, ("Invalid RBX Service %s"):format(serviceName))
			rawset(tbl, serviceName, service)
			
			return service
		end
	end,
})