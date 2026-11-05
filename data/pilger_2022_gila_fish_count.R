#!/usr/bin/env Rscript
# Table:  pilger_2022_gila_fish_count
# Source: Dryad doi:10.5061/dryad.sxksn0332, version 165279 (published 2022-02-23), licence CC0 1.0 (as shown on
#         the Dryad landing page and in the API record). Pilger, T. "Data from: Demography predicts genetic
#         effective size in a desert stream fish community".
# Paper:  Pilger, T. J. et al. (2022). Demography predicts genetic effective size in a desert stream fish
#         community. The American Naturalist, doi:10.1086/720208 (Dryad's primary_article; not read). Field methods
#         of the short-term ecological surveys: Whitney et al. (2014) Can. J. Fish. Aquat. Sci.,
#         doi:10.1139/cjfas-2014-0153 (cited in the deposit; not read). Design from the deposited README.txt.
# Data:   README.txt and six files. Used here:
#         Pilger_etal_fish_catch.csv: 40,802 rows, one per measured fish or batch of fish from the October surveys of
#           the "short-term ecological studies" in the upper Gila River basin, New Mexico, 2008-2017: Site ID (sample
#           id), Site Name, Date (m/d/Y), Month, Year, Habitat, Location, Gear (electrofishing, seine or both), Pass_number
#           (1-2), Mark, Species (six-letter code), SPP_SIZE, Count, TotalLength.mm. The README lists the nine
#           focal species used in the paper; the file also holds the other species caught (29 codes incl. two
#           spellings each of PYLOLI and Native tadpole).
#         Pilger_etal_fish_area.csv: 119 site-year rows (Site Name, Year, Month = October, Sum of Length (m), Average of
#           Width (m), Area (m2)): the area sampled at each site in each year (sample table).
#         Not used: Pilger_etal_metaNe_LTPA.csv (annual presence/absence of the nine focal species at long-term
#           NMDGF sites 1988-2010, rows only for species documented at a site), and the genetic and summary files
#           (metaNe_LHpars, metaNe_Nes, metaNe_stats: estimates).
#         Site-years: 121 in the catch file, 119 in the area file. Four 2014 site-years (Middle Box, Middle Fork,
#           Sunset Canal, West Fork) have catch but no area; "Sunset" 2017 in the catch is "Sunset Canal" 2017 in the
#           area file (only spelling, asserted); Black Canyon 2013 and 2014 have area but no catch rows.
# Mapping (standard E9 community counts, one survey per site-year):
#   unit = site; period = year (1 = 2008 ... 10 = 2017; __periods has the year); no occasion (one October survey
#   per site-year, over 1-2 days); taxon = species code; y = individuals caught (sum of Count over gears, passes,
#   habitats and locations). Survey evidence: sample_table, the area file's site-years plus the four 2014
#   site-years with catch but no area (obs_area_m2 NA there). Every recorded taxon gets a row at every survey
#   (y = 0 where not caught). obs_area_m2, obs_length_m, obs_width_m (area file), obs_n_passes, obs_gear (gears
#   used that year at the site), date = first day of the site-year's sampling, obs_n_days.
#   Not shipped: Black Canyon 2013 and 2014 (area sampled but no catch rows: zero catch or missing records is not
#   stated); individual lengths, marks and mesohabitat detail (sub-survey records); the LTPA file (species rows
#   only where documented, so the zeros for the other focal species cannot be told from "not listed"); the
#   genetic and demographic estimates. No coordinates in the deposit (spikedace and Gila trout IUCN EN, loach minnow VU).
#   IUCN: four categories set by hand from the IUCN record GBIF returns (see below), where the assessed name
#   differs from GBIF's accepted name.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "pilger_2022_gila_fish_count"
dir <- download_dryad("10.5061/dryad.sxksn0332", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), identical(attr(dir, "version"), "165279"),
          length(list.files(dir)) == 7L)
ct <- fread(file.path(dir, "Pilger_etal_fish_catch.csv"), encoding = "Latin-1")
ar <- fread(file.path(dir, "Pilger_etal_fish_area.csv"))
setnames(ct, c("Site Name", "TotalLength.mm"), c("site", "tl")); setnames(ar, c("Site Name", "Sum of Length (m)", "Average of Width (m)"), c("site", "len", "wid"))
stopifnot(nrow(ct) == 40802L, nrow(ar) == 119L, all(ct$Month == "October"), all(ar$Month == "October"),
          all(ct$Count >= 1L), !anyNA(ct$Count), all(ct$Pass_number %in% 1:2), !anyDuplicated(ar[, .(site, Year)]))
ct[site == "Sunset", site := "Sunset Canal"]
ct[Species %in% c("PYlOLI"), Species := "PYLOLI"]; ct[Species %in% c("Native tadpole", "Native Tadpole"), Species := "NATTAD"]
ct[, date := as.IDate(Date, format = "%m/%d/%Y")]
stopifnot(!anyNA(ct$date), all(year(ct$date) == ct$Year))
cy <- unique(ct[, .(site, Year)]); ay <- ar[, .(site, Year)]
no_area <- fsetdiff(cy, ay); no_catch <- fsetdiff(ay, cy)
stopifnot(nrow(no_area) == 4L, all(no_area$Year == 2014L), setequal(no_area$site, c("Middle Box", "Middle Fork", "Sunset Canal", "West Fork")),
          nrow(no_catch) == 2L, all(no_catch$site == "Black Canyon"), setequal(no_catch$Year, 2013:2014))
surveys <- merge(cy, ar[, .(site, Year, obs_length_m = len, obs_width_m = round(wid, 3), obs_area_m2 = round(Area, 2))], by = c("site", "Year"), all.x = TRUE)
stopifnot(nrow(surveys) == 121L - 4L + 4L, sum(is.na(surveys$obs_area_m2)) == 4L)
sv <- ct[, .(date = format(min(date)), obs_n_days = uniqueN(date), obs_n_passes = max(Pass_number),
             obs_gear = paste(sort(unique(tolower(sub("Shock", "Electrofishing", Gear[Gear != ""])))), collapse = "; ")), by = .(site, Year)]
surveys <- merge(surveys, sv, by = c("site", "Year"))
surveys[obs_gear == "", obs_gear := NA_character_]
tx <- sort(unique(ct$Species)); stopifnot(length(tx) == 26L)
cnt <- ct[, .(y = sum(Count)), by = .(site, Year, taxon = Species)]
long <- CJ(k = seq_len(nrow(surveys)), taxon = tx)
long <- cbind(surveys[long$k], taxon = long$taxon)
long <- merge(long, cnt, by = c("site", "Year", "taxon"), all.x = TRUE)
stopifnot(nrow(cnt) == nrow(long[!is.na(y)]))
long[is.na(y), y := 0L]
stopifnot(sum(long$y) == sum(ct$Count), nrow(long) == 121L * 26L)
yrs <- 2008:2017
long[, `:=`(unit = site, period = match(Year, yrs))]
long[, c("site", "Year") := NULL]
long <- order_eco(long)
cat(sprintf("  %d site-years at %d sites, %d taxa, %d fish\n", nrow(surveys), uniqueN(long$unit), length(tx), sum(long$y)))

sp <- data.table(taxon = tx)
sci <- c(AGOCHR = "Agosia chrysogaster", AMENAT = "Ameiurus natalis", CATINS = "Catostomus insignis", CYPCAR = "Cyprinus carpio",
         CYPLUT = "Cyprinella lutrensis", GAMAFF = "Gambusia affinis", GILNIG = "Gila nigra", ICTPUN = "Ictalurus punctatus",
         ICTSPP = "Ictalurus", LEPCYA = "Lepomis cyanellus", LEPMAC = "Lepomis macrochirus", LITCAT = "Lithobates catesbeianus",
         MEDFUL = "Meda fulgida", MICDOL = "Micropterus dolomieu", MICSAL = "Micropterus salmoides", NATTAD = "Anura",
         ONCGIL = "Oncorhynchus gilae", ONCMYK = "Oncorhynchus mykiss", ORCVIR = "Faxonius virilis", PANCLA = "Pantosteus clarkii",
         PANPLE = "Pantosteus plebeius", PIMPRO = "Pimephales promelas", PYLOLI = "Pylodictis olivaris", RHIOSC = "Rhinichthys osculus",
         SALTRU = "Salmo trutta", TIACOB = "Tiaroga cobitis")
stopifnot(setequal(names(sci), tx))
rank <- fifelse(tx == "ICTSPP", "genus", fifelse(tx == "NATTAD", "order", "species"))
vern <- c(AGOCHR = "Longfin dace", AMENAT = "Yellow bullhead", CATINS = "Sonora sucker", CYPCAR = "Common carp", CYPLUT = "Red shiner",
          GAMAFF = "Western mosquitofish", GILNIG = "Headwater chub", ICTPUN = "Channel catfish", ICTSPP = "Ictalurus catfish (unidentified)",
          LEPCYA = "Green sunfish", LEPMAC = "Bluegill", LITCAT = "American bullfrog", MEDFUL = "Spikedace", MICDOL = "Smallmouth bass",
          MICSAL = "Largemouth bass", NATTAD = "native anuran tadpoles (unidentified)", ONCGIL = "Gila trout", ONCMYK = "Rainbow trout",
          ORCVIR = "Virile crayfish", PANCLA = "Desert sucker", PANPLE = "Rio Grande sucker", PIMPRO = "Fathead minnow",
          PYLOLI = "Flathead catfish", RHIOSC = "Speckled dace", SALTRU = "Brown trout", TIACOB = "Loach minnow")
taxa <- make_taxa(tx, unname(sci[tx]), vernacularName = unname(vern[tx]), taxonRank = rank, allow_higher = "ICTSPP", no_key = "NATTAD",
                  taxonRemarks = fifelse(tx == "NATTAD", "deposit code 'Native tadpole': unidentified native anuran tadpoles; no single GBIF key (GBIF strict match for Anura returns none)", NA_character_))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# set by hand from the IUCN records GBIF returns (the assessed name differs from GBIF's accepted name for the key):
# Lithobates catesbeianus LC (assessed as Aquarana catesbeianus, IUCN 58565), Pantosteus clarkii LC (62193),
# Pantosteus plebeius DD (191238), Tiaroga cobitis VU (39285)
hand <- c(LITCAT = "LC", PANCLA = "LC", PANPLE = "DD", TIACOB = "VU")
stopifnot(all(is.na(taxa[taxon %in% names(hand), taxon_iucnCategory])))
taxa[taxon %in% names(hand), taxon_iucnCategory := hand[taxon]]
stopifnot(identical(taxa[taxon_iucnCategory %in% c("VU", "EN", "CR"), sort(taxon)], c("MEDFUL", "ONCGIL", "TIACOB")))
periods <- data.table(period = seq_along(yrs), period_year = yrs, period_month = "October")

dataset <- list(
  title = "Fish and other aquatic animals caught by electrofishing and seining at 16 sites in the upper Gila River basin, New Mexico, each October 2008-2017",
  creator = "Pilger, Tyler",
  pubDate = "2022", doi = "10.5061/dryad.sxksn0332", sourceURL = "https://doi.org/10.5061/dryad.sxksn0332",
  citation = "Pilger, T. (2022). Data from: Demography predicts genetic effective size in a desert stream fish community [Dataset]. Dryad. https://doi.org/10.5061/dryad.sxksn0332",
  paperDOI = "10.1086/720208",
  abstract = "Annual October surveys of stream reaches in the upper Gila River basin, New Mexico (Gila, West, Middle and East Forks and tributaries), by electrofishing and seining in one or two passes, from the short-term ecological studies that accompany the New Mexico Department of Game and Fish long-term monitoring; 6 sites a year in 2008-2010, 11-16 from 2011. Catch is summed per site, year and taxon, with the reach length, width and area sampled. Native desert fishes (longfin dace, spikedace, loach minnow, headwater chub, Sonora and desert suckers, speckled dace) are caught alongside introduced fishes, bullfrogs and crayfish. The authors used the densities of nine native and introduced species, with genetic data, to relate demography to genetic effective size.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Each October, a reach of about 100-400 m at each site sampled by backpack electrofishing and seining (one or two passes) across its mesohabitats; every fish counted and measured; reach length and mean width recorded.",
  samplingProtocolCode = "electrofishing", surveyEvidence = "sample_table",
  responseType = "count", unitKind = "site",
  closure = "none", closureNote = "one survey per site per year; period = year",
  occasionKind = "none", taxonInclusion = "recorded",
  geographicCoverage = "Upper Gila River basin, Grant and Catron Counties, New Mexico, USA (no coordinates in the deposit)",
  temporalCoverage = "2008-10/2017-10",
  covariateNote = "obs_length_m, obs_width_m, obs_area_m2: reach length sampled, mean wetted width and area (area file; NA for four 2014 site-years absent from it). obs_n_passes: 1 or 2. obs_gear: gears recorded in the site-year's catch rows. date: the first day of the site-year's sampling; obs_n_days: days it spanned (1-2).",
  notShipped = list(
    black_canyon = "Black Canyon 2013 and 2014: the area file records a sampled reach but the catch file has no rows; the deposit does not say whether nothing was caught or the records are missing.",
    individual_records = "total lengths, marks, mesohabitat, location within reach and pass of each fish: sub-survey detail, summed into y",
    ltpa = "Pilger_etal_metaNe_LTPA.csv (annual presence/absence of nine species at long-term sites 1988-2010): rows exist only for species documented at a site, so the zeros for the others cannot be told from 'not listed'",
    estimates = "the effective-size, Fst, migration and occupancy estimates in the metaNe files"),
  notes = "Catch codes are the authors' six-letter codes; 'PYlOLI' is merged into PYLOLI and the two spellings of 'Native tadpole' into NATTAD (order Anura); ICTSPP is an unidentified Ictalurus. 'Sunset' (2017) is 'Sunset Canal' in the area file and is merged. The survey set is the area file's 119 site-years less the two Black Canyon years, plus four 2014 site-years with catch but no area. Every recorded taxon has a row at every survey, so a non-fish taxon (bullfrog, crayfish, tadpoles) has zeros where it was not caught; whether those were always recorded is not stated.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/pilger_2022_gila_fish_count.R")
stage_dict_row(TABLE,
  description = "Annual October electrofishing and seining catch of 26 fish and other aquatic taxa at 16 stream sites in the upper Gila River basin, New Mexico, 2008-2017, with reach area sampled.",
  url = "https://doi.org/10.5061/dryad.sxksn0332",
  reference = "Pilger, T. J., et al. (2022). Demography predicts genetic effective size in a desert stream fish community. The American Naturalist.",
  doi_paper = "10.1086/720208", doi_data = "10.5061/dryad.sxksn0332",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip; catch summed per site-year-taxon; area file as sample table; two Black Canyon years and the LTPA file not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "N-mixture (community counts, one survey per site-year)",
  sampling_protocol = "electrofishing", design = "Multi-season (10 annual surveys, one per site-year)",
  realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Desert stream fishes with native and introduced species; area sampled as effort.")
