Distributions = Distributions or {}

local distributionTable = {
    all = {
        inventoryfemale = {
            rolls = 2,
            items = {
                {item = "ZWBF.Contraceptive", amount = 30},
                {item = "ZWBF.Lactaid", amount = 15},
                {item = "ZWBF.BreastPump", amount = 10},
                {item = "ZWBF.BreastPump", amount = 10},
                {item = "ZWBF.VaginalDouche_empty", amount = 20},
            }
        },
        medicine = {
            rolls = 5,
            items = {
                {item = "ZWBF.Contraceptive", amount = 40},
                {item = "ZWBF.Lactaid", amount = 10},
                {item = "ZWBF.BreastPump", amount = 10},
                {item = "ZWBF.VaginalDouche_empty", amount = 20},
            }
        }
    },
    bathroom = {
        counter = {
            rolls = 5,
            items = {
                {item = "ZWBF.Contraceptive", amount = 70},
                {item = "ZWBF.Lactaid", amount = 10},
                {item = "ZWBF.BreastPump", amount = 10},
                {item = "ZWBF.VaginalDouche_empty", amount = 30},
            }
        },
        medicine = {
            rolls = 5,
            items = {
                {item = "ZWBF.Contraceptive", amount = 60},
                {item = "ZWBF.Lactaid", amount = 10},
                {item = "ZWBF.BreastPump", amount = 10},
                {item = "ZWBF.VaginalDouche_empty", amount = 15},
            }
        }
    },
    motelroomoccupied = {
        sidetable = {
            rolls = 5,
            items = {
                {item = "ZWBF.Contraceptive", amount = 40},
                {item = "ZWBF.BreastPump", amount = 10},
                {item = "ZWBF.VaginalDouche_empty", amount = 10},
            }
        }
    },
    Bag_DoctorBag = {
        counter = {
            rolls = 5,
            items = {
                {item = "ZWBF.Contraceptive", amount = 75},
                {item = "ZWBF.Lactaid", amount = 50},
                {item = "ZWBF.BreastPump", amount = 20},
                {item = "ZWBF.VaginalDouche_empty", amount = 20},
            }
        }
    },
    Bag_MedicalBag = {
        counter = {
            rolls = 5,
            items = {
                {item = "ZWBF.Contraceptive", amount = 75},
                {item = "ZWBF.Lactaid", amount = 50},
                {item = "ZWBF.BreastPump", amount = 40},
                {item = "ZWBF.VaginalDouche_empty", amount = 35},
            }
        }
    }
}

table.insert(Distributions, 1, distributionTable)

-- for mod compatibility:
SuburbsDistributions = distributionTable
