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
local Pregnancy = require("ZWBF/ZWBFPregnancy")
local Womb = require("ZWBF/ZWBFWomb")

--- LOCAL FUNCTIONS

--- Handles impregnation
local function impregnate()
	local character = getPlayer()
	if (
		(not character:isFemale()) or
		Pregnancy:getIsPregnant() or
		Womb:getOnContraceptive() or
		character:HasTrait("Infertile")
	) then return end

	local fertility = Womb:getFertility()
	if ZombRandFloat(0, 1) > (1 - fertility) then
		local text = getText("IGUI_ZWBF_UI_Fertilized")
		HaloTextHelper.addText(character, text, HaloTextHelper.getColorGreen())
		Pregnancy:start()
	end
end

--- Inject sperm into the player's womb
local function injectSperm(character)

	if not character:isFemale() then return end

	if (Utils.Inventory:hasItem("ZWBF.Condom", character)) then
		local inventory = character:getInventory()
		inventory:Remove("Condom")
		inventory:AddItem("ZWBF.CondomUsed", 1)
	else
		-- show a Halo Text with the amount of sperm injected
		local amount = ZombRand(MIN_AMOUNT, MAX_AMOUNT) -- Random amount between MIN and MAX
		local text = string.format("%s %sml", getText("IGUI_ZWBF_UI_Sperm"), amount)
		HaloTextHelper.addTextWithArrow(character, text, true, HaloTextHelper.getColorGreen())

		Womb:addSperm(amount) -- add sperm to the womb
		impregnate() -- handle pregnancy
	end
end

table.insert(
	ActionEvents.Perform,
	function(action)
		local character = action.character
		if not character:isFemale() then return end
		if Utils.Animation:isAllowed(character) then
			injectSperm(character)
			Womb:setIsAnimation(false)
		end
	end
)

table.insert(ActionEvents.Update,
		function(action)
			local duration = action.duration
			local delta = action:getJobDelta()
			local character = action.character

			if not character:isFemale() then return end

			if Utils.Animation:isAllowed(character) then
				Womb:setIsAnimation(true)
				Womb:setAnimationDuration(duration)
				Womb:setAnimationDelta(delta)
			end
		end
)

table.insert(
	ActionEvents.Stop,
	function(action)
		Womb:setIsAnimation(false)
	end
)
