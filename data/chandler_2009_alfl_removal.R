#!/usr/bin/env Rscript
# Table:  chandler_2009_alfl_removal
# Source: unmarked package files csv/alfl.csv and csv/alflCovs.csv (GPL >= 3): alder flycatcher
#         point counts with three 5-minute intervals at 50 points, Massachusetts, 2005
#         (Chandler, King & DeStefano 2009, Auk 126). The dataset of the unmarked
#         capture-recapture (multinomPois) vignette.
# Data:   alfl.csv: one row per detected individual with id (point), survey (1-3), and
#         interval1-3 (0/1 detected in that interval); alflCovs.csv: 50 points x woody,
#         struct, time.1-3, date.1-3. Survey 1 only is shipped, as in the vignette.
# Mapping (standard E1-E5, E9 declared stretch; multinomial N-mixture, removal design,
#   standard_draft.md section 3.3): unit = point, taxon = EMPALN, occasion = removal interval
#   1..3 with y_raw = "int1".."int3", y = number of individuals FIRST detected in that
#   interval; unit_woody, unit_struct, unit_time_survey1, unit_date_survey1. 
#   multinomialType = removal (E9: the cell-probability function is metadata, not data).
#   surveyEvidence = deposited_matrix (every point has three cells; points with no
#   detections are all-zero rows in the covariate file's point list).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(unmarked))
TABLE <- "chandler_2009_alfl_removal"

alfl <- read.csv(system.file("csv", "alfl.csv", package = "unmarked"))
covs <- read.csv(system.file("csv", "alflCovs.csv", package = "unmarked"), row.names = 1)
stopifnot(nrow(covs) == 50, all(alfl$id %in% rownames(covs)), all(alfl$survey %in% 1:3))
alfl$ch <- factor(paste0(alfl$interval1, alfl$interval2, alfl$interval3),
                  levels = c("001", "010", "011", "100", "101", "110", "111"))
alfl$id <- factor(alfl$id, levels = rownames(covs))
a1 <- alfl[alfl$survey == 1, ]
H <- table(a1$id, a1$ch)
y <- cbind(int1 = rowSums(H[, c("100", "101", "110", "111")]), int2 = rowSums(H[, c("010", "011")]), int3 = H[, "001"])
stopifnot(nrow(y) == 50, sum(y) == nrow(a1))
site_covs <- data.frame(woody = covs$woody, struct = covs$struct, time_survey1 = covs$time.1, date_survey1 = covs$date.1)
umf <- unmarkedFrameMPois(y = y, siteCovs = site_covs, type = "removal")
long <- mpois_to_eco(umf, taxon = "EMPALN")
stopifnot(nrow(long) == 150, all(c("int1", "int2", "int3") %in% long$y_raw), setequal(long$unit, rownames(covs)))

taxa <- make_taxa("EMPALN", "Empidonax alnorum", vernacularName = "Alder Flycatcher")
dataset <- list(
  title = "Alder flycatcher removal counts, 50 points x 3 five-minute intervals, Massachusetts 2005, survey 1 (unmarked alfl.csv)",
  creator = "Chandler, Richard B.; King, David I.; DeStefano, Stephen",
  pubDate = "2009", sourceURL = "https://cran.r-project.org/package=unmarked",
  citation = "Chandler, R. B., King, D. I. & DeStefano, S. (2009). Scrub-shrub bird habitat associations at multiple spatial scales in beaver meadows in Massachusetts. The Auk 126(1), 186-197. https://doi.org/10.1525/auk.2009.08083. Data as bundled in unmarked (Fiske & Chandler 2011), files csv/alfl.csv and csv/alflCovs.csv.",
  paperDOI = "10.1525/auk.2009.08083",
  intellectualRights = list(spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html"),
  abstract = "Textbook multinomial N-mixture (removal) dataset: alder flycatchers first detected in each of three consecutive 5-minute intervals of a 15-minute point count at 50 points in beaver meadows, Massachusetts, 2005; survey 1 of 3, as analysed in the unmarked capture-recapture vignette.",
  samplingProtocol = "15-minute point counts split into three 5-minute removal intervals; individuals assigned to the interval of first detection. Per-individual time and distance records in the source are collapsed to interval counts.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix",
  responseType = "multinomial_cell", multinomialType = "removal", unitKind = "site", closure = "occasion",
  geographicCoverage = "Beaver meadows, western Massachusetts, USA (no coordinates in the package files)",
  temporalCoverage = "2005",
  coordinatesCoarsened = NA,
  notShipped = list(surveys_2_and_3 = "the package file holds three surveys per point; survey 1 only is shipped, as in the vignette; a gmultmix-style table with period = survey is a follow-up",
                    per_individual_rows = "individual capture histories across intervals are collapsed to first-detection interval counts"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/chandler_2009_alfl_removal.R")
stage_dict_row(TABLE,
  description = "Alder flycatcher removal counts (individuals first detected in each of three 5-minute intervals) at 50 points in Massachusetts beaver meadows, 2005, survey 1, with woody vegetation, structure, time and date covariates (unmarked alfl.csv; Chandler, King & DeStefano 2009). First multinomial_cell table.",
  url = "https://cran.r-project.org/package=unmarked",
  reference = "Chandler, R. B., King, D. I. & DeStefano, S. (2009). Scrub-shrub bird habitat associations at multiple spatial scales in beaver meadows in Massachusetts. The Auk 126(1), 186-197.",
  doi_paper = "10.1525/auk.2009.08083", original_license = "GPL-3", derived_license = "GPL-3",
  notes = "Textbook dataset bundled with an R package. occasion indexes the removal interval (standard E9 declared stretch); multinomialType = removal. Round-trip tested in converters/rt_03_alfl_removal.R.",
  source_via = "R package (unmarked)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multinomial N-mixture (removal)",
  sampling_protocol = "point_count", design = "Single-season", realm = "Terrestrial", country = "USA",
  coordinates = "None in source", notes = "Textbook dataset (unmarked). Declared stretch: occasion = removal interval.")
