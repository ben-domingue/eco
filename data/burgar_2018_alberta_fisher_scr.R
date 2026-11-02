#!/usr/bin/env Rscript
# Table:  burgar_2018_alberta_fisher_scr
# Source: Dryad doi:10.5061/dryad.dh7cd36 (CC0 1.0), version 17922 (published 2019-07-05)
#   Burgar, J. M., Stewart, F. E. C., Volpe, J. P., Fisher, J. T. & Burton, A. C. (2019). Data
#   from: Estimating density for species conservation: comparing camera trap spatial count
#   models to genetic spatial capture-recapture models. Dryad.
# Paper:  Burgar, J. M., Stewart, F. E. C., Volpe, J. P., Fisher, J. T. & Burton, A. C. (2018).
#         Estimating density for species conservation: Comparing camera trap spatial count
#         models to genetic spatial capture-recapture models. Global Ecology and Conservation
#         15, e00411. doi:10.1016/j.gecco.2018.e00411 (open access, CC BY-NC-ND; the publisher
#         returned a bot wall to the agent, so the design below rests on the deposit, the
#         Dryad abstract and the readme-less file structure).
# Data:   three files. edf.csv (43 rows): the SCR encounter data file, one row per genetic
#         detection of an identified fisher at a hair-snag site: sessionID (all 1),
#         individualID_2016 (1..24), occasionID_2016 (1..4), secr_trapID (1..64), sex (F/M).
#         TDF.csv (64 rows): the trap deployment file, secr_trapID, Easting, Northing (UTM
#         metres, zone not stated) and one usage column per occasion ("1".."4"), all 1.
#         Fisher_60min2016_matrix.csv: the unmarked camera data, shipped as the sibling table
#         burgar_2018_alberta_fisher_count (site ids 1..66 minus 11 and 21, a numbering that
#         does not match secr_trapID, so the two tables are not joined).
#         Asserted below: 43 encounters, 24 individuals (15 F, 9 M, sex constant within
#         individual), 4 occasions, 64 traps all used on all 4 occasions, no duplicate
#         (individual, occasion, trap), every trap in the edf is in the TDF.
#
# Mapping (standard E1-E6, E9 experimental: spatial capture-recapture, closed population,
#   genetic (hair snag) detections):
#   unit = individual fisher (F1..F24), trap = hair-snag site (T01..T64), occasion = the
#   deposit's sampling occasion 1..4 (one session = one period, omitted), y = 1 if the
#   individual's hair was genotyped at that site on that occasion, else 0; a (unit, trap,
#   occasion) is recorded at most once, so no y_raw. Survey set = effort_table: the TDF
#   usage columns; every site was used on every occasion (64 x 4 = 256 surveyed
#   site-occasions). Full rectangle 24 x 256 = 6,144 rows (BATCH_LOG batch 5 convention).
#   unit_sex as deposited. unitKind = individual. __traps: trap, x, y (UTM metres as
#   deposited; the zone is not stated: zone 12N places the grid at 53.2-53.6 N,
#   112.7-113.1 W, east of Edmonton, Alberta, the authors' fisher study area; zone 11N
#   would put it in the Rocky Mountain foothills), n_occasions_used = 4. Fisher is IUCN
#   Least Concern; coordinates kept as published.
#   NOT shipped: nothing from these two files. Calendar dates of the occasions are not
#   deposited (the column names say 2016).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "burgar_2018_alberta_fisher_scr"
SCRIPT <- "data/burgar_2018_alberta_fisher_scr.R"
dir <- download_dryad("10.5061/dryad.dh7cd36", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("edf.csv", "Fisher_60min2016_matrix.csv", "TDF.csv")))

edf <- fread(file.path(dir, "edf.csv"))
tdf <- fread(file.path(dir, "TDF.csv"))
stopifnot(identical(names(edf), c("sessionID", "individualID_2016", "occasionID_2016", "secr_trapID", "sex")),
          identical(names(tdf), c("secr_trapID", "Easting", "Northing", "1", "2", "3", "4")),
          nrow(edf) == 43, nrow(tdf) == 64)

# --- traps and usage (the survey set) ----------------------------------------------------
stopifnot(identical(tdf$secr_trapID, 1:64), all(unlist(tdf[, c("1", "2", "3", "4")]) == 1L),
          all(tdf$Easting > 359e3 & tdf$Easting < 385e3), all(tdf$Northing > 5898e3 & tdf$Northing < 5941e3))
traps <- tdf[, .(trap = sprintf("T%02d", secr_trapID), x = as.numeric(Easting), y = as.numeric(Northing),
                 n_occasions_used = 4L)]
usage <- melt(tdf[, c("secr_trapID", "1", "2", "3", "4"), with = FALSE], id.vars = "secr_trapID",
              variable.name = "occasion", value.name = "used")[used == 1]
usage[, `:=`(trap = sprintf("T%02d", secr_trapID), occasion = as.integer(as.character(occasion)))]
stopifnot(nrow(usage) == 256)

# --- encounters ---------------------------------------------------------------------------
stopifnot(all(edf$sessionID == 1L), all(edf$occasionID_2016 %in% 1:4), all(edf$secr_trapID %in% 1:64),
          all(edf$sex %in% c("F", "M")), uniqueN(edf$individualID_2016) == 24,
          identical(sort(unique(edf$individualID_2016)), 1:24),
          all(edf[, uniqueN(sex), by = individualID_2016]$V1 == 1),
          edf[, uniqueN(individualID_2016), by = sex][order(sex), V1] == c(15L, 9L),
          !anyDuplicated(edf[, .(individualID_2016, occasionID_2016, secr_trapID)]))
enc <- edf[, .(unit = sprintf("F%02d", individualID_2016), trap = sprintf("T%02d", secr_trapID),
               occasion = as.integer(occasionID_2016), sex, y = 1L)]
cat(sprintf("  %d genetic detections of %d fishers (%d F, %d M) at %d of 64 sites over 4 occasions\n",
            nrow(enc), uniqueN(enc$unit), uniqueN(enc[sex == "F", unit]), uniqueN(enc[sex == "M", unit]), uniqueN(enc$trap)))

# --- the rectangle: individual x used site-occasion -------------------------------------
inds <- unique(enc[, .(unit, sex)])[order(unit)]
long <- CJ(unit = inds$unit, i = seq_len(nrow(usage)))
long <- cbind(long[, .(unit)], usage[long$i, .(trap, occasion)])
long <- merge(long, enc[, .(unit, trap, occasion, y)], by = c("unit", "trap", "occasion"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- merge(long, inds, by = "unit")
stopifnot(nrow(long) == 24 * 256, sum(long$y) == 43)
long <- long[, .(unit, taxon = "PEKPEN", y, trap, occasion, unit_sex = sex)]
long <- order_eco(long)

taxa <- make_taxa("PEKPEN", "Pekania pennanti", vernacularName = "Fisher", taxon_iucnCategory = "LC")

dataset <- list(
  title = "Genetic spatial capture-recapture of fishers at 64 hair-snag sites, Alberta, 2016: 24 individuals x 64 sites x 4 occasions",
  creator = "Burgar, Joanna M.; Stewart, Frances E. C.; Volpe, John P.; Fisher, Jason T.; Burton, A. Cole",
  pubDate = "2019", doi = "10.5061/dryad.dh7cd36", sourceURL = "https://doi.org/10.5061/dryad.dh7cd36",
  citation = "Burgar, J. M., Stewart, F. E. C., Volpe, J. P., Fisher, J. T., & Burton, A. C. (2019). Data from: Estimating density for species conservation: comparing camera trap spatial count models to genetic spatial capture-recapture models [Data set]. Dryad. https://doi.org/10.5061/dryad.dh7cd36",
  paperDOI = "10.1016/j.gecco.2018.e00411",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Non-invasive genetic detections of individually identified fishers (Pekania pennanti) at 64 hair-snag sites over four sampling occasions in 2016, the 'marked' data set of a study comparing genetic spatial capture-recapture density estimates with camera-trap spatial count estimates for the same population. The deposit is a secr-style encounter data file (individual, occasion, trap, sex) and a trap deployment file (site coordinates and per-occasion usage, all sites used on all occasions). The table is one row per fisher x site x occasion, y = 1 where the individual was genotyped from hair at that site on that occasion. 24 individuals (15 females, 9 males), 43 detections.",
  samplingProtocol = "Hair-snag sites on a 64-site array (deposited as secr trap 1-64, UTM coordinates), checked on four sampling occasions in 2016; hair samples genotyped to individual and sex. Occasion dates and the snag design are in the paper, which the agent could not fetch.",
  samplingProtocolCode = "hair_snag", surveyEvidence = "effort_table",
  surveyEvidenceNote = "TDF.csv carries a usage column per occasion; every site was used on every occasion (256 site-occasions). Every individual carries all 256, including occasions without a detection.",
  responseType = "detection", unitKind = "individual",
  closure = "single session (one period, omitted): the four occasions are treated as a closed population, as in the authors' SCR; occasion = sampling occasion 1-4",
  geographicCoverage = "Alberta, Canada; site coordinates in __traps in UTM metres (zone not stated in the deposit; zone 12N places the grid at 53.2-53.6 N, 112.7-113.1 W, the Beaver Hills east of Edmonton)",
  temporalCoverage = "2016",
  crs = "UTM metres, zone not stated in the deposit; EPSG:32612 (zone 12N) by inference from the coordinate range and the authors' study area",
  coordinatesCoarsened = list(value = FALSE, method = "kept as published: fisher is IUCN Least Concern"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps. Closed population, four occasions, genetic (hair-snag) detections. The sibling table burgar_2018_alberta_fisher_count holds the unmarked camera-trap data from the same study; its site numbering (1-66) differs from secr_trapID and the deposit gives no key, so the two are not joined.",
  notes = "Occasion calendar dates are not deposited (column names carry 2016). Individuals are F01-F24 (the deposit's individualID_2016), sites T01-T64 (secr_trapID). unit_sex as deposited.",
  notShipped = list(Fisher_60min2016_matrix.csv = "the unmarked camera detections, shipped as burgar_2018_alberta_fisher_count"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Genetic spatial capture-recapture detections of 24 fishers at 64 hair-snag sites over 4 occasions in Alberta, 2016 (one row per fisher x site x occasion), with UTM site coordinates in __traps.",
  url = "https://doi.org/10.5061/dryad.dh7cd36",
  reference = "Burgar, J. M., Stewart, F. E. C., Volpe, J. P., Fisher, J. T., & Burton, A. C. (2018). Estimating density for species conservation: Comparing camera trap spatial count models to genetic spatial capture-recapture models. Global Ecology and Conservation, 15, e00411.",
  doi_paper = "10.1016/j.gecco.2018.e00411", doi_data = "10.5061/dryad.dh7cd36",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Closed-population genetic SCR (E9 experimental): trap key + __traps. Survey set = TDF usage (all sites, all occasions). Sibling camera table burgar_2018_alberta_fisher_count not joinable (different site numbering). Below floor (24 individuals).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (closed population, genetic)",
  sampling_protocol = "hair_snag", design = "Single-season (4 occasions, 64 hair-snag sites)", realm = "Terrestrial",
  country = "CAN", coordinates = "As published (site coordinates in __traps, UTM; zone inferred 12N)",
  notes = "Experimental (E9): trap key + __traps. Individuals as unit, full rectangle. Paper unreachable (publisher bot wall); dates from the deposit's column names only.")
