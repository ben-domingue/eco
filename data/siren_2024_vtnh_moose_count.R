#!/usr/bin/env Rscript
# Table:  siren_2024_vtnh_moose_count  (moose calves and adult cows, monthly maximum counts on
#         225 camera sites, May-August 2014-2019, Vermont and New Hampshire; open multistate
#         N-mixture / Dail-Madsen data)
# Source: Dryad doi:10.5061/dryad.tqjq2bw76 (CC0 1.0), version 328132 (published 2024-11-12).
#   Siren, A., Kilborn, J., Bernier, C., Patry, R., Cliche, R., Prout, L., Gifford, S.,
#   Callahan, C. & Wixsom, S. (2024). Monitoring animal populations with cameras using open,
#   multistate, N-mixture models [Data set]. Dryad.
#   The README asks that parties reusing the moose data contact the authors to discuss
#   collaboration; that is a request, not a term of the CC0 dedication, and is repeated in notes.
# Paper:  Sirén, A. P. K., et al. (2024). Monitoring animal populations with cameras using open,
#         multistate, N-mixture models. Ecology and Evolution 14(12), e70583.
#         doi:10.1002/ece3.70583 (open access; read from Europe PMC, PMC11638134).
# Data:   README.md; moose_data.rds, a 257 x 6 x 2 x 4 numeric array: camera site index 1..257
#         (225 used; the README says "n = 225 [indexed as 257]"), year 2014..2019, state
#         Juveniles / Adults, monthly survey May..Aug. Values 0, 1, 2; NA = no survey (battery
#         failure, malfunction, staggered entry: paper section 3.2). Paper 2.3: "we only
#         considered the maximum number of calves and adult cows detected within pictures at a
#         site during a monthly survey occasion"; populations assumed closed within the
#         May-August season. Paper 3.2: 568 adult-female and 192 juvenile monthly detections
#         (the sums of the counts), >1 animal in a month 2 and 7 times. moose_data_bulls.rds,
#         same shape and labels; its Juveniles slice is identical to the main file's and its
#         Adults slice is greater or equal cell by cell (585 vs 568), but the README describes
#         it as counts of bulls and cows, which its two-state layout does not show; the authors
#         did not analyse it. No coordinates, site names or covariates are deposited.
# Mapping (standard E1-E5): unit = camera site S001..S257 (the deposited index; 32 indices with
#   no survey have no rows), taxon = species x stage (E6): ALCALC_J (calves, lifeStage juvenile)
#   and ALCALC_A (adult cows, lifeStage adult; bulls not counted, taxonRemarks), period = year
#   1..6 (2014..2019, __periods), occasion = month 1..4 (May..August), y = the monthly maximum
#   count in one picture. Survey evidence = deposited_matrix: NA cells (no survey) are missing
#   rows, and the NA pattern is identical for the two stages (asserted).
#   NOT shipped: moose_data_bulls.rds (its layout does not match its README description; not
#   analysed), the authors' simulation and model outputs.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "siren_2024_vtnh_moose_count"
SCRIPT <- "data/siren_2024_vtnh_moose_count.R"
dir <- download_dryad("10.5061/dryad.tqjq2bw76", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          setequal(list.files(dir), c("README.md", "moose_data.rds", "moose_data_bulls.rds")))
x <- readRDS(file.path(dir, "moose_data.rds"))
dn <- dimnames(x)
stopifnot(identical(dim(x), c(257L, 6L, 2L, 4L)), identical(dn[[1]], as.character(1:257)),
          identical(dn[[2]], as.character(2014:2019)), identical(dn[[3]], c("Juveniles", "Adults")),
          identical(dn[[4]], c("May", "Jun", "Jul", "Aug")),
          all(x %in% c(0, 1, 2, NA)),
          identical(is.na(x[, , 1, ]), is.na(x[, , 2, ])),              # one survey set for both stages
          sum(apply(x, 1, function(a) any(!is.na(a)))) == 225,         # README: 225 sites
          sum(x[, , "Adults", ], na.rm = TRUE) == 568, sum(x[, , "Juveniles", ], na.rm = TRUE) == 192,   # paper 3.2
          sum(x[, , "Adults", ] > 1, na.rm = TRUE) == 2, sum(x[, , "Juveniles", ] > 1, na.rm = TRUE) == 7)
b <- readRDS(file.path(dir, "moose_data_bulls.rds"))
stopifnot(identical(b[, , 1, ], x[, , 1, ]), all(b[, , 2, ] >= x[, , 2, ], na.rm = TRUE))   # what notShipped says

long <- as.data.table(as.data.frame.table(x, responseName = "y", stringsAsFactors = FALSE))
setnames(long, c("site", "year", "state", "month", "y"))
long <- long[!is.na(y)]
long <- long[, .(unit = sprintf("S%03d", as.integer(site)), taxon = c(Juveniles = "ALCALC_J", Adults = "ALCALC_A")[state],
                 y = as.integer(y), period = as.integer(year) - 2013L, occasion = match(month, dn[[4]]))]
long <- order_eco(long)
stopifnot(nrow(long) == 2 * sum(!is.na(x[, , 1, ])), nrow(long) == 4400, uniqueN(long$unit) == 225,
          long[, .N, by = .(unit, period, occasion)][, all(N == 2)])

taxa <- make_taxa(c("ALCALC_A", "ALCALC_J"), c("Alces alces", "Alces alces"),
                  vernacularName = c("moose (adult cow)", "moose (calf)"),
                  lifeStage = c("adult", "juvenile"),
                  taxonRemarks = c("Adult females (cows) only: the array's Adults state counts cows; bulls were not counted in it.",
                                   "Calves of the year."))
periods <- data.table(period = 1:6, year = 2014:2019, start = sprintf("%d-05-01", 2014:2019), end = sprintf("%d-08-31", 2014:2019))

dataset <- list(
  title = "Moose calves and adult cows: monthly maximum counts at 225 camera sites, May-August 2014-2019, Vermont and New Hampshire",
  creator = "Siren, Alexej; Kilborn, Jillian; Bernier, Chris; Patry, Riley; Cliche, Rachel; Prout, Leighlan; Gifford, Suzanne; Callahan, Catherine; Wixsom, Scott",
  pubDate = "2024", doi = "10.5061/dryad.tqjq2bw76",
  sourceURL = "https://doi.org/10.5061/dryad.tqjq2bw76", paperDOI = "10.1002/ece3.70583",
  citation = "Siren, A., Kilborn, J., Bernier, C., Patry, R., Cliche, R., Prout, L., Gifford, S., Callahan, C., & Wixsom, S. (2024). Monitoring animal populations with cameras using open, multistate, N-mixture models [Data set]. Dryad. https://doi.org/10.5061/dryad.tqjq2bw76",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera traps at 225 sites across Vermont and New Hampshire recorded moose from 2014 to 2019. For each site, year and summer month (May-August) the authors recorded the maximum number of calves and of adult cows seen together in one picture, to avoid double counting, and analysed the counts with an open, multistate (calf, adult) Dail-Madsen N-mixture model to estimate abundance, apparent survival and recruitment. About half of the site-months were not surveyed (battery failure, malfunction, staggered entry of cameras); those cells have no rows.",
  samplingProtocol = "Remote cameras at independent locations (not randomised; for example along game trails) operated across years; each May-August month is a survey occasion, and the response is the maximum number of calves and of adult cows detected within one picture at the site in that month.",
  samplingProtocolCode = "camera_trap", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "the authors assumed closure across the four monthly occasions of a May-August season; the population is open between years (Dail-Madsen)",
  occasionKind = "time", taxonInclusion = "target", surveyEvidence = "deposited_matrix",
  temporalCoverage = "2014-05/2019-08",
  geographicCoverage = "Vermont and New Hampshire, USA (no coordinates deposited)",
  notShipped = list(bulls_file = "moose_data_bulls.rds: README describes counts of bulls and cows, but the array has the same two states as the main file (Juveniles identical; Adults greater or equal); not analysed by the authors",
                    model_outputs = "abundance, survival and recruitment estimates and the simulation study"),
  notes = "taxon is species x life stage (E6): ALCALC_J calves, ALCALC_A adult cows. Site indices are the deposit's (1..257, 225 used). The README asks those reusing the moose data to contact the authors to discuss collaboration (a request; the deposit is CC0).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Monthly maximum counts of moose calves and adult cows on 225 camera sites in Vermont and New Hampshire, May-August 2014-2019 (4,400 site-month-stage rows), the authors' open multistate N-mixture (Dail-Madsen) input.",
  url = "https://doi.org/10.5061/dryad.tqjq2bw76",
  reference = "Sirén, A. P. K., Hallworth, M. T., Kilborn, J. R., et al. (2024). Monitoring animal populations with cameras using open, multistate, N-mixture models. Ecology and Evolution, 14(12), e70583.",
  doi_paper = "10.1002/ece3.70583", doi_data = "10.5061/dryad.tqjq2bw76",
  original_license = "CC0 1.0 (README requests contact before reuse)", derived_license = "CC0 1.0",
  notes = "taxon = species x life stage. No coordinates or covariates deposited. The bulls array is not shipped (layout does not match its README).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "N-mixture (open, multistate: calf and adult; Dail-Madsen)",
  sampling_protocol = "Camera trap", design = "Multi-season (6 years x 4 monthly occasions)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source",
  notes = "Stage-structured counts as species x stage taxa; monthly maximum count in one picture.")
