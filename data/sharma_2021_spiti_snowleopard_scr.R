#!/usr/bin/env Rscript
# Table:  sharma_2021_spiti_snowleopard_scr
# Source: Dryad, doi:10.5061/dryad.3r2280gfx, version 122668 (version 4, published 2021-06-02), licence CC0 1.0 as
#         shown on the Dryad dataset page (asserted from the dataset JSON). Sharma, R. K., Sharma, K., Borchers, D.,
#         Bhatnagar, Y. V., Suryawanshi, K. R. & Mishra, C.
# Paper:  Sharma, R. K. et al. (2021). Spatial variation in population-density, movement and detectability of snow
#         leopards in a multiple use landscape in Spiti Valley, Trans-Himalaya. PLOS ONE 16(5): e0250900,
#         doi:10.1371/journal.pone.0250900 (open access, read for this script). Methods, "Estimating snow leopard
#         population density using camera traps" (p. 4): Reconyx RM45 cameras at 30 sites, October 2011 to January
#         2012, 80 days, 14 single and 16 double placements, no bait or lure; snow leopards at 25 of 30 sites;
#         a set of photographs is a new encounter when at least four hours from the previous set of the same animal
#         (count detectors); 124 encounters, 12 discarded as unidentifiable; 16 adults identified from both-side and
#         right-side flanks, with complete identification. The model (p. 6) uses topography as a trap factor with
#         levels ridgeline, cliff and gully bed, and single vs double cameras.
# Data:   Rishi_captures_encrypted.csv: 112 encounters (#SessionID 1, ID, Occasion 1, TrapID 1..30), the secr
#           count-detector capture file: one row per encounter.
#         Rishi_Traps_encrypted.csv: 30 traps: ID, X, Y (World Mercator metres with a constant added to each of x
#           and y by the authors, the Dryad usage notes say, so distances are true and the location is hidden),
#           Effort (days operated, 14-44), Covariates ('/'), Z (trap topography code C / N / R), Two_Camera.
#         Rishi_mask_encrypted.csv: the 20,513-point SCR habitat mask with prey density, ruggedness, altitude,
#           livestock and their standardised forms.
# Mapping (count-detector SCR, ruling 2026-11-06, E9): unitKind individual, responseType count, unit = the
#   leopard's id, taxon = PANUNC, trap = camera site, y = the individual's encounters at the trap under the
#   4-hour independence rule, obs_effort_days = the trap's days of operation (effortColumn). One occasion, so no
#   occasion column; every individual has a row at every one of the 30 traps (16 x 30 = 480 rows).
#   surveyEvidence = effort_table (Effort > 0 at all 30 traps, asserted). __traps: x, y (as deposited),
#   effort_days, topography_code (Z as deposited: C, N, R; the paper's levels are ridgeline, cliff, gully bed,
#   and the deposit does not spell out the letters), two_camera.
#   Coordinates (E7): snow leopard is IUCN VU; the source displaced the coordinates itself by undisclosed
#   constant offsets, so they are shipped as published (E7 ruling 5) and coordinatesCoarsened says how.
#   Partial identity (E2): the paper reports complete identification of all 16 adults (both-side and right-side
#   flanks, no left-only individuals), so no unit_identity column.
# Not shipped: the habitat mask (a model input: a grid of habitat covariates, not a survey record); the density
#   and detection estimates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "sharma_2021_spiti_snowleopard_scr"

dir <- download_dryad("10.5061/dryad.3r2280gfx", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 3)
cap <- fread(file.path(dir, "Rishi_captures_encrypted.csv"), colClasses = list(character = "ID"))
setnames(cap, c("session", "id", "occasion", "trap"))
tr <- fread(file.path(dir, "Rishi_Traps_encrypted.csv"))
setnames(tr, c("trap", "x", "y", "effort", "covs", "z", "two_camera"))
stopifnot(nrow(cap) == 112L, all(cap$session == 1L), all(cap$occasion == 1L), uniqueN(cap$id) == 16L,
          nrow(tr) == 30L, identical(tr$trap, 1:30), all(cap$trap %in% tr$trap), uniqueN(cap$trap) == 25L,
          all(tr$effort > 0), sum(tr$two_camera == "Yes") == 16L, sum(tr$two_camera == "No") == 14L,
          all(tr$covs == "/"), setequal(tr$z, c("C", "N", "R")))
cat(sprintf("  traps with a snow leopard: %d of 30 (paper: 25)\n", uniqueN(cap$trap)))

grid <- CJ(unit = sort(unique(cap$id)), trap = tr$trap)
cnt <- cap[, .(y = .N), by = .(unit = id, trap)]
long <- cnt[grid, on = .(unit, trap)]
long[is.na(y), y := 0L]
long <- merge(long, tr[, .(trap, obs_effort_days = effort)], by = "trap")
long[, `:=`(taxon = "PANUNC", trap = as.character(trap))]
long <- order_eco(long)
stopifnot(nrow(long) == 480L, sum(long$y) == 112L, all(long[, sum(y), by = unit]$V1 >= 1L))

traps <- tr[, .(trap = as.character(trap), x, y, effort_days = effort, topography_code = z,
                two_camera = as.integer(two_camera == "Yes"))]
taxa <- make_taxa("PANUNC", "Panthera uncia", vernacularName = "Snow leopard")

dataset <- list(
  title = "Count-detector spatial capture-recapture of 16 snow leopards at 30 camera traps, Spiti Valley, India, October 2011 to January 2012",
  creator = "Sharma, Rishi Kumar; Sharma, Koustubh; Borchers, David; Bhatnagar, Yash Veer; Suryawanshi, Kulbhushan Singh; Mishra, Charudutt",
  pubDate = "2021", doi = "10.5061/dryad.3r2280gfx", sourceURL = "https://doi.org/10.5061/dryad.3r2280gfx",
  citation = "Sharma, R. K., Sharma, K., Borchers, D., Bhatnagar, Y. V., Suryawanshi, K. S., & Mishra, C. (2021). Spatial variation in population-density, movement and detectability of snow leopards in a multiple use landscape in Spiti Valley, Trans-Himalaya [Dataset]. Dryad. https://doi.org/10.5061/dryad.3r2280gfx",
  paperDOI = "10.1371/journal.pone.0250900",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Camera traps at 30 sites over 953 km2 of Spiti Valley, Himachal Pradesh, India, operated for 80 days from October 2011 to January 2012; 16 adult snow leopards identified from pelage, 112 identifiable encounters. The authors fitted count-detector SCR (secr) with density depending on wild prey density. One row per leopard x camera site: the number of encounters (sets of photographs at least four hours apart) over the deployment, with the site's days of operation.",
  samplingProtocol = "Unbaited camera traps (single or paired to photograph both flanks) at sites with snow leopard sign, operated 14-44 days each over 80 days; encounters are sets of photographs of one individual separated by at least four hours (the authors' independence rule for count detectors).",
  samplingProtocolCode = "camera_trap", surveyEvidence = "effort_table",
  responseType = "count", unitKind = "individual",
  closure = "none", closureNote = "a single deployment of 80 days treated by the authors as closed, with no temporal effect on detection; the count over the deployment is the observation",
  occasionKind = "none", taxonInclusion = "single", effortColumn = "obs_effort_days",
  geographicCoverage = "Spiti Valley, Lahaul and Spiti district, Himachal Pradesh, India (about 32.2 N, 78.0 E); trap coordinates displaced by the source",
  temporalCoverage = "2011-10/2012-01",
  crs = "local: World Mercator metres with an undisclosed constant added to x and to y by the source (distances between traps are true)",
  coordinatesCoarsened = list(value = FALSE, method = "Displaced by the source: the authors added two undisclosed constants to the World Mercator x and y of every trap (and the mask) to hide the locations of a VU species; shipped as published (E7 ruling 5)"),
  covariateNote = "obs_effort_days: days the camera site operated (the deposit's trap Effort), the same on every row of a trap. __traps topography_code is the deposit's Z (C, N, R); the paper's topography levels are ridgeline, cliff and gully bed.",
  notShipped = list(mask = "Rishi_mask_encrypted.csv: the SCR habitat mask (20,513 points with prey density, ruggedness, altitude, livestock covariates), a model input, not a survey record",
                    unidentified = "12 encounters the authors discarded as unidentifiable are not in the deposit",
                    model_output = "density, movement and detectability estimates"),
  notes = "Encounters, not photographs: 2,830 images make 124 encounters under the four-hour rule, of which the 112 identified are here. All 16 individuals are adults with complete identification (paper p. 4).")

ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = "data/sharma_2021_spiti_snowleopard_scr.R")
stage_dict_row(TABLE,
  description = "Encounter counts of 16 individually identified snow leopards at 30 camera-trap sites in Spiti Valley, Himachal Pradesh, India, over 80 days in 2011-2012 (count-detector SCR), with each site's days of operation and displaced trap coordinates.",
  url = "https://doi.org/10.5061/dryad.3r2280gfx",
  reference = "Sharma, R. K., Sharma, K., Borchers, D., Bhatnagar, Y. V., Suryawanshi, K. R., & Mishra, C. (2021). Spatial variation in population-density, movement and detectability of snow leopards in a multiple use landscape in Spiti Valley, Trans-Himalaya. PLOS ONE, 16(5), e0250900.",
  doi_paper = "10.1371/journal.pone.0250900", doi_data = "10.5061/dryad.3r2280gfx",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Count-detector SCR (ruling 2026-11-06): y = encounters per individual x trap under a 4-hour rule; coordinates displaced by the source; habitat mask not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (count detectors, camera traps)",
  sampling_protocol = "camera_trap", design = "Single-season (one 80-day deployment; 30 camera sites)",
  realm = "Terrestrial", country = "IND", coordinates = "As published (displaced by the source)",
  notes = "Experimental (E9): count-detector SCR, trap key + __traps; IUCN VU.")
