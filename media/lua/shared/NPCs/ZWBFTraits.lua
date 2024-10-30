require("NPCS/MainCreationMethods")


-- PZ Variables
local TraitFactory = TraitFactory
-- local Perks = Perks
local getText = getText
local Events = Events

--- Table of all the traits relevant to ZWBF
local TRAITS_LIST = {
    {
		IdentifierType = "Fertile",
		Cost = 2,
		Profession = false,
		MutualExclusives = {},
	},
    {
		IdentifierType = "Infertile",
		Cost = -3,
		Profession = false,
		MutualExclusives = {"Fertile"},
	},
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