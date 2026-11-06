#!/usr/bin/env Rscript
# Table:  iknayan_2023_svalley_pollinator_occ
# Source: Dryad doi:10.5061/dryad.0k6djhb68 (CC0 1.0, as shown on the Dryad page; published
#         2023-12-27). Iknayan, K., Heath, S., Terrill, S., Wenny, D., Panlasigui, S., Wang, Y.,
#         Beller, E. & Spotswood, E. Patterns in bird and pollinator occupancy and richness in a
#         mosaic of urban office parks across scales and seasons.
# Paper:  Iknayan, K. et al. (2024). Ecology and Evolution, doi:10.1002/ece3.10958. Office-park
#         sites in Palo Alto, Mountain View and Sunnyvale (Santa Clara Valley, California); one
#         100 m2 pollinator plot per 1-ha site, visual 15-minute surveys between 10:00 and 15:00
#         in spring, early summer and late summer 2017 by one entomologist, recording every
#         invertebrate on flowers to the lowest feasible rank (Dryad methods).
# Data:   data.zip -> data/pollinator_survey_data.RDS, a list: meta_data (118 surveys: survey_id,
#         plot_id (41 plots), survey_date 2017-04-27..2017-09-22, visit_number 1-4), raw_data
#         (696 records: survey_id, pollinator taxon (original and harmonised `species`, 42
#         taxa), plant visited, count = n_obs_interactions, ITIS ids), det_covs (j_date) and eh
#         (42 taxa x 4 visits x 41 transects, 0/1: the authors' detection array, NA where not
#         surveyed and in 3 taxon-surveys whose raw count is NA). data/model_data.RDS holds the
#         bird arrays (not built here: see the queue note). README.md, metadata.txt.
# Mapping (standard: community occupancy, E9 core): unit = plot_id; taxon = harmonised taxon
#   (most at genus, as the surveyor identified them); occasion = visit_number; date =
#   survey_date; y = 1 if the taxon has any raw record at the survey, else 0 (asserted equal to
#   eh wherever eh is not NA, and 1 in the 3 cells eh leaves NA because the count was not
#   recorded); obs_individuals = summed count (NA in those 3 cells). Survey evidence:
#   sample_table (meta_data lists every survey; every taxon gets a row at every survey).
#   Not shipped: the plant visited by each record (interaction data); ITIS ids (taxa are
#   matched on GBIF instead). No coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "iknayan_2023_svalley_pollinator_occ"
dir <- download_dryad("10.5061/dryad.0k6djhb68", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^data\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
p <- readRDS(file.path(ex, "data", "pollinator_survey_data.RDS"))
md <- as.data.table(p$meta_data); r <- as.data.table(p$raw_data); eh <- p$eh
stopifnot(nrow(md) == 118, !anyDuplicated(md$survey_id), uniqueN(md$plot_id) == 41,
          !anyDuplicated(md[, .(plot_id, visit_number)]), all(r$survey_id %in% md$survey_id),
          !anyNA(r$species), uniqueN(r$species) == 42, setequal(r$species, dimnames(eh)$species))
codes0 <- sort(unique(r$species))
nm <- sub(" (sp\\.|gn\\.)$", "", codes0)
rank <- ifelse(grepl("gn\\.$", codes0), "family", ifelse(grepl("sp\\.$", codes0), "genus", "species"))
code <- ifelse(rank == "species", toupper(paste0(substr(nm, 1, 3), substr(sub("^\\S+ ", "", nm), 1, 3))), toupper(nm))
stopifnot(!anyDuplicated(code))
r[, species := code[match(species, codes0)]]
cnt <- r[, .(det = 1L, n = if (anyNA(count)) NA_real_ else sum(count)), by = .(survey_id, species)]
stopifnot(sum(is.na(cnt$n)) == 3)
long <- CJ(survey_id = md$survey_id, taxon = sort(unique(r$species)))
long <- merge(long, cnt[, .(survey_id, taxon = species, det, n)], by = c("survey_id", "taxon"), all.x = TRUE)
long[is.na(det), `:=`(det = 0L, n = 0)]
long <- merge(long, md[, .(survey_id, unit = plot_id, occasion = as.integer(visit_number), date = format(as.IDate(survey_date)))], by = "survey_id")
# agreement with the authors' detection array
ehv <- eh[cbind(match(codes0[match(long$taxon, code)], dimnames(eh)$species), match(as.character(long$occasion), dimnames(eh)$visit),
                match(long$unit, dimnames(eh)$transect))]
stopifnot(all(ehv[!is.na(ehv)] == long$det[!is.na(ehv)]), sum(is.na(ehv)) == 3, all(long$det[is.na(ehv)] == 1))
long <- order_eco(long[, .(unit, taxon, y = det, occasion, date, obs_individuals = n)])
stopifnot(nrow(long) == 118 * 42)
nk <- code[codes0 %in% c("Ceratina sp.", "Osmia sp.")]
taxa <- make_taxa(code, codes0, lookupName = nm, taxonRank = rank, allow_higher = setdiff(code[rank != "species"], nk), no_key = nk,
                  taxonRemarks = ifelse(code %in% nk, "genus; no taxonID: GBIF strict matching does not resolve the genus name uniquely", NA))
dataset <- list(
  title = "Visual detections of 42 flower-visiting insect taxa on 1-4 surveys of 41 office-park plots in Silicon Valley, California, 2017",
  creator = "Iknayan, Kelly; Heath, Sacha; Terrill, Scott; Wenny, Daniel; Panlasigui, Stephanie; Wang, Yiwei; Beller, Erin; Spotswood, Erica",
  pubDate = "2023", doi = "10.5061/dryad.0k6djhb68", sourceURL = "https://doi.org/10.5061/dryad.0k6djhb68",
  citation = "Iknayan, K. et al. (2023). Patterns in bird and pollinator occupancy and richness in a mosaic of urban office parks across scales and seasons [Dataset]. Dryad. https://doi.org/10.5061/dryad.0k6djhb68",
  paperDOI = "10.1002/ece3.10958",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Detection/non-detection, with individual counts, of 42 flower-visiting insect taxa (bees, wasps, flies, butterflies; mostly identified to genus by sight) on 15-minute visual surveys of 100 m2 plots at 41 office-park sites in Palo Alto, Mountain View and Sunnyvale, California, 1-4 surveys per plot between April and September 2017.",
  samplingProtocol = "One 100 m2 plot in the most floriferous vegetation of each 1-ha site; 15-minute meandering visual survey between 10:00 and 15:00 by one entomologist recording every invertebrate on flowers, identified by sight to the lowest feasible rank; spring, early summer and late summer 2017.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "sample_table", responseType = "detection",
  unitKind = "site", closure = "open", closureNote = "visits span April to September; the authors analysed season-specific richness indices",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Office parks in Palo Alto, Mountain View and Sunnyvale, Santa Clara County, California, USA; no coordinates deposited",
  temporalCoverage = "2017-04/2017-09",
  notShipped = list(plant_visited = "the flower each record was on (plant-pollinator interaction data)",
                    bird_arrays = "model_data.RDS bird detection arrays (a 3 x 3 visit structure the deposit does not define; queued for review)"),
  notes = "y is detection; obs_individuals is the summed count of individuals recorded (NA in 3 taxon-surveys where a record has no count: Apis twice, Ceratina once). Taxa named 'X sp.' are at genus and 'X gn.' at family, as identified by the surveyor.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/iknayan_2023_svalley_pollinator_occ.R")
stage_dict_row(TABLE,
  description = "Visual detection/non-detection and counts of 42 flower-visiting insect taxa on 118 surveys of 41 office-park plots in Silicon Valley, California, 2017.",
  url = "https://doi.org/10.5061/dryad.0k6djhb68",
  reference = "Iknayan, K. et al. (2024). Patterns in bird and pollinator occupancy and richness in a mosaic of urban office parks across scales and seasons. Ecology and Evolution.",
  doi_paper = "10.1002/ece3.10958", doi_data = "10.5061/dryad.0k6djhb68", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Pollinator community detections from the raw survey records; bird arrays held.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Community occupancy (single season)",
  sampling_protocol = "visual_encounter", design = "Single-season (1-4 visual surveys per plot)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Urban pollinators, mostly genus rank.")
