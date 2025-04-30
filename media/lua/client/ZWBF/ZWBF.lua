local EngorgementClass = require("ZWBF/ZWBFEngorgement")

-- local Lactation = require("ZWBF/ZWBFLactation")

local Engorgement = EngorgementClass:new()

Events.EveryOneMinute.Add(function()
    Engorgement:update()
end)

