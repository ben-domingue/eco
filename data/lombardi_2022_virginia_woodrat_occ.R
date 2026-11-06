#!/usr/bin/env Rscript
# Table:  lombardi_2022_virginia_woodrat_occ
# Source: Dryad doi:10.5061/dryad.4f4qrfjd4 (source of record), CC0 1.0, published 2022-02-10, fetched from its
#         Zenodo mirror (record 6036992, which carries the Dryad DOI; licence id "cc-zero", asserted). No
#         request was made to Dryad.
#   Lombardi, J. V., Mengak, M. T. & Castleberry, S. B. (2022). Allegheny Woodrat occupancy across Western
#   Virginia, United States [Dataset]. Dryad.
# Paper:  Lombardi, J. V., Mengak, M. T. & Castleberry, S. B. (2022). Allegheny woodrat occupancy across western
#         Virginia, United States. Wildlife Biology 2022, e01023. doi:10.1002/wlb3.01023 (CC BY). Live trapping at
#         rock outcrops, 2009-2011, single-season occupancy per year.
# Data:   Data.csv, 226 rows, one per site-year: Year (2009 59 rows, 2010 126, 2011 41), TN1-TN4 (trap night 1-4:
#         1 woodrat captured, 0 not, "-" trap not active), Elevation (m), Isolation-by-distance (distance to the
#         nearest occupied rock outcrop, km), Oak-Hickory, Mixed (forest type present in the site, 0/1).
#         README.txt defines the columns. There is no site identifier: a site trapped in two years cannot be
#         linked, so each row is its own unit. The "-" cells follow a mostly removal-like pattern (trapping
#         often ended after a capture or after two nights), but not always (asserted counts below); the
#         deposit's "-" is the survey record.
# Mapping: unit = "<year>_<row within year>" (the site-year; ids valid only within a year, closureNote),
#   taxon = NEOMAG, period = year (1-3, __periods), occasion = trap night 1-4, y = TN (0/1).
#   surveyEvidence = deposited_matrix: "-" (not active) is distinct from 0 and has no row.
#   unit_elevation_m, unit_isolation_km (distance to the nearest occupied outcrop: observed occupancy status of
#   other outcrops, not a model estimate), unit_oak_hickory, unit_mixed_forest.
#   No coordinates deposited. Neotoma magister IUCN NT.
#   Not shipped: the paper's occupancy and detection estimates (model output).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "lombardi_2022_virginia_woodrat_occ"
REC <- "6036992"

zen <- function(key) download_cached(sprintf("https://zenodo.org/api/records/%s/files/%s/content", REC, URLencode(key, reserved = TRUE)), TABLE, filename = key)
meta_f <- file.path(RAW_DIR, TABLE, "zenodo_record.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file(paste0("https://zenodo.org/api/records/", REC), meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)
stopifnot(identical(meta$metadata$license$id, "cc-zero"), identical(meta$doi, "10.5061/dryad.4f4qrfjd4"),
          setequal(meta$files$key, c("README.txt", "Data.csv")))
invisible(zen("README.txt"))
d <- fread(zen("Data.csv"), na.strings = "-")
stopifnot(identical(names(d), c("Year", "TN1", "TN2", "TN3", "TN4", "Elevation", "Isolation-by-distance", "Oak-Hickory", "Mixed")),
          nrow(d) == 226L, identical(as.integer(table(d$Year)), c(59L, 126L, 41L)),
          all(unlist(d[, TN1:TN4]) %in% c(0L, 1L, NA)), !anyNA(d$TN1),
          !anyNA(d[, 6:9]), all(d$`Oak-Hickory` %in% 0:1), all(d$Mixed %in% 0:1))
d[, pat := paste(TN1, TN2, TN3, TN4)]
stopifnot(d[pat == "1 NA NA NA", .N] == 49L, d[pat == "0 0 NA NA", .N] == 118L, d[pat == "0 0 0 0", .N] == 14L,
          sum(!is.na(as.matrix(d[, TN1:TN4]))) == 473L, sum(as.matrix(d[, TN1:TN4]), na.rm = TRUE) == 145L)
d[, unit := sprintf("%d_%03d", Year, seq_len(.N)), by = Year]
long <- melt(d, id.vars = c("unit", "Year", "Elevation", "Isolation-by-distance", "Oak-Hickory", "Mixed"),
             measure.vars = paste0("TN", 1:4), variable.name = "night", value.name = "y")
long <- long[!is.na(y)]
long[, `:=`(occasion = as.integer(sub("TN", "", night)), period = Year - 2008L, taxon = "NEOMAG", y = as.integer(y))]
setnames(long, c("Elevation", "Isolation-by-distance", "Oak-Hickory", "Mixed"),
         c("unit_elevation_m", "unit_isolation_km", "unit_oak_hickory", "unit_mixed_forest"))
long[, c("night", "Year") := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 473L, uniqueN(long$unit) == 226L, sum(long$y) == 145L, !anyDuplicated(long[, .(unit, occasion)]))

taxa <- make_taxa("NEOMAG", "Neotoma magister", vernacularName = "Allegheny woodrat")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa)
periods <- data.table(period = 1:3, year = 2009:2011)

dataset <- list(
  title = "Allegheny woodrat live-trapping detections over up to four nights at 226 rock-outcrop site-years, western Virginia, 2009-2011",
  creator = "Lombardi, Jason V.; Mengak, Michael T.; Castleberry, Steven B.",
  pubDate = "2022", doi = "10.5061/dryad.4f4qrfjd4", sourceURL = "https://doi.org/10.5061/dryad.4f4qrfjd4",
  citation = "Lombardi, J. V., Mengak, M. T., & Castleberry, S. B. (2022). Allegheny Woodrat occupancy across Western Virginia, United States [Dataset]. Dryad. https://doi.org/10.5061/dryad.4f4qrfjd4",
  paperDOI = "10.1002/wlb3.01023",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Presence/absence from live trapping of the Allegheny woodrat, a rock-outcrop specialist, at sites across western Virginia in 2009-2011, used for single-season occupancy models per year with elevation, isolation from the nearest occupied outcrop and forest type as covariates.",
  samplingProtocol = "Live traps set at rock outcrops for up to four nights per site and year; a capture on a trap night is a detection; trap nights with no active traps are marked '-'.",
  samplingProtocolCode = "live_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "closed",
  closureNote = "Occupancy is assumed closed over the trap nights of a site-year. The deposit has no site identifier, so each row (site-year) is its own unit: units are valid only within their year and a site trapped in two years appears as two unlinked units.",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Western Virginia, USA (no site coordinates deposited)",
  temporalCoverage = "2009/2011",
  covariateNote = "unit_elevation_m: site elevation (m). unit_isolation_km: distance to the nearest occupied rock outcrop (km), computed by the authors from observed occupancy of other outcrops. unit_oak_hickory, unit_mixed_forest: forest type present at the site (0/1).",
  notShipped = list(
    inactive_nights = "431 trap nights marked '-' (traps not active): no rows",
    site_identity = "the deposit has no site identifier; sites trapped in several years cannot be linked",
    model_output = "the authors' occupancy and detection estimates"),
  notes = "Trapping at a site often stopped after the first capture (49 site-years trapped one night with a capture), so later nights are often not surveyed; a removal-style detection model fits. Units are site-years, not sites.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/lombardi_2022_virginia_woodrat_occ.R")
stage_dict_row(TABLE,
  description = "Allegheny woodrat (Neotoma magister) live-trap detections over up to four nights at 226 rock-outcrop site-years in western Virginia, 2009-2011, with elevation, isolation and forest-type covariates.",
  url = "https://doi.org/10.5061/dryad.4f4qrfjd4",
  reference = "Lombardi, J. V., Mengak, M. T. & Castleberry, S. B. (2022). Allegheny woodrat occupancy across western Virginia, United States. Wildlife Biology 2022, e01023. https://doi.org/10.1002/wlb3.01023",
  doi_paper = "10.1002/wlb3.01023", doi_data = "10.5061/dryad.4f4qrfjd4",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad deposit fetched from its Zenodo mirror (record 6036992, carrying the Dryad DOI). No site id: unit = site-year.",
  source_via = "Zenodo mirror of Dryad (file API)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Single-season occupancy (per year)",
  sampling_protocol = "live_trap", design = "Multi-season (3 years, up to 4 trap nights; site-years unlinked)",
  realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "Units are site-years: the deposit has no site id.")
