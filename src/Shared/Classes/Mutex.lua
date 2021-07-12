-- Mutual exclusion lock used for asynchronous operations, not necessarily threading or processes
-- Works via Bindable events' :Wait() method behaving in a way such that only one thread may
-- resume after the event is fired
-- Dynamese (Enduo)
-- 07.11.2021



local DeepObject = require(script.Parent.DeepObject)
local Mutex = {}
Mutex.__index = Mutex
setmetatable(Mutex, DeepObject)


function Mutex.new()
    local bindable = Instance.new("BindableEvent")

	local self = DeepObject.new({
        _Locked = false;
        _Lock = bindable;
    })

	return setmetatable(self, Mutex)
end


-- Attempts to acquire the lock, yields the thread if already locked
function Mutex:Lock()
    if (self._Locked) then
        self._Lock.Event:Wait()
    end

    self._Locked = true
end


-- Attempts to acquire lock, will not yield the thread if failed
-- @returns <boolean> on acquire
function Mutex:TryLock()
    if (not self._Locked) then
        self:Lock()
        return true
    else
        return false
    end
end


-- Releases the lock, and fires the signal for other yielding threads
function Mutex:Release()
    self._Locked = false
    self._Lock:Fire()
end


return Mutex
