--- Localized global functions from PZ
local ISInventoryPaneContextMenu = ISInventoryPaneContextMenu
local ISTimedActionQueue = ISTimedActionQueue
local instanceof = instanceof
local getText = getText
local getSpecificPlayer = getSpecificPlayer
local Events = Events

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
--- @param player any
--- @param context any
--- @param items any
function ZWBFInventoryClass:BuildInventoryCM(player, context, items)
	local playerObj = getSpecificPlayer(player)
	for _, v in ipairs(items) do
		local item = (instanceof(v, "InventoryItem") and v) or v.items[1]

		if (
				string.find(item:getType(), "Baby") and
						self.Lactation:getMilkAmount() >= self.Lactation:getBottleAmount()
		) then
			context:addOption(
					getText("ContextMenu_BreastFeed_Baby"),
					item,
					function() self:OnFeed_Baby(item, playerObj, items) end
			)
		elseif item:getType() == "Contraceptive" and
				not self.Womb:getOnContraceptive() and
				not self.Pregnancy:getIsPregnant()
		then
			context:addOption(
					getText("ContextMenu_Take_Contraceptive"),
					item,
					function() self:OnTake_Contraceptive(item, playerObj, items) end
			)
		elseif item:getType() == "Lactaid" then
			context:addOption(
					getText("ContextMenu_Take_Lactaid"),
					item,
					function() self:OnTake_Lactaid(item, playerObj, items) end
			)
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
