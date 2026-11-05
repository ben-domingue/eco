#!/usr/bin/env Rscript
# Table:  dutta_2024_panna_carnivore_occ
# Source: Dryad doi:10.5061/dryad.djh9w0w8h, version 3 (2024-10-14), CC0 1.0 (as shown on the Dryad page).
#   Dutta, S., Maheswaran, G. & Krishnamurthy, R. (2024). Data from: Interspecific interactions among major
#   carnivores in Panna Tiger Reserve: A multispecies occupancy approach. Dryad.
# Paper:  Dutta, S., Maheswaran, G. & Krishnamurthy, R. (2024). Interspecific interactions among major carnivores
#         in Panna Tiger Reserve: a multispecies occupancy approach. Biotropica, doi:10.1111/btp.13389
#         (from Dryad's primary_article link). Design from the Dryad methods text: paired Cuddeback C1 camera
#         traps in a 2-km2 grid, two seasons of 2019: winter (January-February, ~32 days, 475 stations) and
#         summer (May-June, ~38 days, 338 stations).
# Data:   per season (winter_*, summer_*):
#           species_matrix.csv: TrapCode x Tiger_k / Leopard_k / Hyena_k, k = session (7 winter, 8 summer);
#             0/1, NA = camera non-functional (readme).
#           effort.csv: TrapCode x Session_k, trap nights in the session (0 to 5; sessions are 5 nights,
#             the last one 3).
#           covariates.csv: TrapCode, canopy (%), lst_* (land surface temperature, C), dist_v (m to village),
#             dist_w* (m to water), ndvi_*, slope (degrees).
#         Checked: the three files of a season share TrapCode in the same order; in every species the NA cells
#         are exactly the cells with effort 0 (103 winter, 149 summer). Winter has 476 stations (the methods
#         text says 475) and summer 338. TrapCode numbering is per season: the codes overlap (1-390 in summer,
#         1-489 in winter) but canopy, distance to village and slope differ for the same code in the two
#         seasons, so a code is not the same place across seasons.
# Mapping (single-season occupancy, three target species, two seasons): unit = season x station ("W<code>",
#   "S<code>"), since the deposit does not link stations across seasons; period = season (1 winter, 2 summer;
#   in __periods); occasion = session; y = detection 0/1; obs_trap_nights = effort. Survey evidence:
#   effort_table (a survey exists where trap nights > 0). Every station covariate is unit_ (each unit lies in
#   one season, so season-specific LST, NDVI and distance to water are constant within it). taxon = TIGER /
#   LEOPARD / HYENA (Panthera tigris EN, Panthera pardus VU, Hyaena hyaena NT); no coordinates are deposited,
#   so nothing to coarsen. Session dates are not deposited; no date column. No model output is deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "dutta_2024_panna_carnivore_occ"
dir <- download_dryad("10.5061/dryad.djh9w0w8h", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

sp <- c(TIGER = "Tiger", LEOPARD = "Leopard", HYENA = "Hyena")
seasons <- list(list(name = "winter", pre = "W", K = 7L, n = 476L, nNA = 103L, lst = "lst_w", dw = "dist_ww", ndvi = "ndvi_w"),
                list(name = "summer", pre = "S", K = 8L, n = 338L, nNA = 149L, lst = "lst_s", dw = "dist_ws", ndvi = "ndvi_s"))
parts <- list()
for (i in seq_along(seasons)) {
  s <- seasons[[i]]
  m  <- fread(file.path(dir, paste0(s$name, "_species_matrix.csv")))
  ef <- fread(file.path(dir, paste0(s$name, "_effort.csv")))
  cv <- fread(file.path(dir, paste0(s$name, "_covariates.csv")))
  stopifnot(nrow(m) == s$n, identical(m$TrapCode, ef$TrapCode), identical(m$TrapCode, cv$TrapCode), !anyDuplicated(m$TrapCode),
            identical(names(ef), c("TrapCode", paste0("Session_", seq_len(s$K)))),
            identical(names(cv), c("TrapCode", "canopy", s$lst, "dist_v", s$dw, s$ndvi, "slope")), !anyNA(cv))
  E <- as.matrix(ef[, -1]); stopifnot(!anyNA(E), all(E %in% 0:5), sum(E == 0) == s$nNA)
  ids <- paste0(s$pre, m$TrapCode)
  y <- array(NA_real_, c(s$n, s$K, 3), dimnames = list(ids, NULL, names(sp)))
  for (k in names(sp)) {
    Y <- as.matrix(m[, paste0(sp[[k]], "_", seq_len(s$K)), with = FALSE])
    stopifnot(all(Y %in% c(0, 1, NA)), all(is.na(Y) == (E == 0)))   # surveyed iff trap nights > 0
    y[, , k] <- Y
  }
  Ef <- E; Ef[E == 0] <- NA
  site_covs <- data.table(season = s$name, canopy_pct = cv$canopy, land_surface_temp_c = cv[[s$lst]],
                          dist_village_m = cv$dist_v, dist_water_m = cv[[s$dw]], ndvi = cv[[s$ndvi]], slope_deg = cv$slope)
  l <- array_to_eco(y, site_ids = ids, site_covs = site_covs, obs_covs = list(trap_nights = Ef))
  l[, period := i]
  parts[[i]] <- l
}
long <- order_eco(rbindlist(parts, use.names = TRUE))
stopifnot(nrow(long) == 3 * (476 * 7 - 103 + 338 * 8 - 149), uniqueN(long$unit) == 476 + 338)
print(long[, .(det = sum(y)), by = .(period, taxon)])

taxa <- make_taxa(names(sp), c("Panthera tigris", "Panthera pardus", "Hyaena hyaena"),
                  vernacularName = c("Tiger", "Leopard", "Striped hyena"))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[, .(taxon, taxon_iucnCategory)])
periods <- data.table(period = 1:2, season = c("winter", "summer"), year = 2019L,
                      months = c("January-February", "May-June"), n_stations = c(476L, 338L), n_sessions = c(7L, 8L))

dataset <- list(
  title = "Camera-trap detections of tiger, leopard and striped hyena at 814 station-seasons in Panna Tiger Reserve, India, winter and summer 2019",
  creator = "Dutta, Supratim; Maheswaran, Gopinathan; Krishnamurthy, Ramesh", pubDate = "2024",
  doi = "10.5061/dryad.djh9w0w8h", sourceURL = "https://doi.org/10.5061/dryad.djh9w0w8h",
  citation = "Dutta, S., Maheswaran, G., & Krishnamurthy, R. (2024). Data from: Interspecific interactions among major carnivores in Panna Tiger Reserve: A multispecies occupancy approach [Dataset]. Dryad. https://doi.org/10.5061/dryad.djh9w0w8h",
  paperDOI = "10.1111/btp.13389",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Paired camera traps in a 2-km2 grid across Panna Tiger Reserve, Madhya Pradesh, India, in winter (January-February) and summer (May-June) 2019, used to fit multispecies occupancy models of tiger, leopard and striped hyena with canopy, land surface temperature, NDVI, slope and distances to village and water.",
  samplingProtocol = "Paired motion-triggered camera traps on trails, forest roads and riverbeds, one station per 2-km2 cell; detection histories in 5-night sessions (the last session 3 nights); trap nights per session is the effort.",
  samplingProtocolCode = "camera_trap", occasionLength = "5 nights", effortColumn = "obs_trap_nights",
  surveyEvidence = "effort_table",
  responseType = "detection", unitKind = "site", closure = "closed", occasionKind = "time",
  closureNote = "Closed within a season; a unit is a station in one season, because the deposit numbers stations separately per season.",
  taxonInclusion = "target",
  geographicCoverage = "Panna Tiger Reserve, Madhya Pradesh, India (no coordinates deposited)", temporalCoverage = "2019-01/2019-06",
  notShipped = list(`station identity across seasons` = "TrapCode is numbered per season (covariates differ for the same code), so a winter and a summer station with the same code are different units"),
  notes = "Winter has 476 stations in the deposit; the Dryad methods text says 475.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/dutta_2024_panna_carnivore_occ.R")

stage_dict_row(TABLE,
  description = "Camera-trap detection/non-detection of tiger, leopard and striped hyena at 476 winter and 338 summer stations in 5-night sessions in Panna Tiger Reserve, India (2019), with trap nights per session and six station covariates.",
  url = "https://doi.org/10.5061/dryad.djh9w0w8h",
  reference = "Dutta, S., Maheswaran, G., & Krishnamurthy, R. (2024). Interspecific interactions among major carnivores in Panna Tiger Reserve: A multispecies occupancy approach. Biotropica.",
  doi_paper = "10.1111/btp.13389", doi_data = "10.5061/dryad.djh9w0w8h",
  original_license = "CC0 1.0", derived_license = "CC0-1.0",
  notes = "Unit = season x station (station codes are per season). Fetched as the Dryad version zip.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (multispecies)",
  sampling_protocol = "camera_trap", design = "Single-season (two seasons, stations not linked)", realm = "Terrestrial", country = "IND",
  coordinates = "None in source", notes = "Tiger (EN), leopard (VU), striped hyena (NT). Occasion = 5 trap nights.", status = "tagged")
