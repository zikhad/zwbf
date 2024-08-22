Distributions = Distributions or {}

local distributionTable = {
    all = {
        inventoryfemale = {
            items = {
                {item = "ZWBF.Contraceptive", amount = 20},
                {item = "ZWBF.Lactaid", amount = 10},
                {item = "ZWBF.BreastPump", amount = 1},
                {item = "ZWBF.BreastPump", amount = 1},
                {item = "ZWBF.VaginalDouche_empty", amount = 5},
            }
        },
        medicine = {
            items = {
                {item = "ZWBF.Contraceptive", amount = 10},
                {item = "ZWBF.Lactaid", amount = 5},
                {item = "ZWBF.BreastPump", amount = 2},
                {item = "ZWBF.VaginalDouche_empty", amount = 5},
            }
        }
    },
    bathroom = {
        counter = {
            items = {
                {item = "ZWBF.Contraceptive", amount = 20},
                {item = "ZWBF.Lactaid", amount = 5},
                {item = "ZWBF.BreastPump", amount = 10},
                {item = "ZWBF.VaginalDouche_empty", amount = 15},
            }
        },
        medicine = {
            items = {
                {item = "ZWBF.Contraceptive", amount = 20},
                {item = "ZWBF.Lactaid", amount = 5},
                {item = "ZWBF.BreastPump", amount = 5},
                {item = "ZWBF.VaginalDouche_empty", amount = 10},
            }
        }
    },
    motelroomoccupied = {
        sidetable = {
            items = {
                {item = "ZWBF.Contraceptive", amount = 5},
                {item = "ZWBF.BreastPump", amount = 1},
                {item = "ZWBF.VaginalDouche_empty", amount = 5},
            }
        }
    },
    Bag_DoctorBag = {
        counter = {
            items = {
                {item = "ZWBF.Contraceptive", amount = 20},
                {item = "ZWBF.Lactaid", amount = 10},
                {item = "ZWBF.BreastPump", amount = 2},
                {item = "ZWBF.VaginalDouche_empty", amount = 5},
            }
        }
    },
    Bag_MedicalBag = {
        counter = {
            items = {
                {item = "ZWBF.Contraceptive", amount = 10},
                {item = "ZWBF.Lactaid", amount = 5},
                {item = "ZWBF.BreastPump", amount = 4},
                {item = "ZWBF.VaginalDouche_empty", amount = 5},
            }
        }
    }
}

table.insert(Distributions, 1, distributionTable)

-- for mod compatibility:
SuburbsDistributions = distributionTable
