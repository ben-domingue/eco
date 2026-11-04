#!/usr/bin/env Rscript
# Table:  maihoff_2023_berchtesgaden_bees_count
# Source: Dryad doi:10.5061/dryad.80gb5mkt1 (CC0 1.0 as shown on the dataset JSON), version
#   208382 (version 4, published 2022-12-07). Maihoff, F. Raw data: Wildbee Monitoring along two
#   elevational gradients in Germany. (Dryad links the record to a transcriptome paper,
#   doi:10.1016/j.isci.2022.105175; the abstract and methods are those of the paper below.)
# Paper:  Maihoff, F., Friess, N., Hoiss, B., Schmid-Egger, C., Kerner, J., Neumayer, J.,
#   Hopfenmueller, S., Baessler, C., Mueller, J., & Classen, A. (2023). Smaller, more diverse and
#   on the way to the top: Rapid community shifts of montane wild bees within an extraordinary
#   hot decade. Diversity and Distributions 29: 272-288, doi:10.1111/ddi.13658 (CC BY 4.0; not
#   read: the Dryad methods text and README carry the design).
# Data:   BGL_monitoring.csv (";"): 5,380 rows, one per specimen (abundance 1) or blank sampling
#           event (species "null", abundance 0; 6 walks), Berchtesgadener Land (BGL) 2009 and
#           2019: species, genus, date, sampling hour (rounded), site (60 x 60 m), sub-transect
#           (1-10, 5 min each), replicate (walk number within site-year), year_site_replicate.
#           33 sites, 5 walks (>= 1200 m) or 6 walks (lower) per site-year, both years
#           (asserted). Bombus lucorum and B. terrestris are deposited as one complex
#           ("Bombus lucorum_terrestris"), as the README recommends.
#         year_site_info_BGL.csv: per site-year elevation, mean temperature during sampling,
#           mean annual temperature (both modelled from adjacent climate stations), mean flower
#           cover over the walks, management (m mown once in late summer, g grazed, n not
#           managed) and its binary form. It has a 2009 row for a site T2 that has no walks
#           (T2 also has 2009 flower records; dropped with the site).
#         BGL_sitecoordinates.csv: centre of each site (WGS84) and its mountain transect
#           (site names differ in case from the monitoring file: WMa1 / Wma1).
#         BGL_flowercover_data.csv: flower cover (%) per plant species per site and date.
#         temperature_period_BGL.csv: modelled mean annual temperature per site-year 2005-2020.
#         BF_monitoring.csv, BF_sitecoordinates.csv, year_site_info_BF.csv,
#           temperature_period_BF.csv: the Bavarian Forest gradient (not shipped, see below).
#         README.docx: column definitions.
# Mapping (community counts, responseType count, unitKind site):
#   unit = BGL site (33), taxon = bee species code (130 species and the B. lucorum/terrestris
#   complex), period = 1 (2009) or 2 (2019), occasion = walk number within the site-year (1-6).
#   y = specimens of the species caught on the walk (sweep netting along 10 sub-transects,
#   50 min), sub-transects summed. Survey evidence: row_presence. Every walk of the 33 sites x
#   2 years appears in the file, because walks with no bee were entered as explicit blank
#   sampling events. Every site-year has 5 or 6 walks (40 and 26 site-years, asserted), the
#   methods' five above 1200 m and six below; the elevation rule holds in 58 of 66 site-years,
#   the rest lie near 1200 m (5 walks at 766-1162 m, 6 at 1245 m). The source's replicate
#   number is the campaign round (1-7, in calendar order); 8 site-years skip a round number,
#   which is a round the site was not walked in, not a lost walk (the walk count still matches
#   the protocol). occasion = walk order within the site-year; obs_round = the source number.
#   A species absent from a walk's rows is a zero (all wild bees and honeybees were recorded).
#   date = the walk's date (six walks span two days: the first day, obs_n_days = 2).
#   obs_first_hour = the earliest sampling hour recorded on the walk (hours are rounded and
#   recorded per specimen, so this approximates the start). obs_flower_cover_pct = summed
#   flower cover of all plant species recorded at the site on the walk's date (NA when no
#   flower survey has that date; 88% of walk-days have one).
#   period_ (site x year): period_temperature_sampling_c, period_temperature_annual_c (modelled
#   from climate stations, not from the bee data), period_mean_flower_cover_pct (the source's
#   site-year mean), period_management (m / g / n; changes between years at T5 and HO3).
#   unit_: elevation, mountain transect, coordinates.
#   Coordinates: as deposited (site centres, 8 decimals) unless a species is IUCN CR, EN or VU
#   (checked through GBIF with iucn_category(); none is, so nothing is coarsened).
#   v1.1: closure = open (May-September walks follow flight seasons), occasionKind = time,
#   taxonInclusion = recorded. BOMBLUTE is the source's species aggregate (taxonRank
#   speciesAggregate, taxonID the genus Bombus via allow_higher, taxonRemarks in __taxa; E6).
#   Not shipped: the Bavarian Forest (BF) gradient: specimen rows from Malaise and flight-
#   interception traps with collection dates only, no record of trap runs or empty catches,
#   sites split between 2007 and 2008, so its survey set cannot be recovered. Sub-transect
#   counts (summed; empty sub-transects have no row). The 2009 site-information row for T2 (no
#   walks in the data). temperature_period_BGL.csv beyond the sampled years.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "maihoff_2023_berchtesgaden_bees_count"
dir <- download_dryad("10.5061/dryad.80gb5mkt1", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), attr(dir, "version") == "208382")
stopifnot(setequal(list.files(dir), c("BF_monitoring.csv", "BF_sitecoordinates.csv", "BGL_flowercover_data.csv", "BGL_monitoring.csv",
                                      "BGL_sitecoordinates.csv", "README.docx", "temperature_period_BF.csv", "temperature_period_BGL.csv",
                                      "year_site_info_BF.csv", "year_site_info_BGL.csv")))
rd <- function(f) fread(file.path(dir, f), sep = ";", encoding = "UTF-8")
g <- rd("BGL_monitoring.csv"); si <- rd("year_site_info_BGL.csv"); co <- rd("BGL_sitecoordinates.csv"); fc <- rd("BGL_flowercover_data.csv")

# ---- walks ----
stopifnot(nrow(g) == 5380, setequal(g$year, c(2009L, 2019L)), uniqueN(g$site) == 33, !"T2" %in% g$site,
          all(g$year_site_replicate == paste(g$year, g$site, g$replicate, sep = "_")),
          g[species == "null", all(abundance == 0 & special_info == "blanck sampling event")], sum(g$species == "null") == 6,
          g[species != "null", all(abundance == 1)],
          all(g$special_info %in% c("", "blanck sampling event", "bettre use Bombus sensu stricto complex due to field identifications")),
          g[special_info == "bettre use Bombus sensu stricto complex due to field identifications", all(species == "Bombus lucorum_terrestris")],
          !any(g$species %in% c("Bombus lucorum", "Bombus terrestris")),
          g[species == "null", .N, by = year_site_replicate][, all(N == 1)],
          !any(g[species == "null", year_site_replicate] %in% g[species != "null", year_site_replicate]))
g[, d := as.IDate(day, "%d.%m.%Y")]
stopifnot(!anyNA(g$d), all(year(g$d) == g$year), all(month(g$d) %in% 5:9))
wk <- g[, .(nrep = uniqueN(replicate), maxrep = max(replicate)), by = .(year, site)]
stopifnot(nrow(wk) == 66, all(wk$nrep %in% 5:6), wk[, .N, by = .(year, nrep)][order(year, nrep), all(N == c(20, 13, 20, 13))],
          sum(wk$nrep != wk$maxrep) == 8, max(wk$maxrep) == 7)   # replicate = campaign round; 8 site-years skip a round number
wk[, alt := si$alt[match(site, si$site)]]
stopifnot(sum((wk$alt < 1200) == (wk$nrep == 6)) == 58)   # the methods' rule (6 walks below 1200 m, 5 above) holds in 58 of 66 site-years
walks <- g[, .(date = min(d), obs_n_days = uniqueN(d), obs_first_hour = min(as.integer(substr(sampling_time, 1, 2)))), by = .(year, site, replicate)]
stopifnot(nrow(walks) == 356, sum(walks$obs_n_days == 2) == 6, all(walks$obs_n_days <= 2), !anyNA(walks$obs_first_hour))
setorder(walks, site, year, replicate)
stopifnot(walks[, all(diff(as.integer(date)) > 0), by = .(site, year)]$V1)   # round numbers follow the calendar
walks[, `:=`(walk = seq_len(.N), obs_round = replicate), by = .(site, year)]

# ---- flower cover per walk day ----
stopifnot(setequal(setdiff(fc$site, g$site), "T2"), sum(fc$site == "T2") == 93, all(fc$cov >= 0 & fc$cov <= 100), !anyNA(fc$cov))
fc <- fc[site != "T2"]   # T2: flower surveys in 2009 but no bee walks in the deposit
fc[, d := as.IDate(date_flowermoni, "%d.%m.%Y")]; stopifnot(!anyNA(fc$d))
fcs <- fc[, .(obs_flower_cover_pct = round(sum(cov), 3)), by = .(site, date = d)]
walks <- merge(walks, fcs, by = c("site", "date"), all.x = TRUE)
cat(sprintf("  walks with a flower survey on the walk date: %.0f%%\n", 100 * mean(!is.na(walks$obs_flower_cover_pct))))

# ---- site-year and site information ----
si[, key := paste(year, site)]
stopifnot(nrow(si) == 67, !anyDuplicated(si$key), setequal(setdiff(si$key, unique(paste(g$year, g$site))), "2009 T2"),
          all(unique(paste(g$year, g$site)) %in% si$key), si[, uniqueN(alt), by = site][, all(V1 == 1)],
          all(si$manangement %in% c("m", "g", "n")), si[, all((manangement == "n") == (management_binary == "unmanaged") | site == "T5" | manangement != "n")])
si <- si[key != "2009 T2"]
pc <- si[, .(unit = site, period = match(year, c(2009L, 2019L)), period_temperature_sampling_c = round(meanT_duringsampling, 3),
             period_temperature_annual_c = round(T_annual, 3), period_mean_flower_cover_pct = round(mean_flowercover, 3),
             period_management = manangement)]
stopifnot(nrow(pc) == 66, sum(pc[, uniqueN(period_management), by = unit]$V1 > 1) == 2)
co[, site_l := tolower(site)]
stopifnot(nrow(co) == 33, setequal(co$site_l, tolower(g$site)), !anyDuplicated(co$site_l),
          all(co$Lat > 47.4 & co$Lat < 47.8 & co$Lon > 12.7 & co$Lon < 13.1))
units <- data.table(unit = sort(unique(g$site)))
units[, i := match(tolower(unit), co$site_l)]
units[, `:=`(unit_transect = co$transect[i], unit_decimalLatitude = co$Lat[i], unit_decimalLongitude = co$Lon[i],
             unit_elevation_m = si$alt[match(unit, si$site)])][, i := NULL]
stopifnot(!anyNA(units), min(units$unit_elevation_m) == 641, max(units$unit_elevation_m) == 2032)

# ---- taxa ----
spp <- sort(unique(g[species != "null", species]))
stopifnot(length(spp) == 131, all(grepl("^[A-Z][a-z]+ [a-z_]+$", spp)), all(sub(" .*$", "", spp) == g$genus[match(spp, g$species)]))
sp <- data.table(source = spp)
sp[, `:=`(binomial = fifelse(source == "Bombus lucorum_terrestris", "Bombus lucorum/terrestris complex", source),
          lookup = fifelse(source == "Bombus lucorum_terrestris", "Bombus", fifelse(source == "Coelioxys alata", "Coelioxys alatus", source)),   # GBIF spells the epithet alatus
          rank = fifelse(source == "Bombus lucorum_terrestris", "speciesAggregate", "species"))]
sp[, taxon := toupper(paste0(substr(sub(" .*$", "", source), 1, 4), substr(sub("^\\S+ ", "", source), 1, 6)))]
sp[source == "Bombus lucorum_terrestris", taxon := "BOMBLUTE"]
stopifnot(!anyDuplicated(sp$taxon))
taxa <- make_taxa(sp$taxon, sp$binomial, taxonRank = sp$rank, lookupName = sp$lookup,
                  taxonRemarks = fifelse(sp$taxon == "BOMBLUTE", "species aggregate recorded as one by the source (B. lucorum and B. terrestris workers cannot be told apart in the field; README: 'better use Bombus sensu stricto complex'); taxonID is the genus Bombus", NA_character_),
                  allow_higher = "BOMBLUTE")
stopifnot(!anyNA(taxa$taxonID), all(taxa[taxon != "BOMBLUTE", gbifMatchType] == "EXACT"),
          taxa[taxon == "BOMBLUTE", taxonID == "https://www.gbif.org/species/1340278"])   # the complex resolves to the genus Bombus Latreille (HIGHERRANK)
taxa[, taxon_iucnCategory := fifelse(taxonRank == "species", iucn_category(taxonID, scientificName), NA_character_)]
print(taxa[, .N, by = taxon_iucnCategory])
# four Osmia names GBIF keys under Hoplitis come back NA because the IUCN record carries the
# source's own name (Osmia claviventris, leucomelana, mitis, villosa: the same species, the
# record answers NE for each); taken as NE
OSM <- c("OSMICLAVIV", "OSMILEUCOM", "OSMIMITIS", "OSMIVILLOS")
stopifnot(setequal(taxa[is.na(taxon_iucnCategory) & taxonRank == "species", taxon], OSM))
taxa[taxon %in% OSM, taxon_iucnCategory := "NE"]
flagged <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU")]
print(flagged[, .(taxon, scientificName, gbifAcceptedName, taxon_iucnCategory)])
COARSEN <- nrow(flagged) > 0
if (COARSEN) {
  cc <- coarsen_coords(units$unit_decimalLatitude, units$unit_decimalLongitude)
  units[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, unit_coordinateUncertaintyInMeters = cc$uncertainty_m)]
}

# ---- long ----
counts <- g[species != "null", .(y = sum(abundance)), by = .(year, site, replicate, source = species)]
counts[, taxon := sp$taxon[match(source, sp$source)]]
walks[, `:=`(unit = site, period = match(year, c(2009L, 2019L)), occasion = walk)][, walk := NULL]
long <- walks[rep(seq_len(.N), each = nrow(sp))][, taxon := rep(sp$taxon, times = nrow(walks))]
long <- merge(long, counts[, .(year, site, replicate, taxon, y)], by = c("year", "site", "replicate", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- merge(long, pc, by = c("unit", "period"))
long[, `:=`(date = format(date), year = NULL, site = NULL, replicate = NULL)]
stopifnot(nrow(long) == 356 * 131, sum(long$y) == 5374, sum(long$y) == sum(g$abundance))
long <- order_eco(long)

periods <- data.table(period = 1:2, period_year = c(2009L, 2019L),
                      period_start = sapply(c(2009L, 2019L), function(y) format(min(walks[year == y, date]))),
                      period_end = sapply(c(2009L, 2019L), function(y) format(max(walks[year == y, date]))))
dataset <- list(
  title = "Transect-walk counts of 131 wild bee taxa at 33 grassland sites along an elevational gradient (641-2032 m), Berchtesgadener Land, Germany, 2009 and 2019",
  creator = "Maihoff, Fabienne; Friess, Nicolas; Hoiss, Bernhard; Schmid-Egger, Christian; Kerner, Janika; Neumayer, Johann; Hopfenmueller, Sebastian; Baessler, Claus; Mueller, Joerg; Classen, Alice",
  pubDate = "2022-12-07", doi = "10.5061/dryad.80gb5mkt1", sourceURL = "https://doi.org/10.5061/dryad.80gb5mkt1",
  citation = "Maihoff, F. (2022). Raw data: Wildbee Monitoring along two elevational gradients in Germany [Dataset]. Dryad. https://doi.org/10.5061/dryad.80gb5mkt1",
  paperDOI = "10.1111/ddi.13658",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Wild bees and honeybees caught by sweep netting on standardised 50-minute transect walks (10 sub-transects of 5 min) at 33 grassland sites (60 x 60 m; 18 extensively grazed or mown, 15 unmanaged) along five mountain transects in and around Berchtesgaden National Park, May to September 2009 and resampled in 2019; five walks per site-year above 1200 m, six below. The paper reports upward elevational shifts of the bee communities over the decade, driven by mean annual temperature.",
  samplingProtocol = "Standardised transect walks: 10 evenly spaced sub-transects per site, 5 minutes each (50 minutes per walk), all wild bees and honeybees caught with sweep nets, 9:30 to 18:00 in sunny weather or above 17 C at 650 m on cloudy days. Walks with no bee recorded as blank sampling events. Flower cover per plant species estimated on site visits.",
  samplingProtocolCode = "transect_count", occasionLength = "one 50-minute transect walk",
  surveyEvidence = "row_presence",
  surveyEvidenceNote = "Every walk is in BGL_monitoring.csv: specimen rows, or for the six walks with no bee an explicit blank sampling event (species null, abundance 0). Each of the 66 site-years has 5 or 6 walks, the methods' five above 1200 m and six below (the rule holds in 58 site-years; the other 8 lie near 1200 m). The source's replicate number is a campaign round; 8 site-years skip a round number but keep the protocol's walk count, so the gap is a round not walked, not a lost walk. A species absent from a walk's rows is a zero.",
  responseType = "count", unitKind = "site",
  closure = "open", closureNote = "not assumed within a period: walks run from May to September and follow each species' flight season; period = year (2009, 2019)",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = list(description = "Berchtesgadener Land, Bavaria, Germany: Berchtesgaden National Park and vicinity (Hintersee, Hochalm, Watzmann, Wimbachtal and lowland sites)",
                            boundingBox = list(west = min(units$unit_decimalLongitude), east = max(units$unit_decimalLongitude),
                                               south = min(units$unit_decimalLatitude), north = max(units$unit_decimalLatitude))),
  temporalCoverage = sprintf("%s/%s", min(long$date), max(long$date)),
  coordinatesCoarsened = if (COARSEN) list(value = TRUE, method = sprintf("0.1 degree cell centres (coarsen_coords), because %s (IUCN %s per GBIF) occur in the table", paste(flagged$scientificName, collapse = ", "), paste(flagged$taxon_iucnCategory, collapse = ", "))) else
    list(value = FALSE, method = "As published: site centre coordinates as deposited; no species in the table is IUCN CR, EN or VU (checked through GBIF)"),
  notShipped = list(`Bavarian Forest gradient` = "BF_monitoring.csv and its site files: Malaise and flight-interception trap specimens with collection dates only; no record of trap runs or empty catches, sites split between 2007 and 2008, so the survey set cannot be recovered",
                    `sub-transect counts` = "summed into the walk; empty sub-transects have no row, so sub-transect zeros cannot be evidenced",
                    `T2 2009` = "year_site_info_BGL.csv has a 2009 row and BGL_flowercover_data.csv 93 flower records for a site T2 that has no bee walks in the monitoring file (not resampled in 2019); without walk records it is not a surveyed unit here",
                    `temperature series` = "temperature_period_BGL.csv (modelled annual means 2005-2020); the sampled years are in period_temperature_annual_c",
                    `management_binary` = "derivable from period_management"),
  notes = "B. lucorum and B. terrestris are one taxon (BOMBLUTE) as deposited; workers cannot be told apart in the field. Apis mellifera (managed honeybee) is included as recorded. Temperatures are modelled from climate stations. obs_first_hour is the earliest rounded specimen hour, an approximation of the walk's start. Site names in the coordinate file differ in case (WMa1 = Wma1). occasion is the walk's order within the site-year; obs_round is the source's round number (1-7).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, units = units, script = "data/maihoff_2023_berchtesgaden_bees_count.R")

stage_dict_row(TABLE,
  description = "Counts of 131 wild bee taxa (including honeybee and the B. lucorum/terrestris complex) on 356 standardised 50-minute transect walks at 33 grassland sites from 641 to 2032 m in Berchtesgadener Land, Germany, in 2009 and 2019, with flower cover, modelled temperature and management per site-year.",
  url = "https://doi.org/10.5061/dryad.80gb5mkt1",
  reference = "Maihoff, F., Friess, N., Hoiss, B., Schmid-Egger, C., Kerner, J., Neumayer, J., Hopfenmueller, S., Baessler, C., Mueller, J., & Classen, A. (2023). Smaller, more diverse and on the way to the top: Rapid community shifts of montane wild bees within an extraordinary hot decade. Diversity and Distributions, 29, 272-288.",
  doi_paper = "10.1111/ddi.13658", doi_data = "10.5061/dryad.80gb5mkt1",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Zeros from the walk list (blank walks recorded). Sub-transects summed. The Bavarian Forest trap data in the same deposit are not shipped (no survey set).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "transect_count", design = "Multi-season (2 years, 2009 and 2019, x 5-6 walks per site)",
  realm = "Terrestrial", country = "DEU", coordinates = if (COARSEN) "Coarsened (0.1 deg)" else "As published",
  notes = "Wild bees along an elevational gradient, resampled after a decade; sweep-net transect walks.", status = "tagged")
