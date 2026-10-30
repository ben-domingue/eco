# 3. Multinomial N-mixture, removal design: Alder Flycatcher (unmarked alfl.csv), as in the unmarked
#    multinomPois vignette: survey 1, counts per removal interval, covariates struct, woody, time, date.
source("rt_common.R")
DS <- "alfl_removal"
alfl <- read.csv(system.file("csv", "alfl.csv", package = "unmarked"))
covs <- read.csv(system.file("csv", "alflCovs.csv", package = "unmarked"), row.names = 1)
alfl$captureHistory <- paste(alfl$interval1, alfl$interval2, alfl$interval3, sep = "")
alfl$captureHistory <- factor(alfl$captureHistory, levels = c("001", "010", "011", "100", "101", "110", "111"))
alfl$id <- factor(alfl$id, levels = rownames(covs))
alfl1 <- alfl[alfl$survey == 1, ]
alfl.H1 <- table(alfl1$id, alfl1$captureHistory)
# removal counts per interval (textbook: first-capture interval)
y <- cbind(rowSums(alfl.H1[, c("100", "101", "110", "111")]),
           rowSums(alfl.H1[, c("010", "011")]), alfl.H1[, "001"])
colnames(y) <- c("int1", "int2", "int3")
umf <- unmarkedFrameMPois(y = y, siteCovs = covs[, c("woody", "struct", "time.1", "date.1")], type = "removal")
long <- mpois_to_eco(umf, item = "EMPALN")
v <- validate_eco(long); record(DS, "validate_eco", v$ok, paste(v$problems, collapse = "; "))
record(DS, "resp_raw carries cell label", all(c("int1", "int2", "int3") %in% long$resp_raw))
write_eco(long, "chandler_2009_alfl_removal", OUT,
          items = data.frame(item = "EMPALN", scientificName = "Empidonax alnorum", vernacularName = "Alder Flycatcher", taxonRank = "species",
                             taxonID = "https://www.gbif.org/species/2483057"),
          dataset = list(title = "Alder Flycatcher removal counts, survey 1 (unmarked alfl)", responseType = "multinomial_cell",
                         multinomialType = "removal", unitKind = "site", itemKind = "taxon", closure = "occasion",
                         intellectualRights = "GPL-3 (bundled with unmarked)"))
back <- read_eco(file.path(OUT, "chandler_2009_alfl_removal.csv"))
umf2 <- eco_to_mpois(back, type = "removal")
record(DS, "y identical", same_matrix(getY(umf), getY(umf2)))
record(DS, "siteCovs identical", same_df(siteCovs(umf), siteCovs(umf2)))
record(DS, "multinomialType needed from metadata", TRUE, "cell-probability function not recoverable from the table")
f1 <- multinomPois(~ 1 ~ woody, umf); f2 <- multinomPois(~ 1 ~ woody, umf2)
record(DS, "multinomPois estimates identical", same_estimates(coef(f1), coef(f2)), sprintf("lam(woody)=%.4f", coef(f1)[2]))
write_results(DS)
