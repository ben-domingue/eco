#!/usr/bin/env Rscript
# Table:  ukpoms_2026_uk_pantrap_count
# Source: NERC Environmental Information Data Centre (EIDC) doi:10.5285/5841bfae-471b-498c-af89-c30e5140d6c5,
#         published 2026-06-22, licence Open Government Licence v3 ("This resource is available under the terms of
#         the Open Government Licence"; catalogue record, asserted from the cached catalogue JSON), with a required
#         acknowledgement (carried in the citation and notes). OGL v3 is an attribution-only licence.
#   UK Pollinator Monitoring Scheme (2026). 1km square pan trap survey data from the UK Pollinator Monitoring Scheme,
#   2017-2023. NERC EDS Environmental Information Data Centre.
# Paper:  Carvell, C. et al. (2016, 2020), the scheme's design reports (cited by the supporting document; not read).
# Data:   the EIDC data package zip (supporting-documents/ukpoms_1kmpantrapdata_2017-2023_metadata.docx describes it):
#         samples.csv: 7,050 samples, one per pan-trap station (1-5) per visit, in 96 randomly chosen 1 km squares
#           (location_code; x1km_square OS grid reference; land_cover agricultural / semi-natural, constant within a
#           square, asserted), 2017-2023; date (dd/mm/yyyy); trap_active_from / _to (about 6 h between 09:00 and
#           17:00); trap_disturbed (yes / no / not sure); weather at start and end; habitat; sorted counts of other
#           invertebrate groups; bees and hoverflies totals. Up to four visits per square-year, May-September; gaps
#           where a square was not visited.
#         insects.csv: 24,175 specimen records (one row per bee or hoverfly, count 1, adults), sample_id linking to
#           samples (all present), taxon_source / taxon_standardised / taxon_aggregated (the scheme's analysis
#           taxon, aggregating species not reliably separated, e.g. Bombus lucorum/terrestris/magnus/cryptarum).
#           1,066 records have no standardised or aggregated name; their taxon_source carries a subgenus
#           ("Lasioglossum (Evylaeus) calceatum"): with the subgenus removed every one is a name the file standardises
#           elsewhere, except Anthophora plumipes (1 record, kept as its own taxon).
#           The samples' bees + hoverflies equals the specimen rows of the sample for 7,049 of 7,050 samples (one
#           sample 15 against 16, asserted).
#         flowers.csv: floral units in bloom within 2 m of each station (a separate survey of plants; not shipped).
# Mapping (repeated counts, community): unit = pan-trap station ("<location_code>_<station>"), cluster_id = 1 km square
#   (location_code), taxon = a code for the scheme's aggregated taxon, period = year (1 = 2017 ... 7 = 2023),
#   occasion = visit within the square-year (1-5, by date), date, y = specimens of the taxon in the station's sample.
#   surveyEvidence = sample_table (samples.csv). taxonInclusion = recorded (bees and hoverflies identified in this
#   table). obs_: trap_disturbed (1 yes, 0 no, NA not sure), hours active, temperature, cloud, wind at start;
#   unit_land_cover, unit_x1km_square, unit_country. Coordinates are the 1 km grid squares the scheme (UKCEH and
#   JNCC, public bodies) publishes; kept as published (E7 agency rule).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "ukpoms_2026_uk_pantrap_count"
ID <- "5841bfae-471b-498c-af89-c30e5140d6c5"
mf <- file.path(RAW_DIR, TABLE, "eidc_record.json"); dir.create(dirname(mf), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(mf)) download.file(paste0("https://catalogue.ceh.ac.uk/documents/", ID), mf, quiet = TRUE, headers = c("User-Agent" = UA, Accept = "application/json"))
meta <- fromJSON(mf)
stopifnot(any(grepl("Open Government Licence", meta$useConstraints$value)), paste0("10.5285/", ID) %in% meta$resourceIdentifiers$code)
z <- download_cached(sprintf("https://data-package.ceh.ac.uk/data/%s.zip", ID), TABLE, filename = "data_package.zip")
ex <- file.path(dirname(z), "x"); if (!dir.exists(ex)) unzip(z, exdir = ex)
s <- fread(file.path(ex, "data", "ukpoms_1kmpantrapdata_2017-2023_samples.csv"))
i <- fread(file.path(ex, "data", "ukpoms_1kmpantrapdata_2017-2023_insects.csv"), colClasses = list(character = "count"))
stopifnot(nrow(s) == 7050L, !anyDuplicated(s$sample_id), uniqueN(s$location_code) == 96L, all(s$pan_trap_station %in% 1:5),
          setequal(s$year, 2017:2023), s[, uniqueN(land_cover), by = location_code][, all(V1 == 1L)],
          s[, uniqueN(x1km_square), by = location_code][, all(V1 == 1L)],
          nrow(i) == 24175L, all(i$count == "1"), all(i$stage == "adult"), all(i$sample_id %in% s$sample_id))
# analysis taxon: the scheme's aggregate; subgenus-written source names mapped through the file's own standardisation
map <- unique(i[taxon_standardised != "", .(taxon_standardised, taxon_aggregated)])
stopifnot(!anyDuplicated(map$taxon_standardised))
i[, clean := trimws(gsub("\\s+", " ", sub(" sensu strictu$", "", gsub("\\([A-Za-z]+\\) ", "", taxon_source))))]
i[, tx := taxon_aggregated]
i[tx == "", tx := map$taxon_aggregated[match(clean, map$taxon_standardised)]]
stopifnot(sum(i$taxon_aggregated == "") == 1066L, sum(is.na(i$tx)) == 1L, i[is.na(tx), clean] == "Anthophora plumipes")
i[is.na(tx), tx := clean]
cnt <- i[, .(y = .N), by = .(sample_id, tx)]
tot <- merge(s[, .(sample_id, t = bees + hoverflies)], i[, .N, by = sample_id], all.x = TRUE)[is.na(N), N := 0L]
stopifnot(tot[t != N, .N] == 1L)
# one station-date entered twice (square 59, 20/07/2023, station 2; two digitisers, 0+1 and 0+0 specimens): neither
# can be preferred, so both samples are dropped and the station has no row at that visit
dupe <- s[, .N, by = .(location_code, date, pan_trap_station)][N > 1]
stopifnot(nrow(dupe) == 1L, dupe$location_code == "59", dupe$date == "20/07/2023", dupe$pan_trap_station == 2L)
drop_ids <- s[dupe, on = .(location_code, date, pan_trap_station), sample_id]
n_drop_spec <- i[sample_id %in% drop_ids, .N]; stopifnot(n_drop_spec == 1L)
s <- s[!sample_id %in% drop_ids]; i <- i[!sample_id %in% drop_ids]; cnt <- cnt[!sample_id %in% drop_ids]
# visits: within a square-year, ordered by date
s[, d := as.Date(date, "%d/%m/%Y")]
stopifnot(!anyNA(s$d), all(year(s$d) == s$year))
vis <- unique(s[, .(location_code, year, d)])[order(location_code, year, d)][, occasion := seq_len(.N), by = .(location_code, year)]
s <- merge(s, vis, by = c("location_code", "year", "d"))
stopifnot(!anyDuplicated(s[, .(location_code, pan_trap_station, year, occasion)]))
taxa_names <- sort(unique(i$tx))
code <- toupper(sapply(strsplit(sub("/.*$", "", sub(" species complex$", "", taxa_names)), " "), function(w)
  if (length(w) == 1) substr(w[1], 1, 6) else paste0(substr(w[1], 1, 3), substr(w[2], 1, 3))))
agg <- grepl("/| species complex$", taxa_names)
code[agg] <- paste0(code[agg], "_AGG")
dup <- unique(code[duplicated(code)])
for (dd in dup) { w <- which(code == dd); code[w] <- toupper(sapply(strsplit(taxa_names[w], "[ /]"), function(x) paste0(substr(x[1], 1, 4), substr(x[2] %||% "", 1, 4))))
  if (any(duplicated(code[w]))) code[w] <- paste0(code[w], seq_along(w)) }
stopifnot(!anyDuplicated(code))
tmap <- data.table(tx = taxa_names, taxon = code, agg = agg)
cnt <- merge(cnt, tmap[, .(tx, taxon)], by = "tx")
s[, `:=`(unit = paste0(location_code, "_", pan_trap_station), period = year - 2016L)]
grid <- CJ(sample_id = s$sample_id, taxon = tmap$taxon)
long <- merge(grid, cnt[, .(sample_id, taxon, y)], by = c("sample_id", "taxon"), all.x = TRUE)[is.na(y), y := 0L]
hrs <- function(a, b) { f <- function(x) { p <- as.integer(strsplit(x, ":")[[1]]); p[1] + p[2] / 60 }
  round(mapply(function(u, v) if (is.na(u) || is.na(v) || !nzchar(u) || !nzchar(v)) NA_real_ else f(v) - f(u), a, b), 2) }
s[, obs_hours_active := hrs(trap_active_from, trap_active_to)]
long <- merge(long, s[, .(sample_id, unit, period, occasion, date = format(d), cluster_id = as.character(location_code),
                          unit_country = country, unit_land_cover = land_cover, unit_x1km_square = x1km_square,
                          obs_trap_disturbed = c(yes = 1L, no = 0L)[trap_disturbed], obs_hours_active,
                          obs_temperature_start = temperature_start, obs_cloud_cover_start = cloud_cover_start,
                          obs_wind_speed_start = wind_speed_start)], by = "sample_id")
long[, sample_id := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 7048L * nrow(tmap), sum(long$y) == 24174L, s[, uniqueN(unit_country <- country), by = unit][, all(V1 == 1L)])
cat(sprintf("  %d rows, %d stations in %d squares, %d taxa (%d aggregates), %d specimens\n", nrow(long), uniqueN(long$unit),
            uniqueN(long$cluster_id), nrow(tmap), sum(tmap$agg), sum(long$y)))
# taxa: species and genera matched on GBIF; aggregates of several species carry no key
rank <- ifelse(tmap$agg, "species aggregate", ifelse(grepl(" ", tmap$tx), "species", ifelse(grepl("idae$", tmap$tx), "family", "genus")))
taxa <- make_taxa(tmap$taxon, tmap$tx, taxonRank = rank, lookupName = tmap$tx,
                  no_key = tmap$taxon[tmap$agg],
                  taxonRemarks = ifelse(tmap$agg, "the scheme's aggregate of species not reliably separated in pan-trap samples; GBIF holds no taxon for the aggregate",
                                        ifelse(tmap$tx == "Anthophora plumipes", "recorded once with a subgenus and no standardised name; kept as its own taxon", NA_character_)),
                  exact = FALSE)
# rows the strict match did not resolve exactly (genera with homonyms fall to a higher taxon, some species come back
# FUZZY): re-matched with the source's order and family as hints, accepted only when GBIF returns the name itself
# among animals; otherwise no taxonID, with a remark (E6)
hint <- unique(i[, .(tx, order, family)])[, .SD[1], by = tx]
fixme <- taxa[!taxon %in% tmap$taxon[tmap$agg] & !(gbifMatchType == "EXACT" & !kingdom_taxonID(taxonID))]
for (k in seq_len(nrow(fixme))) {
  tk <- fixme$taxon[k]; nm <- fixme$scientificName[k]; hh <- hint[tx == nm]
  h <- gbif_taxon_hinted(nm, list(kingdom = "Animalia", class = "Insecta", order = hh$order, family = if (taxa[taxon == tk, taxonRank] == "family") NA else hh$family))
  # a FUZZY match that differs only in the epithet's gender ending (lentus / lenta) is the same species
  gender <- identical(h$matchType, "FUZZY") && !is.na(h$canonicalName) && identical(sub(" .*", "", h$canonicalName), sub(" .*", "", nm)) &&
    identical(substr(sub(".* ", "", h$canonicalName), 1, nchar(sub(".* ", "", nm)) - 2), substr(sub(".* ", "", nm), 1, nchar(sub(".* ", "", nm)) - 2))
  if ((identical(h$canonicalName, nm) || gender) && identical(h$kingdom, "Animalia") && identical(h$rank, taxa[taxon == tk, taxonRank]))
    taxa[taxon == tk, `:=`(taxonID = h$taxonID, gbifMatchType = paste0(h$matchType, " (hinted)"),
                           taxonRemarks = if (gender) sprintf("GBIF backbone spells the epithet with another gender ending: %s", h$canonicalName) else NA_character_)]
  else taxa[taxon == tk, `:=`(taxonID = NA_character_, gbifMatchType = paste0(h$matchType, " (hinted, rejected)"),
                              taxonRemarks = sprintf("GBIF backbone gives no exact match for '%s' (strict: %s; hinted: %s %s)", nm, fixme$gbifMatchType[k], h$matchType, h$canonicalName %||% ""))]
}
print(taxa[taxon %in% fixme$taxon, .(taxon, scientificName, taxonRank, gbifMatchType, taxonID)])
stopifnot(!any(kingdom_taxonID(taxa$taxonID)), taxa[!taxon %in% tmap$taxon[tmap$agg], !anyNA(taxonID)])
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[taxon_iucnCategory %in% c("CR", "EN", "VU"), .(taxon, scientificName, taxon_iucnCategory)])
periods <- data.table(period = 1:7, year = 2017:2023, n_samples = s[, .N, by = year][order(year), N])
ack <- meta$useConstraints$value[grepl("acknowledgement", meta$useConstraints$value)]
dataset <- list(
  title = "Bee and hoverfly counts in pan traps at five stations per 1 km square, 96 squares of the UK Pollinator Monitoring Scheme, up to four visits a year, 2017-2023",
  creator = "UK Pollinator Monitoring Scheme", pubDate = "2026", doi = paste0("10.5285/", ID), sourceURL = paste0("https://doi.org/10.5285/", ID),
  citation = sprintf("UK Pollinator Monitoring Scheme (2026). 1km square pan trap survey data from the UK Pollinator Monitoring Scheme, 2017-2023. NERC EDS Environmental Information Data Centre. https://doi.org/10.5285/%s. Contains data supplied by UK Centre for Ecology & Hydrology.", ID),
  intellectualRights = list(spdx = "OGL-UK-3.0", url = "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/"),
  abstract = "The UK Pollinator Monitoring Scheme's 1 km square survey: in randomly selected agricultural and semi-natural 1 km squares across England, Scotland, Wales and Northern Ireland, five pan-trap stations (three UV-coloured bowls each) along a diagonal are run for six hours on up to four fine-weather visits a year, May-September; all bees and hoverflies in each station's sample are identified to species where possible.",
  samplingProtocol = "Five pan-trap stations per 1 km square, each a set of three water-filled bowls (UV yellow, blue, white) set for about six hours between 09:00 and 17:00 in suitable weather (minimum 13-15 C, wind Beaufort 5 or less); the three bowls of a station are one sample; bees and hoverflies identified by experts.",
  samplingProtocolCode = "pan_trap", surveyEvidence = "sample_table",
  responseType = "count", unitKind = "site", closure = "open",
  closureNote = "Visits of a year span May-September (at least two weeks apart), across which the insect community changes; the station's count per visit is the observation.",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "United Kingdom: England, Scotland, Wales and Northern Ireland (1 km squares as OS grid references)",
  temporalCoverage = "2017-05/2023-09",
  coordinatesCoarsened = list(value = FALSE, method = "1 km OS grid squares as published by the scheme (UKCEH / JNCC); no point coordinates are deposited"),
  covariateNote = "cluster_id: 1 km square (location code). unit_x1km_square: OS grid reference of the square. unit_land_cover: agricultural or semi-natural (square stratum). obs_trap_disturbed: 1 yes, 0 no, NA not sure. obs_hours_active: hours between trap_active_from and trap_active_to. obs_temperature_start (C), obs_cloud_cover_start (%), obs_wind_speed_start (Beaufort).",
  notShipped = list(double_entry = "square 59, 20/07/2023, station 2 was entered twice (two samples, 1 specimen between them): both dropped",
                    flowers = "floral units in bloom within 2 m of each station (a plant survey)",
                    other_groups = "sorted counts of wasps, sawflies, other flies, moths, butterflies, beetles, spiders and other invertebrates (group totals, not species)",
                    one_sample_total = "one sample's bees + hoverflies total (15) differs from its specimen rows (16); the specimens are shipped",
                    end_weather = "weather at the end of the trapping period, exposure, shade, vegetation height and habitat codes"),
  notes = paste("Required acknowledgement:", ack))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/ukpoms_2026_uk_pantrap_count.R")
stage_dict_row(TABLE,
  description = "Bee and hoverfly specimen counts per pan-trap station and visit in 96 UK Pollinator Monitoring Scheme 1 km squares, 2017-2023.",
  url = paste0("https://doi.org/10.5285/", ID), reference = "", doi_paper = "", doi_data = paste0("10.5285/", ID),
  original_license = "Open Government Licence v3, with the scheme's required acknowledgement (UK PoMS partnership, UKCEH and JNCC)",
  derived_license = "OGL-UK-3.0", notes = "Supersedes the 2017-2020/2021 versions; scheme aggregate taxa.", source_via = "EIDC data package (zip)")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Community abundance (repeated counts)",
  sampling_protocol = "pan_trap", design = "Multi-season (7 years, up to 4 visits, 5 stations per square)",
  realm = "Terrestrial", country = "GBR", coordinates = "As published (1 km grid squares)", notes = "National monitoring scheme; aggregates have no GBIF key.")
