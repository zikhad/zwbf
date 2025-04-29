local Utils = {}
Utils.Table = {} -- Utility functions for tables
Utils.Animation = {} -- Utility functions for animations
Utils.Inventory = {} -- Utility functions related to Inventory

-- Localized PZ Variables
local ISToolTip = ISToolTip
local ISTimedActionQueue = ISTimedActionQueue;
local getPlayer = getPlayer;
local ZomboWinAnimationData = ZomboWinAnimationData;

-- ZomboWin Variables
local AnimationUtils = require("ZomboWin/ZomboWinAnimationUtils")

-- LOCAL FUNCTIONS

--- Gets the player current animation
--- @param player any | nil
--- @return string | nil
local function getAnim(player)
    player = player or getPlayer()
	--Loop through table but returns first result
    for i,n in pairs(ISTimedActionQueue.getTimedActionQueue(player).queue) do
		--Returns name of the animation
        return n.animation --Or reutrn n for full table information
	end
    return nil
end

-- Get animation info table
local function getAnimInfo(player)
    -- Get Current animation name
    local CurrentAnim = getAnim(player or getPlayer())
    -- Check if any animation is playing
    if not CurrentAnim then return nil end

    -- Loop through all animations in ZomboWinAnimationData
    for _, data in pairs(ZomboWinAnimationData) do
        -- Loop through all actors in the current animation data
        for _, actor in ipairs(data.actors) do
            -- Compare current animation name with the actor's perform stage
            if actor.stages[1].perform == CurrentAnim then
                -- Return the animation data for the current animation
                return data
            end
        end
    end

    -- Return nil if no matching animation is found
    return nil
end
-- // LOCAL FUNCTIONS

--- Returns character skin color
--- @param character any
--- @return integer
function Utils:getSkinColor(character)
    character = character or getPlayer()
   return character:getHumanVisual():getSkinTextureIndex()
end

--- Define the function to check if any value from table1 exists in table2
--- @param table1 table
--- @param table2 table
function Utils.Table:some(table1, table2)
    for _, value1 in ipairs(table1) do
        for _, value2 in ipairs(table2) do
            if value1 == value2 then
                return true
            end
        end
    end
    return false
end


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

--- Check if the current animation does not have any of the excluded tags
--- @param player any | nil character of the animation (default: player)
--- @param excludedTags string[] | nil table with tags to exclude
--- @return boolean
function Utils.Animation:isAllowed(player, excludedTags)
    player = player or getPlayer()
    excludedTags = excludedTags or {"Oral", "Masturbation", "Anal", "Solo", "Mast"}

    local animationData = getAnimInfo(player) or {}
    if Utils.Table:some(animationData.tags or {}, excludedTags) then
        return false
    end
    return true
end

--- Returns the item if player is wearing it
--- @param itemName string
--- @param player any
--- @return table | nil
function Utils.Inventory:wearingItem(itemName, player)
    player = player or getPlayer()
    local wornItems = player:getWornItems()
    if not wornItems then return nil end

    for i = wornItems:size() - 1, 0, -1 do
        local item = wornItems:get(i):getItem()
        if item:IsClothing() and item:getName() == itemName then
            return item
        end
    end

    return nil
end

--- Returns true if the player have the item in inventory
--- @param itemName any
--- @return boolean
function Utils.Inventory:hasItem(itemName, player)
    player = player or getPlayer()
    local inventory = player:getInventory()
    local items = inventory:getItems()
    if items then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if itemName == item:getFullType() then
                return true
            end
        end
    end
    return false
end

return Utils
