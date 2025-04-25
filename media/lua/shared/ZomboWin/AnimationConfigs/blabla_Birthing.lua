require "ZomboWin/ZomboWinConfig" --- Always include this at the top to forceload ZomboWin prior to this animation file

table.insert(ZomboWinAnimationData, {
	prefix = "ZomboWin_",
	id = "blabla_Birthing",
	tags = {"Solo", "Sitting"},
	actors = {
		{
			gender = "Female",
			stages = {
                {
					perform = "blabla_Birthing",
					duration = 6000
				}
			}
		}
	}
})