#!/usr/bin/env Rscript
# Tables: work_2026_ocala_odonates_comm (coarsened) and work_2026_ocala_odonates_exact_comm (E7.3 sibling without
#         Libellula jesseana)
# Source: Harvard Dataverse doi:10.7910/DVN/M7XVVL, version 1.0 (released 2026-06-09), licence
#         CC0 1.0 (as shown on the Dataverse page: "CC0 1.0", SPDX CC0-1.0). Work, Kirsten (Stetson
#         University). "Odonate species richness and abundance in Ocala National Forest ponds".
# Paper:  Work, K. A. & Ray, H. A. (2026). Proximity and local ecological conditions affect odonate
#         assemblages in Ocala National Forest ponds. Journal of Freshwater Ecology 41(1), 2711736.
#         doi:10.1080/02705060.2026.2711736 (CC BY-NC 4.0 article; not read: publisher full text is
#         not fetchable from here, and Crossref carries no abstract). Design from the deposit.
# Data:   one file, "Ray and Work Ocala National Forest odonate data.xlsx" (Dataverse file 13995388),
#         three sheets:
#           Pond characteristics  16 ponds in 4 groups of 4 (Wildcat, Crooked, Hopkins, Salt; group
#               name only on the first pond of each group): DMS coordinates (one string, lat then
#               lon; Hopkins pond 3 carries a stray trailing "7"), size m2, depth m, nearest-neighbour
#               distance m, distance to the closest forest m, % open water, open-water area m2,
#               % grass, % lily cover, sunfish / fish / crayfish presence 0/1.
#           Odonate adult data    64 rows = 4 visits (May 2022, August 2022, June 2023, August
#               2023; month on the first row of each block) x 16 ponds, 45 species columns 0/1
#               (aerial-net presence) plus two blank, all-empty columns (dropped).
#           Odonate nymph data    same 64 x 45 layout, dipnet counts: the sibling table
#               work_2026_ocala_odonatenymphs_count. Three species headers are spelled differently
#               there (Nehalennia "intercolis", "Argiogomphus" pallidus, "Progomphus" cavallaris);
#               columns match by position (asserted).
#         The Dataverse description says summers 2021 and 2023; the data sheets say 2022 and 2023,
#         and the sheets are followed.
#
# Mapping (standard E9 community occupancy, responseType detection): unit = pond ("Wildcat-1"),
#   cluster_id = pond group, taxon = 6-letter code (genus 3 + species 3) of the corrected name,
#   period = year (1 = 2022, 2 = 2023), occasion = visit within the year (1, 2), y = 0/1 adult
#   collected. Survey evidence: the deposited matrix (every pond x visit row present, every
#   species cell filled with 0 or 1); every taxon on the 45-species list gets a row at every
#   survey, including species collected only as nymphs. obs_survey_month = YYYY-MM of the visit
#   (no day given, so no `date`). unit_: the pond characteristics, measured once.
#   Coordinates: DMS to 0.01 s in the deposit; Libellula jesseana (purple skimmer) is IUCN VU (GBIF
#   lookup below) and a Florida endemic, so the ponds are in its native range and all pond
#   coordinates are coarsened to the 0.1 degree cell (E7(b), coarsen_coords()).
#   E7.4: the pond ids name places ("Crooked-1") and the pond groups are place names, so the
#   coarsened table uses unit = P01..P16 and cluster_id = G1..G4 (ponds and groups in sheet
#   order); work_2026_ocala_odonates_exact_comm keeps the names and the DMS coordinates (decimal degrees) as
#   deposited, and has every recorded species but Libellula jesseana.
#   v1.1: closure = open (visits two to three months apart; closureNote), occasionKind = time,
#   taxonInclusion = recorded: the species of the 45-column list never collected as adults in this
#   table (collected only as nymphs, by the other method) are not listed (notShipped).
#   Not shipped: the two blank species columns; the never-recorded species.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "work_2026_ocala_odonates_comm"
meta_f <- download_cached("https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/M7XVVL",
                          TABLE, filename = "dataverse_dataset.json")
meta <- fromJSON(meta_f)$data$latestVersion
stopifnot(identical(meta$license$rightsIdentifier, "CC0-1.0"), meta$versionNumber == 1L,
          identical(meta$files$dataFile$id, 13995388L))
f <- download_cached("https://dataverse.harvard.edu/api/access/datafile/13995388", TABLE, filename = "ocala_odonates.xlsx")
stopifnot(identical(excel_sheets(f), c("Pond characteristics", "Odonate adult data", "Odonate nymph data")))

# ---- ponds
pc <- as.data.table(read_excel(f, 1, .name_repair = "minimal"))
stopifnot(nrow(pc) == 16L, identical(names(pc)[1:4], c("Group", "Pond", "GPS coordinates", "Size (m2)")))
pc[, Group := Reduce(function(a, b) if (is.na(b)) a else b, Group, accumulate = TRUE)]
stopifnot(identical(unique(pc$Group), c("Wildcat", "Crooked", "Hopkins", "Salt")), all(pc[, .N, by = Group]$N == 4L),
          identical(as.integer(pc$Pond), rep(1:4, 4)))
gps <- pc[["GPS coordinates"]]
stopifnot(sum(grepl("W7$", gps)) == 1L, which(grepl("W7$", gps)) == 11L)   # Hopkins 3: stray "7"
gps <- sub("W7$", "W", trimws(gps))
dms <- regmatches(gps, regexec("^(\\d+)°(\\d+)'([0-9.]+)\"N (\\d+)°(\\d+)'([0-9.]+)\"W$", gps))
stopifnot(all(lengths(dms) == 7L))
dd <- function(d, m, s) as.numeric(d) + as.numeric(m) / 60 + as.numeric(s) / 3600
lat <- sapply(dms, function(x) dd(x[2], x[3], x[4])); lon <- -sapply(dms, function(x) dd(x[5], x[6], x[7]))
stopifnot(all(lat > 29 & lat < 29.4), all(lon > -81.8 & lon < -81.5))
pond_id <- paste0(pc$Group, "-", pc$Pond)
num <- function(x) as.numeric(x)
site_covs <- data.frame(size_m2 = num(pc[["Size (m2)"]]), depth_m = num(pc[["Depth (m)"]]),
  nearest_neighbour_m = num(pc[["Nearest neighbor distance (m)"]]),
  forest_distance_m = num(pc[["Distance to the closest forest (m)"]]),
  open_water_pct = num(pc[["% Open water"]]), open_water_area_m2 = num(pc[["Open water area (m2)"]]),
  grass_pct = num(pc[["% Grass coverage"]]), lily_pct = num(pc[["% Lily coverage"]]),
  sunfish = as.integer(pc[["Sunfish presence/absence"]]), fish = as.integer(pc[["Fish presence/absence"]]),
  crayfish = as.integer(pc[["Crayfish presence/absence"]]))
stopifnot(!anyNA(site_covs), all(unlist(site_covs[, c("sunfish", "fish", "crayfish")]) %in% 0:1),
          all(site_covs$fish >= site_covs$sunfish))

# ---- species sheets
read_sheet <- function(i) {
  d <- suppressMessages(as.data.table(read_excel(f, i, .name_repair = "minimal")))
  stopifnot(nrow(d) == 64L, ncol(d) == 50L, identical(names(d)[1:3], c("Date", "Group", "Pond")),
            identical(which(names(d) == ""), 23:24), all(is.na(d[[23]])), all(is.na(d[[24]])))
  d
}
ad <- read_sheet(2); ny <- read_sheet(3)
visits <- c("May 2022", "August 2022", "June 2023", "August 2023")
for (d in list(ad, ny)) {
  stopifnot(identical(d$Date[!is.na(d$Date)], visits), identical(which(!is.na(d$Date)), c(1L, 17L, 33L, 49L)),
            identical(as.integer(d$Pond), rep(rep(1:4, 4), 4)),
            identical(d$Group[!is.na(d$Group)], rep(c("Wildcat", "Crooked", "Hopkins", "Salt"), 4)))
}
sp_cols <- setdiff(seq_len(50), c(1:3, 23:24))
src <- names(ad)[sp_cols]
stopifnot(length(src) == 45L, identical(names(ny)[sp_cols] != src,
  names(ny)[sp_cols] %in% c("Nehalennia intercolis", "Argiogomphus pallidus", "Progomphus cavallaris")))
fix <- c("Argia mœsta" = "Argia moesta", "Coryphœschna ingens" = "Coryphaeschna ingens",
         "Nasiæschna panacatha" = "Nasiaeschna pentacantha", "Pachydiplex longipennis" = "Pachydiplax longipennis",
         "Epitheca cyanosura" = "Epitheca cynosura", "Gomphus cavallaris" = "Gomphus cavillaris")
stopifnot(all(names(fix) %in% src))
sci <- ifelse(src %in% names(fix), fix[src], src)
code <- toupper(paste0(substr(sub(" .*", "", sci), 1, 3), substr(sub(".* ", "", sci), 1, 3)))
stopifnot(!anyDuplicated(code))

m <- as.matrix(ad[, ..sp_cols]); storage.mode(m) <- "integer"
stopifnot(!anyNA(m), all(m %in% 0:1))
# rows are visit-major (4 visits x 16 ponds): y[pond, visit, species]
y <- array(NA_integer_, c(16, 4, 45), dimnames = list(pond_id, NULL, code))
for (v in 1:4) y[, v, ] <- m[(v - 1) * 16 + 1:16, ]
stopifnot(sum(y) == sum(m))
cat(sprintf("  adults: %d ponds x %d visits x %d species; %d detections; %d species never collected as adults\n",
            16, 4, 45, sum(y), sum(colSums(m) == 0)))
month <- matrix(rep(c("2022-05", "2022-08", "2023-06", "2023-08"), each = 16), 16)

taxa <- make_taxa(code, sci, lookupName = sci, taxon_sourceName = src)
stopifnot(!anyNA(taxa$taxonID))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[is.na(taxon_iucnCategory), .(taxon, scientificName)])
flagged <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU")]
# Libellula jesseana (purple skimmer, VU) is a Florida endemic: these ponds are in its native range (E7(b))
stopifnot(identical(flagged$taxon, "LIBJES"), identical(flagged$taxon_iucnCategory, "VU"))
cc <- coarsen_coords(lat, lon)
site_covs$decimalLatitude <- round(lat, 6); site_covs$decimalLongitude <- round(lon, 6)
cat(sprintf("  IUCN flagged: %s; %d ponds coarsened into %d 0.1-degree cells\n",
            paste(flagged$scientificName, flagged$taxon_iucnCategory), 16L, uniqueN(paste(cc$lat, cc$lon))))
long <- array_to_eco(y, site_ids = pond_id, site_covs = site_covs, period = c(1L, 1L, 2L, 2L),
                     obs_covs = list(survey_month = month))
long[, cluster_id := sub("-\\d$", "", unit)]
setcolorder(long, c("unit", "taxon", "y", "period", "occasion", "cluster_id"))
# taxonInclusion = recorded: drop the species never collected in this table
never <- long[, .(n = sum(y)), by = taxon][n == 0, taxon]
stopifnot(length(never) == 15, !"LIBJES" %in% never)
never_names <- taxa[match(never, taxon), scientificName]
long <- long[!taxon %in% never]; taxa <- taxa[!taxon %in% never]
long_exact <- long[taxon != "LIBJES"]
pid <- setNames(sprintf("P%02d", seq_along(pond_id)), pond_id)
gid <- setNames(paste0("G", 1:4), c("Wildcat", "Crooked", "Hopkins", "Salt"))
long[, `:=`(unit = unname(pid[unit]), cluster_id = unname(gid[cluster_id]))]
ci <- match(long$unit, pid)
long[, `:=`(unit_decimalLatitude = cc$lat[ci], unit_decimalLongitude = cc$lon[ci], unit_coordinateUncertaintyInMeters = cc$uncertainty_m[ci])]
stopifnot(!anyNA(long$unit), !anyNA(long$cluster_id))
stopifnot(nrow(long) == 16L * 4L * (45L - length(never)), sum(long$y) == sum(m), all(long$occasion %in% 1:2))

periods <- data.table(period = 1:2, year = c(2022L, 2023L), n_occasions = 2L,
                      visit_months = c("May, August", "June, August"))

emit <- function(TABLE, lg, tx, exact) {
  dataset <- list(
    title = paste0("Adult odonate (dragonfly and damselfly) detection/non-detection at 16 ponds in Ocala National Forest, Florida, four aerial-net visits 2022-2023", if (exact) " (without Libellula jesseana, coordinates as deposited)" else ""),
    creator = "Work, Kirsten; Ray, H. A.", pubDate = "2026", doi = "10.7910/DVN/M7XVVL",
    sourceURL = "https://doi.org/10.7910/DVN/M7XVVL",
    citation = "Work, K. (2026). Odonate species richness and abundance in Ocala National Forest ponds [Dataset]. Harvard Dataverse, V1. https://doi.org/10.7910/DVN/M7XVVL",
    paperDOI = "10.1080/02705060.2026.2711736",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = paste0(sprintf("Presence of %d odonate species as adults collected with aerial nets at 16 ponds in four spatial groups in Ocala National Forest, Florida, on four visits (May and August 2022, June and August 2023), with pond size, depth, isolation, vegetation and fish / crayfish presence. Collected to test whether assemblages are more similar in nearby ponds and which ecological variables predict assemblage structure; nymphs collected with dipnets on the same visits are a sibling table.", nrow(tx)), if (exact) " This table omits Libellula jesseana (IUCN VU) so that pond names and coordinates ship as deposited." else ""),
    samplingProtocol = "Adults collected with aerial nets at each pond on each visit; nymphs with dipnets (sibling table). Sampling time or area per visit is not given in the deposit.",
    samplingProtocolCode = "aerial_net", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
    closure = "open", occasionKind = "time", taxonInclusion = "recorded",
    closureNote = "period, loosely: two visits two to three months apart within a summer; adult flight seasons differ by species, so a species' availability changes between visits",
    geographicCoverage = "Ocala National Forest, Marion County, Florida, USA (29.12-29.33 N, 81.61-81.74 W)",
    temporalCoverage = "2022-05/2023-08",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = "As deposited (degrees-minutes-seconds to 0.01 s, converted to decimal degrees): Libellula jesseana (IUCN VU) is not in this table (E7.3)") else
      list(value = TRUE, method = "Pond coordinates (degrees-minutes-seconds to 0.01 s in the deposit) generalised to the 0.1 degree cell centre with coarsen_coords(), uncertainty = cell half-diagonal; flagged taxon: Libellula jesseana (IUCN VU via GBIF; Florida endemic, so in its native range); pond and group names replaced by P01..P16 and G1..G4 (E7.4)"),
    notes = "Visit months only (obs_survey_month); no day, so no `date`. The Dataverse description says summers 2021 and 2023; the sheets say 2022 and 2023 and are followed. Six source spellings corrected for GBIF (Argia moesta, Coryphaeschna ingens, Nasiaeschna pentacantha, Pachydiplax longipennis, Epitheca cynosura, Gomphus cavillaris); the source spelling is in __taxa taxon_sourceName. Species collected only as nymphs are not listed (taxonInclusion = recorded). Hopkins pond 3's coordinate string has a stray trailing '7', dropped. Sampling effort per visit is not in the deposit.",
    notShipped = c(list(`two blank species columns` = "unlabelled and empty in both stage sheets",
                      `species never collected as adults` = sprintf("%d species of the 45-column list never collected in this table (only as nymphs): %s", length(never), paste(never_names, collapse = ", ")),
                      `Odonate nymph data` = "shipped as work_2026_ocala_odonatenymphs_count"),
                   if (exact) list(LIBJES = sprintf("Libellula jesseana (IUCN VU): in work_2026_ocala_odonates_comm only, whose coordinates are coarsened"))
                   else list(`pond and group names` = sprintf("place names (E7.4): unit P01..P16, cluster_id G1..G4; names in work_2026_ocala_odonates_exact_comm"))))
  ds <- write_table(lg, TABLE, dataset, taxa = tx, periods = periods, script = "data/work_2026_ocala_odonates_comm.R")

  stage_dict_row(TABLE,
    description = paste0(sprintf("Detection/non-detection of %d adult odonate species (aerial nets) at 16 ponds in four groups in Ocala National Forest, Florida, on four visits (2 per summer, 2022-2023), with pond size, depth, isolation, vegetation cover and fish / crayfish presence.", nrow(tx)), if (exact) " Libellula jesseana omitted; coordinates as deposited." else " Coordinates coarsened (Libellula jesseana VU)."),
    url = "https://doi.org/10.7910/DVN/M7XVVL",
    reference = "Work, K. A., & Ray, H. A. (2026). Proximity and local ecological conditions affect odonate assemblages in Ocala National Forest ponds. Journal of Freshwater Ecology, 41(1), 2711736.",
    doi_paper = "10.1080/02705060.2026.2711736", doi_data = "10.7910/DVN/M7XVVL",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = paste0(if (exact) "E7.3 sibling of work_2026_ocala_odonates_comm without Libellula jesseana. " else "", "Sibling of work_2026_ocala_odonatenymphs_count (same visits, dipnet counts). Below the sample floor (16 ponds). Visit months only."),
    source_via = "Harvard Dataverse")
  stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Community occupancy (multi-season)",
    sampling_protocol = "aerial_net", design = "Multi-season (2 summers x 2 visits)", realm = "Freshwater",
    country = "USA", coordinates = if (exact) "As published" else "Coarsened (0.1 deg) (Libellula jesseana VU)", notes = "Adults only; nymph counts are the sibling table; cluster_id = pond group.")
}
emit(TABLE, long, taxa, exact = FALSE)
emit("work_2026_ocala_odonates_exact_comm", long_exact, taxa[taxon != "LIBJES"], exact = TRUE)
