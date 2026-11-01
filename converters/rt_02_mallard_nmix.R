# 2. N-mixture: mallard (unmarked; 239 sites x 3 visits, obs covs ivel, date)
source("rt_common.R")
DS <- "mallard_nmix"
data(mallard)
umf <- unmarkedFramePCount(y = mallard.y, siteCovs = mallard.site, obsCovs = mallard.obs)
long <- umf_to_eco(umf, taxon = "ANAPLA", site_ids = seq_len(nrow(mallard.y)))
allNA <- which(rowSums(!is.na(mallard.y)) == 0)
record(DS, "all-NA sites have no rows", !any(allNA %in% long$unit), sprintf("sites %s", paste(allNA, collapse = ",")))
v <- validate_eco(long); record(DS, "validate_eco", v$ok, paste(v$problems, collapse = "; "))
record(DS, "rows == non-NA cells", nrow(long) == sum(!is.na(mallard.y)), sprintf("%d rows, %d NA cells", nrow(long), sum(is.na(mallard.y))))
record(DS, "y is count (max > 1)", max(long$y) > 1, sprintf("max=%d", max(long$y)))
write_eco(long, "kery_2005_mallard_count", OUT,
          taxa = data.frame(taxon = "ANAPLA", scientificName = "Anas platyrhynchos", vernacularName = "Mallard", taxonRank = "species",
                             taxonID = "https://www.gbif.org/species/9761484"),
          dataset = list(title = "Mallard counts, Swiss MHB (unmarked::mallard)", responseType = "count", unitKind = "site",
                         closure = "occasion", intellectualRights = "GPL-3 (bundled with unmarked)"))
back <- read_eco(file.path(OUT, "kery_2005_mallard_count.csv"))
umf2 <- eco_to_umf(back, "pcount", site_ids = seq_len(nrow(mallard.y)))
ss <- surveyed_sites(mallard.y)
record(DS, "y identical", same_matrix(getY(umf), getY(umf2)))
record(DS, "siteCovs identical at surveyed sites", same_df(siteCovs(umf)[ss, ], siteCovs(umf2)[ss, ]))
record(DS, "siteCovs lost for all-NA sites", all(is.na(siteCovs(umf2)[allNA, ])), "expected: a unit with no surveys has no rows")
co <- compare_obs(obsCovs(umf), obsCovs(umf2), getY(umf))
record(DS, "obsCovs identical at surveyed cells", co$ok)
record(DS, "obsCovs values at unsurveyed cells (lost)", TRUE, sprintf("%d values not representable", co$n_lost))
f1 <- pcount(~ ivel + date ~ length + elev + forest, umf, K = 50)
f2 <- pcount(~ ivel + date ~ length + elev + forest, umf2, K = 50)
record(DS, "pcount estimates identical", same_estimates(coef(f1), coef(f2)), sprintf("lam(elev)=%.4f", coef(f1)["lam(elev)"]))
write_results(DS)
