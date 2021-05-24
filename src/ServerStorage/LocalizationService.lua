-- Localization Service
-- Dynamese (Enduo)
-- February 20, 2021


local EnvironmentLanguage = "EN"
local LocalizationService = {}


-- Returns string topics at path
function LocalizationService:GetLocalizedStringTopics(path)
    local directories = path:split(".")
    local category = directories[1]
    local group = directories[2]
    local topics
    
    if (not pcall(function() topics = self.Shared.Strings[EnvironmentLanguage][category][group] end)) then
        error("Invalid string path " .. path)
    end

    return topics
end


-- Returns a specific string inside a string subtopic at path
function LocalizationService:GetLocalizedString(path)
    local directories = path:split(".")
    local topics = LocalizationService:GetLocalizedStringTopics(path)
    local currentDirectory = topics
    local str

    -- Move up to the last directory
    for i = 3, #directories - 1 do
        currentDirectory = currentDirectory[directories[i]]
    end

    str = currentDirectory[directories[#directories]] or currentDirectory[tonumber(directories[#directories])]
    assert(str ~= nil, "Invalid string path " .. path)

    return str
end


function LocalizationService:SetLanguage(lang)
    if (self.Shared.Strings:FindFirstChild(lang) ~= nil) then
        EnvironmentLanguage = lang
    else
        warn("Unsupported language " .. lang)
    end
end


function LocalizationService:GetLanguage()
    return EnvironmentLanguage
end


return LocalizationService