#!/usr/bin/env Rscript
# Table:  mizel_2018_alaska_sparrows_count
# Source: Dryad doi:10.5061/dryad.90kp2 (CC0 1.0, as shown on the Dryad page; published
#         2018-11-02). Mizel, J.D., Schmidt, J.H. & Lindberg, M.S. Data from: Accommodating
#         temporary emigration in spatial distance sampling models.
# Paper:  Mizel, J.D., Schmidt, J.H. & Lindberg, M.S. (2018). Journal of Applied Ecology 55(3),
#         doi:10.1111/1365-2664.13053. Point-count surveys of savannah sparrow and American tree
#         sparrow in Alaska with distances, repeated visits; spatial distance sampling with
#         temporary emigration (abstract).
# Data:   Counts2sp.csv (750 rows = 150 sites x 5 visits: ATSPcounts, SAVScounts; NA = not
#         surveyed, 284 rows); pcovariates.csv (the same 750 rows: Site, newsite 1-150, Visit 1-5,
#         juldate, effort, Noise, Observer2, reltime; NA exactly where counts are NA, asserted);
#         ATSP.csv / SAVS.csv (one row per detected bird: pixel, site, visit, distance to the
#         point; the per site-visit tallies equal the counts, asserted); NDVI_200 / NDVI_250
#         (pixel covariate grids); Appendix_S3.txt (JAGS code: T = 5 visits, 150 sites, 466
#         surveys).
# Mapping (standard: repeated counts, community N-mixture, E9 core): unit = newsite; taxon =
#   SPIARB (American tree sparrow), PASSAN (savannah sparrow); occasion = visit 1..5; y =
#   count. obs_: day of year (juldate; no year deposited), effort, noise, observer code,
#   reltime (as deposited). Survey evidence: deposited_matrix (NA = not surveyed; 466 surveys).
#   Not shipped: the per-bird distances and pixel grids (a spatial distance-sampling layout; a
#   distance table could be built from them later), the original Site ids (newsite is the
#   authors' index). No coordinates; both species IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "mizel_2018_alaska_sparrows_count"
dir <- download_dryad("10.5061/dryad.90kp2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rf <- function(n) { f <- list.files(dir, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f) }
cn <- rf("Counts2sp\\.csv"); pc <- rf("pcovariates\\.csv")
stopifnot(nrow(cn) == 750, nrow(pc) == 750, identical(names(cn), c("ATSPcounts", "SAVScounts")), !anyDuplicated(pc[, .(newsite, Visit)]),
          uniqueN(pc$newsite) == 150, all(pc$Visit %in% 1:5), identical(is.na(cn$SAVScounts), is.na(pc$effort)), identical(is.na(cn$ATSPcounts), is.na(cn$SAVScounts)),
          sum(!is.na(cn$SAVScounts)) == 466)
d <- cbind(pc, cn)[!is.na(SAVScounts)]
for (sp in c("SAVS", "ATSP")) {
  ind <- rf(paste0(sp, "\\.csv"))[, .N, by = .(newsite = Site, Visit)]
  m <- merge(d[, .(newsite, Visit, c = get(paste0(sp, "counts")))], ind, by = c("newsite", "Visit"), all.x = TRUE)[is.na(N), N := 0L]
  stopifnot(all(m$c == m$N), nrow(merge(ind, d[, .(newsite, Visit)])) == nrow(ind))
}
long <- melt(d[, .(unit = sprintf("S%03d", newsite), occasion = as.integer(Visit), obs_date_doy = juldate, obs_effort = effort, obs_noise = Noise,
                   obs_observer_code = Observer2, obs_reltime = reltime, SPIARB = ATSPcounts, PASSAN = SAVScounts)],
             measure.vars = c("SPIARB", "PASSAN"), variable.name = "taxon", value.name = "y", variable.factor = FALSE)
long[, y := as.integer(y)]; long <- order_eco(long)
stopifnot(nrow(long) == 466 * 2)
taxa <- make_taxa(c("SPIARB", "PASSAN"), c("Spizelloides arborea", "Passerculus sandwichensis"), vernacularName = c("American tree sparrow", "Savannah sparrow"),
                  lookupName = c("Spizella arborea", "Passerculus sandwichensis"))
dataset <- list(
  title = "Counts of American tree sparrow and savannah sparrow on up to five repeat point counts at 150 sites in Alaska",
  creator = "Mizel, Jeremy D.; Schmidt, Joshua H.; Lindberg, Mark S.", pubDate = "2018", doi = "10.5061/dryad.90kp2", sourceURL = "https://doi.org/10.5061/dryad.90kp2",
  citation = "Mizel, J. D., Schmidt, J. H., & Lindberg, M. S. (2018). Data from: Accommodating temporary emigration in spatial distance sampling models [Dataset]. Dryad. https://doi.org/10.5061/dryad.90kp2",
  paperDOI = "10.1111/1365-2664.13053",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Counts of American tree sparrow and savannah sparrow on up to five repeat point counts at 150 survey sites in Alaska (466 surveys), with day of year, effort, noise, observer and time covariates per survey: the counts behind a spatial distance-sampling model with temporary emigration.",
  samplingProtocol = "Repeated point counts with distance to each detected bird (unlimited radius, mapped to pixels), up to five visits per site in one breeding season.",
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix", responseType = "count",
  unitKind = "site", closure = "open", closureNote = "temporary emigration between visits is the paper's subject (TPP / TEDS models); one breeding season", occasionKind = "time",
  taxonInclusion = "target", geographicCoverage = "Alaska, USA (see the paper); no coordinates deposited",
  temporalCoverage = "survey year not stated in the deposit (paper 2018)",
  notShipped = list(distances = "per-bird distances and pixel ids (ATSP.csv, SAVS.csv) and the NDVI / elevation pixel grids: a spatial distance-sampling layout", site_ids = "original Site ids (newsite, the authors' 1-150 index, is the unit)"),
  notes = "Counts equal the per-visit tallies of the individual distance records (asserted). Survey covariates as deposited: juldate as obs_date_doy (no year deposited), effort, noise, observer code and reltime (units in the paper).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/mizel_2018_alaska_sparrows_count.R")
stage_dict_row(TABLE, description = "Repeat point counts of American tree sparrow and savannah sparrow at 150 Alaska sites (466 surveys), with survey covariates.",
  url = "https://doi.org/10.5061/dryad.90kp2", reference = "Mizel, J. D., Schmidt, J. H., & Lindberg, M. S. (2018). Accommodating temporary emigration in spatial distance sampling models. Journal of Applied Ecology, 55(3).",
  doi_paper = "10.1111/1365-2664.13053", doi_data = "10.5061/dryad.90kp2", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "N-mixture counts; individual distances not shipped.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (repeated counts)",
  sampling_protocol = "point_count", design = "Single-season (up to 5 visits)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Two sparrows; distances available in the deposit.")
