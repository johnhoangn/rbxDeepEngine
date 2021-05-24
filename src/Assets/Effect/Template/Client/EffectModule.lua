-- Name this file "EffectModule"


local module = {}


function module:Play(...)
	print("Effect played")
end


function module:Change(...)
	print("Effect changed")
end


function module:Stop(...)
	print("Effect stopped")
end


function module:Reset(...)
	print("Effect reset")
end


function module:Destroy(...)
	print("Effect destroyed")
end


return module
