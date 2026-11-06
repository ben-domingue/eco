#!/usr/bin/env Rscript
# Table:  poutanen_2018_finland_whitetail_scr
# Source: Dryad doi:10.5061/dryad.43j74d0 (CC0 1.0, as shown on the Dryad page; published
#         2018-12-18). Poutanen, J., Pusenius, J., Wikstrom, M. & Brommer, J.E. Data from:
#         Estimating population density of the white-tailed deer in Finland using non-invasive
#         genetic sampling and spatial capture-recapture.
# Paper:  Poutanen, J. et al. (2019). Annales Zoologici Fennici 56, doi:10.5735/086.056.0101.
#         Faecal DNA from 180 20 x 20 m plots in clusters of four, three weekly visits in autumn
#         2015; 27 individuals identified from 36 genotyped samples (abstract).
# Data:   tdf.txt (180 plots: ID, X, Y, occ1-occ3 usage 0/1), edf.txt (36 encounters: Session =
#         1, ID 1-27, Occasion 1-3, TrapID, Sex F/M), RscriptAnalyses.txt (secr proximity
#         detectors, 3 occasions; per-occasion precipitation 0.1 / 2.9 / 0.3 mm in the script).
# Mapping (standard: E9 experimental, SCR; proximity detectors): unit = deer ID ("D01"...); taxon
#   = ODOVIR; trap = plot ID; occasion = visit 1..3; y = 1 if the deer's faeces were genotyped
#   from the plot at that visit. Rows: every individual x every plot-visit with usage = 1 (full
#   rectangle, ruling #30). Survey evidence: effort_table (usage columns of tdf). unit_sex.
#   obs_precip_mm from the authors' script (one value per visit). __traps: plot x, y as
#   deposited (projected metres; values consistent with ETRS89 / TM35FIN, EPSG:3067, which the
#   deposit does not name). White-tailed deer is introduced in Finland and IUCN LC: as published.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "poutanen_2018_finland_whitetail_scr"
dir <- download_dryad("10.5061/dryad.43j74d0", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rf <- function(n) { f <- list.files(dir, paste0("^", n, "$"), recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1); fread(f) }
td <- rf("tdf\\.txt"); ed <- rf("edf\\.txt")
stopifnot(identical(names(td), c("ID", "X", "Y", "occ1", "occ2", "occ3")), nrow(td) == 180, !anyDuplicated(td$ID),
          identical(names(ed), c("Session", "ID", "Occasion", "TrapID", "Sex")), nrow(ed) == 36, all(ed$Session == 1),
          uniqueN(ed$ID) == 27, all(ed$TrapID %in% td$ID), all(ed$Occasion %in% 1:3), all(ed$Sex %in% c("F", "M")),
          ed[, uniqueN(Sex), by = ID][, all(V1 == 1)], !anyDuplicated(ed[, .(ID, Occasion, TrapID)]))
U <- melt(td[, .(trap = ID, occ1, occ2, occ3)], id.vars = "trap", variable.name = "o", value.name = "use")[use == 1]
U[, occasion := as.integer(sub("occ", "", o))]
stopifnot(all(paste(ed$TrapID, ed$Occasion) %in% paste(U$trap, U$occasion)))
long <- CJ(ID = sort(unique(ed$ID)), i = seq_len(nrow(U)))
long <- cbind(long[, .(ID)], U[long$i, .(trap, occasion)])
long <- merge(long, ed[, .(ID, trap = TrapID, occasion = Occasion, y = 1L)], by = c("ID", "trap", "occasion"), all.x = TRUE)[is.na(y), y := 0L]
long <- merge(long, unique(ed[, .(ID, unit_sex = Sex)]), by = "ID")
long[, `:=`(unit = sprintf("D%02d", ID), taxon = "ODOVIR", obs_precip_mm = c(0.1, 2.9, 0.3)[occasion])][, ID := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 27 * nrow(U), sum(long$y) == 36)
traps <- td[, .(trap = ID, x = X, y = Y, used_occ1 = occ1, used_occ2 = occ2, used_occ3 = occ3)]
taxa <- make_taxa("ODOVIR", "Odocoileus virginianus", vernacularName = "White-tailed deer")
dataset <- list(
  title = "Faecal-DNA spatial capture-recapture of 27 white-tailed deer at 180 sample plots in southwestern Finland, three weekly visits, autumn 2015",
  creator = "Poutanen, Jenni; Pusenius, Jyrki; Wikström, Mikael; Brommer, Jon E.", pubDate = "2018",
  doi = "10.5061/dryad.43j74d0", sourceURL = "https://doi.org/10.5061/dryad.43j74d0",
  citation = "Poutanen, J., Pusenius, J., Wikström, M., & Brommer, J. E. (2018). Data from: Estimating population density of the white-tailed deer in Finland using non-invasive genetic sampling and spatial capture-recapture [Dataset]. Dryad. https://doi.org/10.5061/dryad.43j74d0",
  paperDOI = "10.5735/086.056.0101",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Genotyped faecal samples of white-tailed deer (Odocoileus virginianus) from 180 20 x 20 m plots in clusters of four, searched on three weekly visits in autumn 2015 in southwestern Finland: one row per identified deer x plot-visit in use, y = 1 where the deer was genotyped, with sex and plot coordinates.",
  samplingProtocol = "Faecal pellet groups collected from 180 fixed 20 x 20 m plots (clusters of four) on three weekly visits; individuals and sex identified from 12-14 microsatellites; plots are proximity detectors.",
  samplingProtocolCode = "noninvasive_genetic", surveyEvidence = "effort_table", responseType = "detection",
  unitKind = "individual", closure = "closed", closureNote = "three weekly visits before the hunting season, analysed as closed (secr)",
  occasionKind = "time", taxonInclusion = "single", crs = "projected metres as deposited; no CRS named (values consistent with ETRS89 / TM35FIN, EPSG:3067)",
  geographicCoverage = "Southwestern Finland (study plots in __traps)", temporalCoverage = "2015",
  coordinatesCoarsened = list(value = FALSE, method = "as published: white-tailed deer is introduced in Finland and IUCN LC"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key (sample plot) and __traps, usage per occasion.",
  notShipped = list(none = "the encounter and plot files are shipped whole; precipitation per visit comes from the authors' script"),
  notes = "obs_precip_mm is the per-visit precipitation the authors give in their R script (0.1, 2.9, 0.3 mm). 209 of 245 faecal samples could not be identified to an individual (abstract); they are not in the deposit.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, traps = traps, script = "data/poutanen_2018_finland_whitetail_scr.R")
stage_dict_row(TABLE,
  description = "Faecal-DNA SCR of 27 white-tailed deer at 180 plots in Finland, three weekly visits in autumn 2015, with plot usage and coordinates.",
  url = "https://doi.org/10.5061/dryad.43j74d0",
  reference = "Poutanen, J., Pusenius, J., Wikström, M., & Brommer, J. E. (2019). Estimating population density of the white-tailed deer in Finland using non-invasive genetic sampling and spatial capture-recapture. Annales Zoologici Fennici, 56.",
  doi_paper = "10.5735/086.056.0101", doi_data = "10.5061/dryad.43j74d0", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "SCR (E9 experimental), plots as proximity detectors.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture",
  sampling_protocol = "noninvasive_genetic", design = "Single-season (3 weekly visits, 180 plots)", realm = "Terrestrial",
  country = "FIN", coordinates = "As published (projected metres in __traps)", notes = "Experimental (E9).")
