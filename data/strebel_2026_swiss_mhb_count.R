#!/usr/bin/env Rscript
# Tables: strebel_2026_swiss_mhb_count             per-visit territory counts, all 162 species, coordinates coarsened (E7.3)
#         strebel_2026_swiss_mhb_exact_count       the same without the flagged turtle dove, coordinates as published
#         strebel_2026_swiss_mhb_total_count       season territory total per square-year, all 162 species, coarsened
#         strebel_2026_swiss_mhb_total_exact_count the same without the turtle dove, coordinates as published
# Source: Zenodo doi:10.5281/zenodo.18480886 (record 18480886, published 2026-02-04; concept
#         doi:10.5281/zenodo.15854963, the annually updated release), "Supplementary material for
#         «Data of the Swiss Common Breeding Bird Monitoring Program»", Strebel N, Wechsler S,
#         Buehler R, Haefliger G, Keller V, Kery M, Rogenmoser C, Spiess M, Varga K, Volet B,
#         Zbinden N, Schmid H (Swiss Ornithological Institute). Licence as shown on the record:
#         CC BY 4.0 (asserted from the Zenodo API below); the data paper says the same.
# Paper:  Strebel N et al. (2025). Data of the Swiss common breeding bird monitoring program.
#         Ecology 106(12): e70268. doi:10.1002/ecy.70268 (CC BY 4.0, open access). Its Metadata S1
#         (Ecology data-paper metadata, read from the PMC supplementary zip) supplies the column
#         definitions, the CRS and the causes of the missing values quoted below.
# Data:   header-species-count.csv: 7,113 rows, one per survey (square x year), 267 1-km squares,
#           1999-2025 (some square-years missing: not surveyed or survey rejected for quality):
#           samplearea_id, x-koord / y-koord (square centroid, CH1903+ / LV95, EPSG:2056), lon / lat
#           (centroid, WGS84), year, route_length (m), median_elevation (m, multiples of 50),
#           n_visits (2 above the timberline, 3 elsewhere; changes over the years at 2 squares),
#           n_recorded_species (the number of species with territories at the survey: a count of
#           the total column, asserted, not shipped).
#         data-territories.csv: 1,152,306 rows = 7,113 square-years x 162 species: species_id
#           (Vogelwarte code), euring_id, nameeg, namelt (BirdLife taxonomy), samplearea_id, year,
#           territories_visit_1..3 (territories found occupied at each visit), territories_total
#           (territories delimited from all visits by the observer, by Autoterri since 2022).
#         Missing values (Metadata S1, Class IV.C, and asserted below):
#           (1) visit 3 NA at the 1,264 two-visit square-years (protocol);
#           (2) visit 1, or visits 1 and 2, NA for a species (rows with some per-visit value):
#               observations before a species-specific date limit are left aside so that staging
#               migrants are not counted (the visit is outside the species' counting window). Two
#               square-years (2008, 2009) have visit 2 NA and visit 1 kept for 17 and 24 late
#               breeders (41 rows), shipped as deposited. Metadata S1 adds that where no territory
#               resulted, the visits "were set to 0 independent on whether the survey was conducted
#               before or after the species-specific date limit"; in this release most such rows
#               keep the NA (137,847 visit-1-NA rows have a total of 0), so some deposited visit-1
#               zeros of late breeders may lie before the date limit; they are shipped as deposited.
#           (3) all three visits NA with a total: mapping data not digitally available, so no
#               detection history (39,211 species x square-years, mostly 1999-2012; 36,530 of them
#               with a positive total);
#           (4) all visits and the total NA: the data for that species at that survey were not
#               valid (188 records at 120 surveys).
#         Four species are withheld by the source to avoid disturbance at nesting sites (Metadata
#         S1): Tetrao urogallus, Aquila chrysaetos, Falco peregrinus, Bubo bubo (taxaWithheld).
# Mapping (E1-E7; ruling 2026-11-06 "per-visit series and season total", E1):
#   unit = samplearea_id; taxon = 6-letter code from genus + epithet (as kery_2014_mhb_comm; three
#   collisions resolved below); period = year index 1..27 (1999..2025, year in __periods).
#   Per-visit tables: occasion = visit 1..3, y = territories_visit_k; a row exists where the value is
#   not NA. A survey (square, year, visit) exists for every visit of every deposited square-year
#   (n_visits visits; asserted: every such visit has a value for some species), so the survey set is
#   the header table (surveyEvidence = sample_table). __survey_taxa (taxon, unit, period, occasion)
#   lists the species counted at each visit: causes (2), (3) and (4) are not surveyed for that
#   species. Season-total tables: no occasion, y = territories_total, a row wherever it is not NA;
#   __survey_taxa (taxon, unit, period) drops the 188 invalid records (4). obs_per_visit_values = 1
#   where the per-visit series exists for that species x square-year, 0 under cause (3). The totals
#   are not a function of the visits (4,050 exceed the visit sum; 3,432 positive totals have every
#   visit 0, asserted): the total is that table's observation, as the ruling says.
#   Covariates: unit_decimalLatitude / unit_decimalLongitude (WGS84) and unit_x / unit_y (LV95) of the
#   square centroid, unit_coordinateUncertaintyInMeters (707 m, the half-diagonal of the 1 km
#   square), unit_route_length_m, unit_median_elevation_m; period_n_visits (2 or 3).
#   E7: iucn_category() flags the European turtle dove (Streptopelia turtur, VU, native breeder);
#   the square centroids are 1 km apart, finer than 0.1 degree, so (E7.3) each table ships whole
#   and coarsened under its name (lat/lon to 0.1-degree cell centres, x/y to 10 km LV95 cell
#   centres, elevation to 100 m, E7.1 and E7.4; square ids are numbers, not place names) and
#   without the turtle dove at source precision as the _exact sibling. The source's own
#   sensitive species are withheld by the source (taxaWithheld).
#   Not shipped: n_recorded_species (a count of the total column); the visit dates and durations
#   are not deposited. Overlap: kery_2014_mhb_comm (AHMbook::MHB2014) is the 2014 season of the
#   same scheme from another deposit; the kery single-species MHB tables likewise.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
options(timeout = 1200)
SCRIPT <- "data/strebel_2026_swiss_mhb_count.R"
RAWT <- "strebel_2026_swiss_mhb_count"
REC <- "https://zenodo.org/api/records/18480886"

# --- licence and files, from the Zenodo record --------------------------------------------
rec <- fromJSON(paste(readLines(url(REC, headers = c("User-Agent" = UA)), warn = FALSE), collapse = ""), simplifyVector = FALSE)
stopifnot(identical(rec$metadata$license$id, "cc-by-4.0"),
          setequal(vapply(rec$files, `[[`, "", "key"), c("data-territories.csv", "header-species-count.csv")))
f_d <- download_cached(sprintf("%s/files/data-territories.csv/content", REC), RAWT)
f_h <- download_cached(sprintf("%s/files/header-species-count.csv/content", REC), RAWT)
stopifnot(unname(tools::md5sum(f_d)) == "558219b26a8975c9c6efa37bbabe6d58",
          unname(tools::md5sum(f_h)) == "f6e700eafa9ef1a203112a8b671024ef")

d <- fread(f_d, na.strings = "NA")
h <- fread(f_h, na.strings = "NA")
setnames(h, c("x-koord", "y-koord"), c("xk", "yk"))
V <- paste0("territories_visit_", 1:3)

# --- the header: surveys ------------------------------------------------------------------
stopifnot(nrow(h) == 7113, uniqueN(h[, .(samplearea_id, year)]) == 7113, uniqueN(h$samplearea_id) == 267,
          !anyNA(h), all(h$year %in% 1999:2025), all(h$n_visits %in% 2:3), sum(h$n_visits == 2) == 1264,
          all(h$median_elevation %% 50 == 0))
# square-level facts are constant across years; n_visits changes at two squares (529, 531)
stopifnot(h[, .(uniqueN(xk), uniqueN(yk), uniqueN(lon), uniqueN(lat), uniqueN(route_length), uniqueN(median_elevation)), by = samplearea_id][, all(unlist(.SD) == 1), .SDcols = -1],
          setequal(h[, uniqueN(n_visits), by = samplearea_id][V1 > 1, samplearea_id], c(529L, 531L)))

# --- the territories file -----------------------------------------------------------------
stopifnot(nrow(d) == 1152306, uniqueN(d$species_id) == 162, uniqueN(d$namelt) == 162, uniqueN(d$euring_id) == 162,
          nrow(unique(d[, .(samplearea_id, year, species_id)])) == nrow(d),
          d[, .N, by = .(samplearea_id, year)][, all(N == 162)])
d <- merge(d, h[, .(samplearea_id, year, n_visits, n_recorded_species)], by = c("samplearea_id", "year"))
stopifnot(nrow(d) == 1152306)
# n_recorded_species is the number of species with a positive total (derived; not shipped)
stopifnot(d[, .(n = sum(territories_total > 0, na.rm = TRUE), r = n_recorded_species[1]), by = .(samplearea_id, year)][, all(n == r)])
for (v in V) stopifnot(all(d[[v]][!is.na(d[[v]])] >= 0))
d[, pat := paste0(as.integer(is.na(territories_visit_1)), as.integer(is.na(territories_visit_2)), as.integer(is.na(territories_visit_3)))]
pt <- d[, .N, by = .(n_visits, pat, tot = fifelse(is.na(territories_total), "NA", fifelse(territories_total > 0, "pos", "0")))]
setkey(pt, n_visits, pat, tot)
EXPECT <- data.table(n_visits = c(2L, 2L, 2L, 2L, 2L, 2L, 2L, 3L, 3L, 3L, 3L, 3L, 3L, 3L, 3L, 3L, 3L, 3L),
                     pat = c("001", "001", "101", "101", "111", "111", "111", "000", "000", "010", "010", "100", "100", "110", "110", "111", "111", "111"),
                     tot = c("0", "pos", "0", "pos", "0", "NA", "pos", "0", "pos", "0", "pos", "0", "pos", "0", "pos", "0", "NA", "pos"),
                     N = c(183046L, 17982L, 516L, 26L, 27L, 48L, 3123L, 584916L, 176143L, 40L, 1L, 86915L, 10239L, 50932L, 2151L, 2654L, 140L, 33407L))
setkey(EXPECT, n_visits, pat, tot)
stopifnot(isTRUE(all.equal(pt, EXPECT, check.attributes = FALSE)))
# (1) visit 3 is NA exactly at two-visit square-years
stopifnot(all(is.na(d$territories_visit_3) == (d$n_visits == 2 | d$pat == "111")))
# (4) a NA total only with every visit NA: 188 records at 120 surveys
stopifnot(sum(is.na(d$territories_total)) == 188, all(d[is.na(territories_total), pat] == "111"),
          uniqueN(d[is.na(territories_total), .(samplearea_id, year)]) == 120)
# (3) no per-visit values but a total: 39,211, of which 36,530 positive (3,123 at two-visit and
#     33,407 at three-visit square-years): the totals the per-visit table cannot carry
N_NOVISIT_POS <- d[pat == "111" & territories_total > 0, .N]
stopifnot(d[pat == "111" & !is.na(territories_total), .N] == 39211, N_NOVISIT_POS == 36530,
          d[pat == "111" & territories_total > 0 & n_visits == 3, .N] == 33407)
# the total is not a function of the visits
dv <- d[pat %in% c("000", "001")]
dv[, `:=`(mx = pmax(territories_visit_1, territories_visit_2, territories_visit_3, na.rm = TRUE),
          sm = territories_visit_1 + territories_visit_2 + fcoalesce(territories_visit_3, 0L))]
stopifnot(dv[territories_total < mx, .N] == 0, dv[territories_total > sm, .N] == 4050,
          dv[territories_total > 0 & mx == 0, .N] == 3432, dv[territories_total == 0 & mx > 0, .N] == 0)
# positive totals over all-zero visits concentrate in a few species whose per-visit series looks
# incomplete (records filed under a subspecies or form are a likely cause; not stated by the source)
z0 <- d[!pat %in% "111" & territories_total > 0, .(n = sum(pmax(territories_visit_1, territories_visit_2, territories_visit_3, na.rm = TRUE) == 0)), by = namelt]
stopifnot(z0[namelt == "Acanthis flammea", n] == 1070, z0[namelt == "Passer domesticus", n] == 923,
          z0[namelt == "Poecile montanus", n] == 374, z0[namelt == "Passer hispaniolensis", n] == 198)
tp <- d[territories_total > 0, .N, by = namelt]
stopifnot(tp[namelt == "Acanthis flammea", N] == 1249, tp[namelt == "Passer hispaniolensis", N] == 213,
          tp[namelt == "Lanius senator", N] == 1, tp[namelt == "Emberiza hortulana", N] == 1)
rm(dv)

# --- taxa ---------------------------------------------------------------------------------
sp <- unique(d[, .(species_id, euring_id, nameeg, namelt)])
setorder(sp, species_id)
g <- sub(" .*", "", sp$namelt); e <- sub("^\\S+ ", "", sp$namelt)
sp[, code := toupper(paste0(substr(g, 1, 3), substr(e, 1, 3)))]
clash <- sp[duplicated(code) | duplicated(code, fromLast = TRUE), namelt]
stopifnot(setequal(clash, c("Corvus corone", "Corvus cornix", "Corvus corax", "Pyrrhocorax pyrrhocorax", "Pyrrhula pyrrhula",
                            "Saxicola rubetra", "Saxicola rubicola")))
FIX <- c("Corvus corone" = "CORCRN", "Corvus cornix" = "CORCRX", "Corvus corax" = "CORCRA",
         "Pyrrhocorax pyrrhocorax" = "PYCPYR", "Pyrrhula pyrrhula" = "PYRPYR",
         "Saxicola rubetra" = "SAXRUT", "Saxicola rubicola" = "SAXRUC")
sp[namelt %in% names(FIX), code := FIX[namelt]]
stopifnot(!anyDuplicated(sp$code))
d[, taxon := sp$code[match(species_id, sp$species_id)]]
# GBIF lookups for BirdLife names the backbone holds under another genus or spelling (same species):
# Botaurus minutus = Ixobrychus minutus; Astur gentilis = Accipiter gentilis; Chloris chloris needs its
# authorship (plant-genus homonym); Phylloscopus sibilatrix is spelled sibillatrix on the backbone.
LOOK <- c("Botaurus minutus" = "Ixobrychus minutus", "Astur gentilis" = "Accipiter gentilis",
          "Chloris chloris" = "Chloris chloris (Linnaeus, 1758)", "Phylloscopus sibilatrix" = "Phylloscopus sibillatrix")
lookup <- ifelse(sp$namelt %in% names(LOOK), LOOK[sp$namelt], sp$namelt)
taxa <- make_taxa(sp$code, sp$namelt, vernacularName = sp$nameeg, lookupName = lookup,
                  taxon_species_id = sp$species_id, taxon_euring_id = sp$euring_id)
# E7(b): IUCN categories through GBIF. NA answers are genus moves or spellings of the same species
# (Curruca communis / curruca, filed under Sylvia on the backbone; Phylloscopus sibilatrix), all LC.
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
na_iucn <- taxa[is.na(taxon_iucnCategory), scientificName]
cat("  IUCN NA (genus move / spelling, LC):", paste(na_iucn, collapse = ", "), "\n")
stopifnot(all(na_iucn %in% c("Curruca communis", "Curruca curruca", "Phylloscopus sibilatrix", "Botaurus minutus", "Astur gentilis")))
taxa[is.na(taxon_iucnCategory), taxon_iucnCategory := "LC"]
FLAGGED <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), taxon]
stopifnot(identical(FLAGGED, "STRTUR"))
WITHHELD <- c("Tetrao urogallus", "Aquila chrysaetos", "Falco peregrinus", "Bubo bubo")
stopifnot(!any(WITHHELD %in% sp$namelt))

# --- long tables --------------------------------------------------------------------------
years <- 1999:2025
d[, period := match(year, years)]
ucov <- h[, .(unit_decimalLatitude = lat[1], unit_decimalLongitude = lon[1], unit_x = xk[1], unit_y = yk[1],
              unit_route_length_m = route_length[1], unit_median_elevation_m = median_elevation[1]), by = samplearea_id]
pv <- melt(d[, c("samplearea_id", "taxon", "period", "n_visits", V), with = FALSE],
           id.vars = c("samplearea_id", "taxon", "period", "n_visits"), measure.vars = V,
           variable.name = "occasion", value.name = "y", na.rm = TRUE)
pv[, occasion := as.integer(sub(".*_", "", occasion))]
N_PV <- 3 * nrow(d) - sum(is.na(d[, ..V]))
stopifnot(nrow(pv) == N_PV, N_PV == 2933248)
# every visit of every deposited square-year carries a value for some species: the survey set is the header
surveys <- h[, .(occasion = seq_len(n_visits)), by = .(samplearea_id, year)]
stopifnot(nrow(surveys) == 20075, nrow(unique(pv[, .(samplearea_id, period, occasion)])) == 20075)
pv <- merge(pv, ucov, by = "samplearea_id")
pv <- pv[, .(unit = samplearea_id, taxon, y, period, occasion, unit_decimalLatitude, unit_decimalLongitude,
             unit_coordinateUncertaintyInMeters = 707L, unit_x, unit_y, unit_route_length_m, unit_median_elevation_m,
             period_n_visits = n_visits)]
tt <- d[!is.na(territories_total)]
tt <- merge(tt, ucov, by = "samplearea_id")
tt <- tt[, .(unit = samplearea_id, taxon, y = territories_total, period, unit_decimalLatitude, unit_decimalLongitude,
             unit_coordinateUncertaintyInMeters = 707L, unit_x, unit_y, unit_route_length_m, unit_median_elevation_m,
             period_n_visits = n_visits, obs_per_visit_values = as.integer(pat != "111"))]
stopifnot(nrow(tt) == 1152118, tt[obs_per_visit_values == 0, .N] == 39211)
# E10 taxonInclusion = recorded: a species with no positive per-visit value is not recorded in the
# per-visit table (only in the totals); it has no rows there (asserted set, listed in notShipped)
PV_NEVER <- pv[, .(any = any(y > 0)), by = taxon][any == FALSE, taxon]
stopifnot(setequal(taxa[taxon %in% PV_NEVER, scientificName], c("Lanius senator", "Passer hispaniolensis", "Acanthis flammea", "Emberiza hortulana")))
pv <- pv[!taxon %in% PV_NEVER]
rm(d); invisible(gc())
periods <- data.table(period = seq_along(years), year = years)

# --- emit ---------------------------------------------------------------------------------
CIT <- "Strebel, N., Wechsler, S., Buehler, R., Haefliger, G., Keller, V., Kery, M., Rogenmoser, C., Spiess, M., Varga, K., Volet, B., Zbinden, N. & Schmid, H. (2026). Supplementary material for «Data of the Swiss Common Breeding Bird Monitoring Program» [Data set]. Zenodo. https://doi.org/10.5281/zenodo.18480886. Data paper: Strebel, N. et al. (2025). Data of the Swiss common breeding bird monitoring program. Ecology 106(12): e70268. https://doi.org/10.1002/ecy.70268"
REF <- "Strebel N, Wechsler S, Buehler R, Haefliger G, Keller V, Kery M, Rogenmoser C, Spiess M, Varga K, Volet B, Zbinden N, Schmid H (2025). Data of the Swiss common breeding bird monitoring program. Ecology 106(12): e70268."
PROTO <- "Simplified territory mapping (Swiss Common Breeding Bird Monitoring, MHB): one skilled observer walks a fixed 4-6 km route through a 1-km square in early morning in good weather, three visits per breeding season (two above the timberline) within 4-6 weeks between mid-April and early July, mapping every bird seen or heard; records meeting species-specific breeding-period and behaviour criteria are grouped into territories (manually, by Autoterri since 2022)."

emit <- function(TABLE, total, exact) {
  lg <- copy(if (total) tt else pv); tx <- copy(taxa)
  if (!total) tx <- tx[!taxon %in% PV_NEVER]
  if (exact) {
    lg <- lg[!taxon %in% FLAGGED]; tx <- tx[!taxon %in% FLAGGED]
  } else {
    cc <- coarsen_coords(lg$unit_decimalLatitude, lg$unit_decimalLongitude)
    lg[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, unit_coordinateUncertaintyInMeters = as.integer(cc$uncertainty_m),
              unit_x = floor(unit_x / 10000) * 10000 + 5000, unit_y = floor(unit_y / 10000) * 10000 + 5000,
              unit_median_elevation_m = round(unit_median_elevation_m, -2))]
  }
  st <- if (total) unique(lg[, .(taxon, unit, period)]) else unique(lg[, .(taxon, unit, period, occasion)])
  # taxonInclusion = recorded: every listed species has a territory in this table's own surveys
  stopifnot(lg[, any(y > 0), by = taxon][, all(V1)], uniqueN(lg$taxon) == nrow(tx))
  ntx <- nrow(tx)
  sib <- if (total) c("strebel_2026_swiss_mhb_total_count", "strebel_2026_swiss_mhb_total_exact_count")
         else c("strebel_2026_swiss_mhb_count", "strebel_2026_swiss_mhb_exact_count")
  other <- if (total) "strebel_2026_swiss_mhb_count (per-visit territory counts, with __survey_taxa)"
           else "strebel_2026_swiss_mhb_total_count (season territory totals per square-year)"
  what <- if (total) "season territory totals" else "territory counts per visit"
  dataset <- list(
    title = sprintf("Swiss Common Breeding Bird Monitoring (MHB) 1999-2025: %s of %d bird species on %d 1-km squares%s",
                    what, ntx, uniqueN(lg$unit),
                    if (exact) ", without the turtle dove, coordinates as published" else ", coordinates coarsened to 0.1 degree"),
    creator = "Strebel, Nicolas; Wechsler, Samuel; Buehler, Roman; Haefliger, Guido; Keller, Verena; Kery, Marc; Rogenmoser, Christian; Spiess, Martin; Varga, Katarina; Volet, Bernard; Zbinden, Niklaus; Schmid, Hans (Swiss Ornithological Institute)",
    pubDate = "2026-02-04", doi = "10.5281/zenodo.18480886", paperDOI = "10.1002/ecy.70268",
    sourceURL = "https://doi.org/10.5281/zenodo.18480886", citation = CIT,
    intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
    abstract = paste0("The Swiss Common Breeding Bird Monitoring (MHB) of the Swiss Ornithological Institute surveys 267 1-km squares on a systematic grid across Switzerland (250-2750 m) every breeding season since 1999 by simplified territory mapping. ",
      if (total) "This table carries the number of territories delimited per species, square and year from all two or three visits (territories_total), the basis of the Swiss population indices; for 39,211 species x square-years (mostly 1999-2012) no per-visit values exist because the mapping data are not digital, so these totals are the only record of those surveys. obs_per_visit_values says which totals have a per-visit series in the sibling table."
      else "This table carries the detection histories: the number of territories found occupied at each visit, for N-mixture and occupancy models. A species is counted at a visit only when the visit falls after its species-specific date limit, and per-visit values are missing where the maps were not digitised (mostly before 2013); __survey_taxa lists the species counted at each visit."),
    samplingProtocol = PROTO, samplingProtocolCode = "territory_survey",
    responseType = "count", unitKind = "site",
    closure = if (total) "none" else "closed", occasionKind = if (total) "none" else "time",
    closureNote = if (total) "one season total per square-year; territories may change between years"
                  else "visits within one breeding season (4-6 weeks at a square), assumed closed; territories may change between years (period)",
    taxonInclusion = "recorded",
    surveyEvidence = "sample_table",
    surveyEvidenceNote = paste0("The survey list is header-species-count.csv (one row per conducted and accepted square-year, with n_visits); ",
      if (total) "every species has a total at every survey except 188 records the source marks as not valid (all values NA), which __survey_taxa (taxon, unit, period) leaves out."
      else "every visit of every listed square-year has a value for some species (asserted). __survey_taxa (taxon, unit, period, occasion) lists the species counted at each visit: a NA value is not surveyed for that species, because the visit is before the species' date limit (visit 1, or visits 1-2, for late breeders), the mapping data are not digital (all visits NA: 39,211 species x square-years), or the record is not valid (188, total also NA)."),
    surveyTaxaNote = if (total) "__survey_taxa (taxon, unit, period): the species with a valid total at each square-year; 188 records the source marks as not valid are absent."
                     else "__survey_taxa (taxon, unit, period, occasion): the species counted at each visit; visits outside a species' counting window, square-years whose maps are not digital, and invalid records are absent.",
    geographicCoverage = "Switzerland, 267 1-km squares of the Swiss Biodiversity Monitoring grid (CH1903+ / LV95), 250-2750 m a.s.l.",
    temporalCoverage = "1999/2025",
    crs = "unit_decimalLatitude / unit_decimalLongitude: WGS84 (EPSG:4326); unit_x / unit_y: CH1903+ / LV95 (EPSG:2056); square centroids",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = "as published (centroids of the 1-km squares, uncertainty 707 m, the half-diagonal); the flagged European turtle dove (Streptopelia turtur, IUCN VU) is not in this table (E7.3); the coarsened table with every species is " %+% sib[1])
                           else list(value = TRUE, method = "E7: the table includes the European turtle dove (Streptopelia turtur, IUCN VU), so unit_decimalLatitude / unit_decimalLongitude are snapped to the centre of the 0.1-degree cell (coarsen_coords(); unit_coordinateUncertaintyInMeters is the cell half-diagonal), unit_x / unit_y to the centre of the 10 km LV95 cell (floor(x / 10000) * 10000 + 5000, uncertainty 7,071 m), and unit_median_elevation_m rounded to 100 m (E7.4). The table without the turtle dove at source precision is " %+% sib[2] %+% " (E7.3)"),
    taxaWithheld = WITHHELD,
    notShipped = c(list(
      n_recorded_species = "header-species-count.csv: the number of species with a positive total at the survey; a count of the total column (asserted), not an observation",
      visit_dates = "not deposited (no visit dates or durations in the release)"),
      if (!total) list(territories_total = sprintf("the season total is %s (%d positive totals have no per-visit values; ruling 2026-11-06, E1)", "strebel_2026_swiss_mhb_total_count", N_NOVISIT_POS))
      else list(territories_visit = "the per-visit series is in strebel_2026_swiss_mhb_count"),
      if (!total) list(never_recorded_per_visit = sprintf("%s: no positive per-visit value in any survey (positive totals only: Acanthis flammea 1,249, Passer hispaniolensis 213, Lanius senator 1, Emberiza hortulana 1), so not recorded in this table (taxonInclusion = recorded); they are in the season-total tables", paste(taxa[taxon %in% PV_NEVER, scientificName], collapse = ", "))),
      if (exact) list(STRTUR = sprintf("the European turtle dove (IUCN VU) is left out of this precise-coordinate table (E7.3); it is in %s with coarsened coordinates", sib[1]))),
    notes = paste0(
      "Two tables per E7 pair from one deposit (ruling 2026-11-06, per-visit series and season total): the per-visit counts and the season totals; the other is ", other, ". ",
      sprintf("%d positive season totals (%d at three-visit squares) have no per-visit values. ", N_NOVISIT_POS, 33407L),
      if (!total) "Metadata S1 says that where no territory resulted the visits were set to 0 whatever the species' date limit, so some visit-1 zeros of late breeders may precede the limit; most such rows keep the NA in this release. Two square-years (2008, 2009) have visit 2 NA and visit 1 kept for 41 late-breeder rows, as deposited. "
      else "",
      if (!total) "Positive totals over all-zero visits (3,432) concentrate in a few species (Acanthis flammea 1,070, Passer domesticus 923, Poecile montanus 374, Passer hispaniolensis 198), whose per-visit series may be incomplete; Acanthis flammea and Passer hispaniolensis have no positive per-visit value at all and are not in this table. "
      else "The totals are delimited from all visits, not summed: 4,050 exceed the visit sum and 3,432 positive totals have every visit 0. ",
      "Four sensitive species are withheld by the source (taxaWithheld). Taxon codes are genus+epithet initials as in kery_2014_mhb_comm (BirdLife names; Curruca for Sylvia communis / curruca). ",
      "Overlap: kery_2014_mhb_comm (AHMbook::MHB2014) and the kery single-species MHB tables are subsets of the same scheme from other deposits; this release is the scheme's own, 1999-2025."))
  ds <- write_table(lg, TABLE, dataset, taxa = tx, periods = periods[period %in% lg$period], survey_taxa = st, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Swiss Common Breeding Bird Monitoring (MHB), 267 1-km squares, 1999-2025: %s of %d bird species by simplified territory mapping%s%s.",
                          if (total) "season territory totals per square-year" else "territories found occupied at each of 2-3 visits per season (detection histories, __survey_taxa)",
                          ntx, if (exact) "; without the turtle dove (IUCN VU), coordinates as published" else "; coordinates coarsened to 0.1 degree",
                          ""),
    url = "https://doi.org/10.5281/zenodo.18480886", reference = REF,
    doi_paper = "10.1002/ecy.70268", doi_data = "10.5281/zenodo.18480886",
    original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
    notes = paste0("Zenodo record 18480886 (annual release, concept 10.5281/zenodo.15854963). ",
                   if (total) "Season-total table (ruling 2026-11-06); per-visit sibling strebel_2026_swiss_mhb_count. " else "Per-visit table; season totals in strebel_2026_swiss_mhb_total_count. ",
                   if (exact) "E7.3 sibling without the turtle dove." else "Coordinates coarsened (turtle dove VU); precise sibling " %+% sib[2] %+% ".",
                   " Four sensitive species withheld by the source."),
    source_via = "Zenodo")
  stage_tag_row(TABLE, ds, taxon_group = "Birds",
    model_family = if (total) "Abundance (territory counts, multi-season)" else "Community abundance (N-mixture) / community occupancy, multi-season",
    sampling_protocol = "territory_survey",
    design = if (total) "Multi-season (27 years x 1 season total)" else "Multi-season (27 years x 2-3 visits)",
    realm = "Terrestrial", country = "CHE",
    coordinates = if (exact) "As published (1 km square centroids)" else "Coarsened (0.1 deg)",
    notes = sprintf("National breeding bird monitoring, %d species; %s", ntx,
                    if (total) "totals include 1999-2012 surveys without per-visit values." else "per-visit values missing for 39,211 species x square-years (maps not digital, mostly 1999-2012); __survey_taxa for date limits."))
}
`%+%` <- function(a, b) paste0(a, b)
emit("strebel_2026_swiss_mhb_count", total = FALSE, exact = FALSE)
emit("strebel_2026_swiss_mhb_exact_count", total = FALSE, exact = TRUE)
emit("strebel_2026_swiss_mhb_total_count", total = TRUE, exact = FALSE)
emit("strebel_2026_swiss_mhb_total_exact_count", total = TRUE, exact = TRUE)
