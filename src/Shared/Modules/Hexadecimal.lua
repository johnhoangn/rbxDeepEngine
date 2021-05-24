-- Hexadecimal
-- Dynamese (Enduo)
-- February 24, 2021



local FLOOR = math.floor


local Hexadecimal = {}
local Alphabet = {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 
    "A", "B", "C", "D", "E", "F"
}


function Hexadecimal.new(integer, numChars)
    local final = {}
    local isNegative = integer < 0

    numChars = numChars or 1

    if (integer < 0) then
        integer *= -1
    end

    while (integer > 0) do
        local int = FLOOR(integer/16)
        local rem = integer - int * 16

        integer = int

        table.insert(final, Alphabet[rem + 1])
    end

    local currLen = #final
    for _ = 1, numChars - currLen do
        table.insert(final, "0")
    end

    local hex = table.concat(final):reverse()

    if (isNegative) then
        return "-" .. hex
    else
        return hex
    end
end


return Hexadecimal