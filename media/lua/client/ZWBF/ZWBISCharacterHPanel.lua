require "ISUI/ISPanelJoypad"
require "ISCharacterInfoWindow_AddTab"

--- Localized global functions from PZ
local ISPanelJoypad = ISPanelJoypad
local getSpecificPlayer = getSpecificPlayer
local Joypad = Joypad
local getPlayerInfoPanel = getPlayerInfoPanel
local UIFont = UIFont
local getTextManager = getTextManager
local ISWindow = ISWindow
local getCore = getCore

ISCharacterHPanel = ISPanelJoypad:derive("ISCharacterHPanel");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)


function ISCharacterHPanel:initialise()
    ISPanelJoypad.initialise(self);
end

function ISCharacterHPanel:new(x, y, width, height, playerNum)
    local o = {};
    o = ISPanelJoypad:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;
    o.playerNum = playerNum
    o.char = getSpecificPlayer(playerNum);
    o:noBackground();
    o.textX = 0
    o.textY = 0
    ISCharacterHPanel.instance = o;
   return o;
end

function ISCharacterHPanel:createChildren()
    print("ZWBG Panel - create children here")
    self.textY = 0
    ---
    local image = ISSimpleImage:new(self,"media/ui/womb/normal/womb_normal_0.png")
    self:addChild(image)
    
    ---
    self:setScrollChildren(true)
    self:addScrollBars()
end

function ISCharacterHPanel:setVisible(visible)
    self.javaObject:setVisible(visible);
end

function ISCharacterHPanel:prerender()
    ISPanelJoypad.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
    self:createChildren()
end

function ISCharacterHPanel:addTextLine(str, textX, textY, maxTextWidth)
    local txt = "- " .. str
    self:drawText(txt, textX, textY, 1, 1, 1, 1, UIFont.Small)
    local txtWidth = getTextManager():MeasureStringX(UIFont.Small, txt)
    if txtWidth > maxTextWidth then maxTextWidth = txtWidth end
    textY = textY + FONT_HGT_SMALL
    return maxTextWidth, textY
end

function ISCharacterHPanel:render()
    local textX = self.textX
    local textY = self.textY
    local maxTextWidth = 0
    
    -- TODO: components should be put in here
    
    maxTextWidth, textY = self:addTextLine("xpto", textX, textY, maxTextWidth)

    --- calculate witdh and height of the panel
    local widthRequired = self.textX * 2 + maxTextWidth;
    if widthRequired > self:getWidth() then
        self:setWidthAndParentWidth(widthRequired);
    end

    local tabHeight = self.y
    local maxHeight = getCore():getScreenHeight() - tabHeight
    if ISWindow and ISWindow.TitleBarHeight then maxHeight = maxHeight - ISWindow.TitleBarHeight end
    
    self:setHeightAndParentHeight(math.min(textY, maxHeight));
    self:setScrollHeight(textY)
    
    self:clearStencilRect()
end

function ISCharacterHPanel:onMouseWheel(del)
    self:setYScroll(self:getYScroll() - del * 30)
    return true
end

--[[

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

]]

addCharacterPageTab("HPanel", ISCharacterHPanel)