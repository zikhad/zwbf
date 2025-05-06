--- Localized global functions from PZ
local ISInventoryPaneContextMenu = ISInventoryPaneContextMenu
local ISTimedActionQueue = ISTimedActionQueue
local instanceof = instanceof
local getText = getText
local getSpecificPlayer = getSpecificPlayer
local Events = Events

local ZWBFActionFeedBaby = require("ZWBF/Actions/ZWBFFeedBaby")
local ZWBFActionTakeContraceptive = require("ZWBF/Actions/ZWBFTakeContraceptive")
local ZWBFActionTakeLactaid = require("ZWBF/Actions/ZWBFTakeLactaid")

--- ZWBFInventoryClass
--- This class handles inventory-related actions for ZomboWinBeingFemale
local ZWBFInventoryClass = {}
ZWBFInventoryClass.__index = ZWBFInventoryClass

--- Constructor
--- Initializes the class with required modules
function ZWBFInventoryClass:new(props)
	props = props or {}
	local instance = setmetatable({}, ZWBFInventoryClass)
	instance.name = props.name or "Inventory"
	instance.Womb = props.Womb or require("ZWBF/ZWBFWomb")
	instance.Pregnancy = props.Pregnancy or require("ZWBF/ZWBFPregnancy")
	instance.Lactation = props.Lactation or require("ZWBF/ZWBFLactation")
	return instance
end

--- Common function to handle item actions
--- @param item any
--- @param player any
--- @param action any
function ZWBFInventoryClass:handleItemAction(item, player, action)
	ISInventoryPaneContextMenu.transferIfNeeded(player, item)
	ISTimedActionQueue.add(action:new(player, item))
end

--- Handler for when Contraceptive is taken
--- @param item any
--- @param player any
--- @param items any
function ZWBFInventoryClass:OnTake_Contraceptive(item, player, items)
	self:handleItemAction(item, player, ZWBFActionTakeContraceptive)
end

--- Handler for when Lactaid is taken
--- @param item any
--- @param player any
--- @param items any
function ZWBFInventoryClass:OnTake_Lactaid(item, player, items)
	self:handleItemAction(item, player, ZWBFActionTakeLactaid)
end

--- Handler for when Baby is fed
--- @param item any
--- @param player any
--- @param items any
function ZWBFInventoryClass:OnFeed_Baby(item, player, items)
	self:handleItemAction(item, player, ZWBFActionFeedBaby)
end

--- Create context menu for ZomboWinBeingFemale
--- @param playerId number
--- @param context table
--- @param items table
function ZWBFInventoryClass:BuildInventoryCM(playerId, context, items)
	local player = getSpecificPlayer(playerId)

	-- Define item actions
	local itemActions = {
		{
			text = getText("ContextMenu_BreastFeed_Baby"),
			itemType = "Baby",
			condition = function(item)
				return self.Lactation:getMilkAmount() >= self.Lactation:getBottleAmount()
			end,
			handler = function(item)
				self:OnFeed_Baby(item, player, items)
			end
		},
		{
			text = getText("ContextMenu_Take_Contraceptive"),
			itemType = "Contraceptive",
			condition = function(item)
				return (
						not self.Womb:getOnContraceptive() and
						not self.Womb:getInRecovery() and
						not self.Pregnancy:getIsPregnant()
				)
			end,
			handler = function(item)
				self:OnTake_Contraceptive(item, player, items)
			end
		},
		{
			text = getText("ContextMenu_Take_Lactaid"),
			itemType = "Lactaid",
			condition = function(item)
				return true
			end,
			handler = function(item)
				self:OnTake_Lactaid(item, player, items)
			end
		}
	}

	-- Iterate through items and add context menu options
	for _, v in ipairs(items) do
		local item = (instanceof(v, "InventoryItem") and v) or v.items[1]

		for _, action in ipairs(itemActions) do
			if string.find(item:getType(), action.itemType) and action.condition(item) then
				context:addOption(action.text, item, action.handler)
			end
		end
	end
end

--- Hook up event listeners
function ZWBFInventoryClass:registerEvents()
	Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items)
		self:BuildInventoryCM(player, context, items)
	end)
end

return ZWBFInventoryClass
