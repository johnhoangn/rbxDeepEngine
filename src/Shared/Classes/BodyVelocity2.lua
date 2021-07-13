-- BodyVelocity2, BodyVelocity's successor (at least I hoped it to be)
-- Created since Constraint-based linear velocity is still not here

-- Managed to 99.99% match normal BodyVelocity
--  (the catch is you have to set the part's velocity on the first frame for the last .01%)

-- Usage: Treat it like a normal BodyVelocity, parent it, change maxforce, change velocity, etc.

-- Dynamese (Enduo)
-- 7.12.2021

-- Updated using .AssemblyMass, this should work well enough in all situations now


local ZERO_VECTOR = Vector3.new()
local DEFAULT_MAX_FORCE = 4000 -- All axes

local RunService = game:GetService("RunService")

local BodyVelocity2 = {}
BodyVelocity2.__index = BodyVelocity2

local Managed = {
    Num = 0;
    List = {};
}

local Stepper = nil


-- If stepper not initialized, start one
local function TryStart()
    if (Stepper == nil) then
        Stepper = RunService.Heartbeat:Connect(function()
            for bv, _ in pairs(Managed.List) do
                if (bv._Parent == nil) then continue end
                bv:Step()
            end
        end)
    end
end


-- Creates a new BodyVelocity2 instance
function BodyVelocity2.new()
    local vForce = Instance.new("VectorForce")
    local attach = Instance.new("Attachment")
	local self = setmetatable({
        -- Default values for BodyVelocity
        -- P has no effect in PGS solver, omitting
        _Velocity = Vector3.new();
        _MaxForce = Vector3.new(1, 1, 1) * DEFAULT_MAX_FORCE;
        _Parent = nil;

        Instance = vForce;
        Attach = attach;
	}, BodyVelocity2)

    vForce.Force = ZERO_VECTOR
    vForce.ApplyAtCenterOfMass = true
    vForce.Attachment0 = attach
    vForce.RelativeTo = Enum.ActuatorRelativeTo.World

    Managed.Num += 1
    Managed.List[self] = true

	return self
end


function BodyVelocity2.__newindex(self, index, value)
    if (index == "Parent") then
        rawset(self, "_Parent", value)
        self.Instance.Parent = value
        self.Attach.Parent = value
        TryStart()

    elseif (index == "Velocity") then
        --self._Parent.AssemblyLinearVelocity = value
        rawset(self, "_Velocity", value)
        TryStart()

    elseif (index == "MaxForce") then
        rawset(self, "_MaxForce", value)
        TryStart()

    else
        rawset(self, index, value)
    end
end


-- Updates the VectorForce to achieve target velocity
-- https://devforum.roblox.com/t/replicating-bodyvelocity-using-constraints/307790/20
function BodyVelocity2:Step()
    local part = self._Parent
    local targetForce =
        (Vector3.new(0, workspace.Gravity, 0)
        + (self._Velocity - part.Velocity)) * part.AssemblyMass

    self.Instance.Force = Vector3.new(
        math.clamp(targetForce.X, -self._MaxForce.X, self._MaxForce.X),
        math.clamp(targetForce.Y, -self._MaxForce.Y, self._MaxForce.Y),
        math.clamp(targetForce.Z, -self._MaxForce.Z, self._MaxForce.Z)
    )
end


function BodyVelocity2:Destroy()
    self.Instance:Destroy()
    self.Attach:Destroy()

    Managed.Num -= 1
    Managed.List[self] = nil

    -- Let's not use runservice when there are no BVs out there
    if (Stepper ~= nil and Managed.Num == 0) then
        Stepper:Disconnect()
        Stepper = nil
    end
end


return BodyVelocity2
