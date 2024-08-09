--- Localized global functions from PZ
local getPlayer = getPlayer
local ZombRandFloat = ZombRandFloat
local ZombRand = ZombRand
local Events = Events
local BodyPartType = BodyPartType
local HaloTextHelper = HaloTextHelper
local getText = getText

-- VARIABLES
local Utils = require("ZWBF/ZWBFUtils")
local Pregnancy = require("ZWBF/ZWBFPregnancy")

local Womb = {}

Womb.data = {
    SpermAmount = 0,
    SpermAmountTotal = 0,
    CycleDay = 0,
    CyclePhase = "",
    Fertility = 0,
    OnContraceptive = false
}

-- CONSTANTS
Womb.CONSTANTS = {
    MAX_CAPACITY = 1000, -- Maximum amount of sperm the womb can hold
    SPERM_LEVEL = 17, -- Number of sperm levels (For UI)
    PREGNANCY_RECOVERY_DAYS = 7, -- Number of days to recover after pregnancy
    WETNESS = { -- Wetness range for the groin
        MIN = 30,
        MAX = 100
    }
}

--- Apply wetness to the groin
--- @param amount number (optional) The amount of wetness to apply
function Womb:applyWetness(amount)
    local player = getPlayer()
    local Groin = player:getBodyDamage():getBodyPart(BodyPartType.FromString("Groin"))
    Groin:setWetness(Groin:getWetness() + amount)
end

--- Adds sperm to the womb
--- @param amount number
function Womb:addSperm(amount)
    local data = Womb.data
    data.SpermAmount = data.SpermAmount + amount
    data.SpermAmountTotal = data.SpermAmountTotal + amount -- add to total 
end

--- (DEBUG) This function is used to clear All the sperm in the Womb
function Womb:clearAllSperm()
    local data = Womb.data
    data.SpermAmount = 0
    data.SpermAmountTotal = 0
end

--- SCENES
local animStep = 0 -- the current step of the animation

--- Returns the scene image depending on Womb's conditions
--- @return string
local function sceneWomb()
    local data = Womb.data
    animStep = animStep + 0.1 -- always increment the anim step
    local animIndex
    local isPregnant = Pregnancy:getIsPregnant()
    local progress = Pregnancy:getProgress()
    local fullness = (data.SpermAmount > (Womb.CONSTANTS.MAX_CAPACITY / 2)) and "full" or "empty"

    -- Number of repetitions (used for both pregnant and empty cases)
    local repetitions = 10

    if isPregnant and progress > 0.6 then
        -- Pregnant animation: 0 to 4 then 4 to 0, 'animReps' times before going 0 to 11
        local loopIndex = math.floor(animStep) % 10
        if loopIndex < 5 then
            animIndex = loopIndex
        else
            animIndex = 9 - loopIndex
        end
        
        if math.floor(animStep / 10) >= repetitions then
            animIndex = math.floor(animStep) - 10 * repetitions
            animIndex = animIndex > 11 and 11 or animIndex
        end
        
        return string.format("media/ui/sex/pregnant/sex_%s.png", animIndex) -- return the scene image

    elseif fullness == "empty" then
        -- Not pregnant and fullness is empty: 0 to 4 then 4 to 0, 'animReps' times before going 0 to 9
        local loopIndex = math.floor(animStep) % 10
        if loopIndex < 5 then
            animIndex = loopIndex
        else
            animIndex = 9 - loopIndex
        end
        
        if math.floor(animStep / 10) >= repetitions then
            animIndex = math.floor(animStep) - 10 * repetitions
            animIndex = animIndex > 9 and 9 or animIndex
        end

    else
        -- Not pregnant and fullness is full: 0 to 9 then 9 to 0 repeatedly
        local loopIndex = math.floor(animStep) % 18
        if loopIndex < 9 then
            animIndex = loopIndex
        else
            animIndex = 17 - loopIndex
        end
    end

    return string.format("media/ui/sex/normal/sex_%s_%s.png", fullness, animIndex) -- return the scene image
end



--- Returns the normal Womb image depending on Womb's conditions
--- @return string
local function normalWomb()
    local data = Womb.data
    local percentage = math.floor((data.SpermAmount / Womb.CONSTANTS.MAX_CAPACITY) * 100)
    local imageIndex = Utils:percentageToNumber(percentage, Womb.CONSTANTS.SPERM_LEVEL)
    
    -- If any amount of sperm is present, give the first image
    if imageIndex == 0 and data.SpermAmount > 0 then
        imageIndex = 1
    end
    local status = "normal"
    if Pregnancy:getIsPregnant() then
        status = "conception"

        if Pregnancy:getInLabor() then
            status = "birth"
            imageIndex = Utils:percentageToNumber(Pregnancy:getLaborProgress() * 100, 11)
        elseif Pregnancy:getProgress() > 0.05 then
            status = "pregnant"
            local progress = (Pregnancy:getProgress() < 0.9) and (Pregnancy:getProgress() * 100) or 100
            imageIndex = Utils:percentageToNumber(progress, 6)
        end
    end
    return string.format("media/ui/womb/%s/womb_%s_%s.png", status, status, imageIndex)
end
--- // SCENES

--- Set cycle phase based on the current day
local function setCyclePhase()
    local data = Womb.data
    if Pregnancy:getIsPregnant() then
        data.CyclePhase = "Pregnant"
        data.Fertility = 0
    elseif data.CycleDay < 1 then
        data.CyclePhase = "Recovery"
        data.Fertility = 0
    elseif data.CycleDay < 7 then
        Pregnancy:onFinishRecovery()
        data.CyclePhase = "Menstruation"
    elseif data.CycleDay < 14 then
        data.CyclePhase = "Follicular"
    elseif data.CycleDay < 21 then
        data.CyclePhase = "Ovulation"
    else
        data.CyclePhase = "Luteal"
    end
end

--- Set fertility based on the current cycle phase and conditions like pregnancy and contraceptives
local function setFertility()
    local data = Womb.data
    if Pregnancy:getIsPregnant() then
        data.Fertility = Pregnancy:getProgress()
    elseif data.OnContraceptive or data.CyclePhase == "Pregnant" or data.CyclePhase == "Recovery" or data.CyclePhase == "Luteal" then
        data.Fertility = 0
    elseif data.CyclePhase == "Ovulation" then
        data.Fertility = ZombRandFloat(0.8, 1)
    else
        data.Fertility = ZombRandFloat(0, 0.4)
    end
end

--- Check if the player is on contraceptives
local function onCheckContraceptive()
    local player = getPlayer()
    local data = Womb.data
    data.OnContraceptive = player:getModData().wombOnContraceptive or false
    if data.OnContraceptive then
        data.Fertility = 0
    end
end

--- Check if the player is pregnant
local function onCheckPregnancy()
    local data = Womb.data
    if Pregnancy:getIsPregnant() then
        data.CycleDay = -Womb.CONSTANTS.PREGNANCY_RECOVERY_DAYS
        if Pregnancy:getProgress() > 0.5 then
            data.SpermAmount = 0
        end
        setFertility()
    end
end

--- Run down logic to eventually empty the womb
local function onRunDown()
    if ZombRand(100) < 80 then return end -- 80% chance not doing anything
    local player = getPlayer()
    local amount = ZombRand(10)
    local data = Womb.data
    if data.SpermAmount > 0 then
        local text = string.format("%s %sml", getText("IGUI_ZWBF_UI_Sperm"), amount)
        HaloTextHelper.addTextWithArrow(player, text, false, HaloTextHelper.getColorWhite())
        Womb:applyWetness(ZombRand(Womb.CONSTANTS.WETNESS.MIN, Womb.CONSTANTS.WETNESS.MAX))
    end
    data.SpermAmount = data.SpermAmount - amount
end

--- Add one day to the cycle
function Womb:addCycleDay()
    local player = getPlayer()
    local data = Womb.data
    data.OnContraceptive = false
    print("ZWBF - Womb - Add Cycle Day - " .. data.CycleDay)
    if not Pregnancy:getIsPregnant() then
        data.OnContraceptive = player:getModData().wombOnContraceptive or false
        data.CycleDay = (data.CycleDay < 28) and (data.CycleDay + 1) or 1
    end
    setFertility()
end

--- Get the current cycle phase to be used in the UI
--- @return string Womb.data.cyclePhase cycle phase
function Womb:getCyclePhase()
    local cycleTranslations = {
        ["Recovery"] = "IGUI_ZWBF_UI_Recovery",
        ["Menstruation"] = "IGUI_ZWBF_UI_Menstruation",
        ["Follicular"] = "IGUI_ZWBF_UI_Follicular",
        ["Ovulation"] = "IGUI_ZWBF_UI_Ovulation",
        ["Luteal"] = "IGUI_ZWBF_UI_Luteal",
        ["Pregnant"] = "IGUI_ZWBF_UI_Pregnant"
    }
    return cycleTranslations[Womb.data.CyclePhase]
end

--- Set the player on contraceptives
--- @param status boolean
function Womb:setContraceptive(status)
    Womb.data.OnContraceptive = status
    setFertility()
end

--- Get the player's contraceptive status
--- @return boolean Womb.data.OnContraceptive contraceptive status
function Womb:getOnContraceptive()
    return Womb.data.OnContraceptive
end

--- Set the amount of sperm in the womb
--- @param amount number Sperm amount
function Womb:setSpermAmount(amount)
    Womb.data.SpermAmount = amount
end

--- Get the amount of sperm in the womb
--- @return number Womb.data.SpermAmount sperm amount
function Womb:getSpermAmount()
    return Womb.data.SpermAmount
end

--- Get the total amount of sperm in the womb
--- @return number Womb.data.SpermAmountTotal total sperm amount
function Womb:getSpermAmountTotal()
    return Womb.data.SpermAmountTotal
end

--- Get the current Fertility to be used in the UI
--- @return number Womb.data.Fertility fertility percentage
function Womb:getFertility()
    return Womb.data.Fertility
end

--- Returns the Womb image depending on Womb's conditions
--- @return string
function Womb:getImage()
    local player = getPlayer()
    
    -- check if the player is in a scene
    if (
        player:getModData().ZomboWinSexScene and
        Utils:isAnimationAllowed(Utils:getAnim())
    ) then
        print("ZWBF - Womb - In Scene" .. Utils:getAnim()) -- debug the current animation
        -- if so, a scene will be selected based on womb conditions
        return sceneWomb()
    end
    animStep = 0 -- clear the anim step if not in a scene
    
    return normalWomb() -- If not in a scene, the normal womb will be shown
end

--- (DEBUG) Set player Pregnancy
--- @param status boolean Pregnancy status
function Womb:setPregnancy(status)
    if status then
        Pregnancy:start()
    else
        Pregnancy:stop()
    end
    Womb:addCycleDay()
end

--- (DEBUG) Advance the player's pregnancy by 24h
function Womb:advancePregnancy()
    Pregnancy:advancePregnancy(24)
    setFertility()
end

--- Update the Womb data
function Womb:update()
    local player = getPlayer()
    local data = Womb.data
    
    if data.SpermAmount > Womb.CONSTANTS.MAX_CAPACITY then
        data.SpermAmount = Womb.CONSTANTS.MAX_CAPACITY
    elseif data.SpermAmount < 0 then
        data.SpermAmount = 0
    end
    player:getModData().ZWBFWomb = data
end

--- Initializes the Womb, This should be called on creation of player
function Womb:init()
    local player = getPlayer()
    local data = player:getModData().ZWBFWomb or {}
    data.SpermAmount = data.SpermAmount or 0
    data.SpermAmountTotal = data.SpermAmountTotal or 0
    data.CycleDay = data.CycleDay or ZombRand(1, 28)
    data.OnContraceptive = data.OnContraceptive or false
    Womb.data = data
    
    setFertility()
end

--- Update the UI, should be called every minute
local function onUpdateUI()
    if not Womb or not Pregnancy then return end
    Womb:update()
    setCyclePhase()
end

--- Hook up event listeners
Events.OnCreatePlayer.Add(Womb.init)

Events.OnPostRender.Add(onUpdateUI)
Events.EveryOneMinute.Add(onCheckContraceptive)
Events.EveryOneMinute.Add(onCheckPregnancy)

Events.EveryTenMinutes.Add(onRunDown)

Events.EveryDays.Add(Womb.addCycleDay)

return Womb
