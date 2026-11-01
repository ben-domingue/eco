# 4. CJS capture histories: dipper (marked; 294 individuals x 7 occasions, sex)
source("rt_common.R")
suppressPackageStartupMessages(library(marked))
DS <- "dipper_cjs"
data(dipper)
long <- ch_to_eco(dipper, taxon = "CINCIN")
v <- validate_eco(long); record(DS, "validate_eco", v$ok, paste(v$problems, collapse = "; "))
record(DS, "rows == N x T", nrow(long) == nrow(dipper) * 7)
record(DS, "period present, occasion absent", "period" %in% names(long) && !"occasion" %in% names(long))
write_eco(long, "lebreton_1992_dipper_cjs", OUT,
          taxa = data.frame(taxon = "CINCIN", scientificName = "Cinclus cinclus", vernacularName = "White-throated Dipper", taxonRank = "species",
                             taxonID = "https://www.gbif.org/species/2492826"),
          dataset = list(title = "European dipper capture histories 1981-1987 (marked::dipper)", responseType = "detection",
                         unitKind = "individual", closure = "period", intellectualRights = "GPL-2+ (bundled with marked)"))
back <- read_eco(file.path(OUT, "lebreton_1992_dipper_cjs.csv"))
d2 <- eco_to_ch(back, collapse_freq = FALSE)
d2$sex <- factor(d2$sex, levels = levels(dipper$sex))
record(DS, "ch identical (same order)", identical(d2$ch, dipper$ch))
record(DS, "sex identical", identical(as.character(d2$sex), as.character(dipper$sex)))
f1 <- crm(dipper, model.parameters = list(Phi = list(formula = ~sex), p = list(formula = ~1)), hessian = FALSE)
f2 <- crm(d2,     model.parameters = list(Phi = list(formula = ~sex), p = list(formula = ~1)), hessian = FALSE)
record(DS, "crm estimates identical", same_estimates(f1$results$beta$Phi, f2$results$beta$Phi) && same_estimates(f1$results$beta$p, f2$results$beta$p),
       sprintf("Phi(sexMale)=%.4f", f1$results$beta$Phi[2]))
write_results(DS)
