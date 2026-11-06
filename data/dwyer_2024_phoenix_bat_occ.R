#!/usr/bin/env Rscript
# Table:  dwyer_2024_phoenix_bat_occ
# Source: Dryad doi:10.5061/dryad.w6m905qx2, version 287284 (published 2024-04-08), CC0 1.0 (Dryad metadata,
#         asserted; the README says "CC0 1.0 Universal (CC0 1.0) Public Domain"). Lewis, J., Dwyer, J. & Moore, M.
#         Trade-offs in habitat use and occupancy of bats across the gradient of urbanization and seasons.
#         Raw files read from batch 35's cache (no Dryad request in batch 47).
# Paper:  Dwyer, J. M., Lewis, J. S. & Moore, M. S. (2024). Trade-offs in habitat use and occupancy of bats
#         across the gradient of urbanization and seasons. Ecosphere 15, e4884. doi:10.1002/ecs2.4884 (PDF
#         supplied by Ben, not committed). 50 sites in the Phoenix metropolitan area, Arizona, below 550 m,
#         stratified over five urbanization classes, > 2 km apart (one > 1.5 km); one stationary passive
#         acoustic monitor per site for five consecutive nights, sunset to sunrise, in each of four seasons of
#         2019 (winter 7 Jan-1 Mar, spring 8 Apr-31 May, summer 8 Jul-30 Aug, fall 7 Oct-29 Nov); sites in six
#         groups surveyed in random order. Species identification: SonoBat 4.2.2 automated pass (quality 0.80)
#         to remove noise, then manual identification of every call following NABat guidelines; a species is
#         detected on a night when a voucher file (one confidently identified recording per species per
#         night) was selected. Nyctinomops femorosaccus and N. macrotis are combined as Nyctinomops sp.; Myotis
#         with 35-45 kHz calls (M. auriculus, M. ciliolabrum, M. occultus, M. velifer, M. volans) as
#         "40 kHz Myotis" (most likely M. velifer). Table 1: nightly occasions and sites with a detection per
#         species and season; "5 nightly occasions at each of the 50 sites per season".
# Data:   46 files <CODE>_S<k><Season>_input.txt (k = 1 winter, 2 spring, 3 summer, 4 fall), one per species x
#         season with any detection, each 50 rows (Site 1-50): ch = five-night detection history (0/1, no
#         missing night), Week (week of the season the site was surveyed, 1-8), UrbanCat (1-3), Urb<r> =
#         proportion urbanized within r m (125-2000), NDVI<r>, Water (distance to water, m), MinTemp1-5 and
#         Moon1-5 (per night), their averages, standardized (S) and quadratic (Q) versions, and undocumented
#         U<r>N<r> columns. The README lists the species codes but never expands them; they are the NABat
#         four-letter codes, and each code's detections per season equal one row of the paper's Table 1
#         (asserted; one cell differs: Nyctinomops in fall, 20 detection-nights in the deposit, 21 in Table 1, at the
#         same 11 sites): 40MY 40 kHz Myotis, ANPA Antrozous pallidus, COTO Corynorhinus townsendii, EPFU Eptesicus
#         fuscus, EUPE Eumops perotis, LABL Lasiurus blossevillii, LACI Lasiurus cinereus, LANO Lasionycteris
#         noctivagans, LAXA Lasiurus xanthinus, MYCA Myotis californicus, MYYU Myotis yumanensis, NYSP
#         Nyctinomops sp. (big/pocketed free-tailed bat), PAHE Parastrellus hesperus, TABR Tadarida brasiliensis.
#         The 10 species x seasons with no file are exactly the cells of Table 1 with 0 occasions (asserted).
#         Site-level covariates (Urb, NDVI, Water) differ slightly between seasons for a site (the monitor's
#         placement each season), constant within site x season across the species files (asserted).
# Mapping (dynamic / multi-season community occupancy): unit = site, period = season (1 winter ... 4 fall),
#   occasion = night 1-5, taxon = the 14 codes (taxonInclusion recorded: every taxon the survey identified),
#   y = night detected. One detector surveys all species (a shared detector), and every site was surveyed five
#   nights each season (the paper's Table 1 note; every file has 50 sites x 5 nights, no missing night), so the
#   survey set is 50 x 4 x 5 and a species x season with no file is y = 0 at every survey (surveyEvidence =
#   deposited_matrix, with Table 1's zeros for the absent files). Detections are the authors' manual
#   identifications after an automated noise filter (the source's call, automated-detections ruling).
#   unit_urban_cat; period_week, period_urb_<r>, period_ndvi_<r>, period_water_m (constant within site x
#   season); obs_min_temp_c and obs_moon_pct per night.
# Not shipped: standardized and quadratic versions (UrbS, UrbQ, NDVIS, WaterS, AvSMinTemp, AvSMoon:
#   recoverable), the season averages AvgMinTemp and AvgMoon (means of the nightly values shipped), and the
#   undocumented U<r>N<r> columns. No coordinates or dates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "dwyer_2024_phoenix_bat_occ"
dir <- download_dryad("10.5061/dryad.w6m905qx2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), attr(dir, "version") == "287284")
fs <- list.files(dir, "_input\\.txt$")
stopifnot(length(fs) == 46L, all(grepl("^[0-9A-Z]{4}_S[1-4](Winter|Spring|Summer|Fall)_input\\.txt$", fs)))
x <- rbindlist(lapply(fs, function(f) {
  d <- fread(file.path(dir, f), colClasses = list(character = "ch"))
  d[, `:=`(code = substr(f, 1, 4), season = as.integer(substr(f, 7, 7)))]
  d[, .(code, season, Site, ch, Week, UrbanCat, Urb125, Urb250, Urb500, Urb1000, Urb2000,
        NDVI125, NDVI250, NDVI500, NDVI1000, NDVI2000, Water, MinTemp1, MinTemp2, MinTemp3, MinTemp4, MinTemp5,
        Moon1, Moon2, Moon3, Moon4, Moon5)]
}))
stopifnot(all(x[, .N, by = .(code, season)]$N == 50L), x[, all(sort(Site) == 1:50), by = .(code, season)]$V1,
          all(grepl("^[01]{5}$", x$ch)), uniqueN(x$code) == 14L)
# site x season facts are the same in every species' file
SV <- c("Week", "UrbanCat", "Urb125", "Urb250", "Urb500", "Urb1000", "Urb2000", "NDVI125", "NDVI250", "NDVI500",
        "NDVI1000", "NDVI2000", "Water", paste0("MinTemp", 1:5), paste0("Moon", 1:5))
for (v in SV) stopifnot(x[, uniqueN(get(v)), by = .(Site, season)][, all(V1 == 1L)])
stopifnot(x[, uniqueN(UrbanCat), by = Site][, all(V1 == 1L)])
# Table 1 of the paper (occasions, sites per season W, Sp, Su, F) identifies each code
tab1 <- fread(text = "code,name,o1,s1,o2,s2,o3,s3,o4,s4
EPFU,Big brown bat,0,0,13,9,18,9,0,0
NYSP,Big/pocketed free-tailed bat,22,13,23,13,12,8,21,11
MYCA,California myotis,0,0,16,7,40,18,6,6
PAHE,Canyon bat,43,17,92,29,184,48,77,27
LACI,Hoary bat,7,7,16,10,6,6,0,0
TABR,Mexican free-tailed bat,157,48,188,50,160,42,120,44
ANPA,Pallid bat,0,0,4,2,8,4,0,0
LANO,Silver-haired bat,0,0,2,2,3,2,8,7
COTO,Townsend's big-eared bat,0,0,1,1,3,2,1,1
EUPE,Western mastiff bat,6,6,10,4,3,2,8,5
LABL,Western red bat,11,9,9,4,3,3,13,9
LAXA,Western yellow bat,16,12,41,21,63,35,25,16
MYYU,Yuma myotis,5,4,32,16,44,17,21,15
40MY,40 kHz Myotis,0,0,14,9,26,12,0,0")
t1 <- rbindlist(lapply(1:4, function(k) tab1[, .(code, season = k, occ = get(paste0("o", k)), sites = get(paste0("s", k)))]))
obs <- x[, .(occ = sum(nchar(gsub("0", "", ch))), sites = sum(grepl("1", ch))), by = .(code, season)]
cmp <- merge(t1, obs, by = c("code", "season"), all = TRUE, suffixes = c("", ".d"))
# one cell differs: Nyctinomops in fall has 20 nights with a detection in the deposit, 21 in Table 1 (sites agree, 11)
stopifnot(cmp[!is.na(occ.d) & (occ != occ.d | sites != sites.d), identical(paste(code, season, occ, occ.d, sites, sites.d), "NYSP 4 21 20 11 11")])
stopifnot(nrow(cmp) == 56L, cmp[!is.na(occ.d), sum(occ != occ.d | sites != sites.d)] == 1L,
          cmp[is.na(occ.d), all(occ == 0L & sites == 0L)], cmp[is.na(occ.d), .N] == 10L)

# --- long: every site x season x night x taxon --------------------------------------------------------
ss <- unique(x[, c("Site", "season", SV), with = FALSE])
stopifnot(nrow(ss) == 200L)
nights <- ss[rep(seq_len(.N), each = 5)][, occasion := rep(1:5, times = 200)]
nights[, obs_min_temp_c := fcase(occasion == 1L, MinTemp1, occasion == 2L, MinTemp2, occasion == 3L, MinTemp3, occasion == 4L, MinTemp4, occasion == 5L, MinTemp5)]
nights[, obs_moon_pct := fcase(occasion == 1L, Moon1, occasion == 2L, Moon2, occasion == 3L, Moon3, occasion == 4L, Moon4, occasion == 5L, Moon5)]
det <- x[, .(occasion = 1:5, y = as.integer(strsplit(ch, "")[[1]])), by = .(code, season, Site)]
long <- CJ(code = tab1$code, idx = seq_len(nrow(nights)))
long <- cbind(long, nights[long$idx])
long <- merge(long, det, by = c("code", "season", "Site", "occasion"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- long[, .(unit = Site, taxon = code, y, period = season, occasion,
                 unit_urban_cat = UrbanCat, period_week = Week,
                 period_urb_125 = Urb125, period_urb_250 = Urb250, period_urb_500 = Urb500, period_urb_1000 = Urb1000, period_urb_2000 = Urb2000,
                 period_ndvi_125 = NDVI125, period_ndvi_250 = NDVI250, period_ndvi_500 = NDVI500, period_ndvi_1000 = NDVI1000, period_ndvi_2000 = NDVI2000,
                 period_water_m = Water, obs_min_temp_c, obs_moon_pct)]
long <- order_eco(long)
stopifnot(nrow(long) == 50L * 4L * 5L * 14L, sum(long$y) == sum(obs$occ), !anyDuplicated(long[, .(unit, taxon, period, occasion)]))
cat(sprintf("  %d rows, %d detections (species-nights)\n", nrow(long), sum(long$y)))

taxa <- make_taxa(
  c("40MY", "ANPA", "COTO", "EPFU", "EUPE", "LABL", "LACI", "LANO", "LAXA", "MYCA", "MYYU", "NYSP", "PAHE", "TABR"),
  c("Myotis auriculus/ciliolabrum/occultus/velifer/volans", "Antrozous pallidus", "Corynorhinus townsendii", "Eptesicus fuscus",
    "Eumops perotis", "Lasiurus blossevillii", "Lasiurus cinereus", "Lasionycteris noctivagans", "Lasiurus xanthinus",
    "Myotis californicus", "Myotis yumanensis", "Nyctinomops", "Parastrellus hesperus", "Tadarida brasiliensis"),
  vernacularName = c("40 kHz Myotis", "Pallid bat", "Townsend's big-eared bat", "Big brown bat", "Western mastiff bat", "Western red bat",
                     "Hoary bat", "Silver-haired bat", "Western yellow bat", "California myotis", "Yuma myotis",
                     "Big/pocketed free-tailed bat", "Canyon bat", "Mexican free-tailed bat"),
  taxonRank = c("speciesGroup", rep("species", 10), "genus", rep("species", 2)),
  no_key = "40MY",
  taxonRemarks = c("the authors' '40 kHz Myotis': calls of Myotis auriculus, M. ciliolabrum, M. occultus, M. velifer and M. volans, not separable acoustically (most likely M. velifer, paper); not a GBIF taxon, so taxonID is empty",
                   rep(NA, 10), "Nyctinomops femorosaccus and N. macrotis combined (acoustically indistinguishable, paper)", NA, NA))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[, .(taxon, scientificName, gbifMatchType, taxon_iucnCategory)])
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
periods <- data.table(period = 1:4, season = c("winter", "spring", "summer", "fall"), year = 2019L,
                      window = c("2019-01-07/2019-03-01", "2019-04-08/2019-05-31", "2019-07-08/2019-08-30", "2019-10-07/2019-11-29"))
dataset <- list(
  title = "Acoustic detections of 14 bat taxa on five nights per season at 50 sites across the urbanization gradient of Phoenix, Arizona, in four seasons of 2019",
  creator = "Lewis, Jesse; Dwyer, Jessie; Moore, Marianne", pubDate = "2024",
  doi = "10.5061/dryad.w6m905qx2", sourceURL = "https://doi.org/10.5061/dryad.w6m905qx2",
  citation = "Lewis, J., Dwyer, J. & Moore, M. (2024). Trade-offs in habitat use and occupancy of bats across the gradient of urbanization and seasons [Dataset]. Dryad. https://doi.org/10.5061/dryad.w6m905qx2",
  paperDOI = "10.1002/ecs2.4884",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Passive acoustic monitors recorded bats for five consecutive nights in each of four seasons of 2019 at 50 sites stratified across the urbanization gradient of the Phoenix metropolitan area, Arizona. Calls were filtered automatically and identified manually; a species is detected on a night when a confidently identified voucher call was found. The authors fitted Royle-Nichols and single-season occupancy models per species and season against urbanization, vegetation greenness and distance to water.",
  samplingProtocol = "One stationary passive acoustic bat monitor per site recording from sunset to sunrise on five consecutive nights in each season (winter, spring, summer, fall 2019); calls filtered with SonoBat 4.2.2 (quality 0.80) and identified manually under NABat guidelines; one voucher call per species per night.",
  samplingProtocolCode = "acoustic", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "Every species x season file holds all 50 sites x 5 nights with no missing night, and the paper states 5 nightly occasions at each of the 50 sites in every season. The 10 species x seasons with no file are the cells of the paper's Table 1 with no detection (asserted); one monitor surveys all species, so they are y = 0 at every survey.",
  responseType = "detection", unitKind = "site", closure = "closed",
  closureNote = "closed within a season (five consecutive nights), open between seasons", occasionKind = "time",
  taxonInclusion = "recorded",
  geographicCoverage = "Phoenix metropolitan area, Maricopa County, Arizona, USA, below 550 m (no site coordinates deposited)",
  temporalCoverage = "2019-01/2019-11",
  covariateNote = "unit_urban_cat: urbanization category (1 low, 2 moderate, 3 high). period_week: week of the season in which the site was surveyed. period_urb_<r>: proportion urbanized (impervious surface, NAIP 2010) within r m; period_ndvi_<r>: mean NDVI (Landsat 8) within r m; period_water_m: distance to the nearest water (m); these vary slightly between seasons for a site, as deposited. obs_min_temp_c: minimum temperature of the night (deg C); obs_moon_pct: lunar illumination at 23:00 (per cent).",
  notShipped = list(standardized = "UrbS, UrbQ, NDVIS, WaterS, AvSMinTemp, AvSMoon: standardized and quadratic versions of shipped covariates",
                    season_means = "AvgMinTemp, AvgMoon: means of the nightly values shipped",
                    undocumented = "U<r>N<r> columns, which the README does not define"),
  notes = "Species codes are NABat four-letter codes, which the README does not expand; each code's nightly detections and sites per season equal one row of the paper's Table 1 (asserted), except Nyctinomops in fall, 20 detection-nights in the deposit and 21 in Table 1 (both at 11 sites). Detections are manual identifications after an automated noise filter (the authors' call).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/dwyer_2024_phoenix_bat_occ.R")
stage_dict_row(TABLE,
  description = "Nightly acoustic detections of 14 bat taxa at 50 sites across the Phoenix, Arizona, urbanization gradient, five nights in each of four seasons of 2019, with urbanization, NDVI, distance to water, nightly temperature and moonlight.",
  url = "https://doi.org/10.5061/dryad.w6m905qx2",
  reference = "Dwyer, J. M., Lewis, J. S. & Moore, M. S. (2024). Trade-offs in habitat use and occupancy of bats across the gradient of urbanization and seasons. Ecosphere 15, e4884. https://doi.org/10.1002/ecs2.4884",
  doi_paper = "10.1002/ecs2.4884", doi_data = "10.5061/dryad.w6m905qx2", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Species codes resolved against the paper's Table 1 (PDF supplied by Ben); read from batch 35's cache.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic occupancy (multi-species)",
  sampling_protocol = "acoustic", design = "Multi-season (4 seasons x 5 nights)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Urban bats; manual call identification; seasons as periods.")
