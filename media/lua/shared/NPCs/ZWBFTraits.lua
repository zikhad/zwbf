--- TraitsManager Class
--- Handles the initialization and management of traits
local TraitsManager = {}
TraitsManager.__index = TraitsManager

--- Constructor
--- Initializes the TraitsManager with a list of traits
function TraitsManager:new()
    local instance = setmetatable({}, TraitsManager)
    instance.traitsList = {
        -- Infertile trait [3]: You are infertile. You cannot get pregnant
        {
            IdentifierType = "Infertile",
            Cost = 3,
            Profession = false,
            MutualExclusives = {"Fertile", "Hyperfertile", "Pregnancy"},
        },
        -- Fertile [-2]: You are very fertile <br>- Higher chance of getting pregnant <br>- +50% fertility
        {
            IdentifierType = "Fertile",
            Cost = -2,
            Profession = false,
            MutualExclusives = {"Hyperfertile"},
        },
        -- Fertile trait [-2]: You are very fertile. Higher chance of getting pregnant +50% fertility
        {
            IdentifierType = "Hyperfertile",
            Cost = -6,
            Profession = false,
            MutualExclusives = {},
        },
        -- Pregnancy [-8]: Starts the game pregnant
        {
            IdentifierType = "Pregnancy",
            Cost = -8,
            Profession = false,
            MutualExclusives = {},
        },
        -- Dairy Cow [-4]: Increases milk production rate (+25%) and time lactating (+25%).
        {
            IdentifierType = "DairyCow",
            Cost = 4,
            Profession = false,
            MutualExclusives = {},
        },
        -- TODO: Add Baby Crazy trait -6 > Decreases Unhappiness, Boredom and Stress when breastfeeding and when getting pregnant. Reduces injuries by 10% when in the 2nd or 3rd trimester.
        -- TODO: Add Dedicated Parent trait -10 > Reduces injuries, fatigue rate and endurance loss when a baby is equipped, by 20% (my bf has this)
    }
    return instance
end

--- Initializes traits by adding them to the TraitFactory
function TraitsManager:initTraits()
    for _, data in ipairs(self.traitsList) do
        local name = getText("UI_Trait_" .. data.IdentifierType)
        local description = getText("UI_Trait_" .. data.IdentifierType .. "_Description")

        local trait = TraitFactory.addTrait(data.IdentifierType, name, data.Cost, description, data.Profession)

        if data.Callback then
            data.Callback(trait)
        end
    end

    self:setMutualExclusives()
end

--- Sets mutual exclusives for traits
function TraitsManager:setMutualExclusives()
    for _, data in ipairs(self.traitsList) do
        for _, exclusive in ipairs(data.MutualExclusives) do
            TraitFactory.setMutualExclusive(data.IdentifierType, exclusive)
        end
    end
end

--- Registers events for initializing traits
function TraitsManager:registerEvents()
    Events.OnGameBoot.Add(function() self:initTraits() end)
    Events.OnCreateLivingCharacter.Add(function() self:initTraits() end)
end


local traitsManager = TraitsManager:new()
traitsManager:registerEvents()

--return TraitsManager
