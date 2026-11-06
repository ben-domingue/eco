#!/usr/bin/env Rscript
# Table:  fidino_2018_chicago_mesocarn_dynocc
# Source: Dryad doi:10.5061/dryad.k5mp137 (CC0 1.0, as shown on the Dryad page; published
#         2018-11-01). Fidino, M., Simonis, J.L. & Magle, S.B. Data from: A multi-state dynamic
#         occupancy model to estimate local colonization-extinction rates and patterns of
#         co-occurrence between two or more interacting species.
# Paper:  Fidino, M., Simonis, J.L. & Magle, S.B. (2019). Methods in Ecology and Evolution 10(2),
#         233-244, doi:10.1111/2041-210X.13117. Urban Wildlife Information Network camera
#         stations in the Chicago region, four seasons a year, spring 2010 to spring 2013.
# Data:   Fidino_MEE.zip -> data/fidino_sp_data.csv (44,772 rows: Season (SP/SU/FA/WI + 2-digit
#         year), Week (week 1-4), Date (m/d/Y), SeasonWeek, StationID, SurveyID, Coyote, Opossum,
#         Raccoon: 1 detected that day, 0 not, NA "sampling did not occur", README_for_Fidino_MEE
#         .pdf); data/fidino_covariate_data.csv (103 stations: House = housing density, Tree and
#         Imp = proportion tree and impervious cover within 1000 m; the 20 stations with fewer
#         than two seasons of data, which the authors dropped, have none); scripts and JAGS
#         models. Asserted: 123 stations x 13 seasons x 28 consecutive days, one row each; the NA
#         pattern is identical across the three species.
# Mapping (standard: dynamic community occupancy, E9 core): unit = StationID; taxon = CANLAT,
#   DIDVIR, PROLOT; period = season 1..13 in time order (__periods: label, season, year, first
#   day); occasion = day 1..28 within the season; date = Date; y = the cell; NA = no row.
#   Survey evidence: deposited_matrix. unit_: housing density, tree, impervious (NA for the 20
#   stations without covariates). No coordinates are deposited.
#   Overlap: murray_2021_chicago_coyote_mange is the same camera network's coyote days scored
#   for mange (a state response, 2010-2014, 115 stations); this table is the detection series of
#   three species from the authors' own file, a different response and taxon set (processing
#   guide: the same survey as two response types is two tables).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "fidino_2018_chicago_mesocarn_dynocc"
dir <- download_dryad("10.5061/dryad.k5mp137", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
zf <- list.files(dir, "^Fidino_MEE\\.zip$", recursive = TRUE, full.names = TRUE); stopifnot(length(zf) == 1)
ex <- file.path(dirname(zf), "unz"); if (!dir.exists(ex)) unzip(zf, exdir = ex)
b <- file.path(ex, "Fidino_MEE", "data")
d <- fread(file.path(b, "fidino_sp_data.csv"), na.strings = "NA")
cv <- fread(file.path(b, "fidino_covariate_data.csv"))
SEAS <- c("SP10", "SU10", "FA10", "WI11", "SP11", "SU11", "FA11", "WI12", "SP12", "SU12", "FA12", "WI13", "SP13")
stopifnot(nrow(d) == 44772, identical(unique(d$Season), SEAS), uniqueN(d$StationID) == 123,
          identical(d$SurveyID, paste(d$StationID, d$Season, sep = "-")),
          nrow(cv) == 103, all(cv$StationID %in% d$StationID), !anyNA(cv))
d[, dt := as.IDate(Date, format = "%m/%d/%Y")]
stopifnot(!anyNA(d$dt), !anyDuplicated(d[, .(StationID, Season, dt)]))
d[, period := match(Season, SEAS)]
setorder(d, StationID, period, dt)
d[, occasion := seq_len(.N), by = .(StationID, period)]
stopifnot(all(d[, .N, by = .(StationID, period)]$N == 28),
          d[, all(as.integer(diff(dt)) == 1), by = .(StationID, period)][, all(V1)],
          d[, uniqueN(dt), by = .(period, occasion)][, all(V1 == 1)])    # day k of a season is one calendar day
na <- is.na(as.matrix(d[, .(Coyote, Opossum, Raccoon)]))
stopifnot(all(rowSums(na) %in% c(0, 3)), sum(na[, 1]) == 18705)
s <- d[!is.na(Coyote)]
long <- melt(s[, .(unit = StationID, period, occasion, date = format(dt), CANLAT = Coyote, DIDVIR = Opossum, PROLOT = Raccoon)],
             measure.vars = c("CANLAT", "DIDVIR", "PROLOT"), variable.name = "taxon", value.name = "y", variable.factor = FALSE)
long[, y := as.integer(y)]
long <- merge(long, cv[, .(unit = StationID, unit_housing_density = House, unit_tree_cover_1km = Tree, unit_impervious_1km = Imp)],
              by = "unit", all.x = TRUE)
long <- order_eco(long)
stopifnot(nrow(long) == (44772 - 18705) * 3, all(long$y %in% 0:1), uniqueN(long$unit) == 111)   # 12 stations never sampled
pd <- d[, .(start = min(dt)), by = .(period, Season)][order(period)]
periods <- pd[, .(period, period_label = Season,
                  period_season = c(SP = "spring", SU = "summer", FA = "fall", WI = "winter")[substr(Season, 1, 2)],
                  period_year = 2000L + as.integer(substr(Season, 3, 4)), period_first_day = format(start))]
taxa <- make_taxa(c("CANLAT", "DIDVIR", "PROLOT"), c("Canis latrans", "Didelphis virginiana", "Procyon lotor"),
                  vernacularName = c("Coyote", "Virginia opossum", "Raccoon"))
dataset <- list(
  title = "Daily camera-trap detections of coyote, Virginia opossum and raccoon at 111 Chicago-area stations over 13 seasons, 2010-2013",
  creator = "Fidino, Mason; Simonis, Juniper L.; Magle, Seth B.", pubDate = "2018",
  doi = "10.5061/dryad.k5mp137", sourceURL = "https://doi.org/10.5061/dryad.k5mp137",
  citation = "Fidino, M., Simonis, J. L., & Magle, S. B. (2018). Data from: A multi-state dynamic occupancy model to estimate local colonization-extinction rates and patterns of co-occurrence between two or more interacting species [Dataset]. Dryad. https://doi.org/10.5061/dryad.k5mp137",
  paperDOI = "10.1111/2041-210X.13117",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Daily detection/non-detection of coyote, Virginia opossum and raccoon at 111 camera stations (12 more stations in the file were never sampled) of the Urban Wildlife Information Network along an urban gradient in the Chicago region, in four-week sampling seasons four times a year from spring 2010 to spring 2013 (13 seasons), with housing density, tree cover and impervious cover around 103 stations.",
  samplingProtocol = "Motion-triggered camera stations along transects radiating from downtown Chicago, each run for 28 days per season in spring, summer, fall and winter; detections per species per day.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "closed within a 28-day season, open between the 13 seasons (dynamic co-occurrence model)",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Chicago metropolitan region, Illinois, USA; no coordinates deposited",
  temporalCoverage = "2010-05/2013-05",
  notShipped = list(none = "every observation column is shipped; Week, SeasonWeek and SurveyID are recodes of Date, Season and StationID"),
  notes = "The same camera network's coyote days scored for mange are murray_2021_chicago_coyote_mange (state response). 20 of the 123 stations have fewer than two seasons of data and no covariates (the authors dropped them from the analysis); they are kept here with NA covariates.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/fidino_2018_chicago_mesocarn_dynocc.R")
stage_dict_row(TABLE,
  description = "Daily camera-trap detection/non-detection of coyote, opossum and raccoon at 111 Chicago-area stations over 13 seasons (2010-2013), with urbanisation covariates.",
  url = "https://doi.org/10.5061/dryad.k5mp137",
  reference = "Fidino, M., Simonis, J. L., & Magle, S. B. (2019). A multistate dynamic occupancy model to estimate local colonization-extinction rates and patterns of co-occurrence between two or more interacting species. Methods in Ecology and Evolution, 10(2), 233-244.",
  doi_paper = "10.1111/2041-210X.13117", doi_data = "10.5061/dryad.k5mp137", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic co-occurrence input; overlaps the coyote mange table murray_2021_chicago_coyote_mange (different response).", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Dynamic community occupancy (co-occurrence)",
  sampling_protocol = "camera_trap", design = "Multi-season (13 seasons x 28 days)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Urban gradient; three interacting mesocarnivores.")
