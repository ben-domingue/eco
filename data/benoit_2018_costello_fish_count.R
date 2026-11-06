#!/usr/bin/env Rscript
# Table:  benoit_2018_costello_fish_count
# Source: Dryad doi:10.5061/dryad.ft71172 (source of record), CC0 1.0, fetched from its Zenodo mirror (record 4973445,
#         which carries the Dryad DOI; licence id "cc-zero", asserted). No request was made to Dryad.
#   Benoit, D. M., Jackson, D. A. & Ridgway, M. S. (2018). Data from: Assessing the impacts of imperfect detection on
#   estimates of diversity and community structure through multispecies occupancy modeling [Dataset]. Dryad.
# Paper:  Benoit, D. M., Jackson, D. A. & Ridgway, M. S. (2018). Assessing the impacts of imperfect detection on
#         estimates of diversity and community structure through multispecies occupancy modeling. Ecology and
#         Evolution 8, 4676-4684. doi:10.1002/ece3.4023 (open access; not needed to parse the deposit). Stream fish of
#         Costello Creek, Algonquin Provincial Park, Ontario, sampled with minnow traps.
# Data:   Costello_Species_2009.xls (14 sheets) and Costello_Species_2015.xlsx (13 sheets), one sheet per fish species
#         caught. Each sheet has six blocks headed "Day 1", "Day 2", "Day 3" (twice: traps A01-A18, then B01-B18),
#         each block one row per trap: Trap No., (2009 only: Water Temp.), Habitat, Substrate type, Presence/Absence,
#         Total Catch. Presence/Absence is Total Catch > 0 except one cell (2009 Pumpkinseed, A14, day 3: 0 with a
#         catch of 1; the catch is shipped). The 2009 file has an "Abundance" summary per
#         trap (the sum over days; not shipped) and, on its first sheet, a table of block dates (A Day 1-3:
#         Excel serials 39644-39646, B Day 1-3: 39648-39650, i.e. 15-17 and 19-21 July 2008 although the file is
#         labelled 2009; dates are therefore not shipped). The 2009 White Sucker sheet has 'jymnujymnu' in place of trap
#         B12 in its last block (a keyboard slip; read as B12, asserted). The 2015 Creek Chub sheet labels its last block "Day 2"
#         (a typo for Day 3; blocks are taken in order). Species: 2009 Brown Bullhead, Creek Chub, White Sucker,
#         Golden Shiner, Finescale Dace, Common Shiner, Pumpkinseed, Brook Trout, Pearl Dace, SMB (smallmouth bass),
#         Brook Stickleback, Brassy Minnow, Red Bellied Dace, Yellow Perch; 2015 the same without Finescale Dace
#         (Bullhead = brown bullhead, Northern redbelly dace = red bellied dace).
# Mapping (repeated counts, community): unit = trap (A01-B18; the same trap ids and habitat descriptions in both
#   files), period = file year (1 = 2009, 2 = 2015), occasion = day 1-3 of the trap's block, taxon = species code,
#   y = Total Catch. The deposit has a sheet only for species caught in a year, so whether an uncaught species was
#   looked for is not recorded: __survey_taxa lists, per period, the species with a sheet (Finescale Dace only in
#   2009), and no zeros are invented for it in 2015 (E4.2). unit_grid (A or B), unit_habitat and unit_substrate (the
#   2009 descriptions), obs_water_temp_c (2009, where recorded). surveyEvidence = deposited_matrix.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "benoit_2018_costello_fish_count"
REC <- "4973445"
zen <- function(key) download_cached(sprintf("https://zenodo.org/api/records/%s/files/%s/content", REC, URLencode(key, reserved = TRUE)), TABLE, filename = key)
meta_f <- file.path(RAW_DIR, TABLE, "zenodo_record.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file(paste0("https://zenodo.org/api/records/", REC), meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)
stopifnot(identical(meta$metadata$license$id, "cc-zero"), identical(meta$doi, "10.5061/dryad.ft71172"),
          setequal(meta$files$key, c("Costello_Species_2015.xlsx", "Costello_Species_2009.xls")))
files <- c(`1` = zen("Costello_Species_2009.xls"), `2` = zen("Costello_Species_2015.xlsx"))
spmap <- data.table(sheet = c("Brown Bullhead", "Bullhead", "Creek Chub", "White Sucker", "White sucker", "Golden Shiner", "Golden shiner",
                              "Finescale Dace", "Common Shiner", "Common shiner", "Pumpkinseed", "Brook Trout", "Brook trout", "Pearl Dace",
                              "Pearl dace", "SMB", "Smallmouth bass", "Brook Stickleback", "Brook stickleback", "Brassy Minnow", "Brassy minnow",
                              "Red Bellied Dace", "Northern redbelly dace", "Yellow Perch", "Yellow perch"),
                    taxon = c("AMENEB", "AMENEB", "SEMATR", "CATCOM", "CATCOM", "NOTCRY", "NOTCRY", "CHRNEO", "LUXCOR", "LUXCOR", "LEPGIB",
                              "SALFON", "SALFON", "MARMAR", "MARMAR", "MICDOL", "MICDOL", "CULINC", "CULINC", "HYBHAN", "HYBHAN",
                              "CHREOS", "CHREOS", "PERFLA", "PERFLA"))
sci <- data.table(taxon = c("AMENEB", "SEMATR", "CATCOM", "NOTCRY", "CHRNEO", "LUXCOR", "LEPGIB", "SALFON", "MARMAR", "MICDOL", "CULINC", "HYBHAN", "CHREOS", "PERFLA"),
                  sci = c("Ameiurus nebulosus", "Semotilus atromaculatus", "Catostomus commersonii", "Notemigonus crysoleucas", "Chrosomus neogaeus",
                          "Luxilus cornutus", "Lepomis gibbosus", "Salvelinus fontinalis", "Margariscus margarita", "Micropterus dolomieu",
                          "Culaea inconstans", "Hybognathus hankinsoni", "Chrosomus eos", "Perca flavescens"),
                  vern = c("Brown bullhead", "Creek chub", "White sucker", "Golden shiner", "Finescale dace", "Common shiner", "Pumpkinseed",
                           "Brook trout", "Pearl dace", "Smallmouth bass", "Brook stickleback", "Brassy minnow", "Northern redbelly dace", "Yellow perch"))
read_sheet <- function(f, s) {
  y <- as.data.frame(suppressMessages(readxl::read_excel(f, s, col_names = FALSE, col_types = "text")))
  h <- which(grepl("^Day [123]$", y[[1]]))
  stopifnot(length(h) == 6L)
  out <- list()
  for (b in seq_along(h)) {
    hdr <- trimws(unlist(y[h[b], ])); r <- h[b] + seq_len(18L)
    tn <- y[r, which(hdr == "Trap No.")]; want <- sprintf("%s%02d", if (b <= 3) "A" else "B", 1:18)
    if (s == "White Sucker" && b == 6L) { stopifnot(tn[12] == "jymnujymnu"); tn[12] <- "B12" }   # a keyboard slip in the 2009 file
    stopifnot(identical(tn, want))
    wt <- if ("Water Temp." %in% hdr) suppressWarnings(as.numeric(y[r, which(hdr == "Water Temp.")])) else NA_real_
    out[[b]] <- data.table(trap = tn, occasion = (b - 1L) %% 3L + 1L, pa = as.integer(y[r, which(hdr == "Presence/Absence")]),
                           catch = as.integer(y[r, which(hdr == "Total Catch")]), habitat = y[r, which(hdr == "Habitat")],
                           substrate = y[r, which(hdr == "Substrate type")], obs_water_temp_c = wt)
  }
  rbindlist(out)
}
L <- list(); st <- list()
for (per in names(files)) {
  f <- files[[per]]; sh <- readxl::excel_sheets(f)
  stopifnot(length(sh) == if (per == "1") 14L else 13L, all(sh %in% spmap$sheet))
  for (s in sh) {
    x <- read_sheet(f, s)
    stopifnot(nrow(x) == 108L, !anyNA(x$catch), all(x$catch >= 0L))
    mis <- x[pa != as.integer(catch > 0L)]   # one cell: 2009 Pumpkinseed A14 day 3, Presence/Absence 0 with Total Catch 1
    stopifnot(nrow(mis) == if (per == "1" && s == "Pumpkinseed") 1L else 0L)
    x[, `:=`(period = as.integer(per), taxon = spmap$taxon[match(s, spmap$sheet)])]
    L[[length(L) + 1L]] <- x
  }
  st[[per]] <- data.table(period = as.integer(per), taxon = spmap$taxon[match(sh, spmap$sheet)])
}
long <- rbindlist(L)
stopifnot(!anyDuplicated(long[, .(trap, taxon, period, occasion)]), uniqueN(long$taxon) == 14L)
hab <- unique(long[period == 1L, .(trap, habitat, substrate)])
stopifnot(!anyDuplicated(hab$trap), nrow(hab) == 36L)
# trap-level water temperature: recorded on some 2009 days only; it is an observation of the trap-day
wt <- long[period == 1L, .(obs_water_temp_c = { v <- unique(na.omit(obs_water_temp_c)); if (length(v) == 1L) v else if (!length(v)) NA_real_ else NA_real_ }), by = .(trap, occasion)]
long <- merge(long[, .(unit = trap, taxon, y = catch, period, occasion)], hab[, .(unit = trap, unit_habitat = habitat, unit_substrate = substrate)], by = "unit")
long[, unit_grid := substr(unit, 1, 1)]
long <- merge(long, wt[, .(unit = trap, occasion, period = 1L, obs_water_temp_c)], by = c("unit", "period", "occasion"), all.x = TRUE)
long <- order_eco(long)
survey_taxa <- rbindlist(st)
stopifnot(nrow(long) == 108L * (14L + 13L), survey_taxa[, .N, by = period][order(period), N] == c(14L, 13L),
          !"CHRNEO" %in% survey_taxa[period == 2L, taxon])
cat(sprintf("  %d rows, %d traps, %d taxa, fish caught %d\n", nrow(long), uniqueN(long$unit), uniqueN(long$taxon), sum(long$y)))
taxa <- make_taxa(sci$taxon, sci$sci, vernacularName = sci$vern)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[, .(taxon, scientificName, gbifMatchType, gbifAcceptedName, taxon_iucnCategory)])
periods <- data.table(period = 1:2, year = c(2009L, 2015L), file = c("Costello_Species_2009.xls", "Costello_Species_2015.xlsx"))
dataset <- list(
  title = "Minnow-trap catches of 14 stream fish species at 36 traps over three days, Costello Creek, Algonquin Provincial Park, Ontario, 2009 and 2015",
  creator = "Benoit, David M.; Jackson, Donald A.; Ridgway, Mark S.", pubDate = "2018",
  doi = "10.5061/dryad.ft71172", sourceURL = "https://doi.org/10.5061/dryad.ft71172",
  citation = "Benoit, D. M., Jackson, D. A., & Ridgway, M. S. (2018). Data from: Assessing the impacts of imperfect detection on estimates of diversity and community structure through multispecies occupancy modeling [Dataset]. Dryad. https://doi.org/10.5061/dryad.ft71172",
  paperDOI = "10.1002/ece3.4023",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Stream fish caught in minnow traps at 36 trap locations (two grids of 18) in Costello Creek, Algonquin Provincial Park, Ontario, each trap checked on three consecutive days, in two sampling years; per-trap per-day catch by species. The authors used the presence/absence form in multispecies occupancy models of the effect of imperfect detection on richness and community structure.",
  samplingProtocol = "Baited minnow traps at fixed locations along Costello Creek in two grids (A01-A18, B01-B18), each grid fished for three consecutive days; catch per trap per day counted by species.",
  samplingProtocolCode = "minnow_trap", surveyEvidence = "deposited_matrix",
  responseType = "count", unitKind = "site", closure = "closed",
  closureNote = "The three days of a grid's trapping are assumed closed; the two years are periods.",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Costello Creek, Algonquin Provincial Park, Ontario, Canada (no trap coordinates deposited)",
  temporalCoverage = "2009/2015",
  covariateNote = "unit_grid: trap grid A or B. unit_habitat, unit_substrate: the trap's habitat and substrate description (2009 file). obs_water_temp_c: water temperature at the trap-day where recorded (2009 only).",
  notShipped = list(abundance_summary = "the 2009 per-trap 'Abundance' (sum over days)",
                    dates = "block dates in the 2009 file are July 2008 although the file is labelled 2009; no dates in 2015",
                    presence_absence = "the Presence/Absence column (Total Catch > 0 except one cell, 2009 Pumpkinseed A14 day 3, where the catch of 1 is shipped)"),
  notes = "The deposit has a sheet only for species caught in a year: __survey_taxa lists them per period, so Finescale Dace has no 2015 rows. Year labels follow the file names.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, survey_taxa = survey_taxa, script = "data/benoit_2018_costello_fish_count.R")
stage_dict_row(TABLE,
  description = "Minnow-trap catches of 14 stream fish species at 36 traps over three days in two years, Costello Creek, Algonquin Provincial Park, Ontario.",
  url = "https://doi.org/10.5061/dryad.ft71172",
  reference = "Benoit, D. M., Jackson, D. A. & Ridgway, M. S. (2018). Assessing the impacts of imperfect detection on estimates of diversity and community structure through multispecies occupancy modeling. Ecology and Evolution 8, 4676-4684. https://doi.org/10.1002/ece3.4023",
  doi_paper = "10.1002/ece3.4023", doi_data = "10.5061/dryad.ft71172", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad deposit fetched from its Zenodo mirror (record 4973445, carrying the Dryad DOI). Per-species sheets parsed by block.",
  source_via = "Zenodo mirror of Dryad (file API)")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Community abundance (N-mixture)",
  sampling_protocol = "minnow_trap", design = "Multi-season (2 years, 3 trap days)",
  realm = "Freshwater", country = "CAN", coordinates = "None in source", notes = "Species sheets only for species caught (__survey_taxa).")
