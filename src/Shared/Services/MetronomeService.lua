-- Metronome Service
-- Dynamese (Enduo)
-- February 24, 2021



local MetronomeService = {Priority = 1001}
local Frequencies = {}
local Tasks = {}
local HTTPService, RunService


-- Binds a callback to a frequency
-- @param rate, target frequency floored
-- @param callback, to execute every time the desired period elapses
-- @return taskID, to unbind later 
function MetronomeService:BindToFrequency(frequency, callback)
    frequency = math.floor(frequency)

    local frequencyTasks = Frequencies[frequency]
    local taskID = HTTPService:GenerateGUID()

	if (frequencyTasks == nil) then
		frequencyTasks = { SinceLastTick = 0; NumTasks = 1; Tasks = {taskID = callback}; }
		Frequencies[frequency] = frequencyTasks
    else
        frequencyTasks.Tasks[taskID] = callback
    end

    Tasks[taskID] = {
        Frequency = frequency;
        Callback = callback;
    }

    return taskID
end


-- Unbinds a callback from a frequency group
-- @param taskID, of the callback
function MetronomeService:Unbind(taskID)
    local task = Tasks[taskID]

    assert(task ~= nil, "Invalid taskID " .. taskID)

    local frequency = task.Frequency

    Tasks[taskID] = nil

    Frequencies[frequency].Tasks[taskID] = nil
    Frequencies[frequency].NumTasks -= 1

    if (Frequencies[frequency].NumTasks <= 0) then
        Frequencies[frequency] = nil
    end
end


function MetronomeService:EngineStart()
	RunService.Stepped:Connect(function(_, dt)
        for frequency, frequencyGroup in pairs(Frequencies) do
            local period = 1/frequency
            
            frequencyGroup.SinceLastTick += dt

            if (frequencyGroup.SinceLastTick >= period) then
                frequencyGroup.SinceLastTick = 0

                for _taskID, callback in pairs(frequencyGroup.Tasks) do
                    callback(period)
                end
            end
        end
    end)
end


function MetronomeService:EngineInit()
	HTTPService = self.RBXServices.HttpService
    RunService = self.RBXServices.RunService
end


return MetronomeService