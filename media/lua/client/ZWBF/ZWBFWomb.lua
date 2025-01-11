--- Localized global functions from PZ
local getPlayer = getPlayer
local ZombRandFloat = ZombRandFloat
local ZombRand = ZombRand
local Events = Events
local BodyPartType = BodyPartType
local HaloTextHelper = HaloTextHelper
local getText = getText
local SandboxVars = SandboxVars

local SBVars = SandboxVars.ZWBF

-- VARIABLES
local Utils = require("ZWBF/ZWBFUtils")
local Pregnancy = require("ZWBF/ZWBFPregnancyClass")

local Womb = {}

Womb.SBvars = {
    PregnancyRecovery = 7, -- Number of days to recover after pregnancy,
    WombMaxCapacity = 1000, -- Maximum amount of sperm the womb can hold
    FertilityBonus = 50 -- Fertility Bonus of Fertile Trait
}

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
    SPERM_LEVEL = 17, -- Number of sperm levels (For UI)
    WETNESS = { -- Wetness range for the groin
        MIN = 30,
        MAX = 100
    }
}

--- Apply wetness to the groin
--- @param amount number | nil (optional) The amount of wetness to apply
function Womb:applyWetness(amount)
    amount = amount or ZombRand(Womb.CONSTANTS.WETNESS.MIN, Womb.CONSTANTS.WETNESS.MAX)
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
local animStep = 0 -- the current step of the animation, incremented each call to animate

--- Helper function to calculate animation loop index, optionally reversing the sequence
--- @param maxIndex integer: Maximum index to loop through
--- @param isReversed boolean: Whether the loop should reverse direction
--- @return integer: The calculated animation index for the current step
local function calculateLoopIndex(maxIndex, isReversed)
    -- Determine position in the loop; goes from 0 to maxIndex and back if reversed
    local loopIndex = math.floor(animStep) % (maxIndex * 2)
    if loopIndex < maxIndex then
        return loopIndex -- Forward loop phase
    else
        -- Reverse loop phase if 'isReversed' is true
        return (isReversed and maxIndex - (loopIndex - maxIndex)) or maxIndex - loopIndex
    end
end

--- Determines fullness based on sperm amount in Womb data
--- @param data table: Data related to womb status
--- @return string: "full" or "empty" based on capacity threshold
local function getFullness(data)
    -- Checks if sperm amount is above half the womb's max capacity
    return (data.SpermAmount > (Womb.SBvars.WombMaxCapacity / 2)) and "full" or "empty"
end

--- Main function to select the scene image based on womb and pregnancy conditions
--- @return string: Path to the appropriate scene image
local function sceneWomb()
    animStep = animStep + 0.1 -- Increment animation step with each function call
    local animIndex = 0 -- image index
    local repetitions = 9 -- number of repetitions for loops
    local isPregnant = Pregnancy:getIsPregnant() -- Check pregnancy status
    local progress = isPregnant and Pregnancy:getProgress() or 0 -- Pregnancy progress (0 if not pregnant)
    local fullness = getFullness(Womb.data) -- Determine fullness of the womb

    -- Check for condom use case: animates from 0 to 6, then 6 to 0 in a repeating loop
    if Utils.Inventory:hasItem("ZWBF.Condom") then
        animIndex = calculateLoopIndex(6, true) -- Calculate loop index up to 6, then reverse
        return string.format("media/ui/sex/womb/womb_%s.png", animIndex) -- Return image path for condom case
    end

    -- Pregnant case with high progress (> 0.6): loop 0 to 4 and back, then animate through final frames
    if isPregnant and progress > 0.6 then
        animIndex = calculateLoopIndex(4, true) -- Loop index from 0 to 4 and back
        -- Check if the loop repetitions have completed; if so, proceed with final frames (0-11)
        if math.floor(animStep / 10) >= repetitions then
            animIndex = math.min(math.floor(animStep) - 10 * repetitions, 11) -- Constrain to max frame 11
        end
        return string.format("media/ui/sex/pregnant/sex_%s.png", animIndex) -- Return image path for pregnant case
    end

    -- Non-pregnant cases based on womb fullness
    if fullness == "empty" then
        -- Empty womb animation: loop 0 to 4 and back; after 'repetitions', animate through final frames (0-9)
        animIndex = calculateLoopIndex(4, true) -- Loop index from 0 to 4 and back
        if math.floor(animStep / 10) >= repetitions then
            animIndex = math.min(math.floor(animStep) - 10 * repetitions, 9) -- Constrain to max frame 9
        end
    else
        -- Full womb animation: loop 0 to 9 and back, repeating indefinitely
        animIndex = calculateLoopIndex(9, true) -- Loop index from 0 to 9 and back
    end

    -- Return the image path based on fullness and calculated animIndex
    return string.format("media/ui/sex/normal/sex_%s_%s.png", fullness, animIndex)
end


--- Returns the normal Womb image depending on Womb's conditions
--- @return string
local function normalWomb()
    local data = Womb.data
    local percentage = math.floor((data.SpermAmount / Womb.SBvars.WombMaxCapacity) * 100)
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

--- Set cycle phase based on the current day
local function setCyclePhase()
    local data = Womb.data
    if Pregnancy:getIsPregnant() then
        data.CyclePhase = "Pregnant"
        data.Fertility = Pregnancy:getIsPregnant() and Pregnancy:getProgress() or 0
    elseif data.CycleDay < 1 then
        data.CyclePhase = "Recovery"
        data.Fertility = 0
    elseif data.CycleDay < 6 then
        Pregnancy:onFinishRecovery()
        data.CyclePhase = "Menstruation"
    elseif data.CycleDay < 13 then
        data.CyclePhase = "Follicular"
    elseif data.CycleDay < 16 then
        data.CyclePhase = "Ovulation"
    else
        data.CyclePhase = "Luteal"
    end
end

--- Set fertility based on the current cycle phase and conditions like pregnancy and contraceptives
local function setFertility()
    local data = Womb.data
    local player = getPlayer()
    if (
        data.OnContraceptive or
        player:HasTrait("Infertile")
    ) then
        data.Fertility = 0
    elseif Pregnancy:getIsPregnant() then
        data.Fertility = Pregnancy:getProgress() or 0
    else
        local fertility = {
            ["Recovery"] = 0,
            ["Menstruation"] = ZombRandFloat(0, 0.3),
            ["Follicular"] = ZombRandFloat(0, 0.4),
            ["Ovulation"] = ZombRandFloat(0.85, 1),
            ["Luteal"] = ZombRandFloat(0, 0.3),
        }
        data.Fertility = fertility[data.CyclePhase] or 0;
        if (data.Fertility > 0 and player:HasTrait("Fertile")) then
            data.Fertility = data.Fertility * (1 + (Womb.SBvars.FertilityBonus / 100))
        end
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
        data.CycleDay = -Womb.SBvars.PregnancyRecovery
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
        Womb:applyWetness()
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

--- Get the current Fertility
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
        Utils.Animation:isAllowed(player)
    ) then
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

    if data.SpermAmount > Womb.SBvars.WombMaxCapacity then
        data.SpermAmount = Womb.SBvars.WombMaxCapacity
    elseif data.SpermAmount < 0 then
        data.SpermAmount = 0
    end
    player:getModData().ZWBFWomb = data
end

--- Modify the variables according to player Traits
function Womb:applyTraits()
    local player = getPlayer()
    -- Hyperfertile
    if player:HasTrait("Hyperfertile") then
        -- +100% fertility
        Womb.SBvars.FertilityBonus = SBVars.FertilityBonus * 2
        -- Halves the time before being ready to get pregnant again after birth
        Womb.SBvars.PregnancyRecovery = math.floor(SBVars.PregnancyRecovery / 2)
    end
end

--- Initializes the Womb, This should be called on creation of player
function Womb:init()

    -- setup SandboxVars
    Womb.SBvars.PregnancyRecovery = SBVars.PregnancyRecovery
    Womb.SBvars.WombMaxCapacity = SBVars.WombMaxCapacity
    Womb.SBvars.FertilityBonus = SBVars.FertilityBonus
    -- Apply Traits that are related to the Womb
    Womb:applyTraits()

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
