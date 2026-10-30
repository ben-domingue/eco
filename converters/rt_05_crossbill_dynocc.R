# 5. Dynamic occupancy: crossbill (unmarked; 267 sites x 9 years x 3 visits, NA for missed surveys)
source("rt_common.R")
DS <- "crossbill_dynocc"
data(crossbill)
DATE <- as.matrix(crossbill[, 32:58]); y.cross <- as.matrix(crossbill[, 5:31])
y.cross[is.na(DATE) != is.na(y.cross)] <- NA
sd.DATE <- sd(DATE, na.rm = TRUE); mean.DATE <- mean(DATE, na.rm = TRUE)
DATE <- (DATE - mean.DATE) / sd.DATE
years <- as.character(1999:2007); years <- matrix(years, nrow(crossbill), 9, byrow = TRUE)
umf <- unmarkedMultFrame(y = y.cross, siteCovs = crossbill[, 2:3], yearlySiteCovs = list(year = years),
                         obsCovs = list(date = DATE), numPrimary = 9)
long <- umf_to_eco(umf, item = "LOXCUR", site_ids = crossbill$id)
v <- validate_eco(long); record(DS, "validate_eco", v$ok, paste(v$problems, collapse = "; "))
record(DS, "rows == non-NA cells", nrow(long) == sum(!is.na(y.cross)), sprintf("%d rows, %d NA cells", nrow(long), sum(is.na(y.cross))))
record(DS, "period 1..9, occasion 1..3", identical(sort(unique(long$period)), 1:9) && identical(sort(unique(long$occasion)), 1:3))
write_eco(long, "kery_2010_crossbill_dynocc", OUT,
          items = data.frame(item = "LOXCUR", scientificName = "Loxia curvirostra", vernacularName = "Red Crossbill", taxonRank = "species",
                             taxonID = "https://www.gbif.org/species/2494686"),
          dataset = list(title = "European crossbill detections, Swiss MHB 1999-2007 (unmarked::crossbill)", responseType = "detection",
                         unitKind = "site", itemKind = "taxon", closure = "occasion", intellectualRights = "GPL-3 (bundled with unmarked)"))
back <- read_eco(file.path(OUT, "kery_2010_crossbill_dynocc.csv"))
umf2 <- eco_to_umf(back, "colext", site_ids = crossbill$id)
record(DS, "y identical", same_matrix(getY(umf), getY(umf2)))
record(DS, "siteCovs identical at surveyed sites", same_df(siteCovs(umf)[surveyed_sites(y.cross), ], siteCovs(umf2)[surveyed_sites(y.cross), ]))
ss <- surveyed_sites(y.cross); allNA <- setdiff(seq_len(nrow(y.cross)), ss)
ysc1 <- as.character(yearlySiteCovs(umf)$year); ysc2 <- as.character(yearlySiteCovs(umf2)$year)
surveyed_sp <- as.vector(apply(!is.na(y.cross), 1, function(r) tapply(r, rep(1:9, each = 3), any)))  # apply returns T x M; column-major == site-major
record(DS, "yearlySiteCovs identical at surveyed site-periods", identical(ysc1[surveyed_sp], ysc2[surveyed_sp]))
record(DS, "yearlySiteCovs lost at unsurveyed site-periods", all(is.na(ysc2[!surveyed_sp])), sprintf("%d site-periods; 'year' is a function of period and belongs in the periods side table", sum(!surveyed_sp)))
# rebuild year from period (deterministic), as a periods side table would
umf2@yearlySiteCovs$year <- factor(rep(as.character(1999:2007), nrow(y.cross)))
record(DS, "sites with no surveys at all", TRUE, sprintf("%d sites; their siteCovs are lost", length(allNA)))
# obsCovs: unmarked keeps date at cells where y is NA only if date was non-NA; we NA'd y where date NA so they coincide.
oc1 <- obsCovs(umf); oc2 <- obsCovs(umf2)
record(DS, "obsCovs identical at surveyed cells", isTRUE(all.equal(oc1$date[!is.na(oc1$date)], oc2$date[!is.na(oc2$date)])) && identical(is.na(oc1$date), is.na(oc2$date)))
# fit on surveyed sites only: a never-surveyed site contributes nothing to the likelihood, but its NA siteCovs
# in the reconstructed frame would break the optimiser
f1 <- colext(~ ele + forest, ~ year, ~ year, ~ date, umf[ss, ])
f2 <- colext(~ ele + forest, ~ year, ~ year, ~ date, umf2[ss, ])
record(DS, "colext estimates identical", same_estimates(coef(f1), coef(f2), tol = 1e-5), sprintf("psi(ele)=%.4f", coef(f1)[2]))
write_results(DS)
