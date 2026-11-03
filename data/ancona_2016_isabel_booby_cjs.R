#!/usr/bin/env Rscript
# Table:  ancona_2016_isabel_booby_cjs
# Source: Dryad doi:10.5061/dryad.h0qp0, version 9171 (2016-06-16), CC0 1.0 (as shown on the
#         Dryad landing page and in the API record).
#   Ancona, S., Drummond, H., Rodriguez, C. & Zuniga-Vega, J. J. (2016). Data from: Long-term
#   population dynamics reveal that survival and recruitment of tropical boobies improve
#   after a hurricane.
# Paper:  Ancona, S., Zuniga-Vega, J. J., Rodriguez, C. & Drummond, H. (2017). Long-term
#         population dynamics reveal that survival and recruitment of tropical boobies improve
#         after a hurricane. Journal of Avian Biology 48(2), 320-332, doi:10.1111/jav.01133.
# Data:   one file, Capture_recapture_histories_of_adult_boobies_resighted_every_year_from_
#   1991_to_2013.txt: 4,608 lines in MARK input format, "<23-character history> <m> <f>;",
#   CRLF line ends, no individual IDs. The Dryad file description: blue-footed boobies
#   resighted as breeders during systematic monitoring of a fixed study area (26,889 m2) on
#   Isla Isabel in February-March of every breeding season 1991-2013; the two digits after
#   the history are MARK group columns, "1 0" = male, "0 1" = female. Each line has exactly
#   one 1 between them (2,391 males, 2,217 females), so each line is one bird. Only 10 birds
#   are resighted in 1991 and 1 in 1992 (the monitored cohort of marked breeders was still
#   being built); 2003 is also low (42).
#
# Mapping (standard E1-E5, CJS): unit = line number in the deposit (BFBO0001..BFBO4608; the
#   deposit has no band numbers), taxon = SULNEB, period = year 1..23 (1991..2013, in
#   __periods), y = 0/1 resighted as a breeder. unit_sex = M/F from the group columns. No
#   occasion (one annual resighting season). Rows before first resighting are kept as 0
#   (the authors fit Pradel models, which use them). surveyEvidence = deposited_matrix: the
#   fixed study area was monitored every year 1991-2013 (Dryad file description).
#   Coordinates: none per bird; the island is at 21.87 N, 105.9 W (Dryad location field), in
#   geographicCoverage only. Sula nebouxii is IUCN LC; nothing to coarsen.
#   Not shipped: nothing in the deposit is left out.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ancona_2016_isabel_booby_cjs"
dir <- download_dryad("doi:10.5061/dryad.h0qp0", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "Capture_recapture_histories_of_adult_boobies_resighted_every_year_from_1991_to_2013.txt")
stopifnot(identical(list.files(dir), basename(f)))

lines <- trimws(sub("\r$", "", readLines(f, warn = FALSE)))
lines <- lines[nzchar(lines)]
m <- regmatches(lines, regexec("^([01]{23}) ([01]) ([01]);$", lines))
stopifnot(length(lines) == 4608, all(lengths(m) == 4))
inp <- data.table(ch = sapply(m, `[`, 2), male = as.integer(sapply(m, `[`, 3)), female = as.integer(sapply(m, `[`, 4)))
stopifnot(all(inp$male + inp$female == 1L), sum(inp$male) == 2391, sum(inp$female) == 2217,
          all(grepl("1", inp$ch)))
years <- 1991:2013; Tn <- length(years)
CH <- do.call(rbind, lapply(strsplit(inp$ch, ""), as.integer)); stopifnot(dim(CH) == c(4608, Tn))
stopifnot(colSums(CH)[1:2] == c(10, 1), colSums(CH)[13] == 42)

ids <- sprintf("BFBO%04d", seq_len(nrow(inp)))
long <- array_to_eco(CH, taxon = "SULNEB", site_ids = ids,
                     site_covs = data.frame(sex = ifelse(inp$male == 1L, "M", "F")), period = seq_len(Tn))
long[, occasion := NULL]
stopifnot(nrow(long) == 4608 * Tn, sum(long$y) == sum(CH))

taxa <- make_taxa("SULNEB", "Sula nebouxii", vernacularName = "Blue-footed Booby", taxon_iucnCategory = "LC")
periods <- data.table(period = seq_len(Tn), year = years, season = "February-March breeding-season monitoring")
dataset <- list(
  title = "Annual resighting histories of 4,608 breeding blue-footed boobies, Isla Isabel, Mexico, 1991-2013",
  creator = "Ancona, Sergio; Drummond, Hugh; Rodriguez, Cristina; Zuniga-Vega, Jose Jaime",
  pubDate = "2016", doi = "10.5061/dryad.h0qp0", sourceURL = "https://doi.org/10.5061/dryad.h0qp0",
  citation = "Ancona, S., Drummond, H., Rodriguez, C., & Zuniga-Vega, J. J. (2016). Data from: Long-term population dynamics reveal that survival and recruitment of tropical boobies improve after a hurricane. Dryad. https://doi.org/10.5061/dryad.h0qp0",
  paperDOI = "10.1111/jav.01133",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Capture-recapture histories of 4,608 banded blue-footed boobies resighted as breeders in a fixed 26,889 m2 study area on Isla Isabel, Mexico, every February-March from 1991 to 2013, with sex. The authors fit Pradel models of adult survival, local recruitment and population growth, and tested the effect of a hurricane.",
  samplingProtocol = "Resighting of banded breeding adults during systematic monitoring of a fixed study area in February and March of each breeding season; one annual occasion per bird.",
  samplingProtocolCode = "tag_resight", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "period (one annual occasion; survival and recruitment between years)",
  geographicCoverage = "Isla Isabel, Nayarit, Mexico (21.87 N, 105.9 W; one fixed study area, no per-bird coordinates)",
  temporalCoverage = "1991/2013", coordinatesCoarsened = NA,
  notes = "unit ids are line numbers in the deposit (no band numbers were deposited). Only 10 birds are resighted in 1991 and 1 in 1992, as deposited.",
  notShipped = list())
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/ancona_2016_isabel_booby_cjs.R")

stage_dict_row(TABLE,
  description = "Annual resighting histories (CJS / Pradel) of 4,608 breeding blue-footed boobies (Sula nebouxii) with sex, Isla Isabel, Mexico, 1991-2013 (Ancona et al. 2017).",
  url = "https://doi.org/10.5061/dryad.h0qp0",
  reference = "Ancona, S., Zuniga-Vega, J. J., Rodriguez, C., & Drummond, H. (2017). Long-term population dynamics reveal that survival and recruitment of tropical boobies improve after a hurricane. Journal of Avian Biology 48(2), 320-332.",
  doi_paper = "10.1111/jav.01133", doi_data = "10.5061/dryad.h0qp0",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip (version 9171), one MARK-format file; sex from the two group columns (1 0 male, 0 1 female, per the Dryad file description). No band numbers: unit = line number.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
  sampling_protocol = "tag_resight", design = "Multi-session (23 annual primary periods, no secondary)", realm = "Marine",
  country = "MEX", coordinates = "None in source",
  notes = "Individuals as unit (synthetic ids); rows before first resighting kept as 0 for Pradel models.")
