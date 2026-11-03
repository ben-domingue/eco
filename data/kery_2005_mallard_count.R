#!/usr/bin/env Rscript
# Table:  kery_2005_mallard_count
# Source: unmarked::mallard (GPL >= 3). Swiss MHB mallard repeated counts, 239 quadrats x 3
#         surveys, the dataset of Kery, Royle & Schmid (2005, Ecological Applications 15).
# Data:   mallard.y 239 x 3 counts (NA = survey not made; 58 NA cells, 4 quadrats never
#         surveyed); mallard.site elev, length, forest (standardised); mallard.obs ivel,
#         date (standardised).
# Mapping (standard E1-E5; N-mixture, standard_draft.md section 3.2):
#   unit = quadrat row number, taxon = ANAPLA, occasion = survey 1..3, y = count;
#   unit_elev, unit_length, unit_forest; obs_ivel_std, obs_date_doy_std.
#   NA cells become missing rows (E4); the four never-surveyed quadrats have no rows and
#   their covariates are lost from the core table (round trip rt_02 records this).
#   surveyEvidence = deposited_matrix.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(unmarked))
TABLE <- "kery_2005_mallard_count"

data(mallard)
stopifnot(dim(mallard.y) == c(239, 3), sum(is.na(mallard.y)) == 58, sum(rowSums(!is.na(mallard.y)) == 0) == 4)
stopifnot(all(mallard.y[!is.na(mallard.y)] >= 0), all(mallard.y[!is.na(mallard.y)] == round(mallard.y[!is.na(mallard.y)])))
umf <- unmarkedFramePCount(y = mallard.y, siteCovs = mallard.site,
                           obsCovs = list(ivel_std = mallard.obs$ivel, date_doy_std = mallard.obs$date))
long <- umf_to_eco(umf, taxon = "ANAPLA", site_ids = seq_len(nrow(mallard.y)))
stopifnot(nrow(long) == sum(!is.na(mallard.y)), uniqueN(long$unit) == 235)

taxa <- make_taxa("ANAPLA", "Anas platyrhynchos", vernacularName = "Mallard")
dataset <- list(
  title = "Mallard repeated counts, Swiss MHB, 235 surveyed quadrats (of 239) x 3 surveys (unmarked::mallard)",
  creator = "Kery, Marc; Royle, J. Andrew; Schmid, Hans",
  pubDate = "2005", sourceURL = "https://cran.r-project.org/package=unmarked",
  citation = "Kery, M., Royle, J. A. & Schmid, H. (2005). Modeling avian abundance from replicated counts using binomial mixture models. Ecological Applications 15(4), 1450-1461. https://doi.org/10.1890/04-1120. Data as bundled in unmarked (Fiske & Chandler 2011).",
  paperDOI = "10.1890/04-1120",
  intellectualRights = list(spdx = "GPL-3.0-or-later", url = "https://www.gnu.org/licenses/gpl-3.0.html"),
  abstract = "Textbook N-mixture dataset: mallard counts on up to three surveys of 235 MHB quadrats (239 in unmarked::mallard; four were never surveyed and have no rows), with standardised elevation, transect length and forest cover, and standardised survey intensity and date.",
  samplingProtocol = "Simplified territory mapping along a fixed transect in each 1-km2 quadrat, up to three surveys per breeding season; count of individuals per survey.",
  samplingProtocolCode = "line_transect", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site", closure = "occasion",
  geographicCoverage = "Switzerland, MHB 1-km2 quadrats (no coordinates in the package)",
  temporalCoverage = "one breeding season (2002 per Kery, Royle & Schmid 2005)",
  coordinatesCoarsened = NA,
  covariateNote = "All covariates are standardised in the package; the raw scales are not recoverable.",
  notShipped = list(unsurveyed_quadrats = "4 quadrats with no survey have no rows; their covariates are not in the core table"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/kery_2005_mallard_count.R")
stage_dict_row(TABLE,
  description = "Mallard counts on up to 3 surveys of 239 Swiss MHB 1-km2 quadrats (235 surveyed), with standardised elevation, transect length, forest, survey intensity and date (unmarked::mallard; Kery, Royle & Schmid 2005).",
  url = "https://cran.r-project.org/package=unmarked",
  reference = "Kery, M., Royle, J. A. & Schmid, H. (2005). Modeling avian abundance from replicated counts using binomial mixture models. Ecological Applications 15(4), 1450-1461.",
  doi_paper = "10.1890/04-1120", original_license = "GPL-3", derived_license = "GPL-3",
  notes = "Textbook dataset bundled with an R package; covariates standardised. Round-trip tested in converters/rt_02_mallard_nmix.R.",
  source_via = "R package (unmarked)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture",
  sampling_protocol = "line_transect", design = "Single-season", realm = "Freshwater", country = "CHE",
  coordinates = "None in source", notes = "Textbook dataset (unmarked). 58 unsurveyed cells; 4 quadrats never surveyed.")
