#!/usr/bin/env Rscript
# Table:  vandeweyer_2024_australia_mouse_scr
# Source: Dryad doi:10.5061/dryad.3tx95x6n8 (CC0 1.0, as shown on the Dryad page; published 2024).
#         Van de Weyer, N. et al. Data from: Contrasting patterns of female house mouse spatial
#         organisation among outbreaking and stable populations.
# Paper:  Van de Weyer, N. et al. (2024). Ecology and Evolution, doi:10.1002/ece3.10843. Live trapping of house mice in
#         grain paddocks near Mallala, South Australia (paddocks A, B; October 2019 - February
#         2020) and Parkes, New South Wales (paddocks C, D; November 2020 - February 2021): two
#         grids per paddock (8 grids), each "64 single capture Longworth traps ... set at 10 m
#         intervals on an 8 x 8 grid", "checked and closed each morning ... and opened in the
#         evening", four trapping sessions per grid; mice PIT-tagged (Dryad methods).
# Data:   Van_de_Weyer_et_al_House_Mouse_Captures_Raw_Data.txt (2,344 captures: Session =
#         grid.session (A1.1 ... D8.4, 32 sessions), ID (PIT tag; "UN..." = mice too small to tag,
#         each in one session), Occasion = trap night, Detector = trap 11..88, Sex M/F/U, Region).
#         No trap coordinates and no trap-night schedule are deposited.
#         Quirks: 3 exact duplicate rows (collapsed); 1 mouse-night with captures in two traps
#         (kept: y = 1 in both); 2 tagged mice were caught on two grids.
# Mapping (standard: E9 experimental, SCR, multi-session): one closed population per grid x
#   session. unit = "<grid>_<ID>" (a mouse caught on two grids is two units); cluster_id = grid;
#   period = session 1..4 within the grid; occasion = trap night; trap = "<grid>_<detector>";
#   y = 1 if captured in that trap that night. Rows: every unit x every trap of its grid x every
#   night of every session of its grid (full rectangle, ruling #30; a mouse is at risk on its
#   grid in all four sessions). unit_sex (U where never sexed).
#   Survey evidence: inferred. Rules (surveyEvidenceNote): (1) all 64 traps of a grid were set on
#   every night of a session (the methods); (2) a session's nights are 1..the largest night
#   with a capture (3-5), so a final night without captures would be missing; (3) trap
#   positions are rebuilt from the detector numbers, whose two digits both run 1-8 (64 ids), as
#   an 8 x 8 grid at 10 m spacing: x = 10 (d2 - 1), y = 10 (d1 - 1) m (which digit is the row is
#   not stated; the transposed grid has the same inter-trap distances). House mouse is an
#   introduced pest in Australia, IUCN LC; no geographic coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "vandeweyer_2024_australia_mouse_scr"
dir <- download_dryad("10.5061/dryad.3tx95x6n8", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "House_Mouse_Captures_Raw_Data\\.txt$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
d <- fread(f, header = FALSE, skip = 1, col.names = c("Session", "ID", "Occasion", "Detector", "Sex", "Region"))
stopifnot(nrow(d) == 2344, uniqueN(d$Session) == 32, all(d$Sex %in% c("M", "F", "U")), all(d$Region %in% c("Mallala", "Parkes")),
          uniqueN(d$Detector) == 64, all(d$Detector %/% 10 %in% 1:8), all(d$Detector %% 10 %in% 1:8))
d[, `:=`(grid = sub("\\..*", "", Session), period = as.integer(sub(".*\\.", "", Session)))]
stopifnot(all(d$period %in% 1:4), uniqueN(d$grid) == 8, sum(duplicated(d)) == 3)
d <- unique(d)
stopifnot(sum(duplicated(d[, .(ID, Session, Occasion)])) == 1, d[grepl("^UN", ID), uniqueN(Session), by = ID][, all(V1 == 1)])
d[, unit := paste(grid, ID, sep = "_")]
nights <- d[, .(n = max(Occasion)), by = .(grid, period)]
stopifnot(nrow(nights) == 32, all(nights$n %in% 3:5), d[, all(Occasion >= 1)])
tr <- CJ(det = sort(unique(d$Detector)))
surv <- nights[, .(occasion = seq_len(n)), by = .(grid, period)][, .(det = tr$det), by = .(grid, period, occasion)]
units <- unique(d[, .(unit, grid)])
long <- merge(units, surv, by = "grid", allow.cartesian = TRUE)
caps <- unique(d[, .(unit, grid, period, occasion = Occasion, det = Detector, y = 1L)])
long <- merge(long, caps, by = c("unit", "grid", "period", "occasion", "det"), all.x = TRUE)[is.na(y), y := 0L]
sx <- d[, .(unit_sex = if (any(Sex %in% c("M", "F"))) { s <- unique(Sex[Sex != "U"]); if (length(s) == 1) s else "conflict" } else "U"), by = unit]
stopifnot(sum(sx$unit_sex == "conflict") == 0)
long <- merge(long, sx, by = "unit")
long[, `:=`(taxon = "MUSMUS", cluster_id = grid, trap = paste(grid, det, sep = "_"))][, c("grid", "det") := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == sum(units[, .N, by = grid][nights[, .(tot = sum(n) * 64), by = grid], on = "grid", N * tot]),
          sum(long$y) == nrow(caps))
traps <- CJ(grid = sort(unique(d$grid)), det = tr$det)[, .(trap = paste(grid, det, sep = "_"), x = 10 * (det %% 10 - 1), y = 10 * (det %/% 10 - 1), grid,
                                                          region = ifelse(substr(grid, 1, 1) %in% c("A", "B"), "Mallala", "Parkes"))]
periods <- data.table(period = 1:4, period_note = "trapping session within a grid (Mallala: October 2019 - February 2020; Parkes: November 2020 - February 2021)")
taxa <- make_taxa("MUSMUS", "Mus musculus", vernacularName = "House mouse")
dataset <- list(
  title = "Live-trap spatial capture-recapture of house mice on eight 64-trap grids in Australian grain paddocks, four sessions per grid, 2019-2021",
  creator = "Van de Weyer, Nikki; Ruscoe, Wendy; Henry, Steve; Brown, Peter; Robinson, Freya; Hinds, Lyn; Oh, Kevin", pubDate = "2024", paperDOI = "10.1002/ece3.10843",
  doi = "10.5061/dryad.3tx95x6n8", sourceURL = "https://doi.org/10.5061/dryad.3tx95x6n8",
  citation = "Van de Weyer, N. et al. (2024). Data from: Contrasting patterns of female house mouse spatial organisation among outbreaking and stable populations [Dataset]. Dryad. https://doi.org/10.5061/dryad.3tx95x6n8",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Captures of PIT-tagged house mice (Mus musculus) on eight 8 x 8 Longworth live-trap grids (10 m spacing) in grain paddocks near Mallala, South Australia (2019-20) and Parkes, New South Wales (2020-21), four trapping sessions of 3-5 nights per grid: one row per mouse x trap x night of its grid, with sex.",
  samplingProtocol = "Eight 8 x 8 grids of single-capture Longworth traps at 10 m spacing, baited with wheat and bedding, opened each evening and checked and closed each morning, for 3-5 nights per session, four sessions per grid; mice PIT-tagged (small mice untagged, 'UN' ids).",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "No trap-night schedule or trap coordinates are deposited. A session's nights are taken as 1..the largest night with a capture (3-5), so a final night with no capture would be missing; every one of the grid's 64 traps is taken as set every night (the methods); trap positions are rebuilt from the two-digit detector numbers (1-8 x 1-8) as an 8 x 8 grid at 10 m spacing.",
  responseType = "detection", unitKind = "individual", closure = "closed",
  closureNote = "closed within a 3-5 night session, open between the four sessions of a grid (multi-session SCR)",
  occasionKind = "time", taxonInclusion = "single", crs = "local: trap grid in metres rebuilt from detector numbers (origin at trap 11)",
  geographicCoverage = "Grain paddocks near Mallala, South Australia (about 34.4 S, 138.5 E) and Parkes, New South Wales (about 33.1 S, 148.2 E), Australia",
  temporalCoverage = "2019-10/2021-02",
  coordinatesCoarsened = list(value = FALSE, method = "no geographic coordinates deposited; trap positions are local metres rebuilt from the grid layout"),
  designNote = "Experimental list of E9: spatial capture-recapture, multi-session: cluster_id = grid, period = session, occasion = night, trap = grid_detector with __traps.",
  notShipped = list(duplicates = "3 exact duplicate capture rows (collapsed)"),
  notes = "A mouse caught on two grids is two units (one per grid; 2 tags). Untagged small mice ('UN' ids) occur in one session each. 1 mouse-night has captures in two traps (single-capture traps; kept as recorded). Session calendar dates are not deposited, only the regional ranges.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, traps = traps, script = "data/vandeweyer_2024_australia_mouse_scr.R")
stage_dict_row(TABLE,
  description = "Multi-session live-trap SCR of house mice on eight 64-trap grids in South Australian and New South Wales grain paddocks, 2019-2021.",
  url = "https://doi.org/10.5061/dryad.3tx95x6n8",
  reference = "Van de Weyer, N. et al. (2024). Contrasting patterns of female house mouse spatial organisation among outbreaking and stable populations. Ecology and Evolution.",
  doi_paper = "10.1002/ece3.10843", doi_data = "10.5061/dryad.3tx95x6n8", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "SCR (E9 experimental); trap nights and positions inferred (stated rules).", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (multi-session)",
  sampling_protocol = "live_trap", design = "Multi-session (8 grids x 4 sessions x 3-5 nights)", realm = "Terrestrial",
  country = "AUS", coordinates = "None in source", notes = "Experimental (E9); survey set inferred.")
