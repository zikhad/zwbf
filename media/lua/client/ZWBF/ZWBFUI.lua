local ZWBFUI = {}
ZWBFUI.__index = ZWBFUI

--- Constructor
function ZWBFUI:new()
	local self = setmetatable({}, ZWBFUI)

	self.CharacterInfoTabManager = require("ZWBF/ZWBFCharacterInfoTabManager"):new()
	self.Utils = require("ZWBF/ZWBFUtils")
	self.Womb = require("ZWBF/ZWBFWomb")
	self.Pregnancy = require("ZWBF/ZWBFPregnancy")
	self.Lactation = require("ZWBF/ZWBFLactation")

	self.UI = nil
	self.activePanels = {
		lactation = true,
		womb = true
	}
	self.heights = {
		lactation = 0,
		womb = 0
	}

	self.UIElements = {
		lactation = {
			image = "lactation-image",
			levelTitle = "lactation-level-title",
			levelImage = "lactation-level-image"
		},
		womb = {
			title = "womb-title",
			image = "womb-image",
			spermTitle = "womb-sperm-title",
			spermAmount = "womb-sperm-amount",
			spermTotalTitle = "womb-sperm-total-title",
			spermTotalAmount = "womb-sperm-total-amount",
			cycleTitle = "womb-cycle-title",
			cycleInfoTitle = "womb-cycle-info-title",
			cycleInfo = "womb-cycle-info",
			pregnancyChance = "womb-pregnancy-chance",
			pregnancyBar = "womb-pregnancy-bar",
			pregnancyInfo = "womb-pregnancy-info"
		}
	}
	return self
end


function ZWBFUI:togglePanel(selected)

	if selected == "lactation" then
		self.activePanels.lactation = not self.activePanels.lactation
	end
	if selected == "womb" then
		self.activePanels.womb = not self.activePanels.womb
	end

	-- Update UI visibility
	for key, value in pairs(self.UIElements) do
		for _, element in pairs(value) do
			self.UI[element]:setVisible(self.activePanels[key])
		end
	end

	-- Update UI height (only lactation can be toggled)
	if self.activePanels.lactation then
		self.UI:setHeight(self.heights.lactation)
	else
		self.UI:setHeight(self.heights.womb)
	end
end

--- Creates the UI for the Womb Handler
function ZWBFUI:onCreateUI()
	self.UI = NewUI()
	self.UI:setWidthPixel(200)
	self.UI:setTitle(getText("IGUI_ZWBF_UI_Panel"))

	--- Womb ---
	self.UI:addText("womb-title", string.format("%s:", getText("IGUI_ZWBF_UI_Womb_title")), _, "Center")
	self.UI:nextLine()
	self.UI:addImage("womb-image", "media/ui/womb/normal/womb_normal_0.png")
	self.UI:nextLine()
	self.UI:addText("womb-sperm-title", string.format("%s:", getText("IGUI_ZWBF_UI_Current")), _, "Center")
	self.UI:addText("womb-sperm-amount", "0 ml", _, "Center")
	self.UI:nextLine()
	self.UI:addText("womb-sperm-total-title", string.format("%s:", getText("IGUI_ZWBF_UI_Total")), _, "Center")
	self.UI:addText("womb-sperm-total-amount", "0 ml", _, "Center")
	self.UI:nextLine()
	self.UI:addText("womb-cycle-title", getText("IGUI_ZWBF_UI_Cycle"), _, "Center")
	self.UI:nextLine()
	self.UI:addText("womb-cycle-info-title", string.format("%s:", getText("IGUI_ZWBF_UI_Phase")), _, "Center")
	self.UI:addText("womb-cycle-info", "", _, "Center")
	self.UI:nextLine()

	if not getPlayer():HasTrait("Infertile") then
		self.UI:addText("womb-pregnancy-chance", string.format("%s:", getText("IGUI_ZWBF_UI_Fertility")), _, "Center")
		self.UI:addProgressBar("womb-pregnancy-bar", 0, 0, 1)
		self.UI:addText("womb-pregnancy-info", "", _, "Center")
		self.UI:nextLine()
	end

	-- The height of the womb UI needs to take in consideration the title bar height
	self.heights.womb = self.UI.yAct + self.UI:titleBarHeight()

	--- Milk ---
	--- controls
	self.UI:addText("", getText("IGUI_ZWBF_UI_Milk_title"), _, "Center")
	self.UI:addButton("", getText("IGUI_ZWBF_UI_Milk_toggle"),
			function()
				self:togglePanel("lactation")
			end
	)
	self.UI:nextLine()

	-- Lactation UI
	self.UI:addImage("lactation-image", "media/ui/lactation/boobs/color-0/normal_empty.png")
	self.UI:nextLine()
	self.UI:addText("lactation-level-title", string.format("%s:", getText("IGUI_ZWBF_UI_Milk_Amount")), _, "Center")
	self.UI:addImage("lactation-level-image", "media/ui/lactation/level/milk_level_0.png")

	-- The height of the lactation UI needs to take in consideration the title bar height
	self.heights.lactation = self.UI.yAct + self.UI:titleBarHeight()

	self.UI:setBorderToAllElements(true)
	self.UI:saveLayout()

	self.CharacterInfoTabManager:addTab("HPanel", self.UI)
end

--- Handles the UI update
function ZWBFUI:onUpdateUI()
	if not self.UI.isUIVisible then return end

	-- Milk --
	if self.activePanels == "lactation" then
		self.UI["lactation-image"]:setPath(self.Lactation:getBoobImage())
		self.UI["lactation-level-image"]:setPath(self.Lactation:getMilkLevelImage())
	end

	-- Womb
	self.UI["womb-sperm-amount"]:setText(string.format("%s ml", self.Womb:getSpermAmount()))
	self.UI["womb-sperm-total-amount"]:setText(string.format("%s ml", self.Womb:getSpermAmountTotal()))
	self.UI["womb-image"]:setPath(self.Womb:getImage())
	self.UI["womb-cycle-info"]:setText(getText(self.Womb:getCyclePhase()))
	if not getPlayer():HasTrait("Infertile") then
		self.UI["womb-pregnancy-chance"]:setText(getText(self.Pregnancy:getIsPregnant() and "IGUI_ZWBF_UI_Pregnancy" or "IGUI_ZWBF_UI_Fertility"))
		self.UI["womb-pregnancy-bar"]:setValue(self.Womb:getFertility())
		self.UI["womb-pregnancy-info"]:setText(math.floor(self.Womb:getFertility() * 100) .. "%")
	end
end

--- Create H-Status Context Menu Button
function ZWBFUI:onCreateDebugContextMenu(player, context, items)
	local specificPlayer = getSpecificPlayer(player)
	if not specificPlayer:isFemale() or specificPlayer:isAsleep() or specificPlayer:getVehicle() then return end

	local option = context:addOption(getText("ContextMenu_ZWBF_Being_Female"))
	local submenu = ISContextMenu:getNew(context)
	context:addSubMenu(option, submenu)

	self.Utils:addOption(submenu, getText("ContextMenu_Add_Sperm_Title"), getText("ContextMenu_Add_Description"), function() self.Womb:addSperm(100) end)
	self.Utils:addOption(submenu, getText("ContextMenu_Remove_Title"), getText("ContextMenu_Remove_Description"), function() self.Womb:setSpermAmount(0) end)
	self.Utils:addOption(submenu, getText("ContextMenu_Remove_Total_Title"), getText("ContextMenu_Remove_Total_Description"), function() self.Womb:clearAllSperm() end)
	self.Utils:addOption(submenu, getText("ContextMenu_Add_Cycle_Day_Title"), getText("ContextMenu_Add_Cycle_Day_Description"), function() self.Womb:addCycleDay() end)
	self.Utils:addOption(submenu, getText("ContextMenu_Add_Pregnancy_Title"), getText("ContextMenu_Add_Pregnancy_Description"), function() self.Womb:setPregnancy(true) end)

	if self.Pregnancy:getIsPregnant() then
		self.Utils:addOption(submenu, getText("ContextMenu_Advance_Pregnancy_Title"), getText("ContextMenu_Advance_Pregnancy_Description"), function() self.Womb:advancePregnancy() end)
		self.Utils:addOption(submenu, getText("ContextMenu_Advance_Pregnancy_Labor_Title"), getText("ContextMenu_Advance_Pregnancy_Labor_Description"), function() self.Pregnancy:advanceToLabor() end)
		self.Utils:addOption(submenu, getText("ContextMenu_Remove_Pregnancy_Title"), getText("ContextMenu_Remove_Pregnancy_Description"), function() self.Womb:setPregnancy(false) end)
	end

	self.Utils:addOption(submenu, getText("ContextMenu_Milk_Toggle_Lactation_Title"), getText("ContextMenu_Milk_Toggle_Lactation_Description"), function() self.Lactation:set(not self.Lactation:getIsLactating()) end)
	if self.Lactation:getIsLactating() then
		self.Utils:addOption(submenu, getText("ContextMenu_Milk_Add_Milk_Title"), getText("ContextMenu_Milk_Add_Milk_Description"), function() self.Lactation:add(200) end)
		self.Utils:addOption(submenu, getText("ContextMenu_Milk_Clear_Milk_Title"), getText("ContextMenu_Milk_Clear_Milk_Description"), function() self.Lactation:clear() end)
	end
end

--- Hook up event listeners
function ZWBFUI:registerEvents()
	Events.OnCreateUI.Add(function() self:onCreateUI() end)
	Events.OnPostRender.Add(function() self:onUpdateUI() end)
	if isDebugEnabled() then
		Events.OnFillWorldObjectContextMenu.Add(function(player, context, items) self:onCreateDebugContextMenu(player, context, items) end)
	end
end

local UI = ZWBFUI:new()
UI:registerEvents()

-- return ZWBFUI
