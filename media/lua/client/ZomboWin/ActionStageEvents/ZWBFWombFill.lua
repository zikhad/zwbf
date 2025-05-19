--- WombFill Events
--- These events will be triggered when ZomboWin Action is performed

--- CONSTANTS
local MIN_AMOUNT = 10
local MAX_AMOUNT = 50

--- Localized global functions from PZ
local getText = getText
local HaloTextHelper = HaloTextHelper
local getPlayer = getPlayer
local ZombRand = ZombRand
local ZombRandFloat = ZombRandFloat

--- ZomboWin Variables
local ZomboWin = require("ZomboWin/ZomboWin")
local ActionEvents = ZomboWin.AnimationHandler.ActionEvents

local Utils = require("ZWBF/ZWBFUtils")

--- VARIABLES
local Womb = require("ZWBF/ZWBFWomb")

table.insert(
        ActionEvents.Perform,
        function(action)
            local character = action.character
            if (
                character:isFemale() and
                Utils.Animation:isAllowed(character)
            ) then
                Womb:intercourse()
                Womb:setIsAnimation(false)
            end
        end
)

table.insert(ActionEvents.Update,
        function(action)
            local character = action.character

            if (
                character:isFemale() and
                Utils.Animation:isAllowed(character)
            ) then
                local duration = action.duration
                local delta = action:getJobDelta()

                Womb:setIsAnimation(true)
                Womb:setAnimationDuration(duration)
                Womb:setAnimationDelta(delta)
            end
        end
)

table.insert(
        ActionEvents.Stop,
        function()
            Womb:setIsAnimation(false)
        end
)
