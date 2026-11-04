#!/usr/bin/env Rscript
# Table:  dettling_2021_marin_riparian_count
# Source: Dryad doi:10.5061/dryad.7d7wm37vj (CC0 1.0), version 131113, published 2021-07-22.
#   Dettling, M.D., Dybala, K.E., Humple, D.L. & Gardali, T. (2021). Avian point count data from
#   riparian corridors of protected areas in Marin County California. Dryad.
# Paper:  Dettling, M.D., Dybala, K.E., Humple, D.L. & Gardali, T. (2021). Protected areas safeguard
#   landbird populations in central coastal California: Evidence from long-term population trends.
#   Ornithological Applications 123(4): duab035. doi:10.1093/ornithapp/duab035 (CC BY 4.0).
# Data:   MarinCountCA_avian_point_count_data.csv: 65,968 rows x 6 columns (Transect, Point, Year,
#         Visit, Spp, Count), one row per point-count station x year x visit x species for 14
#         species, with Count = individuals detected aurally or visually within 50 m in 5 minutes,
#         0 when the species was not detected. 183 points on 13 riparian transects (Point =
#         Transect_number), 1997-2019, visits 1-3 (chronological within 1 May-30 June; mostly 2,
#         sometimes 3 in early years, some point-years have only visit 2 or 2-3). Every point-visit
#         carries exactly 14 species rows, so the point-visit set is the survey set. The README
#         says 17 species and 80,104 rows; the deposited file has 14 and 65,968 (asserted; the
#         authors state only selected species were included). Point Blue Conservation Science;
#         data also at the California Avian Data Center. No dates, observers, coordinates or
#         covariates are deposited.
#
# Mapping (standard section 3.2, N-mixture community counts from a per-survey species table):
#   unit = Point (183), cluster_id = Transect (13), period = year index 1..23 (1997-2019, calendar
#   year in __periods), occasion = Visit as deposited (1-3, chronological within the year),
#   taxon = 4-letter BBL/IBP alpha code, y = Count. surveyEvidence = sample_table: a point-visit is
#   surveyed iff it has rows, and it then has a row (0 or count) for every one of the 14 species.
#   Not shipped: nothing withheld; the other species counted in the field were not deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "dettling_2021_marin_riparian_count"
dir <- download_dryad("10.5061/dryad.7d7wm37vj", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "MarinCountCA_avian_point_count_data.csv$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
d <- fread(f)
stopifnot(identical(names(d), c("Transect", "Point", "Year", "Visit", "Spp", "Count")),
          nrow(d) == 65968, !anyNA(d), uniqueN(d$Spp) == 14, uniqueN(d$Point) == 183, uniqueN(d$Transect) == 13,
          all(sub("_[0-9]+$", "", d$Point) == d$Transect), all(d$Visit %in% 1:3), all(d$Year %in% 1997:2019),
          all(d$Count >= 0), max(d$Count) == 10, !anyDuplicated(d[, .(Point, Year, Visit, Spp)]))
# every point-visit has exactly the 14 species rows: the point-visit list is the survey set
pv <- d[, .N, by = .(Point, Year, Visit)]
stopifnot(nrow(pv) == 4712, all(pv$N == 14))
cat(sprintf("  %d point-visits, %d points, %d transects, %d years\n", nrow(pv), uniqueN(d$Point), uniqueN(d$Transect), uniqueN(d$Year)))

# taxa: IBP-AOS alpha codes; eight of the fourteen are not in data/aux/bird_alpha_codes.csv and are
# given here from the IBP-AOS list (Pyle & DeSante)
species <- sort(unique(d$Spp))
alpha <- fread(file.path(ECO_ROOT, "data", "aux", "bird_alpha_codes.csv"))[, .(code, commonName, scientificName)]
extra <- data.table(code = c("BEWR", "BHGR", "CASJ", "CBCH", "NUWO", "OCWA", "SPTO", "WREN"),
                    commonName = c("Bewick's Wren", "Black-headed Grosbeak", "California Scrub-Jay", "Chestnut-backed Chickadee",
                                   "Nuttall's Woodpecker", "Orange-crowned Warbler", "Spotted Towhee", "Wrentit"),
                    scientificName = c("Thryomanes bewickii", "Pheucticus melanocephalus", "Aphelocoma californica", "Poecile rufescens",
                                       "Dryobates nuttallii", "Leiothlypis celata", "Pipilo maculatus", "Chamaea fasciata"))
stopifnot(!any(extra$code %in% alpha$code))
alpha <- rbind(alpha[code %in% species], extra)
stopifnot(setequal(alpha$code, species), !anyDuplicated(alpha$code))
alpha <- alpha[match(species, code)]
taxa <- make_taxa(species, alpha$scientificName, vernacularName = alpha$commonName)
stopifnot(!anyNA(taxa$taxonID))

years <- 1997:2019
long <- d[, .(unit = Point, taxon = Spp, y = Count, period = match(Year, years), occasion = Visit, cluster_id = Transect)]
long <- order_eco(long)
stopifnot(nrow(long) == 4712 * 14, sum(long$y) == sum(d$Count))
periods <- data.table(period = seq_along(years), year = years)
periods <- merge(periods, long[, .(n_points = uniqueN(unit), n_point_visits = uniqueN(paste(unit, occasion))), by = period], by = "period")

dataset <- list(
  title = "Point counts of 14 riparian landbird species at 183 stations on 13 transects in protected areas of Marin County, California, 1997-2019",
  creator = "Dettling, Mark D.; Dybala, Kristen E.; Humple, Diana L.; Gardali, Thomas",
  pubDate = "2021", doi = "10.5061/dryad.7d7wm37vj", sourceURL = "https://doi.org/10.5061/dryad.7d7wm37vj",
  citation = "Dettling, M.D., Dybala, K.E., Humple, D.L. & Gardali, T. (2021). Avian point count data from riparian corridors of protected areas in Marin County California. Dryad. https://doi.org/10.5061/dryad.7d7wm37vj. Paper: Ornithological Applications 123(4): duab035, https://doi.org/10.1093/ornithapp/duab035",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Simplified avian point-count data collected by Point Blue Conservation Science in Marin County, California, 1997-2019: 5-minute point counts twice (occasionally three times) per breeding season between 1 May and 30 June along riparian transects in Point Reyes National Seashore, Golden Gate National Recreation Area, Mount Tamalpais State Park and Bolinas Lagoon Open Space Preserve. Counts are individuals detected within 50 m; the deposit includes 14 selected species with a row (including zeros) at every point-visit.",
  samplingProtocol = "5-minute point counts, detections (aural and visual) within 50 m of a fixed station; stations along riparian transects surveyed in one morning; chronological visits within 1 May-30 June, normally two per year.",
  samplingProtocolCode = "point_count", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion (visits within a breeding season); period = year", occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = list(description = "Riparian corridors in protected areas of Marin County, California, USA (Point Reyes NS, GGNRA, Mount Tamalpais SP, Bolinas Lagoon OSP); no coordinates deposited"),
  temporalCoverage = "1997-05/2019-06",
  notes = "The point-visit set is the deposit's own: every surveyed point-visit has exactly 14 species rows with explicit zeros, so no survey set was inferred. Visit is the deposit's chronological visit number within the year (1-3); some point-years have only visit 2, or visits 2-3, and visit numbers do not map to fixed calendar windows. The README states 17 species and 80,104 rows; the file has 14 species and 65,968 rows. Unbalanced: 44-183 points per year.",
  notShipped = list(`other species` = "the authors counted all species but deposited only 14 selected for the paper's trend analysis",
                    `dates, observers, coordinates` = "not deposited (available from the California Avian Data Center)"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/dettling_2021_marin_riparian_count.R")

stage_dict_row(TABLE,
  description = "Counts of 14 riparian landbird species on 4,712 five-minute 50 m point counts at 183 stations on 13 riparian transects in protected areas of Marin County, California (1997-2019; normally two visits per breeding season), with explicit zeros as deposited by Point Blue Conservation Science.",
  url = "https://doi.org/10.5061/dryad.7d7wm37vj",
  reference = "Dettling, M.D., Dybala, K.E., Humple, D.L. & Gardali, T. (2021). Protected areas safeguard landbird populations in central coastal California: Evidence from long-term population trends. Ornithological Applications 123(4): duab035.",
  doi_paper = "10.1093/ornithapp/duab035", doi_data = "10.5061/dryad.7d7wm37vj",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Deposit is a per-survey species table with explicit zeros (14 of the species counted). No dates, observers or coordinates deposited. README species/row counts (17 / 80,104) differ from the file (14 / 65,968).",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "point_count", design = "Multi-season (23 years x 1-3 visits)", realm = "Terrestrial", country = "USA",
  coordinates = "None in source", notes = "Long-term riparian monitoring; 14 selected species; unbalanced point coverage across years (44-183 points).",
  status = "tagged")
