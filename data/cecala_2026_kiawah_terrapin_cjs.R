#!/usr/bin/env Rscript
# Table:  cecala_2026_kiawah_terrapin_cjs
# Source: Dryad doi:10.5061/dryad.31zcrjf36 (CC0 1.0 as shown on the dataset JSON), version
#   466611 (published 2026-09-30). Cecala, K. Long-term diamondback terrapin capture-recapture
#   data from Kiawah Island, South Carolina (1983-2012).
# Paper:  none named as primary; the deposit lists four related articles that used earlier
#         years of the series (doi:10.2307/3545132, 10.1139/z01-185,
#         10.1016/j.biocon.2007.02.014, 10.2744/CCB-1090.1).
# Data:   one xlsx, one sheet, 3,422 capture records: ID (notch code), Capture (running
#         count of captures of that ID), Month, Day, Year, Location (Site 1-9 on the Kiawah
#         River), MOC (method: Seine, Trammel Net, Crab Trap, Hand, Dip Net, Cast Net,
#         Radiotrans, Not Recorded), Sex, plastron/carapace/width/depth (mm), Mass (g), AGE
#         (annuli), Reliability, EGGS (palpation count). 1,553 marked IDs plus 31 records of
#         unmarked animals (ID "UNMKD"). Records exist for 1983-1999 and 2002-2012; none for
#         2000-2001. Five cells hold text in numeric columns (">1", ">3", "?", "13"); read as
#         text, only Year and ID are used for y.
#
# Mapping (standard section 3.4, CJS): unit = terrapin ID, taxon = MALTER, period = sampling
#   year (index over the 28 years with records; calendar year in __periods), y = 1 if the
#   terrapin was captured at least once that year, else 0. No `occasion` (captures within a
#   season are pooled to the year, the CJS time step of the related papers).
#   Survey evidence: inferred. The README says the population "has been monitored annually
#   since 1983"; a year with at least one capture record is a surveyed year, and 2000-2001
#   (no records at all) are treated as not surveyed, so they have no rows. Rows before first
#   capture are kept as 0 (E4).
#   Excluded from y: 15 radio-telemetry relocations (MOC "Radiotrans", 1992; a relocation of a
#   tagged animal is not a capture) and the 31 UNMKD records (no identity). Crab-trap records
#   (43, often drowned bycatch per the abstract; no fate column) are kept as captures and
#   counted in obs_n_crabtrap so a user can censor them.
#   unit_sex = modal recorded sex (one ID, IJNP, is recorded M then F: set to "U");
#   unit_first_site = location of first capture. obs_n_captures = capture records that year
#   (0 on non-capture rows). Malaclemys terrapin is IUCN Vulnerable; the deposit has site
#   labels only, no coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "cecala_2026_kiawah_terrapin_cjs"
dir <- download_dryad("10.5061/dryad.31zcrjf36", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "Terrapin_Database_-_Kiawah_River_-_1983-2012_-_Dryad_-_Revised.xlsx")
stopifnot(file.exists(f), identical(excel_sheets(f), "Sheet1"))
x <- as.data.table(suppressWarnings(read_excel(f, col_types = "text")))
stopifnot(nrow(x) == 3422L, identical(names(x), c("ID", "Capture", "Month", "Day", "Year", "Location", "MOC", "Sex",
  "Plastron", "Carapace", "Width", "Depth", "Mass", "AGE", "Reliability", "EGGS")))
stopifnot(!anyNA(x$ID), !anyNA(x$Year), all(grepl("^[A-Z]+[0-9]*$", x$ID)))
x[, Year := as.integer(Year)]
yrs <- sort(unique(x$Year))
stopifnot(identical(yrs, c(1983:1999, 2002:2012)))
stopifnot(setequal(unique(x$MOC), c("Seine", "seine", "Trammel Net", "Crab Trap", "Hand", "Dip Net", "Cast Net",
                                    "Radiotrans", "Not Recorded")))
stopifnot(sum(x$ID == "UNMKD") == 31L, sum(x$MOC == "Radiotrans") == 15L, sum(x$MOC == "Crab Trap") == 43L)

cap <- x[ID != "UNMKD" & MOC != "Radiotrans"]
n_ids <- uniqueN(cap$ID)
stopifnot(n_ids == 1553L)
Tn <- length(yrs)
cap[, period := match(Year, yrs)]
yr <- cap[, .(n = .N, n_crab = sum(MOC == "Crab Trap")), by = .(ID, period)]
ids <- sort(unique(cap$ID))
CH <- matrix(0L, length(ids), Tn); CH[cbind(match(yr$ID, ids), yr$period)] <- 1L
NC <- matrix(0L, length(ids), Tn); NC[cbind(match(yr$ID, ids), yr$period)] <- yr$n
NK <- matrix(0L, length(ids), Tn); NK[cbind(match(yr$ID, ids), yr$period)] <- yr$n_crab

sx <- cap[!is.na(Sex), .(sex = if (uniqueN(Sex) == 1L) Sex[1] else "U"), by = ID]
stopifnot(sum(cap[!is.na(Sex), uniqueN(Sex), by = ID]$V1 > 1L) == 1L)
first <- cap[order(Year, as.integer(Month), suppressWarnings(as.integer(Day)))][, .(site = Location[1]), by = ID]
covs <- data.frame(unit_sex = sx$sex[match(ids, sx$ID)], unit_first_site = first$site[match(ids, first$ID)])
covs$unit_sex[covs$unit_sex == "Unk"] <- "U"
stopifnot(!anyNA(covs$unit_first_site))

long <- array_to_eco(CH, taxon = "MALTER", site_ids = ids, site_covs = covs, period = seq_len(Tn))
long[, occasion := NULL]
long[, obs_n_captures := NC[cbind(match(unit, ids), period)]]
long[, obs_n_crabtrap := NK[cbind(match(unit, ids), period)]]
stopifnot(nrow(long) == length(ids) * Tn, sum(long$y) == nrow(yr), sum(long$obs_n_captures) == nrow(cap))
cat(sprintf("  %d terrapins, %d capture records -> %d terrapin-years captured over %d years\n",
            length(ids), nrow(cap), nrow(yr), Tn))

taxa <- make_taxa("MALTER", "Malaclemys terrapin", vernacularName = "Diamondback Terrapin")
periods <- cap[, .(n_records = .N, n_terrapins = uniqueN(ID)), by = .(period, year = Year)][order(period)]
periods[, note := "active-season sampling year; captures pooled to the year"]

dataset <- list(
  title = "Annual capture histories of 1,553 diamondback terrapins, Kiawah River, South Carolina, 1983-2012",
  creator = "Cecala, Kristen", pubDate = "2026", doi = "10.5061/dryad.31zcrjf36",
  sourceURL = "https://doi.org/10.5061/dryad.31zcrjf36",
  citation = "Cecala, K. (2026). Long-term diamondback terrapin capture-recapture data from Kiawah Island, South Carolina (1983-2012) [Dataset]. Dryad. https://doi.org/10.5061/dryad.31zcrjf36",
  paperDOI = NA,
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Capture-mark-recapture records of diamondback terrapins (Malaclemys terrapin) on the Kiawah River, South Carolina, 1983-2012, from seines, trammel nets, cast and dip nets, hand captures and crab-pot recoveries, with morphometrics, age from annuli and egg counts. Here pooled to annual capture histories of the 1,553 marked terrapins.",
  samplingProtocol = "Active-season seining and trammel netting with hand, dip-net and cast-net captures at nine sites on the Kiawah River; individuals notch-marked; crab-pot recoveries recorded.",
  samplingProtocolCode = "net_capture", surveyEvidence = "inferred",
  surveyEvidenceNote = "A year with at least one capture record is a sampling year (README: monitored annually since 1983). No records exist for 2000 and 2001, which are treated as not surveyed and have no rows; if they were surveyed with no captures, that information is not in the deposit.",
  responseType = "detection", unitKind = "individual",
  closure = "period (captures within a season pooled to the year; survival between years)",
  lossesOnCapture = "not coded in the deposit; crab-trap records (often drowned bycatch) counted in obs_n_crabtrap",
  geographicCoverage = "Kiawah River, Kiawah Island, South Carolina, USA (nine site labels, no coordinates)",
  temporalCoverage = "1983/2012", coordinatesCoarsened = NA,
  notShipped = list(radiotelemetry = "15 relocations of radio-tagged terrapins in 1992 (MOC Radiotrans), not captures",
                    unmarked = "31 records of unmarked terrapins (ID UNMKD)",
                    morphometrics = "plastron, carapace, width, depth, mass, age, egg counts per capture (vary within individual; not covariates of the yearly detection)"),
  notes = "Rows before first capture kept as 0 (E4). The sampling years are 1983-1999 and 2002-2012 (28 periods); period indices are consecutive over sampled years, use __periods$year for intervals. One ID (IJNP) recorded as male then female: unit_sex = U.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/cecala_2026_kiawah_terrapin_cjs.R")

stage_dict_row(TABLE,
  description = "Annual capture histories of 1,553 marked diamondback terrapins (Malaclemys terrapin) on the Kiawah River, South Carolina, across 28 sampling years 1983-2012, pooled from 3,376 seine, net, hand and crab-pot captures; sex, first site, captures per year and crab-pot captures per year.",
  url = "https://doi.org/10.5061/dryad.31zcrjf36",
  reference = "Cecala, K. (2026). Long-term diamondback terrapin capture-recapture data from Kiawah Island, South Carolina (1983-2012). Dryad.",
  doi_paper = "", doi_data = "10.5061/dryad.31zcrjf36",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Survey years inferred from capture records (2000-2001 have none). Radio relocations and unmarked animals excluded. IUCN VU species; no coordinates in source.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "CJS capture-recapture",
  sampling_protocol = "net_capture", design = "Multi-session (28 sampling years)", realm = "Marine",
  country = "USA", coordinates = "None in source", notes = "Individuals as unit; estuarine turtle; captures pooled to the year.")
