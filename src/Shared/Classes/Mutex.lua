-- Mutual exclusion lock used for asynchronous operations, not necessarily threading or processes
-- Previous version had a fundemental misunderstanding of how the lua scheduler worked.
-- It wasn't that only one "thread" resumes after the event is fired, lua only ever has one
--  thread running anyway; HOWEVER, all threads who were previously waiting for the event
--  are now back on the scheduler queue so if, inbetween a :Lock() and :Release() occurred YIELDING CODE
--  causing the thread that owns the lock to sleep, and the scheduler will start another thread in the middle
--  of the lock, causing all sorts of undefined behaviour.
--
-- To solve this whole headache, since all threads who were waiting on the event are now back on the
--  scheduler queue, we simply loop the Locked check so that all but one thread go right back to sleep.

-- Dynamese (Enduo)
-- 07.21.2021



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
function Mutex:Lock(callback)
    -- All threads that got in must check if this is still locked,
    --  just in case the owner thread is sleeping
    while (self._Locked) do
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


-- Unlocks this mutex and signals to sleeping threads
function Mutex:Unlock()
    self._Locked = false
    self._Lock:Fire()
end


return Mutex
