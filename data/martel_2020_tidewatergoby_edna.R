#!/usr/bin/env Rscript
# Table:  martel_2020_tidewatergoby_edna
# Source: Dryad doi:10.5061/dryad.vdncjsxs9 (CC0 1.0, as shown on the Dryad page; published
#         2020-10-13). Kinziger, A. (2020). Data: Using environmental DNA and occupancy modeling to
#         estimate rangewide metapopulation dynamics.
# Paper:  Martel, C.M., Sutter, M., Dorazio, R.M. & Kinziger, A.P. (2021). Using environmental DNA
#         and occupancy modelling to estimate rangewide metapopulation dynamics. Molecular Ecology
#         30(13), 3340-3354, doi:10.1111/mec.15693. Dynamic, spatial multi-scale occupancy model
#         (site occupancy by season, water-sample availability, qPCR detection) for the
#         federally endangered tidewater goby across its California range, 2016 and 2017.
# Data:   DataDictionary.pdf is the codebook. TWGeDNA_2016_2017.csv: 813 rows, one per water
#         sample (siteNumber, unique; 417 in season 1 = 2016, 396 in season 2 = 2017) at 192
#         sites (siteID, the same sites in both seasons; site = place name), sample = sample number
#         within site and season (1-10); RecUnit / SubUnit = USFWS recovery unit and sub-unit; do,
#         temp, sal (2 NA), turb (seconds to filter), veg and tide (Pres/Abs) measured at the
#         sample; SL_* = site-season means of those; EstExt (ha) and EstExtBin; pcr1-pcr6 = qPCR
#         replicates 0/1, NA = replicate not run (3 replicates on 686 samples, 4 on 16, 6 on 111;
#         trailing NA only, asserted); lat/lon (WGS84, to 1e-5 to 1e-7 degree) per sample; date
#         (MM/DD/YYYY). Neighborhood_MatrixV6.3.csv: shoreline distances (m) between sites in the
#         same sub-unit (model input). Four R/C++ files are analysis code.
#         Date quirks: 27 season-2 rows do not read as an unambiguous 2017 MM/DD/YYYY date:
#         five Klamath River samples dated 7/11/2016 (year typo), nine San Elijo Lagoon samples
#         dated 21/10/2017 (DD/MM), and 13 samples in the same late block (siteNumber 1443-1466)
#         dated 10/11/2017 or 11/8/2017, which read either way once DD/MM is in use there.
# Mapping (standard E9 experimental multi-scale / eDNA): cluster_id = siteID (the site), unit =
#         siteNumber (the water sample), period = season (1 = 2016, 2 = 2017), occasion = qPCR
#         replicate 1-6, y = qPCR detection 0/1. A row exists iff the replicate was run (non-NA),
#         surveyEvidence = deposited_matrix. A sample belongs to one season, so a unit has one
#         period; site-level dynamics are across cluster_id. unit_ covariates (constant per
#         sample): unit_do_mgl, unit_temp_c, unit_salinity_ppt (NA at 2 samples), unit_turb_s,
#         unit_veg, unit_tide (1 = Pres), unit_estuary_ha, unit_estuary_size (EstExtBin),
#         unit_recovery_unit, unit_recovery_subunit, unit_sample (number within site and season),
#         and the coarsened coordinates. date = the sample date where it reads unambiguously as a
#         date in the season's year (MM/DD/YYYY, month < 10 in 2017), else NA; the deposited string
#         is kept on every row as obs_date_as_deposited.
#         Coordinates: the tidewater goby is federally endangered (US ESA), which the source states
#         (USFWS recovery plan units), so sample coordinates are coarsened to 0.1 degree with
#         coarsen_coords() (E7), and the site names are not shipped (E7.4).
# Not shipped: site names (E7.4); the shoreline-distance neighbourhood matrix (exact inter-site
#         distances would undo the coarsening, and it is a model input); SL_* (site-season means
#         of the shipped sample values, recomputable); model output.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "martel_2020_tidewatergoby_edna"
dir <- download_dryad("10.5061/dryad.vdncjsxs9", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

d <- fread(file.path(dir, "TWGeDNA_2016_2017.csv"))
stopifnot(nrow(d) == 813, !anyDuplicated(d$siteNumber), identical(d[, .N, by = season][order(season)]$N, c(417L, 396L)),
          uniqueN(d$siteID) == 192, all(d[, uniqueN(site), by = siteID]$V1 == 1),
          !anyDuplicated(d[, .(siteID, season, sample)]),
          all(d$veg %in% c("Abs", "Pres")), all(d$tide %in% c("Abs", "Pres")), sum(is.na(d$sal)) == 2,
          all(d$EstExtBin %in% c("large", "small")))
P <- as.matrix(d[, paste0("pcr", 1:6), with = FALSE])
nrep <- rowSums(!is.na(P))
stopifnot(all(P %in% c(NA, 0L, 1L)), all(nrep %in% c(3, 4, 6)),
          all(sapply(seq_len(nrow(P)), function(i) all(!is.na(P[i, seq_len(nrep[i])])))),
          identical(as.integer(table(nrep)), c(686L, 16L, 111L)))

# dates
d[, dt := as.IDate(date, format = "%m/%d/%Y")]
d[, ok := !is.na(dt) & year(dt) == 2015L + season & !(season == 2L & month(dt) >= 10L)]
stopifnot(sum(!d$ok) == 27, all(d[!d$ok]$season == 2L))
d[, iso := ifelse(ok, as.character(dt), NA_character_)]

cc <- coarsen_coords(d$lat, d$lon)
stopifnot(all(d$lat %between% c(32.5, 42)), all(d$lon %between% c(-124.5, -117)))
d[, `:=`(clat = cc$lat, clon = cc$lon)]

long <- rbindlist(lapply(1:6, function(k) d[!is.na(get(paste0("pcr", k))), .(
  unit = siteNumber, taxon = "EUCNEW", period = season, occasion = k, y = get(paste0("pcr", k)),
  date = iso, cluster_id = siteID, obs_date_as_deposited = date,
  unit_sample = sample, unit_recovery_unit = RecUnit, unit_recovery_subunit = SubUnit,
  unit_do_mgl = do, unit_temp_c = temp, unit_salinity_ppt = sal, unit_turb_s = turb,
  unit_veg = as.integer(veg == "Pres"), unit_tide = as.integer(tide == "Pres"),
  unit_estuary_ha = EstExt, unit_estuary_size = EstExtBin,
  unit_decimalLatitude = clat, unit_decimalLongitude = clon)]))
long <- order_eco(long)
stopifnot(nrow(long) == sum(nrep), sum(long$y) == 622L, uniqueN(long$unit) == 813)

taxa <- make_taxa("EUCNEW", "Eucyclogobius newberryi", vernacularName = "Tidewater goby")
periods <- data.table(period = 1:2, year = 2016:2017)
coarse_note <- "Sample coordinates (to 1e-5 to 1e-7 degree in the deposit) coarsened to 0.1 degree with coarsen_coords(): the tidewater goby is federally endangered (US ESA), as the source states. Site names not shipped (E7.4); cluster_id is the deposit's numeric siteID."

dataset <- list(
  title = "Rangewide eDNA qPCR detections of tidewater goby in 813 water samples at 192 California coastal sites, 2016-2017",
  creator = "Kinziger, Andrew", pubDate = "2020", doi = "10.5061/dryad.vdncjsxs9",
  sourceURL = "https://doi.org/10.5061/dryad.vdncjsxs9",
  citation = "Kinziger, A. (2020). Data: Using environmental DNA and occupancy modeling to estimate rangewide metapopulation dynamics [Dataset]. Dryad. https://doi.org/10.5061/dryad.vdncjsxs9",
  paperDOI = "10.1111/mec.15693",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Water samples from estuaries, lagoons and ponds across the California range of the endangered tidewater goby, each tested with 3 to 6 qPCR replicates, at the same 192 sites in 2016 and 2017, with water quality, vegetation, ocean connection and estuary size per sample.",
  samplingProtocol = "Environmental DNA: 1 to 10 water samples per site and season, each filtered and assayed by species-specific qPCR in 3, 4 or 6 replicates.",
  samplingProtocolCode = "eDNA", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "qPCR replicates of one water sample; samples nest in sites (cluster_id), seasons are periods",
  occasionKind = "spatial", taxonInclusion = "single",
  designNote = "Experimental list of E9 (multi-scale / eDNA): cluster_id = site, unit = water sample, occasion = qPCR replicate, period = season (a sample belongs to one season; site dynamics are across cluster_id).",
  geographicCoverage = "coastal California, USA, Del Norte to San Diego counties; coordinates coarsened to 0.1 degree",
  temporalCoverage = "2016-05/2017-11",
  coordinatesCoarsened = list(value = TRUE, method = coarse_note), crs = "EPSG:4326",
  notShipped = list(
    site_names = "place names of the sites (E7.4: coordinates are coarsened for the endangered goby)",
    neighborhood_matrix = "Neighborhood_MatrixV6.3.csv, shoreline distances between sites in a sub-unit: a model input whose exact distances would undo the coarsening",
    SL_covariates = "SL_do, SL_temp, SL_sal, SL_turb, SL_veg: site-season means of the shipped sample values",
    model_output = "dynamic multi-scale occupancy estimates"),
  notes = "date is NA on 27 season-2 samples whose deposited date is not an unambiguous 2017 MM/DD/YYYY date (a 2016 year typo, a DD/MM date and 13 dates in the same block that read either way); the deposited string is on every row as obs_date_as_deposited.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/martel_2020_tidewatergoby_edna.R")
stage_dict_row(TABLE,
  description = "Rangewide environmental DNA survey of the endangered tidewater goby (Eucyclogobius newberryi): qPCR replicate detections in 813 water samples at 192 California coastal sites in 2016 and 2017, samples nested in sites, with per-sample water quality; coordinates coarsened.",
  url = "https://doi.org/10.5061/dryad.vdncjsxs9",
  reference = "Martel, C. M., Sutter, M., Dorazio, R. M., & Kinziger, A. P. (2021). Using environmental DNA and occupancy modelling to estimate rangewide metapopulation dynamics. Molecular Ecology, 30(13), 3340-3354.",
  doi_paper = "10.1111/mec.15693", doi_data = "10.5061/dryad.vdncjsxs9",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-scale eDNA (cluster_id site, unit sample, occasion qPCR replicate); coordinates coarsened and site names withheld (endangered); 27 ambiguous dates set NA with the deposited string kept.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Multi-scale dynamic occupancy (eDNA)",
  sampling_protocol = "eDNA", design = "Multi-season (2 years, samples within sites, 3-6 qPCR replicates)",
  realm = "Freshwater", country = "USA", coordinates = "Coarsened (0.1 deg)",
  notes = "Endangered estuarine goby; rangewide eDNA.")
