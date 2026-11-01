# Package data: the smallest released single-season occupancy table, read from the
# repository's output/ at the commit that released eco version 1. Run from Rpkg/.
schank_2015_tapir_occ <- as.data.frame(data.table::fread("../output/schank_2015_tapir_occ.csv"))
schank_2015_tapir_occ__taxa <- as.data.frame(data.table::fread("../output/schank_2015_tapir_occ__taxa.csv"))
dir.create("data", showWarnings = FALSE)
save(schank_2015_tapir_occ, file = "data/schank_2015_tapir_occ.rda", compress = "xz", version = 2)
save(schank_2015_tapir_occ__taxa, file = "data/schank_2015_tapir_occ__taxa.rda", compress = "xz", version = 2)
