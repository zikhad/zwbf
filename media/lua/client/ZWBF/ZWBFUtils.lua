local Utils = {}

local ISToolTip = ISToolTip
local ISTimedActionQueue = ISTimedActionQueue;
local getPlayer = getPlayer;

local AnimationUtils = require("ZomboWin/ZomboWinAnimationUtils")

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


--- Gets the player current animation
--- @param player any | nil
--- @return string | nil
function Utils:getAnim(player)
    player = player or getPlayer()
	--Loop through table but returns first result
    for i,n in pairs(ISTimedActionQueue.getTimedActionQueue(player).queue) do
		--Returns name of the animation
        return n.animation --Or reutrn n for full table information
	end
    return nil
end

--- Returns true if the animation is whitelisted
--- @param animation string | nil
--- @return boolean
function Utils:isAnimationAllowed(animation)
    animation = animation or ""
    -- TODO: Is it possible to use the tag system to check if the animation is allowed?
    --[[
        local allowedAnimations = AnimationUtils:getAnimations(2,1,1,{"Intercourse"}, {}, false)
        for _, allowedAnimation in ipairs(allowedAnimations) do
            if string.find(animation, allowedAnimation.id) then
                return true
            end        
        end
        return false
        print("XPTO - " .. tostring(xpto));
    ]]

        local blacklist = {
            "bj",
            "blowjob",
            "oral",
            "masturbation",
            "female2",
            "fingering"
        }

        animation = string.lower(animation)

        for _, value in ipairs(blacklist) do
            if string.find(animation, value) then
                return false
            end
        end
        return true
end

return Utils
