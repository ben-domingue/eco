#!/usr/bin/env Rscript
# Table:  prabowo_2016_jambi_birds_count
# Source: Dryad doi:10.5061/dryad.g77m8, version 4987 (version 1, published 2017-09-22), licence CC0 1.0
#         (as shown on the Dryad landing page and in the API record).
#         Prabowo, W. E., Darras, K., Clough, Y., Toledo-Hernández, M., Arlettaz, R., Mulyani, Y. A. &
#         Tscharntke, T. "Data from: Bird responses to lowland rainforest conversion in Sumatran
#         smallholder landscapes, Indonesia".
# Paper:  Prabowo, W. E., Darras, K., Clough, Y., Toledo-Hernández, M., Arlettaz, R., Mulyani, Y. A. &
#         Tscharntke, T. (2016). Bird responses to lowland rainforest conversion in Sumatran smallholder
#         landscapes, Indonesia. PLoS ONE 11(5), e0154876, doi:10.1371/journal.pone.0154876 (open access;
#         methods read).
# Data:   six files.
#   Plots and Homegardens - survey info.csv  123 rows, one per point count visit at the 32 core plots
#            (Plot, Visit 1-4, Date, survey start and end, cloud cover % and its scaled version, Land use).
#            Despite the name it lists no homegarden visits.
#   Bird Detections - plots.csv  331 rows: one per detection (Species, time, Individuals, horizontal
#            distance in m, stratum, activity, audio / visual), with the plot's visit and guild columns
#            repeated. Nine rows with no species and Individuals = 0 are visits with no bird detected.
#            Unidentified birds are "Genus sp." or "sp.N". A species can have several rows in one visit.
#   Bird Detections - homegardens.csv, Homegarden plants.csv, Homegardens_anonymous.csv  the 16
#            homegardens (not shipped, below).
#   Point count analysis.R  the authors' analysis (read): per visit and species, abundance is the
#            maximum of Individuals over that species' rows, and unidentified birds are excluded.
#   Design (paper): 20-minute point counts at the centre of 32 plots (8 each of lowland rainforest,
#   jungle rubber, rubber and oil palm plantation) in the Bukit Duabelas and Harapan landscapes, Jambi
#   province, Sumatra, June-July 2013, between 06:00 and 10:00, by the first author, by sound and sight;
#   birds flying through or over the plot were excluded. Each plot visited four times except five
#   visited three times (the paper lists BO1; the survey table has BO5 with three visits).
#
# Mapping (standard E9 community abundance / N-mixture, responseType count, unitKind site):
#   unit = plot, taxon = 8-letter code (genus 3 + epithet 5) from the scientific name, occasion = visit (1-4), y = the
#   authors' per-visit abundance (max Individuals over the species' rows in that visit); date;
#   obs_start_time, obs_cloud_cover_pct (raw percent); unit_landuse, unit_landscape (Bukit Duabelas or
#   Harapan, from the plot code). cluster_id = landscape.
#   Survey evidence: sample_table (a visit is a row of the survey-info table; every detection row's
#   plot-visit-date is in it, asserted).
#   Coordinates: none deposited (Rhinoplax vigil is IUCN CR; nothing coordinate-level is published).
#   Not shipped: unidentified birds ("Genus sp.", "sp.N"; counted below); the scaled cloud cover
#   (derived); per-detection distance, stratum, activity and detection mode (per record, not per survey
#   taxon); the homegardens: the deposit has no homegarden survey table, the paper and the authors'
#   script disagree on their visits (the script drops visit 4 and expects 15 gardens, the paper has 16
#   visited four times), so their survey set cannot be fixed.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "prabowo_2016_jambi_birds_count"
dir <- download_dryad("doi:10.5061/dryad.g77m8", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "4987"), length(list.files(dir)) == 6L)
sv <- fread(file.path(dir, "Plots and Homegardens - survey info.csv"))
b  <- fread(file.path(dir, "Bird Detections - plots.csv"), na.strings = c("", "NA"))
stopifnot(nrow(sv) == 123L, uniqueN(sv$Plot) == 32L, !anyDuplicated(sv[, .(Plot, Visit)]), all(sv$Visit %in% 1:4),
          identical(sort(sv[, .N, by = Plot][N == 3L, Plot]), c("BF1", "BF2", "BJ2", "BJ4", "BO5")),
          all(sv$Landuse %in% c("forest", "jungle rubber", "rubber", "oil palm")),
          all(substr(sv$Plot, 1, 1) %in% c("B", "H")), sum(is.na(sv$Cloud_cover_percent)) == 16L)
sv[, date := as.IDate(Date, "%d/%m/%Y")]
stopifnot(!anyNA(sv$date), all(format(sv$date, "%Y-%m") %in% c("2013-06", "2013-07")))
stopifnot(nrow(b) == 331L, !nrow(unique(b[, .(Plot, Visit, Date)])[!sv, on = .(Plot, Visit, Date)]),
          b[is.na(Species), .N] == 9L, b[is.na(Species), all(Individuals == 0L)], b[!is.na(Species), all(Individuals >= 1L)])
unid <- b[!is.na(Species) & (grepl("sp\\.", Species))]
stopifnot(nrow(unid) == 28L)
idd <- b[!is.na(Species) & !grepl("sp\\.", Species)]
ab <- idd[, .(y = max(Individuals)), by = .(Plot, Visit, Species)]
sp <- data.table(sci = sort(unique(ab$Species)))
code6 <- function(s) { w <- strsplit(s, " ")[[1]]; toupper(paste0(substr(w[1], 1, 3), substr(w[2], 1, 5))) }
sp[, taxon := vapply(sci, code6, "")]
stopifnot(nrow(sp) == 71L, !anyDuplicated(sp$taxon))
ab[, taxon := sp$taxon[match(Species, sp$sci)]]

long <- CJ(k = seq_len(nrow(sv)), taxon = sp$taxon)
long <- cbind(sv[long$k, .(Plot, Visit, date, obs_start_time = substr(Time_survey_start, 1, 5),
                           obs_cloud_cover_pct = Cloud_cover_percent, unit_landuse = Landuse,
                           unit_landscape = fifelse(substr(Plot, 1, 1) == "B", "Bukit Duabelas", "Harapan"))], taxon = long$taxon)
long <- merge(long, ab[, .(Plot, Visit, taxon, y)], by = c("Plot", "Visit", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- order_eco(long[, .(unit = Plot, taxon, y = as.integer(y), occasion = as.integer(Visit), date = as.character(date),
                           cluster_id = unit_landscape, obs_start_time, obs_cloud_cover_pct, unit_landuse, unit_landscape)])
stopifnot(nrow(long) == 123L * 71L, sum(long$y) == sum(ab$y), long[y > 0, .N] == nrow(ab), uniqueN(long$unit) == 32L)

taxa <- make_taxa(sp$taxon, sp$sci)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# NA = GBIF's accepted name differs from the IUCN record's; where the record carries the deposit's own
# name (for three, as the synonym of a genus move: Cyornis, Pellorneum, Copsychus, same epithet) it is
# the same species and its category is taken (checked 2026-11-05).
same_name <- function(id, nm) {
  r <- fromJSON(file.path(GBIF_DIR, paste0("iucn_", sub(".*/", "", id), ".json")))
  w <- paste(head(strsplit(r$scientificName %||% "", " ")[[1]], 2), collapse = " ")
  if (identical(w, nm)) r$code %||% NA_character_ else NA_character_
}
taxa[is.na(taxon_iucnCategory), taxon_iucnCategory := mapply(same_name, taxonID, scientificName)]
stopifnot(!anyNA(taxa$taxon_iucnCategory))

dataset <- list(
  title = "Repeated 20-minute point counts of 71 bird species in 32 plots of rainforest, jungle rubber, rubber and oil palm, Jambi, Sumatra, Indonesia, 2013",
  creator = "Prabowo, Walesa Edho; Darras, Kevin; Clough, Yann; Toledo-Hernández, Manuel; Arlettaz, Raphael; Mulyani, Yeni A.; Tscharntke, Teja",
  pubDate = "2017", doi = "10.5061/dryad.g77m8", sourceURL = "https://doi.org/10.5061/dryad.g77m8",
  citation = "Prabowo, W. E., Darras, K., Clough, Y., Toledo-Hernández, M., Arlettaz, R., Mulyani, Y. A., & Tscharntke, T. (2017). Data from: Bird responses to lowland rainforest conversion in Sumatran smallholder landscapes, Indonesia [Dataset]. Dryad. https://doi.org/10.5061/dryad.g77m8",
  paperDOI = "10.1371/journal.pone.0154876",
  abstract = "Point counts of birds in 32 plots of four land-use systems (lowland rainforest, jungle rubber agroforest, rubber and oil palm plantations; eight plots each) in the Bukit Duabelas and Harapan landscapes of Jambi province, Sumatra, each visited three or four times in June-July 2013. The paper compares bird abundance, feeding-guild abundance and species richness among land uses.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "20-minute point counts at the plot centre between 06:00 and 10:00 by one observer, by sound and sight with binoculars and a rangefinder (horizontal distance recorded), unfamiliar calls recorded and checked against sound libraries; birds flying through or over the plot excluded; three or four visits per plot on non-rainy days in June-July 2013.",
  samplingProtocolCode = "point_count", surveyEvidence = "sample_table",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "three or four visits per plot within June-July 2013",
  occasionKind = "time", taxonInclusion = "recorded",
  temporalCoverage = "2013-06/2013-07",
  geographicCoverage = "Bukit Duabelas and Harapan Rainforest landscapes, Jambi province, Sumatra, Indonesia (no plot coordinates deposited)",
  notes = "y is the authors' per-visit abundance: the maximum Individuals over a species' detection rows in that visit (Point count analysis.R), not their sum. Visits with no bird detected are in the survey table and carry zero rows. Cloud cover is missing for 16 visits in the source. The paper lists BO1 among the five plots visited three times; the survey table has BO5. Bird names follow the deposit (BirdLife taxonomy per the paper). taxon_iucnCategory from GBIF's IUCN record. For four species GBIF's accepted name differs from the IUCN record, which carries the deposit's own name (three as synonyms of a genus move); their categories are taken from that record.",
  notShipped = list(unidentified = sprintf("%d detection rows of birds not identified to species ('Genus sp.' or 'sp.N')", nrow(unid)),
                    detection_details = "per-record horizontal distance, stratum, activity and audio/visual mode",
                    cloud_cover_scaled = "the authors' standardisation of cloud cover",
                    homegardens = "the 16 homegardens: no homegarden survey table is deposited and the paper (four visits each) and the authors' script (visit 4 excluded) disagree, so their survey set cannot be fixed"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/prabowo_2016_jambi_birds_count.R")
stage_dict_row(TABLE,
  description = "Repeated 20-minute point counts of 71 bird species in 32 plots of lowland rainforest, jungle rubber, rubber and oil palm in Jambi, Sumatra (June-July 2013, three or four visits per plot), with land use, date, time and cloud cover.",
  url = "https://doi.org/10.5061/dryad.g77m8",
  reference = "Prabowo, W. E., Darras, K., Clough, Y., Toledo-Hernández, M., Arlettaz, R., Mulyani, Y. A., & Tscharntke, T. (2016). Bird responses to lowland rainforest conversion in Sumatran smallholder landscapes, Indonesia. PLoS ONE, 11(5), e0154876.",
  doi_paper = "10.1371/journal.pone.0154876", doi_data = "10.5061/dryad.g77m8",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip. Core plots only (homegarden survey set not deposited); unidentified birds dropped; y = authors' max-per-visit rule.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (community counts, single season)",
  sampling_protocol = "point_count", design = "Single-season (3-4 visits)",
  realm = "Terrestrial", country = "IDN", coordinates = "None in source",
  notes = "Land-use gradient from rainforest to oil palm; includes the critically endangered helmeted hornbill.")
