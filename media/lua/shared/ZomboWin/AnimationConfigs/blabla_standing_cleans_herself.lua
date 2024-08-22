require "ZomboWin/ZomboWinConfig" --- Always include this at the top to forceload ZomboWin prior to this animation file

table.insert(ZomboWinAnimationData, {
	prefix = "ZomboWin_",
	id = "blabla_standing_cleans_herself",
	tags = {"Solo", "Standing", "Cleaning"},
	actors = {
		{
			gender = "Female",
			stages = {
                {
					perform = "blabla_standing_cleans_herself",
					duration = 1000
				}
			}
		}
	}
})