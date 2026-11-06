#!/usr/bin/env Rscript
# Table:  pakanen_2020_dunlin_ms  (southern dunlin, multi-state capture-resight histories by
#         geolocator status, Finland, 2002-2018)
# Source: Dryad doi:10.5061/dryad.6m905qfxp (CC0 1.0), version 79046 (published 2020-08-21).
#   Pakanen, V.-M., Rönkä, N., Thomson, R. L., Blomqvist, D. & Koivula, K. (2020). Survival
#   probability in a small shorebird decreases with the time an individual carries a tracking
#   device. Dryad.
# Paper:  Pakanen, V.-M., Rönkä, N., Thomson, R. L., Blomqvist, D. & Koivula, K. (2020). Survival
#         probability in a small shorebird decreases with the time an individual carries a
#         tracking device. Journal of Avian Biology 51(10), e02555. doi:10.1111/jav.02555
#         (title checked on Crossref; not read). Dryad abstract: colour-ringed breeding adults of
#         a closely monitored southern dunlin (Calidris alpina schinzii) population in Finland,
#         2002-2018; "recapture" includes resightings of colour-ringed birds.
# Data:   DATA_for_JAV02555.xls, one sheet "DATA": a MARK input laid out in a spreadsheet. Row 1
#         legend: "A = bird has no geolocator, B: bird is carrying a geolocator, C = geolocator
#         has been removed", SEX, "(-1 are removals due to being killed under nest protective
#         cages)", GEOC2 / quadratic GEOC2 / GEOC1 and time-since-marking covariate legends. Row 3
#         header: 2002..2018 (17 encounter columns, 0/A/B/C), an empty column, MALES, FEMALES
#         (MARK group frequencies: 1, or -1 for a bird removed after its last encounter), then
#         34 individual covariate columns by year, and ";" (MARK row terminator). 337 birds
#         (the Dryad abstract says 338); 169 females and 161 males with frequency 1, 4 males and
#         3 females with -1, all last encountered in 2009. No ring ids, coordinates or dates.
# Mapping (standard E1-E5; E9 multi-state capture-recapture): unit = bird D001..D337 (row order
#   of the sheet), taxon = CALALPSCH (Calidris alpina schinzii), period = year 1..17 (2002-2018,
#   __periods), no occasion, y = state code 0 not encountered, 1 encountered without a geolocator
#   (A), 2 encountered carrying a geolocator (B), 3 encountered after its geolocator was removed
#   (C); y_raw = the letter ("0" where not encountered). Rows: every bird from 2002 (adults
#   caught in the wild, standard E4.4) to 2018, except the seven birds killed under nest cages,
#   whose rows end at their last encounter (2009) with obs_removed = 1. unit_sex from the
#   MALES / FEMALES columns. Survey evidence = deposited_matrix (the encounter history).
#   NOT shipped: the 34 GEOC2, GEOC2 squared, GEOC1 and time-since-marking covariate columns
#   (design covariates the authors computed from the A/B/C histories; recoverable from y_raw).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "pakanen_2020_dunlin_ms"
SCRIPT <- "data/pakanen_2020_dunlin_ms.R"
dir <- download_dryad("10.5061/dryad.6m905qfxp", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(list.files(dir), "DATA_for_JAV02555.xls"))
f <- file.path(dir, "DATA_for_JAV02555.xls")
stopifnot(identical(excel_sheets(f), "DATA"))
x <- as.data.table(suppressMessages(read_excel(f, "DATA", col_names = FALSE, col_types = "text")))
stopifnot(grepl("^Capture-recapture data; A = bird has no", x[[1]][1]),
          identical(unname(unlist(x[3, 1:17])), as.character(2002:2018)),
          identical(unname(unlist(x[3, 19:20])), c("MALES", "FEMALES")), ncol(x) == 55)
d <- x[4:.N]
H <- as.matrix(d[, 1:17]); m <- as.integer(d[[19]]); fe <- as.integer(d[[20]])
stopifnot(nrow(d) == 337, all(H %in% c("0", "A", "B", "C")), all(d[[55]] == ";"), all(is.na(d[[18]])),
          all(rowSums(H != "0") > 0),
          all((m == 0) != (fe == 0)), all(m %in% c(-1L, 0L, 1L)), all(fe %in% c(-1L, 0L, 1L)),
          sum(m == 1) == 161, sum(fe == 1) == 169, sum(m == -1) == 4, sum(fe == -1) == 3,
          sum(H == "A") == 926, sum(H == "B") == 72, sum(H == "C") == 61)
removed <- which(m == -1 | fe == -1)
last <- apply(H != "0", 1, function(v) max(which(v)))
stopifnot(all(last[removed] == 8L))                      # all seven removals in 2009
# no state goes backwards: A -> B -> C only
seq_ok <- apply(H, 1, function(v) { s <- match(v[v != "0"], c("A", "B", "C")); all(diff(s) >= 0) })
stopifnot(all(seq_ok))

long <- data.table(unit = sprintf("D%03d", rep(seq_len(nrow(H)), times = 17)), period = rep(1:17, each = nrow(H)),
                   y_raw = as.vector(H), row = rep(seq_len(nrow(H)), times = 17))
long[, `:=`(last = last[row], rem = row %in% removed)]
long <- long[!(rem & period > last)]
long[, obs_removed := as.integer(rem & period == last)]
long <- long[, .(unit, taxon = "CALALPSCH", y = match(y_raw, c("0", "A", "B", "C")) - 1L, y_raw, period,
                 unit_sex = ifelse(m[row] != 0, "male", "female"), obs_removed)]
long <- order_eco(long)
stopifnot(nrow(long) == 337 * 17 - 7 * 9, sum(long$obs_removed) == 7, sum(long$y > 0) == 926 + 72 + 61)

periods <- data.table(period = 1:17, year = 2002:2018,
                      n_encountered = long[y > 0, .N, by = period][order(period), N])
taxa <- make_taxa("CALALPSCH", "Calidris alpina schinzii", vernacularName = "Southern dunlin", taxonRank = "subspecies")

dataset <- list(
  title = "Southern dunlin multi-state capture-resight histories by geolocator status, 337 colour-ringed breeding adults, Finland, 2002-2018",
  creator = "Pakanen, Veli-Matti; Rönkä, Nelli; Thomson, Robert L.; Blomqvist, Donald; Koivula, Kari",
  pubDate = "2020", doi = "10.5061/dryad.6m905qfxp", sourceURL = "https://doi.org/10.5061/dryad.6m905qfxp",
  paperDOI = "10.1111/jav.02555",
  citation = "Pakanen, V.-M., Rönkä, N., Thomson, R. L., Blomqvist, D., & Koivula, K. (2020). Survival probability in a small shorebird decreases with the time an individual carries a tracking device [Data set]. Dryad. https://doi.org/10.5061/dryad.6m905qfxp",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Annual capture and resighting histories of colour-ringed breeding adult southern dunlins (Calidris alpina schinzii) in a closely monitored Finnish population, 2002-2018, used to test whether apparent survival falls with the number of years a bird carries a geolocator. Each encounter is coded by the bird's geolocator status: A without a geolocator, B carrying one, C after it was removed. Seven birds were killed under nest protective cages in 2009 and leave the study then (obs_removed).",
  samplingProtocol = "Breeding adults captured and colour-ringed, some fitted with leg-mounted geolocators that were later removed on recapture; each breeding season the population is searched and birds are recaptured or resighted by their colour rings (field methods in Pakanen et al. 2011-2020).",
  samplingProtocolCode = "live_trap", responseType = "state", unitKind = "individual",
  stateCodes = list(`0` = "not encountered", `1` = "encountered, no geolocator (A)", `2` = "encountered, carrying a geolocator (B)", `3` = "encountered, geolocator removed (C)"),
  closure = "none", closureNote = "one encounter per breeding season; open between years (CJS / multi-state)", occasionKind = "none",
  taxonInclusion = "single", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The deposited MARK history has one column per breeding season 2002-2018; every bird is surveyed in every season from 2002 (wild-caught adults, E4.4), including seasons before its first encounter (y = 0), until 2018 or its removal.",
  temporalCoverage = "2002/2018",
  geographicCoverage = "One breeding population of the southern dunlin in Finland (the deposit names no site; no coordinates deposited)",
  notShipped = list(design_covariates = "34 columns of GEOC2, GEOC2 squared, GEOC1 and time-since-marking covariates by year: computed by the authors from the A/B/C histories, recoverable from y_raw"),
  notes = "No ring ids in the deposit: units are sheet rows. The Dryad abstract says 338 birds; the sheet has 337. Rows before a bird's first encounter are y = 0 (drop them to condition on first capture, as MARK does). States only move A -> B -> C (asserted).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Multi-state capture-resight histories (0 not seen; seen without, carrying, or after removal of a geolocator) of 337 colour-ringed breeding adult southern dunlins in Finland, 2002-2018, with sex and seven nest-cage removals.",
  url = "https://doi.org/10.5061/dryad.6m905qfxp",
  reference = "Pakanen, V.-M., Rönkä, N., Thomson, R. L., Blomqvist, D., & Koivula, K. (2020). Survival probability in a small shorebird decreases with the time an individual carries a tracking device. Journal of Avian Biology, 51(10), e02555.",
  doi_paper = "10.1111/jav.02555", doi_data = "10.5061/dryad.6m905qfxp",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "MARK input in an xls sheet; state = geolocator status at encounter; authors' derived design covariates not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state CJS capture-recapture (tag status: geolocator effects on survival)",
  sampling_protocol = "live_trap", design = "Multi-session (17 breeding seasons)", realm = "Terrestrial",
  country = "FIN", coordinates = "None in source",
  notes = "Individuals as unit; full rectangle from 2002; state = geolocator status; removals flagged.")
