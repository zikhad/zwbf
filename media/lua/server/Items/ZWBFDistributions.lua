Distributions = Distributions or {}

local distributionTable = {
    all = {
        inventoryfemale = {
            rolls = 2,
            items = {
                {item = "ZWBF.Condom", amount = 60},
                {item = "ZWBF.CondomBox", amount = 45},
                {item = "ZWBF.Contraceptive", amount = 30},
                {item = "ZWBF.VaginalDouche_empty", amount = 20},
                {item = "ZWBF.BreastPump", amount = 10},
                {item = "ZWBF.Lactaid", amount = 5},
            }
        },
        medicine = {
            rolls = 5,
            items = {
                {item = "ZWBF.Condom", amount = 65},
                {item = "ZWBF.CondomBox", amount = 50},
                {item = "ZWBF.Contraceptive", amount = 40},
                {item = "ZWBF.VaginalDouche_empty", amount = 25},
                {item = "ZWBF.BreastPump", amount = 15},
                {item = "ZWBF.Lactaid", amount = 10},
            }
        },
        bin = {
            rolls = 4,
            items = {
                {item = "ZWBF.CondomUsed", amount = 60},
            }
        }
    },
    bathroom = {
        counter = {
            rolls = 5,
            items = {
                {item = "ZWBF.Condom", amount = 95},
                {item = "ZWBF.CondomBox", amount = 70},
                {item = "ZWBF.Contraceptive", amount = 60},
                {item = "ZWBF.VaginalDouche_empty", amount = 35},
                {item = "ZWBF.BreastPump", amount = 15},
                {item = "ZWBF.Lactaid", amount = 10},
            }
        },
        medicine = {
            rolls = 5,
            items = {
                {item = "ZWBF.Condom", amount = 85},
                {item = "ZWBF.CondomBox", amount = 65},
                {item = "ZWBF.Contraceptive", amount = 55},
                {item = "ZWBF.VaginalDouche_empty", amount = 30},
                {item = "ZWBF.BreastPump", amount = 15},
                {item = "ZWBF.Lactaid", amount = 10},
            }
        }
    },
    motelroomoccupied = {
        sidetable = {
            rolls = 5,
            items = {
                {item = "ZWBF.Condom", amount = 70},
                {item = "ZWBF.CondomBox", amount = 50},
                {item = "ZWBF.Contraceptive", amount = 40},
                {item = "ZWBF.VaginalDouche_empty", amount = 15},
                {item = "ZWBF.BreastPump", amount = 10},
                {item = "ZWBF.Lactaid", amount = 5},
            }
        }
    },
    Bag_DoctorBag = {
        rolls = 5,
        items = {
            {item = "ZWBF.Condom", amount = 85},
            {item = "ZWBF.CondomBox", amount = 65},
            {item = "ZWBF.Contraceptive", amount = 55},
            {item = "ZWBF.VaginalDouche_empty", amount = 30},
            {item = "ZWBF.BreastPump", amount = 20},
            {item = "ZWBF.Lactaid", amount = 10},
        }
    },
    Bag_MedicalBag = {
        rolls = 5,
        items = {
            {item = "ZWBF.Condom", amount = 90},
            {item = "ZWBF.CondomBox", amount = 70},
            {item = "ZWBF.Contraceptive", amount = 65},
            {item = "ZWBF.VaginalDouche_empty", amount = 35},
            {item = "ZWBF.BreastPump", amount = 25},
            {item = "ZWBF.Lactaid", amount = 10},
        }
    }
}

table.insert(Distributions, 1, distributionTable)

-- for mod compatibility:
SuburbsDistributions = distributionTable
