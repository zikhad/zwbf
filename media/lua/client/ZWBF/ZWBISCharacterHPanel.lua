require "ISUI/ISPanelJoypad"
require "ISCharacterInfoWindow_AddTab"

--- Localized global functions from PZ
local ISPanelJoypad = ISPanelJoypad
local getSpecificPlayer = getSpecificPlayer
local Joypad = Joypad
local getPlayerInfoPanel = getPlayerInfoPanel

ISCharacterHPanel = ISPanelJoypad:derive("ISCharacterHPanel")

function ISCharacterHPanel:initialise()
	print("ZWBF - UI - TAB - Initialize")
    ISPanelJoypad.initialise(self);
end

function ISCharacterHPanel:createChildren()
	print("ZWBF - UI - TAB - Create Children")
	self:setScrollChildren(true)
    self:addScrollBars()
end

function ISCharacterHPanel:setVisible(visible)
	print("ZWBF - UI - TAB - Set Visible")
    self.javaObject:setVisible(visible);
end

function ISCharacterHPanel:prerender()
	print("ZWBF - UI - TAB - Prerender")
    ISPanelJoypad.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
	self:createChildren()
end

function ISCharacterHPanel:render()
	if not self.char:getModData() then self:clearStencilRect(); return end
end

function ISCharacterHPanel:onMouseWheel(del)
	print("ZWBF - UI - TAB - on onMouseWheel")
    self:setYScroll(self:getYScroll() - del * 30)
    return true
end

function ISCharacterHPanel:new(x, y, width, height, playerNum)
	print("ZWBF - UI - TAB - New")
	local o = {};
    o = ISPanelJoypad:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;
    o.playerNum = playerNum
    o.char = getSpecificPlayer(playerNum);
    o:noBackground();
    o.textX = 20
    o.inputX = 300
    o.textY = 0
    
    ISCharacterHPanel.instance = o;
   return o;
end

function ISCharacterHPanel:ensureVisible()
	print("ZWBF - UI - TAB - ensureVisible")
    if not self.joyfocus then return end
    local child = nil;
    if not child then return end
    local y = child:getY()
    if y - 40 < 0 - self:getYScroll() then
        self:setYScroll(0 - y + 40)
    elseif y + child:getHeight() + 40 > 0 - self:getYScroll() + self:getHeight() then
        self:setYScroll(0 - (y + child:getHeight() + 40 - self:getHeight()))
    end
end

function ISCharacterHPanel:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData);
    self.joypadIndex = nil
    self.barWithTooltip = nil
end

function ISCharacterHPanel:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData);
end

function ISCharacterHPanel:onJoypadDown(button)
    if button == Joypad.LBumper then
        getPlayerInfoPanel(self.playerNum):onJoypadDown(button)
    end
    if button == Joypad.RBumper then
        getPlayerInfoPanel(self.playerNum):onJoypadDown(button)
    end
end

function ISCharacterHPanel:onJoypadDirDown()
    self.joypadIndex = self.joypadIndex + 1
    self:ensureVisible()
    self:updateTooltipForJoypad()
end

function ISCharacterHPanel:onJoypadDirLeft()
end

function ISCharacterHPanel:onJoypadDirRight()
end


addCharacterPageTab("HPanel", ISCharacterHPanel)
-- ISPanelJoypad.initialise(UI)