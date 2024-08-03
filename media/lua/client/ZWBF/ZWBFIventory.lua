--- Localized global functions from PZ
local ISInventoryPaneContextMenu = ISInventoryPaneContextMenu
local ISTimedActionQueue = ISTimedActionQueue
local instanceof = instanceof
local getText = getText
local getSpecificPlayer = getSpecificPlayer
local Events = Events

local Womb = require("ZWBF/ZWBFWomb")
local Pregnancy = require("ZWBF/ZWBFPregnancy")
local Lactation = require("ZWBF/ZWBFLactation")

--- Common function to handle item actions
local function handleItemAction(item, player, action)
	ISInventoryPaneContextMenu.transferIfNeeded(player, item)
	ISTimedActionQueue.add(action:new(player, item))
end

--- Handler for when Contraceptive is taken
--- @param item any
--- @param player any
--- @param items any
function OnTake_Contraceptive(item, player, items)
	handleItemAction(item, player, ZWBFActionTakeContraceptive)
end

--- Handler for when Lactaid is taken
--- @param item any
--- @param player any
--- @param items any
function OnTake_Lactaid(item, player, items)
	handleItemAction(item, player, ZWBFActionTakeLactaid)
end

--- Handler for when Baby is feed
--- @param item any
--- @param player any
--- @param items any
function OnFeed_Baby(item, player, items)
	handleItemAction(item, player, ZWBFActionFeedBaby)
end

--- Create context menu for ZomboWinBeingFemale
--- @param player any
--- @param context any
--- @param items any
function ZWBF_BuildInventoryCM(player, context, items)
	local playerObj = getSpecificPlayer(player)
	for _, v in ipairs(items) do
		local item = (instanceof(v, "InventoryItem") and v) or v.items[1]

		if (
				string.find(item:getType(), "Baby") and
				Lactation:getMilkAmount() > Lactation:getBottleAmount()
			) then
			context:addOption(
				getText("ContextMenu_BreastFeed_Baby"),
				item,
				OnFeed_Baby,
				playerObj,
				items
			)
		elseif item:getType() == "Contraceptive" and
			not Womb:getOnContraceptive() and
			not Pregnancy:getIsPregnant()
		then
			context:addOption(
				getText("ContextMenu_Take_Contraceptive"),
				item,
				OnTake_Contraceptive,
				playerObj,
				items
			)
		elseif item:getType() == "Lactaid"
		then
			context:addOption(
				getText("ContextMenu_Take_Lactaid"),
				item,
				OnTake_Lactaid,
				playerObj,
				items
			)
		end
	end
end

--- Hook up event listeners
Events.OnFillInventoryObjectContextMenu.Add(ZWBF_BuildInventoryCM)
