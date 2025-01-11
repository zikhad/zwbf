require("NPCS/MainCreationMethods")


-- PZ Variables
local TraitFactory = TraitFactory
local getText = getText
local Events = Events

--- Table of all the traits relevant to ZWBF
local TRAITS_LIST = {
    {
		IdentifierType = "Fertile",
		Cost = -2,
		Profession = false,
		MutualExclusives = {},
	},
    {
		IdentifierType = "Infertile",
		Cost = 3,
		Profession = false,
		MutualExclusives = {"Fertile", "Pregnancy"},
	},
    -- TODO: Add Hyperfertile trait +10 > +100% fertility, Halves the time before being ready to get pregnant again after birth, increases chance of successful delivery by 10%
    {
        IdentifierType = "Hyperfertile",
		Cost = -6,
		Profession = false,
		MutualExclusives = {"Fertile", "Infertile"},
    },
    {
        IdentifierType = "Pregnancy",
		Cost = -8,
		Profession = false,
		MutualExclusives = {},
    },
    -- TODO: Add Dairy Cow trait -6 > Increases milk production rate (+25%) and time lactating (+25%).
    {
        IdentifierType = "DairyCow",
		Cost = 4,
		Profession = false,
		MutualExclusives = {},
    },
    -- TODO: Add Baby Crazy trait -6 > Decreases Unhappiness, Boredom and Stress when breastfeeding and when getting pregnant. Reduces injuries by 10% when in the 2nd or 3rd trimester.
    -- TODO: Add Dedicated Parent trait -10 > Reduces injuries, fatigue rate and endurance loss when a baby is equipped, by 20% (my bf has this)
}

local function initTraits()
    for _, data in ipairs(TRAITS_LIST) do
        local name = getText("UI_Trait_" .. data.IdentifierType)
        local description = getText("UI_Trait_" .. data.IdentifierType .. "_Description")

        local trait = TraitFactory.addTrait(data.IdentifierType, name, data.Cost, description, data.Profession)

        for _, exclusive in ipairs(data.MutualExclusives) do
            TraitFactory.setMutualExclusive(data.IdentifierType, exclusive)
        end
    end
end

Events.OnGameBoot.Add(initTraits)