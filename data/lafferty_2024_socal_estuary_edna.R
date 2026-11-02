#!/usr/bin/env Rscript
# Tables: lafferty_2024_tidewatergoby_edna (tidewater goby: qPCR replicates and metabarcoding per
#         water filter, seine at the site level) and lafferty_2024_estuaryfish_mb (estuarine fish
#         community from metabarcoding, filters as replicates within sites): one deposit, two
#         survey designs x response types, one script.
# Source: Dryad doi:10.25349/D9P60T, version 276701 (published 2024-02-02), licence CC0 1.0 (as shown
#         on Dryad). Lafferty, K. D. "Tidewater goby and estuarine fish records from seining, qPCR
#         and metabarcoding data for Southern California Estuaries in 2023".
# Paper:  Lafferty, K. D. (2024). Metabarcoding is (usually) more cost effective than seining or qPCR
#         for detecting tidewater gobies and other estuarine fishes. PeerJ 12: e16847.
#         doi:10.7717/peerj.16847.
# Data:   Field samples 15-17 August 2022 at five Santa Barbara and Ventura County estuaries.
#         Estuaries2022-MiFishU-metadata.csv: 78 rows, one per eDNA water filter (SampleId from
#         Jonah Ventures), with Location (estuary), Site (16 sites: Calleguas Creek 8 sites x 2
#         filters, Mugu Lagoon 2 x 2, Santa Clara River 1 x 17, Ormond Lagoon 1 x 21, Devereux
#         Slough 4 x 5), Date (DD-Mon-YY), tidewater-goby qPCR reads in three replicates (Rep1-3)
#         and the author's presence call per replicate (Rep1P-3P: 1 iff reads > 100, asserted),
#         volume filtered, time, Lat/Long per site (degrees-minutes-seconds or decimal degrees,
#         Units MS/DD), seine dimensions, water depth, temperature, conductivity, dissolved oxygen,
#         and seine catches per species (counts, or P where present but not counted). Seine
#         dimensions are given only at Calleguas Creek, the one estuary seined (Dryad methods); the
#         seine values are repeated on the two filters of a site (one haul per site).
#         JVB1846-qpcr-tabulated-data.csv: the laboratory's qPCR table, identical reads (asserted).
#         New_Estuary_Data.csv: 497 rows, metabarcoding consensus taxa per filter with summed reads
#         (74 filters; the four Mugu Lagoon filters have no rows). Its Estuary column disagrees with
#         the field notes for 45 of 74 filters while SiteName and SampleId agree (the column is
#         misaligned in the deposit); the field notes' Location is used.
#         Not used: DataToResample*R.csv (presence matrices derived from the files above for
#         Calleguas Creek), Final_Matches-esv.data.csv (ESV-level taxonomy behind New_Estuary_Data),
#         InvestmentTable.csv (cost assumptions), Schmelzle_Kinziger_occupancy.csv (third-party data
#         from doi:10.5061/dryad.6rs23, reused by the author; out of this deposit's own data).
#
# Mapping, lafferty_2024_tidewatergoby_edna (standard E9 experimental multi-scale / eDNA, as
# smith_2019_greatbasin_csf_edna _qpcr; responseType detection, unitKind site):
#   cluster_id = site, unit = water filter (SampleId), taxon = EUCNEW, occasion 1-3 = qPCR replicate
#   (y = the author's call, reads > 100; y_raw = reads), occasion 4 = metabarcoding of the same
#   extract (y = 1 if Eucyclogobius newberryi is among the filter's consensus taxa; y_raw = summed
#   reads; no occasion-4 row for the four Mugu Lagoon filters, which have no metabarcoding record).
#   obs_method = qPCR / metabarcoding. The seine is a site-level survey with a different
#   detection process: unit_site_seine_goby_count (0 at all 8 Calleguas Creek sites; NA where not
#   seined), as smith_2019's visual/dipnet confirmation.
# Mapping, lafferty_2024_estuaryfish_mb (community detection, unitKind site):
#   unit = site (14 sites with metabarcoding), occasion = filter index within the site (1..2 to
#   1..21), taxon = the 17 species-rank consensus taxa, y = detected in that filter's metabarcoding,
#   y_raw = summed reads over the taxon's ESVs (21 filter x species pairs have two ESVs; 0 when not
#   detected). Survey evidence: a filter is surveyed iff it has
#   metabarcoding rows (sample_table: the field notes list every filter; the four Mugu Lagoon
#   filters without metabarcoding rows are treated as not sequenced and have no rows).
#   Not shipped: consensus names above species rank (Gobiidae 12 rows, Micropterus 1).
#   Coordinates (both tables): site coordinates as deposited are to 1 second / 5 decimals; the
#   tidewater goby is federally endangered (the paper says so), so coordinates are coarsened to 0.1
#   degree with coarsen_coords().
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/lafferty_2024_socal_estuary_edna.R"
CACHE <- "lafferty_2024_tidewatergoby_edna"
dir <- download_dryad("10.25349/D9P60T", CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

m <- fread(file.path(dir, "Estuaries2022-MiFishU-metadata.csv"), encoding = "UTF-8"); setnames(m, 1, "Location")
q <- fread(file.path(dir, "JVB1846-qpcr-tabulated-data.csv"))
n <- fread(file.path(dir, "New_Estuary_Data.csv"))
stopifnot(nrow(m) == 78L, uniqueN(m$SampleId) == 78L, uniqueN(m$Site) == 16L, all(m$Assay == "TidewaterGoby01"),
          setequal(unique(m$Location), c("Santa Clara River", "Calleguas Creek", "Mugu Lagoon", "Ormond Lagoon", "Devereux Slough")),
          nrow(q) == 78L, setequal(q$SampleId, m$SampleId), all(m$Units %in% c("MS", "DD")),
          all(m[, uniqueN(Location), by = Site]$V1 == 1L))
qq <- merge(m[, .(SampleId, Rep1, Rep2, Rep3)], q[, .(SampleId, Rep1, Rep2, Rep3)], by = "SampleId")
stopifnot(with(qq, all(Rep1.x == Rep1.y & Rep2.x == Rep2.y & Rep3.x == Rep3.y)))
for (k in 1:3) stopifnot(all(m[[paste0("Rep", k, "P")]] == as.integer(m[[paste0("Rep", k)]] > 100L)))   # call = reads > 100
# metabarcoding: 74 filters, keyed by SampleId; the file's Estuary column is misaligned
stopifnot(uniqueN(n$SampleId) == 74L, all(n$SampleId %in% m$SampleId),
          setequal(setdiff(m$SampleId, n$SampleId), m[Location == "Mugu Lagoon", SampleId]))
chk <- merge(unique(n[, .(SampleId, Estuary, SiteName)]), m[, .(SampleId, Location, Site)], by = "SampleId")
stopifnot(all(chk$SiteName == chk$Site), sum(chk$Estuary != chk$Location) == 45L)
# seine: Calleguas Creek only, one haul per site repeated on its two filters
stopifnot(all(!is.na(m[Location == "Calleguas Creek", `Width (m)`])), all(is.na(m[Location != "Calleguas Creek", `Width (m)`])),
          all(m[Location == "Calleguas Creek", uniqueN(`Tidewater goby`), by = Site]$V1 == 1L))

# coordinates: DMS or decimal; site level
dms <- function(s) { v <- as.numeric(regmatches(s, gregexpr("[0-9.]+", s))[[1]]); v[1] + v[2] / 60 + v[3] / 3600 }
m[, `:=`(lat = NA_real_, lon = NA_real_)]
m[Units == "DD", `:=`(lat = as.numeric(Lat), lon = as.numeric(Long))]
m[Units == "MS", `:=`(lat = sapply(Lat, dms), lon = -sapply(Long, dms))]
stopifnot(!anyNA(m$lat), !anyNA(m$lon), all(m$lat %between% c(33.9, 34.5)), all(m$lon %between% c(-120, -118.9)))
site <- m[, .(lat = mean(lat), lon = mean(lon), Location = Location[1], Date = Date[1]), by = Site]
cc <- coarsen_coords(site$lat, site$lon)
site[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon)]
site[, date := as.character(as.IDate(Date, "%d-%b-%y"))]
stopifnot(all(site$date %in% c("2022-08-15", "2022-08-16", "2022-08-17")))
seine <- m[Location == "Calleguas Creek", .(unit_site_seine_goby_count = as.integer(`Tidewater goby`[1])), by = Site]
stopifnot(all(seine$unit_site_seine_goby_count == 0L))

taxa_goby <- make_taxa("EUCNEW", "Eucyclogobius newberryi", vernacularName = "Tidewater goby")
coarse_note <- "Site coordinates (to 1 second or 5 decimals in the deposit) coarsened to 0.1 degree with coarsen_coords(): the tidewater goby is a federally endangered species (US ESA), as the source states."
common <- list(
  creator = "Lafferty, Kevin D. (U.S. Geological Survey, Western Ecological Research Center)", pubDate = "2024",
  doi = "10.25349/D9P60T", sourceURL = "https://doi.org/10.25349/D9P60T",
  citation = "Lafferty, K. D. (2024). Tidewater goby and estuarine fish records from seining, qPCR and metabarcoding data for Southern California Estuaries in 2023 [Dataset]. Dryad. https://doi.org/10.25349/D9P60T",
  paperDOI = "10.7717/peerj.16847", relatedWorks = c("10.5281/zenodo.10049499"),
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Nearshore water samples were pushed through 1-micron disk filters with a 60 cc syringe until clogging (mean 174 cc), preserved and shipped to Jonah Ventures; DNA extracted (DNeasy); three qPCR replicates with a tidewater-goby-specific assay (Schmelzle & Kinziger 2016); 12S MiFish metabarcoding (Illumina NovaSeq, ESVs observed more than 7 times assigned by consensus taxonomy). At Calleguas Creek a seine haul (about 2.4 x 6.4 m in 0.6 m depth) was taken at each water-sampling site (Dryad methods; Lafferty 2024).",
  samplingProtocolCode = "eDNA",
  geographicCoverage = "Santa Clara River mouth, Calleguas Creek, Mugu Lagoon and Ormond Lagoon (Ventura County) and Devereux Slough (Santa Barbara County), California, USA; site coordinates coarsened to 0.1 degree",
  temporalCoverage = "2022-08-15/2022-08-17",
  coordinatesCoarsened = coarse_note)

## ---- table 1: tidewater goby, filter-level qPCR replicates and metabarcoding --------------
mb_goby <- n[taxon_name == "Eucyclogobius newberryi", .(reads = sum(sumreads)), by = SampleId]
qrows <- rbindlist(lapply(1:3, function(k) m[, .(SampleId, Site, occasion = k, y = get(paste0("Rep", k, "P")), y_raw = get(paste0("Rep", k)),
                                                obs_method = "qPCR")]))
mrows <- m[SampleId %in% n$SampleId, .(SampleId, Site, occasion = 4L, obs_method = "metabarcoding")]
mrows <- merge(mrows, mb_goby, by = "SampleId", all.x = TRUE)
mrows[, `:=`(y = as.integer(!is.na(reads)), y_raw = fifelse(is.na(reads), 0L, as.integer(reads)))][, reads := NULL]
g <- rbind(qrows, mrows, use.names = TRUE)
g <- merge(g, m[, .(SampleId, unit_volume_ml = `VOL 1`, unit_depth_m = Depth, unit_water_temp_c = Temp,
                    unit_conductivity = Cond, unit_do_mg_l = `DO (mg/L)`)], by = "SampleId")
g <- merge(g, site[, .(Site, Location, date, unit_decimalLatitude, unit_decimalLongitude)], by = "Site")
g <- merge(g, seine, by = "Site", all.x = TRUE)
g <- g[, .(unit = SampleId, taxon = "EUCNEW", y = as.integer(y), y_raw = as.integer(y_raw), occasion, date, cluster_id = Site,
           obs_method, unit_estuary = Location, unit_decimalLatitude, unit_decimalLongitude, unit_volume_ml, unit_depth_m,
           unit_water_temp_c, unit_conductivity, unit_do_mg_l, unit_site_seine_goby_count)]
g <- order_eco(g)
stopifnot(nrow(g) == 78L * 3L + 74L, !anyDuplicated(g[, .(unit, occasion)]), g[occasion == 4L, sum(y)] == uniqueN(mb_goby$SampleId))
cat(sprintf("  goby: %d rows, %d filters at %d sites; qPCR positive replicates %d, metabarcoding positive filters %d\n",
            nrow(g), uniqueN(g$unit), uniqueN(g$cluster_id), g[occasion <= 3L, sum(y)], g[occasion == 4L, sum(y)]))
T1 <- "lafferty_2024_tidewatergoby_edna"; T2 <- "lafferty_2024_estuaryfish_mb"
ds1 <- write_table(g, T1, c(common, list(
  title = "Tidewater goby eDNA detections in five southern California estuaries, August 2022: three qPCR replicates and 12S metabarcoding per water filter, seine at Calleguas Creek",
  abstract = "Detections of the endangered tidewater goby in 78 water filters from 16 sites in five Santa Barbara and Ventura County estuaries (15-17 August 2022): occasions 1-3 are qPCR replicates (y = the author's call, more than 100 reads; y_raw = reads), occasion 4 is 12S metabarcoding of the same extract (y = goby among the filter's consensus taxa; y_raw = summed reads; no metabarcoding record for the four Mugu Lagoon filters). cluster_id = site; the seine haul taken at each of the 8 Calleguas Creek sites caught no gobies (unit_site_seine_goby_count).",
  surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "Every filter in the field notes has three qPCR replicates (with reads) and, except the four Mugu Lagoon filters, a metabarcoding record in New_Estuary_Data.csv; a filter whose consensus taxa do not include the goby is a metabarcoding 0.",
  responseType = "detection", unitKind = "site",
  closure = "site occupancy closed over the 3-day survey; occasion = qPCR replicate or metabarcoding of one filter",
  occasionCodes = list(`1` = "qPCR replicate 1", `2` = "qPCR replicate 2", `3` = "qPCR replicate 3", `4` = "12S metabarcoding (MiFish) of the same extract"),
  designNote = "Experimental list of E9 (multi-scale / eDNA, multi-method): cluster_id = site (occupancy), unit = water filter (availability), occasion = assay replicate (detection; qPCR 1-3, metabarcoding 4, obs_method). The site-level seine is a covariate, as in smith_2019_greatbasin_csf_edna.",
  notes = "qPCR calls follow the author's threshold (reads > 100, asserted against Rep1P-Rep3P); y_raw keeps the reads so other thresholds can be applied. The metabarcoding file's Estuary column is misaligned for 45 filters in the deposit; estuaries come from the field notes via SampleId. Water chemistry and volume are per filter (unit_). Companion community table: lafferty_2024_estuaryfish_mb.",
  components = list(T2),
  notShipped = list(`third-party occupancy data` = "Schmelzle_Kinziger_occupancy.csv (Schmelzle & Kinziger 2015, doi:10.5061/dryad.6rs23), reused by the author",
                    `derived files` = "DataToResampleMetabarcodesR.csv and DataToResampleSeinesR.csv (presence matrices derived from the shipped files); Final_Matches-esv.data.csv (ESV-level taxonomy); InvestmentTable.csv (cost assumptions)",
                    `seine catches of other species` = "counts at the 8 Calleguas Creek sites (some recorded only as P)"))),
  taxa = taxa_goby, script = SCRIPT)
stage_dict_row(T1,
  description = "Tidewater goby (Eucyclogobius newberryi, federally endangered) eDNA in 78 water filters from 16 sites in five southern California estuaries, August 2022: three qPCR replicates plus 12S metabarcoding per filter (multi-scale, cluster_id = site), seine result per site at Calleguas Creek.",
  url = "https://doi.org/10.25349/D9P60T",
  reference = "Lafferty, K. D. (2024). Metabarcoding is (usually) more cost effective than seining or qPCR for detecting tidewater gobies and other estuarine fishes. PeerJ, 12, e16847.",
  doi_paper = "10.7717/peerj.16847", doi_data = "10.25349/D9P60T", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-method eDNA: qPCR replicates (author's >100-read call, reads as y_raw) and metabarcoding as occasions of a filter; coordinates coarsened (endangered).",
  source_via = "Dryad")
stage_tag_row(T1, ds1, taxon_group = "Fish", model_family = "Multi-scale / multi-method occupancy (eDNA qPCR and metabarcoding)",
  sampling_protocol = "eDNA", design = "Single-season", realm = "Freshwater",
  country = "USA", coordinates = "Coarsened (0.1 deg)", notes = "Endangered goby; site coordinates coarsened; seine as site covariate.")

## ---- table 2: estuarine fish community from metabarcoding, filters within sites ------------
n_species <- n[!is.na(taxon_name) & grepl("^[A-Z][a-z]+ [a-z]+$", taxon_name)]
n_other <- nrow(n) - nrow(n_species)
stopifnot(n_other == 13L, setequal(setdiff(unique(n$taxon_name), unique(n_species$taxon_name)), c("Gobiidae", "Micropterus")))
# several ESVs of one species in a filter: sum their reads
n_esv_dup <- sum(duplicated(n_species[, .(SampleId, taxon_name)]))
n_species <- n_species[, .(sumreads = sum(sumreads)), by = .(SampleId, taxon_name)]
sp <- sort(unique(n_species$taxon_name))
stopifnot(length(sp) == 17L, n_esv_dup == 21L)
code <- toupper(paste0(substr(sub(" .*", "", sp), 1, 3), substr(sub(".* ", "", sp), 1, 3)))
stopifnot(!anyDuplicated(code))
fil <- m[SampleId %in% n$SampleId, .(SampleId, Site)]
setorder(fil, Site, SampleId); fil[, occasion := seq_len(.N), by = Site]
grid <- CJ(SampleId = fil$SampleId, taxon_name = sp)
grid <- merge(grid, n_species[, .(SampleId, taxon_name, sumreads)], by = c("SampleId", "taxon_name"), all.x = TRUE)
grid <- merge(grid, fil, by = "SampleId")
grid <- merge(grid, site[, .(Site, Location, date, unit_decimalLatitude, unit_decimalLongitude)], by = "Site")
grid <- merge(grid, m[, .(SampleId, obs_volume_ml = `VOL 1`, obs_filter_id = SampleId)], by = "SampleId")
c2 <- grid[, .(unit = Site, taxon = code[match(taxon_name, sp)], y = as.integer(!is.na(sumreads)),
               y_raw = fifelse(is.na(sumreads), 0L, as.integer(sumreads)), occasion, date,
               obs_filter_id, obs_volume_ml, unit_estuary = Location, unit_decimalLatitude, unit_decimalLongitude)]
c2 <- order_eco(c2)
stopifnot(nrow(c2) == 74L * 17L, sum(c2$y) == nrow(n_species), uniqueN(c2$unit) == 14L,
          all(c2[, uniqueN(taxon), by = .(unit, occasion)]$V1 == 17L))
cat(sprintf("  community: %d rows, %d sites, %d filters, 17 species, %d detections; %d higher-rank rows not shipped\n",
            nrow(c2), uniqueN(c2$unit), nrow(fil), sum(c2$y), n_other))
taxa2 <- make_taxa(code, sp)
ds2 <- write_table(c2, T2, c(common, list(
  title = "Estuarine fish community detections by 12S metabarcoding, 74 water filters at 14 sites in four southern California estuaries, August 2022",
  abstract = "Species detections from 12S MiFish metabarcoding of 74 water filters (2 to 21 per site) at 14 sites in Calleguas Creek, Santa Clara River mouth, Ormond Lagoon and Devereux Slough, 15-17 August 2022: 17 species-rank consensus taxa (including the endangered tidewater goby and introduced freshwater species), one row per site x filter x species, y = detected, y_raw = summed reads (0 when not detected). Filters are replicate samples of a site (occasion).",
  surveyEvidence = "sample_table",
  surveyEvidenceNote = "The field notes list every filter; a filter is a survey iff it has a metabarcoding record (74 of 78: the four Mugu Lagoon filters have none and are treated as not sequenced). Every species-rank taxon detected anywhere gets a row in every surveyed filter.",
  responseType = "detection", unitKind = "site",
  closure = "site occupancy closed over the 3-day survey; occasion = water filter (replicate sample) at the site",
  notes = "Species-rank consensus taxa only; the metabarcoding file's Estuary column is misaligned for 45 filters in the deposit and estuaries come from the field notes via SampleId. obs_filter_id links a row to the goby table's unit. Detection is ESV-based (ESVs observed more than 7 times, consensus taxonomy; Dryad methods); sequence-database gaps can make some species unassignable (Lafferty 2024).",
  components = list(T1),
  notShipped = list(`higher-rank consensus names` = sprintf("%d rows (Gobiidae 12, Micropterus 1)", n_other),
                    `Mugu Lagoon filters` = "4 filters without a metabarcoding record",
                    `third-party occupancy data` = "Schmelzle_Kinziger_occupancy.csv (doi:10.5061/dryad.6rs23)"))),
  taxa = taxa2, script = SCRIPT)
stage_dict_row(T2,
  description = "Estuarine fish community (17 species) detected by 12S metabarcoding in 74 water filters at 14 sites in four southern California estuaries, August 2022; filters as replicate occasions within sites, summed reads as y_raw.",
  url = "https://doi.org/10.25349/D9P60T",
  reference = "Lafferty, K. D. (2024). Metabarcoding is (usually) more cost effective than seining or qPCR for detecting tidewater gobies and other estuarine fishes. PeerJ, 12, e16847.",
  doi_paper = "10.7717/peerj.16847", doi_data = "10.25349/D9P60T", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Community eDNA metabarcoding, species-rank taxa only; coordinates coarsened (tidewater goby among taxa); companion of lafferty_2024_tidewatergoby_edna.",
  source_via = "Dryad")
stage_tag_row(T2, ds2, taxon_group = "Fish", model_family = "Community occupancy (eDNA metabarcoding, filters as replicates)",
  sampling_protocol = "eDNA", design = "Single-season", realm = "Freshwater",
  country = "USA", coordinates = "Coarsened (0.1 deg)", notes = "Species-rank metabarcoding taxa; endangered goby among taxa; coordinates coarsened.")
