require "ZomboWin/ZomboWinConfig" --- Always include this at the top to forceload ZomboWin prior to this animation file

table.insert(ZomboWinAnimationData, {
	prefix = "ZomboWin_",
	id = "Yonchi_breastpump",
	tags = {"Solo", "Standing", "Pumping"},
	actors = {
		{
			gender = "Female",
			stages = {
                {
					perform = "Yonchi_breastpump",
					duration = 1000
				}
			}
		}
	}
})