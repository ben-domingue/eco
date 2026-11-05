#!/usr/bin/env Rscript
# Table:  cumming_2021_ngami_waterbird_count
# Source: Dryad doi:10.5061/dryad.w0vt4b8rd, version 138175 (version 11, published 2021-09-03),
#         licence CC0 1.0 (as shown on the Dryad landing page and in the API record). The deposited
#         readme adds "must cite original publications (in Dryad and Ecosphere)": an attribution
#         request, recorded in original_license; the citation is carried in the metadata.
#         Cumming, G. S. & Henry, D. A. W. "Understanding arid-region waterbird community dynamics
#         during lake dry-downs".
# Paper:  Cumming, G. S., Henry, D. A. W., Mutumi, G. L. & Ndlovu, M. (2021). Understanding arid-region
#         waterbird community dynamics during lake dry-downs. Ecosphere 12(8), e03668,
#         doi:10.1002/ecs2.3668 (not read; design from the deposited readme and workbook).
# Data:   four files.
#   Cumming_Ecosphere_NgamiCountData_readme.txt  methods, variables, licence note (read).
#   Cumming_Ecosphere_NgamiCountData_v1.xlsx     sheet 1 "original data": 4,392 records, one per
#            species per point count (Location NGA, Mission NGA1..NGA6, Site 1..14 (14 only on trip NGA5), Species (Roberts
#            2005 common name), numbers Foraging / Not_foraging / Flying_over, Day, Month, Year,
#            Start_time, End_time). 228 distinct counts (mission x site x day x start time); a few
#            species appear on two records of one count (summed here). One record with no species
#            (NGA6 site 11, 2 June 2009, 09:32) is a count at which nothing was recorded.
#            Sheets 2-4 are the authors' pivot and averaging of sheet 1 (not shipped); sheet 5 "site
#            coordinates lat-long" gives each site's latitude and longitude (WGS 84) and the lake area
#            per mission from MODIS (km2).
#   NgamiCountData2.txt   sheet 4 as text: per mission x site the authors' averaged numbers (derived;
#            not shipped). Its Xcoord/Ycoord columns hold latitude/longitude respectively.
#   NgamiGuilds.txt       numeric class and guild codes per species, undefined in the deposit (not shipped).
#   Design (readme): half-hour point counts of all birds within 150 m of a stationary observer at
#   fixed points around Lake Ngami, Botswana; six field trips ("missions", about a week each) between
#   October 2007 and June 2009 during successive dry-downs; sites disappear when the water is low.
#
# Mapping (standard E9 community abundance / N-mixture, responseType count, unitKind site):
#   unit = site (1..14; site 14 has no deposited coordinates: unit_lat/unit_lon NA), taxon = 6-letter code from the scientific name, period = mission 1..6
#   (NGA1..NGA6, in time order), occasion = the count's order within site x mission (by date then
#   start time), y = individuals counted (foraging + not foraging + flying over, as the authors'
#   averages use); obs_n_foraging, obs_n_not_foraging, obs_n_flying_over the three parts (vary across
#   taxa within a count, E5); date; obs_start_time; obs_duration_min (NA where the recorded end is
#   before the start). unit_lat, unit_lon coarsened (below). __periods: mission label, month, lake area.
#   Survey evidence: row_presence. A count is a survey where sheet 1 has at least one record for it
#   (the empty NGA6 count is its own record); every one of the 182 species gets a row at every count.
#   Taxa: the Roberts common names are matched to the eBird/Clements taxonomy (en and en_ZA locales,
#   fetched 2026-11-05) and the 14 names that differ are mapped by hand below; GBIF resolves each.
#   Coordinates: the community includes IUCN EN / VU species in their native range (asserted from
#   taxon_iucnCategory), so site coordinates (deposited to 1e-8 degree) are coarsened to the 0.1 degree
#   cell with coarsen_coords() (E7).
#   Not shipped: the authors' averaged sheets and file; guild codes (undefined); exact coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressMessages(library(readxl))
TABLE <- "cumming_2021_ngami_waterbird_count"
dir <- download_dryad("doi:10.5061/dryad.w0vt4b8rd", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "138175"), length(list.files(dir)) == 4L)
xl <- file.path(dir, "Cumming_Ecosphere_NgamiCountData_v1.xlsx")
stopifnot(identical(excel_sheets(xl), c("1) original data", "2) summary pivot table", "3) edits for R with formulae",
                                        "NgamiCountData1.txt", "site coordinates lat-long")),
          any(grepl("must cite original publications", readLines(file.path(dir, "Cumming_Ecosphere_NgamiCountData_readme.txt")))))
d <- as.data.table(suppressMessages(read_excel(xl, 1, skip = 5)))
stopifnot(identical(names(d), c("Location", "Mission", "Site", "Species", "Foraging", "Not_foraging", "Flying_over",
                                "Day", "Month", "Year", "Start_time", "End_time")),
          nrow(d) == 4392L, all(d$Location == "NGA"), all(d$Mission %in% paste0("NGA", 1:6)), all(d$Site %in% 1:14), identical(unique(d[Site == 14, Mission]), "NGA5"),
          !anyNA(d[, .(Day, Month, Year, Start_time, End_time, Foraging, Not_foraging, Flying_over)]))
d[, `:=`(date = as.IDate(sprintf("%04d-%02d-%02d", Year, Month, Day)), st = format(Start_time, "%H:%M"),
         et = format(End_time, "%H:%M"), period = as.integer(sub("NGA", "", Mission)))]
stopifnot(!anyNA(d$date), d[is.na(Species), .N] == 1L,
          d[is.na(Species), Mission == "NGA6" & Site == 11 & Foraging + Not_foraging + Flying_over == 0])

counts <- unique(d[, .(unit = as.character(Site), period, date, st, et)])
setorder(counts, period, unit, date, st)
counts[, occasion := seq_len(.N), by = .(unit, period)]
dur <- as.integer(difftime(as.POSIXct(counts$et, format = "%H:%M", tz = "UTC"), as.POSIXct(counts$st, format = "%H:%M", tz = "UTC"), units = "mins"))
counts[, obs_duration_min := fifelse(dur > 0, dur, NA_integer_)]
stopifnot(nrow(counts) == 228L, nrow(unique(counts[, .(unit, period, date, st)])) == 228L,
          sum(dur == 30L) == 221L, sum(dur <= 0) == 1L, max(counts$occasion) == 7L,
          identical(counts[, .(m = min(date)), by = period][order(period), format(m, "%Y-%m")],
                    c("2007-10", "2008-01", "2008-06", "2008-10", "2009-02", "2009-06")))

# taxa: Roberts common names -> scientific names
eb_f <- file.path(RAW_DIR, TABLE, c("ebird_taxonomy_en.csv", "ebird_taxonomy_en_ZA.csv"))
for (i in 1:2) if (!file.exists(eb_f[i]))
  download.file(sprintf("https://api.ebird.org/v2/ref/taxonomy/ebird?fmt=csv&locale=%s", c("en", "en_ZA")[i]), eb_f[i], quiet = TRUE)
norm <- function(x) gsub("[^a-z]", "", tolower(x))
eb <- rbindlist(lapply(eb_f, fread))[CATEGORY == "species", .(com = COMMON_NAME, sci = SCIENTIFIC_NAME)]
alias <- rbind(eb[, .(k = norm(com), sci)],
               eb[grepl("^.* \\(.*\\) .*$", com), .(k = norm(sub("^(.*) \\((.*)\\) (.*)$", "\\1 \\3", com)), sci)],
               eb[grepl("^.* \\(.*\\) .*$", com), .(k = norm(sub("^(.*) \\((.*)\\) (.*)$", "\\2 \\3", com)), sci)],
               eb[grepl("\\)$", com), .(k = norm(sub(" \\(.*\\)$", "", com)), sci)],
               eb[grepl("\\)$", com), .(k = norm(sub("^.*\\((.*)\\)$", "\\1", com)), sci)])
alias <- unique(alias)[, .(sci = if (uniqueN(sci) == 1L) sci[1] else NA_character_), by = k]
hand <- c("African Quailfinch" = "Ortygospiza atricollis", "African Reed-Warbler" = "Acrocephalus baeticatus",
          "Cattle Egret" = "Bubulcus ibis", "Common House Martin" = "Delichon urbicum",
          "Diderick Cuckoo" = "Chrysococcyx caprius", "Fulvous Duck" = "Dendrocygna bicolor",
          "Green-backed Heron" = "Butorides striata", "Grey-backed Camaroptera" = "Camaroptera brevicaudata",
          "Hottentot Teal" = "Spatula hottentota", "Southern Pale Chanting Goshawk" = "Melierax canorus",
          "White-faced Duck" = "Dendrocygna viduata", "Woolly-necked Stork" = "Ciconia microscelis",
          "Yellow Wagtail" = "Motacilla flava", "Yellow-billed Kite" = "Milvus aegyptius")
sp <- data.table(com = sort(unique(na.omit(d$Species))))
sp[, sci := alias$sci[match(norm(com), alias$k)]]
stopifnot(nrow(sp) == 182L, setequal(sp[is.na(sci), com], names(hand)))
sp[is.na(sci), sci := hand[com]]
stopifnot(!anyDuplicated(sp$sci))
code6 <- function(s) { w <- strsplit(s, " ")[[1]]; toupper(paste0(substr(w[1], 1, 3), substr(w[2], 1, 3))) }
sp[, taxon := vapply(sci, code6, "")]
stopifnot(!anyDuplicated(sp$taxon))

rec <- d[!is.na(Species), .(n_for = sum(Foraging), n_nf = sum(Not_foraging), n_fly = sum(Flying_over)),
         by = .(unit = as.character(Site), period, date, st, com = Species)]
rec[, taxon := sp$taxon[match(com, sp$com)]]
long <- CJ(k = seq_len(nrow(counts)), taxon = sp$taxon)
long <- cbind(counts[long$k], taxon = long$taxon)
long <- merge(long, rec[, .(unit, period, date, st, taxon, n_for, n_nf, n_fly)], by = c("unit", "period", "date", "st", "taxon"), all.x = TRUE)
for (cc in c("n_for", "n_nf", "n_fly")) set(long, which(is.na(long[[cc]])), cc, 0)
long[, `:=`(y = as.integer(n_for + n_nf + n_fly), obs_n_foraging = as.integer(n_for), obs_n_not_foraging = as.integer(n_nf),
            obs_n_flying_over = as.integer(n_fly), date = as.character(date), obs_start_time = st)]
stopifnot(nrow(long) == 228L * 182L, sum(long$y) == d[, sum(Foraging + Not_foraging + Flying_over)],
          nrow(rec) == uniqueN(d[!is.na(Species), .(Mission, Site, Day, Month, Year, st, Species)]),
          long[y > 0, .N] == nrow(rec[n_for + n_nf + n_fly > 0]))

sc <- as.data.table(suppressMessages(read_excel(xl, 5, col_names = FALSE, col_types = "text")))
site <- data.table(unit = sc[[1]], lat = as.numeric(sc[[2]]), lon = as.numeric(sc[[3]]))
stopifnot(identical(site$unit, as.character(1:13)), all(site$lat > -20.5 & site$lat < -20.4), all(site$lon > 22.7 & site$lon < 22.9))
# GBIF backbone names for six recent eBird/Clements genus moves and spellings
gbif_name <- c("Botaurus sturmii" = "Ixobrychus sturmii", "Botaurus minutus" = "Ixobrychus minutus",
               "Anarhynchus pecuarius" = "Charadrius pecuarius", "Thinornis tricollaris" = "Charadrius tricollaris",
               "Buphagus erythroryncha" = "Buphagus erythrorhynchus", "Grus carunculata" = "Bugeranus carunculatus")
stopifnot(all(names(gbif_name) %in% sp$sci))
taxa <- make_taxa(sp$taxon, sp$sci, vernacularName = sp$com,
                  lookupName = ifelse(sp$sci %in% names(gbif_name), gbif_name[sp$sci], sp$sci))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# NA = GBIF's accepted name differs from the IUCN record's; where the record carries the deposit's own
# name (or the GBIF lookup spelling, Buphagus erythrorynchus), it is the same species and its category is taken
taxa[, lookup := ifelse(scientificName %in% names(gbif_name), gbif_name[scientificName], scientificName)]
same_name <- function(id, nm, lk) {
  r <- fromJSON(file.path(GBIF_DIR, paste0("iucn_", sub(".*/", "", id), ".json")))
  w <- paste(head(strsplit(r$scientificName %||% "", " ")[[1]], 2), collapse = " ")
  if (w %in% c(nm, lk, "Buphagus erythrorynchus")) r$code %||% NA_character_ else NA_character_
}
taxa[is.na(taxon_iucnCategory), taxon_iucnCategory := mapply(same_name, taxonID, scientificName, lookup)]
taxa[, lookup := NULL]
stopifnot(!anyNA(taxa$taxon_iucnCategory))
threat <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), scientificName]
stopifnot(length(threat) >= 1L)
cc <- coarsen_coords(site$lat, site$lon)
site[, `:=`(unit_lat = cc$lat, unit_lon = cc$lon)]
long <- merge(long, site[, .(unit, unit_lat, unit_lon)], by = "unit", all.x = TRUE)   # site 14: no coordinates deposited
stopifnot(uniqueN(long$unit) == 14L, long[is.na(unit_lat), all(unit == "14")])
long <- order_eco(long[, .(unit, taxon, y, period, occasion, date, obs_start_time, obs_duration_min,
                           obs_n_foraging, obs_n_not_foraging, obs_n_flying_over, unit_lat, unit_lon)])

d2 <- fread(file.path(dir, "NgamiCountData2.txt"))
la <- unique(d2[, .(Mission, Lake.area)])
stopifnot(nrow(la) == 6L, identical(la$Mission, paste0("NGA", 1:6)))
periods <- data.table(period = 1:6, mission = paste0("NGA", 1:6),
                      months = counts[, paste(sort(unique(format(as.IDate(date), "%Y-%m"))), collapse = ","), by = period][order(period)]$V1,
                      lake_area_km2_modis = la$Lake.area, n_sites_counted = counts[, uniqueN(unit), by = period][order(period)]$V1)

dataset <- list(
  title = "Half-hour point counts of 182 bird species at 14 points around Lake Ngami, Botswana, over six field trips during lake dry-downs, 2007-2009",
  creator = "Cumming, Graeme S.; Henry, Dominic A. W.",
  pubDate = "2021", doi = "10.5061/dryad.w0vt4b8rd", sourceURL = "https://doi.org/10.5061/dryad.w0vt4b8rd",
  citation = "Cumming, G. S., & Henry, D. A. W. (2021). Understanding arid-region waterbird community dynamics during lake dry-downs [Dataset]. Dryad. https://doi.org/10.5061/dryad.w0vt4b8rd",
  paperDOI = "10.1002/ecs2.3668",
  abstract = "Standardised half-hour point counts of all birds within 150 m of a stationary observer at up to 14 fixed points on the shore of Lake Ngami, an ephemeral lake in north-west Botswana, repeated on several days during each of six week-long field trips from October 2007 to June 2009 as the lake shrank from about 50 to 10 km2. Birds were recorded as foraging, not foraging or flying over. The paper analyses changes in waterbird community composition with water level.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Half-hour daylight point counts by a stationary observer recording every bird within 150 m, as foraging, not foraging or flying over, at fixed counting points around the lake; each point counted on several days of each week-long field trip.",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "counts within a field trip span about a week; the community changes between trips with the lake level",
  occasionKind = "time", taxonInclusion = "recorded",
  temporalCoverage = "2007-10/2009-06",
  geographicCoverage = "Lake Ngami, North-West District, Botswana (about 20.46 S, 22.80 E); site coordinates coarsened to 0.1 degree",
  coordinatesCoarsened = list(value = TRUE, method = paste0("site coordinates (WGS 84, deposited to 1e-8 degree) coarsened to the 0.1 degree cell centre with coarsen_coords(): the community includes IUCN threatened species in their native range (", paste(sort(threat), collapse = ", "), ")")),
  notes = "y is all birds counted (foraging + not foraging + flying over), as in the authors' averaged data; the three parts are obs_ columns and vary across taxa within a count. Species are the Roberts (2005) common names as deposited (vernacularName) with scientific names from the eBird/Clements taxonomy; 14 names mapped by hand (Woolly-necked Stork as the African Ciconia microscelis, Yellow-billed Kite as Milvus aegyptius); six eBird names are looked up on GBIF under the backbone's older genus or spelling (Ixobrychus, Charadrius, Buphagus erythrorhynchus, Bugeranus). Records of one species on two lines of one count are summed. Site 14 was counted only on trip NGA5 and has no coordinates in the deposit (unit_lat/unit_lon NA; the averaged file gives it -20, 23). One count (NGA6 site 11, 2009-06-02) recorded no birds and has zero rows for every species. obs_duration_min is NA for one count whose recorded end precedes its start. Not every site was counted on every trip (sites dry out); n_sites_counted per trip is in __periods with the MODIS lake area. taxon_iucnCategory from GBIF's IUCN record. The readme asks users to cite the Dryad deposit and the Ecosphere paper.",
  notShipped = list(averaged_data = "sheets 2-4 of the workbook and NgamiCountData2.txt: the authors' per-trip averages (derived)",
                    guilds = "NgamiGuilds.txt numeric class and guild codes (undefined in the deposit)",
                    exact_coordinates = "coarsened to 0.1 degree (threatened species present)"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/cumming_2021_ngami_waterbird_count.R")
stage_dict_row(TABLE,
  description = "Repeated half-hour point counts of 182 bird species (waterbirds and others) at 14 points around Lake Ngami, Botswana, on six week-long field trips from October 2007 to June 2009 as the lake dried, with foraging / not foraging / flying-over splits and MODIS lake area; coordinates coarsened.",
  url = "https://doi.org/10.5061/dryad.w0vt4b8rd",
  reference = "Cumming, G. S., Henry, D. A. W., Mutumi, G. L., & Ndlovu, M. (2021). Understanding arid-region waterbird community dynamics during lake dry-downs. Ecosphere, 12(8), e03668.",
  doi_paper = "10.1002/ecs2.3668", doi_data = "10.5061/dryad.w0vt4b8rd",
  original_license = "CC0 1.0 (Dryad); deposited readme: 'must cite original publications (in Dryad and Ecosphere)'",
  derived_license = "CC0 1.0 (cite the Dryad deposit and the Ecosphere paper, as the authors ask)",
  notes = "Dryad version zip. Common names mapped to scientific names via the eBird/Clements taxonomy (14 by hand). Coordinates coarsened (threatened species present).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (community counts, multi-season)",
  sampling_protocol = "point_count", design = "Multi-season (6 field trips x 1-7 counts per site)",
  realm = "Freshwater", country = "BWA", coordinates = "Coarsened (0.1 deg)",
  notes = "Ephemeral-lake bird community through successive dry-downs; sites drop out as the water recedes.")
