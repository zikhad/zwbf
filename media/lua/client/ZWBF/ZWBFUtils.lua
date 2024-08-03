local Utils = {}

local ISToolTip = ISToolTip

--- Create an option in provided menu context
--- @param menu any
--- @param title string
--- @param description string
--- @param func any
function Utils:addOption(menu, title, description, func)
    local toolTip = ISToolTip:new()
    toolTip.description = description
    toolTip:initialise()
    toolTip:setVisible(false)

    --- Create the new sub option
    local option = menu:addOption(title, nil, func)
    option.toolTip = toolTip
end

--- Given a percentage and an arbitrary number, returns the corresponding number between 0 and provided maxNumber
--- @param percentage number
--- @param maxNumber number
--- @return integer
function Utils:percentageToNumber(percentage, maxNumber)
    -- Ensure the percentage is within the valid range
    if percentage < 0 then
        percentage = 0
    elseif percentage > 100 then
        percentage = 100
    end

    -- Calculate the corresponding number between 0 and maxNumber
    return math.floor((percentage / 100) * maxNumber)
end

return Utils
