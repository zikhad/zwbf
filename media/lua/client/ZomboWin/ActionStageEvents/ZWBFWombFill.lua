--- WombFill Events
--- These events will be triggered when ZomboWin Action is performed
--- @autor Zikhad 2024

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
local Pregnancy = require("ZWBF/ZWBFPregnancy")
local Womb = require("ZWBF/ZWBFWomb")

--- LOCAL FUNCTIONS

--- Inject sperm into the player's womb
local function injectSperm()
	local amount = ZombRand(MIN_AMOUNT, MAX_AMOUNT) -- Random amount between MIN and MAX
	Womb:addSperm(amount)

	-- show a Halo Text with the amount of sperm injected
	local player = getPlayer()
	local text = string.format("%s %sml", getText("IGUI_ZWBF_UI_Sperm"), amount)
	HaloTextHelper.addTextWithArrow(player, text, true, HaloTextHelper.getColorGreen())
end

--- Handles impregnation
local function impregnate()
	local player = getPlayer()
	if Pregnancy:getIsPregnant() or Womb:getOnContraceptive() then return end
	local fertility = Womb:getFertility()
	if ZombRandFloat(0, 1) > (1 - fertility) then
		local text = getText("IGUI_ZWBF_UI_Fertilized")
		HaloTextHelper.addText(player, text, HaloTextHelper.getColorGreen())
		Pregnancy:start()
	end
end

--- Add the event to the ActionEvents
table.insert(
	ActionEvents.Perform,
	function(action)
		local character = action.character
		if not character:isFemale() then return end
		if Utils.Animation:isAllowed(character) then
			injectSperm()    --- Inject sperm into the womb
			impregnate()     --- Handle impregnation
		end
	end
)
