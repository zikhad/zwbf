require "ZomboWin/ZomboWinConfig" --- Always include this at the top to forceload ZomboWin prior to this animation file

local ZomboWinAnimationData = ZomboWinAnimationData

table.insert(ZomboWinAnimationData, {
	prefix = "ZomboWin_",
	id = "yonchi_standing_breastpump",
	tags = {"Solo", "Standing", "Cleaning"},
	actors = {
		{
			gender = "Female",
			stages = {
                {
					perform = "yonchi_standing_breastpump",
					duration = 1000
				}
			}
		}
	}
})