require "ZomboWin/ZomboWinConfig" --- Always include this at the top to forceload ZomboWin prior to this animation file

table.insert(ZomboWinAnimationData, {
	prefix = "ZomboWin_",
	id = "Birthing",
	tags = {"Solo", "Birthing"},
	actors = {
		{
			gender = "Female",
			stages = {
                {
					perform = "Birthing",
					duration = 1000
				}
			}
		}
	}
})