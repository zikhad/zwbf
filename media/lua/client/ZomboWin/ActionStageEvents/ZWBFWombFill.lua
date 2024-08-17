--- WombFill Events
--- These events will be triggered when ZomboWin Action is performed
--- @autor Zikhad 2024

--- CONSTANTS
local MIN_AMOUNT = 10
local MAX_AMOUNT = 50

--- ZomboWin Variables
local ZomboWin = require("ZomboWin/ZomboWin")
local ActionEvents = ZomboWin.AnimationHandler.ActionEvents

local Utils = require("ZWBF/ZWBFUtils")

--- Localized global functions from PZ
local getText = getText
local HaloTextHelper = HaloTextHelper
local getPlayer = getPlayer
local ZombRand = ZombRand
local ZombRandFloat = ZombRandFloat
local Events = Events

--- VARIABLES
local shouldAddSperm = false -- This is a flag to determine if the sperm should be added to the womb
local lastAnimation = ""

local Pregnancy = require("ZWBF/ZWBFPregnancy")
local Womb = require("ZWBF/ZWBFWomb")

--- Add the event to the ActionEvents
table.insert(
	ActionEvents.Perform,
	function(action)
		shouldAddSperm = true --- flip the flag to true
	end
)

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

--- Inject sperm into the player's womb
local function injectSperm()
	local amount = ZombRand(MIN_AMOUNT, MAX_AMOUNT) -- Random amount between MIN and MAX
	Womb:addSperm(amount)

	-- show a Halo Text with the amount of sperm injected
	local player = getPlayer()
	local text = string.format("%s %sml", getText("IGUI_ZWBF_UI_Sperm"), amount)
	HaloTextHelper.addTextWithArrow(player, text, true, HaloTextHelper.getColorGreen())
end

local function _onPlayerUpdate(character)

	-- Only do this if the ZomboWinSexScene is not playing and the flag is true
	if (
		(not character:getModData().ZomboWinSexScene) and
		shouldAddSperm
	) then
		-- only few animations are allowed to inject sperm
		if Utils.Animation:isAllowed(character) then
			injectSperm()    --- Inject sperm into the womb
			impregnate()     --- Handle impregnation
		end
		lastAnimation = "" --- Reset the last animation
		shouldAddSperm = false --- Reset the flag
	end
end

--- Hook up event listeners
Events.OnPlayerUpdate.Add(_onPlayerUpdate)
