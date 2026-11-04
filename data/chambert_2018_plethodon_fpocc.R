#!/usr/bin/env Rscript
# Table:  chambert_2018_plethodon_fpocc
# Source: Dryad doi:10.5061/dryad.88ks4g5 (CC0 1.0, as shown on the Dryad page; published
#         2019-02-06). Chambert, T., Grant, E.H.C., Miller, D.A.W., Nichols, J.D., Mulder,
#         K.P. & Brand, A.B. (2019). Data from: Two-species occupancy modeling accounting for
#         species misidentification and nondetection.
# Paper:  Chambert, T., Grant, E.H.C., Miller, D.A.W., Nichols, J.D., Mulder, K.P. & Brand,
#         A.B. (2018). Two-species occupancy modelling accounting for species
#         misidentification and non-detection. Methods in Ecology and Evolution 9,
#         1468-1477, doi:10.1111/2041-210X.12985. The worked example: the federally
#         endangered Shenandoah salamander (Plethodon shenandoah) and the red-backed
#         salamander (P. cinereus), Shenandoah National Park, 2011-2014.
# Data:   Data Salamanders.xlsx, three sheets. "readme": state codes 0 = no species
#         detected, 1 = P. cinereus, 2 = P. shenandoah, 3 = both species; 2011 has 3
#         occasions, 2012 2, 2013 5, 2014 3. "Field Detection Y": 131 sites (S1..S131) x
#         13 occasions (header row gives the year of each column), field-identified state
#         0-3, NA = not surveyed. "Confirmatory Data W": same layout and the same NA
#         pattern (asserted), the state confirmed by DNA analysis for the site-occasion;
#         0 where no confirmation exists (W = 0 on 219 site-occasions where the field
#         recorded P. cinereus and on every field 0), so W = 0 means "not confirmed", not
#         "confirmed absent". README_for_Data Salamanders.txt repeats the codes. No dates,
#         no covariates, no coordinates.
#
# Mapping (standard: multi-species occupancy with misidentification, E9 core list:
#   multi-state / false-positive occupancy; the joint state is decomposed losslessly into
#   one detection row per species):
#   unit = site; period = year 1..4 (2011-2014, __periods); occasion = survey within year;
#   taxon = PLECIN, PLESHE; y = the species is in the field-identified state (state 1 or 3
#   for cinereus, 2 or 3 for shenandoah); y_raw = the field state code 0-3 (identical on
#   both taxon rows of a survey); obs_dna_state = the confirmatory code 0-3 (0 = not
#   confirmed), the certain method named in detectionCertainty. Survey evidence: the
#   deposited site x occasion matrix (NA = not surveyed). The field state is
#   reconstructable as y(PLECIN) + 2 * y(PLESHE) = y_raw.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "chambert_2018_plethodon_fpocc"
dir <- download_dryad("10.5061/dryad.88ks4g5", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Data Salamanders\\.xlsx$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1, identical(excel_sheets(f), c("readme", "Field Detection Y", "Confirmatory Data W")))
rd <- function(s) {
  x <- as.matrix(as.data.frame(suppressMessages(read_excel(f, s, col_names = FALSE, col_types = "text"))))
  stopifnot(x[1, 1] == "Site", all(x[-1, -1] %in% c("0", "1", "2", "3", "NA")))
  m <- x[-1, -1]; m[m == "NA"] <- NA; m <- matrix(as.integer(m), nrow(m))
  dimnames(m) <- list(x[-1, 1], x[1, -1]); m
}
Y <- rd("Field Detection Y"); W <- rd("Confirmatory Data W")
YEAR <- as.integer(colnames(Y))

# facts about the source
stopifnot(identical(dim(Y), c(131L, 13L)), identical(rownames(Y), paste0("S", 1:131)), identical(dimnames(Y), dimnames(W)),
          identical(YEAR, rep(2011:2014, c(3, 2, 5, 3))), identical(is.na(Y), is.na(W)),
          sum(!is.na(Y)) == 680, identical(as.vector(table(Y)), c(364L, 222L, 51L, 43L)),
          identical(as.vector(table(W)), c(668L, 4L, 7L, 1L)), all(W[!is.na(Y) & Y == 0] == 0),
          all(rowSums(!is.na(Y)) > 0))

period <- YEAR - 2010L
cin <- ifelse(is.na(Y), NA, as.integer(Y %in% c(1, 3))); she <- ifelse(is.na(Y), NA, as.integer(Y %in% c(2, 3)))
arr <- array(c(cin, she), dim = c(131, 13, 2), dimnames = list(rownames(Y), NULL, c("PLECIN", "PLESHE")))
raw3 <- array(c(Y, Y), dim = c(131, 13, 2))
long <- array_to_eco(arr, site_ids = rownames(Y), period = period, y_raw = raw3,
                     obs_covs = list(dna_state = W))
stopifnot(nrow(long) == 680 * 2, !any(grepl("^unit_unit_", names(long))),
          long[, all(y_raw == sum(y * c(PLECIN = 1L, PLESHE = 2L)[taxon])), by = .(unit, period, occasion)][, all(V1)],
          sum(long[taxon == "PLECIN", y]) == 222 + 43, sum(long[taxon == "PLESHE", y]) == 51 + 43)

taxa <- make_taxa(c("PLECIN", "PLESHE"), c("Plethodon cinereus", "Plethodon shenandoah"),
                  vernacularName = c("Red-backed salamander", "Shenandoah salamander"),
                  taxon_conservationStatus = c(NA, "Endangered (US ESA); IUCN Vulnerable"))
periods <- data.table(period = 1:4, year = 2011:2014, n_occasions = c(3L, 2L, 5L, 3L),
                      n_sites_surveyed = sapply(1:4, function(k) sum(rowSums(!is.na(Y[, period == k, drop = FALSE])) > 0)))

dataset <- list(
  title = "Field-identified and DNA-confirmed detections of Shenandoah and red-backed salamanders at 131 sites in Shenandoah National Park, 2011-2014",
  creator = "Chambert, Thierry; Grant, Evan H. Campbell; Miller, David A. W.; Nichols, James D.; Mulder, Kevin P.; Brand, Adrianne B.",
  pubDate = "2019", doi = "10.5061/dryad.88ks4g5", sourceURL = "https://doi.org/10.5061/dryad.88ks4g5",
  citation = "Chambert, T., Grant, E. H. C., Miller, D. A. W., Nichols, J. D., Mulder, K. P., & Brand, A. B. (2019). Data from: Two-species occupancy modeling accounting for species misidentification and nondetection [Dataset]. Dryad. https://doi.org/10.5061/dryad.88ks4g5",
  paperDOI = "10.1111/2041-210X.12985",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Repeated surveys of 131 sites for two sympatric lungless salamanders, the federally endangered Shenandoah salamander (Plethodon shenandoah) and the red-backed salamander (P. cinereus), over four years (2011-2014, 2-5 surveys per year), recording the species identified in the field and, for a subset of site-occasions, the identity confirmed by DNA analysis. The worked example for a two-species occupancy model that accounts for misidentification between the species.",
  samplingProtocol = "Repeated surveys of salamander sites within each year; animals identified to species in the field, with genetic confirmation of identity for a subset. Survey method and site layout are in the paper.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "period (year)", occasionKind = "time", taxonInclusion = "target",
  detectionCertainty = list(column = "obs_dna_state", method = "DNA-based species identification of animals from the site-occasion", level = "obs (site-occasion)",
                            note = "0 = no confirmation available; 1 = P. cinereus confirmed, 2 = P. shenandoah confirmed, 3 = both confirmed. Field identifications (y, y_raw) may be misidentifications; confirmed codes are certain."),
  stateCodes = list(`0` = "no species detected", `1` = "P. cinereus", `2` = "P. shenandoah", `3` = "both species"),
  geographicCoverage = "Shenandoah National Park, Virginia, USA (talus and forest habitat of P. shenandoah); no coordinates deposited",
  temporalCoverage = "2011/2014",
  coordinatesCoarsened = NA,
  notShipped = list(none = "every deposited cell is shipped"),
  notes = "y is the field identification per species; y_raw is the deposited joint field code (stateCodes), equal to y(PLECIN) + 2 * y(PLESHE) at every survey (asserted). obs_dna_state carries the confirmatory matrix W on both taxon rows; W = 0 means not confirmed (it occurs at most field detections), not confirmed absence. Disagreements exist: field cinereus with DNA both (1), field both with DNA cinereus only (2) or shenandoah only (2). The two-species misidentification model needs the joint code, which y_raw preserves.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/chambert_2018_plethodon_fpocc.R")

stage_dict_row(TABLE,
  description = "Field-identified detections of the endangered Shenandoah salamander and the red-backed salamander at 131 sites in Shenandoah National Park, 2011-2014 (2-5 surveys per year), with the joint field state and the DNA-confirmed identity where available: the worked example for two-species occupancy with misidentification.",
  url = "https://doi.org/10.5061/dryad.88ks4g5",
  reference = "Chambert, T., Grant, E. H. C., Miller, D. A. W., Nichols, J. D., Mulder, K. P., & Brand, A. B. (2018). Two-species occupancy modelling accounting for species misidentification and non-detection. Methods in Ecology and Evolution, 9(6), 1468-1477.",
  doi_paper = "10.1111/2041-210X.12985", doi_data = "10.5061/dryad.88ks4g5",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "First species-misidentification table: joint field state in y_raw, DNA confirmation in obs_dna_state. No coordinates deposited.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Two-species occupancy with misidentification (false positives)",
  sampling_protocol = "visual_encounter", design = "Multi-season (4 years, 2-5 surveys each)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "680 site-occasions; 12 DNA confirmations.")
