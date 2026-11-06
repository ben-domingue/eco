#!/usr/bin/env Rscript
# Tables: gapinski_2025_iowawrp_birds_occ, gapinski_2025_iowawrp_focal_count, gapinski_2025_iowawrp_point_occ
# Source: USGS ScienceBase doi:10.5066/P13DFQSX (USGS data release, ver. 3.0, July 2026; use
#         constraints: "marked with a Creative Common CC0 1.0 Universal License ... public domain");
#         CC0 1.0
#   Gapinski, L.A., Kinkead, K.E., Tucker, A.M., Dinsmore, S.J., and Bishop, T., 2025, Bird point
#   count and covariate data from wetland easements in Iowa, 2007-2009 and 2022-2023 (ver. 3.0, July
#   2026): U.S. Geological Survey data release.
# Data:   Point counts at 7-10 points on each of 55 Iowa wetland easements (Wetlands Reserve Program),
#         15 May to 31 July, in 2007-2009 and again in 2022-2023, deposited as three analysis sets:
#         wrp_bird_data2.csv (property x year x visit x 123 species: present 1 / absent 0 at any
#         point of the property on that visit, NA = no survey; guild) with wrp_covs_combined.csv
#         (property-year: ordinal date, observer and number of points surveyed at each of up to six
#         visits, percent woody cover, easement age in 2007, spatial cluster ids);
#         bpc_for_nmix_and_occ.csv (the same property visits, total individuals of 16 focal species
#         summed over the points) with covs_for_nmix_and_occ.csv (the same dates and points, keyed by
#         property number); multispecies_as_dataframe.csv (2022-2023, point x year x 54 species,
#         presence at visits 1-3, NA = point not surveyed that visit) with multispecies_covs.csv
#         (point-year vegetation: emergent cover, water and trees present, mean dbh, visual
#         obstruction, litter depth, forb / grass / woody cover, easement age; minutes after sunrise,
#         ordinal date and observer id per visit; deposited with each row repeated).
#         Asserted: 571 property-year-visits surveyed, the NA pattern identical across species in
#         every file, the same 571 visits in the presence and count files, the two property-level
#         covariate files agree on dates and points, focal count > 0 exactly where the presence file
#         has 1, and the point file's points match its covariate file.
# Mapping: three tables (two response types, and a point-level survey that the property file cannot
#   be rebuilt from: 54 of its 123 species, 2022-2023 only).
#   _birds_occ: unit = property, period = year (2007, 2008, 2009, 2022, 2023), occasion = visit,
#     y = presence on the visit (aggregated over the points by the source: the survey's observation,
#     E1), taxonInclusion recorded; date from year + ordinal date; observer; obs_n_points; period_
#     percent woody; unit_easement_age_2007.
#   _focal_count: the same surveys, y = individuals of each of 16 focal species summed over the
#     points (the source's count), taxonInclusion target.
#   _point_occ: unit = point, cluster_id = property, period = year (2022, 2023), occasion = visit
#     (1-3), y = presence; period_ vegetation (measured once per point-year), obs_ minutes after
#     sunrise; date; observer.
#   surveyEvidence deposited_matrix in all three (NA = no survey). No coordinates are deposited
#   (properties are anonymised). Taxa: the source's common names matched to the IBP-AOS list
#   (Pyle and DeSante, via trashbirdecology/bbsAssistant) for the scientific name.
# Not shipped: the spatial cluster ids (Clusters4, Clusters5: groupings for the authors' model
#   selection); the guild label (a trait, not an observation; in __taxa as taxon_guild); prop_points
#   (n_points / n_points of the property, recoverable).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SRC <- "gapinski_2025_iowawrp_birds_occ"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/67f95964d4be022c3e84f405?format=json", SRC, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
rd <- function(f) fread(download_cached(fl[[f]], SRC, filename = f), na.strings = c("NA", ""))
b <- rd("wrp_bird_data2.csv"); c1 <- rd("wrp_covs_combined.csv"); n <- rd("bpc_for_nmix_and_occ.csv"); c2 <- rd("covs_for_nmix_and_occ.csv")
m <- rd("multispecies_as_dataframe.csv"); mc <- unique(rd("multispecies_covs.csv"))
ibp <- fread(download_cached("https://raw.githubusercontent.com/trashbirdecology/bbsAssistant/main/data-raw/IBP-AOS-LIST21.csv", SRC, filename = "IBP-AOS-LIST21.csv"), fill = TRUE)
ibp <- ibp[is.na(SP) | SP == ""]   # species rows; "+" marks forms and hybrids
norm <- function(s) gsub("[^a-z]", "", tolower(s))
fix <- c(`Common gallinule moorhen` = "Common Gallinule", `N. Rough-winged swallow` = "Northern Rough-winged Swallow", `Wilsons snipe` = "Wilson's Snipe")
sciname <- function(cn) { k <- ifelse(cn %in% names(fix), fix[cn], cn); i <- match(norm(k), norm(ibp$COMMONNAME)); stopifnot(!anyNA(i)); ibp[i, .(SPEC, SCINAME, COMMONNAME)] }
## ---- property level ----
stopifnot(nrow(b) == 132840, uniqueN(b$CommonName) == 123, uniqueN(b$PropName) == 55, all(b$sum_birds %in% c(0, 1, NA)),
          !anyDuplicated(b[, .(CommonName, visit, PropName, year)]))
sv <- b[, .(na = all(is.na(sum_birds)), ok = all(is.na(sum_birds)) | !anyNA(sum_birds)), by = .(PropName, year, visit)]
stopifnot(all(sv$ok), sum(!sv$na) == 571)
c1[, `:=`(P = sub("__.*", "", uniqueID), year = as.integer(sub(".*__", "", uniqueID)))]
cv <- melt(c1, id.vars = c("P", "year", "percent_woody", "age_2007"), measure.vars = patterns(date = "^date", obs = "^obs", np = "^n_points"), variable.name = "visit")
cv[, visit := as.integer(visit)]
cv <- cv[!is.na(date)]
stopifnot(nrow(cv) == 571, nrow(merge(cv, sv[na == FALSE], by.x = c("P", "year", "visit"), by.y = c("PropName", "year", "visit"))) == 571)
c2[, `:=`(P = paste0("Property", PropNum), year = as.integer(sub(".*__", "", uniqueID)))]
chk <- merge(c1, c2, by = c("P", "year"))
stopifnot(nrow(chk) == 180, all(sapply(1:6, function(i) identical(chk[[paste0("date", i, ".x")]], chk[[paste0("date", i, ".y")]]))),
          all(sapply(1:6, function(i) identical(chk[[paste0("n_points", i, ".x")]], chk[[paste0("n_points", i, ".y")]]))))
yrs <- c(2007L, 2008L, 2009L, 2022L, 2023L)
geo <- list(description = "Wetlands Reserve Program easements across Iowa, USA", boundingBox = list(west = -95.8447, east = -92.2302, south = 41.3933, north = 43.4928))
common <- list(creator = "Gapinski, Lindsey A.W.; Kinkead, Karen E.; Tucker, Anna M.; Dinsmore, Stephen J.; Bishop, Todd", pubDate = "2025",
  doi = "10.5066/P13DFQSX", sourceURL = "https://doi.org/10.5066/P13DFQSX",
  citation = "Gapinski, L.A., Kinkead, K.E., Tucker, A.M., Dinsmore, S.J., and Bishop, T., 2025, Bird point count and covariate data from wetland easements in Iowa, 2007-2009 and 2022-2023 (ver. 3.0, July 2026): U.S. Geological Survey data release, https://doi.org/10.5066/P13DFQSX.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release marked CC0 1.0"),
  samplingProtocolCode = "point_count", surveyEvidence = "deposited_matrix", unitKind = "site", closure = "closed",
  occasionKind = "time", geographicCoverage = geo)
ref <- "Gapinski, L.A., Kinkead, K.E., Tucker, A.M., Dinsmore, S.J., and Bishop, T. (2025). Bird point count and covariate data from wetland easements in Iowa, 2007-2009 and 2022-2023 (ver. 3.0). U.S. Geological Survey data release."
prop_rows <- function(d) merge(d, cv, by.x = c("PropName", "year", "visit"), by.y = c("P", "year", "visit"))
mk <- function(d) d[, .(unit = PropName, taxon, y, period = match(year, yrs), occasion = as.integer(visit),
                        date = format(as.IDate(sprintf("%d-01-01", year)) + as.integer(date) - 1L), observer = obs,
                        unit_easement_age_2007 = age_2007, period_percent_woody = percent_woody, obs_n_points = as.integer(np))]
tb <- sciname(sort(unique(b$CommonName))); tb[, cn := sort(unique(b$CommonName))]
guild <- unique(b[, .(cn = CommonName, group)]); stopifnot(!anyDuplicated(guild$cn))
TABLE <- "gapinski_2025_iowawrp_birds_occ"
d <- prop_rows(b[!is.na(sum_birds)])[, taxon := tb$SPEC[match(CommonName, tb$cn)]][, y := as.integer(sum_birds)]
long <- mk(d)
stopifnot(nrow(long) == 571 * 123, !anyNA(long$date))
taxa <- make_taxa(tb$SPEC, tb$SCINAME, vernacularName = tb$COMMONNAME, taxon_guild = guild$group[match(tb$cn, guild$cn)])
ds <- write_table(long, TABLE, c(list(
  title = "Presence of 123 bird species on repeat point-count visits to 55 wetland easements in Iowa, 2007-2009 and 2022-2023",
  abstract = "Breeding-season point counts (7-10 points per property, up to six visits a year, 15 May to 31 July) at 55 Wetlands Reserve Program easements in Iowa in 2007-2009 and again in 2022-2023, compiled to compare occupancy of breeding birds across a 16-year interval. This table is the property-level presence of every species recorded, on each visit.",
  samplingProtocol = "Point counts at 7-10 points per wetland easement on repeat visits from 15 May to 31 July; a species is present on a visit when recorded at any point of the property.",
  responseType = "detection", taxonInclusion = "recorded",
  closureNote = "visits within a breeding season; period = year (2007-2009 and 2022-2023)", temporalCoverage = "2007-05/2023-07",
  notShipped = list(clusters = "Clusters4, Clusters5: spatial groupings for the authors' model selection")), common),
  taxa = taxa, periods = data.table(period = 1:5, year = yrs), script = "data/gapinski_2025_iowawrp_birds.R")
stage_dict_row(TABLE,
  description = "Presence of 123 bird species on 571 point-count visits (property level) to 55 wetland easements in Iowa, 2007-2009 and 2022-2023, with dates, observers, points surveyed, woody cover and easement age.",
  url = "https://doi.org/10.5066/P13DFQSX", reference = ref, doi_data = "10.5066/P13DFQSX", original_license = "CC0 1.0 (USGS data release)", derived_license = "CC0 1.0",
  notes = "Companion tables gapinski_2025_iowawrp_focal_count (counts) and gapinski_2025_iowawrp_point_occ (point level, 2022-2023).", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (multi-season)", sampling_protocol = "point_count",
  design = "Multi-season (5 years x up to 6 visits)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Wetland easements, two eras 15 years apart.")
## ---- focal counts ----
TABLE <- "gapinski_2025_iowawrp_focal_count"
n[, PropName := paste0("Property", PropNum)]
stopifnot(nrow(n) == 17280, uniqueN(n$CommonName) == 16, !anyDuplicated(n[, .(visit, CommonName, year, PropNum)]),
          n[, all(is.na(sum_birds)) | !anyNA(sum_birds), by = .(PropName, year, visit)][, all(V1)],
          uniqueN(n[!is.na(sum_birds), .(PropName, year, visit)]) == 571)
x <- merge(n[!is.na(sum_birds)], b[!is.na(sum_birds), .(PropName, year, visit, CommonName, pres = sum_birds)], by = c("PropName", "year", "visit", "CommonName"))
stopifnot(nrow(x) == 571 * 16, all((x$sum_birds > 0) == (x$pres == 1)), all(x$sum_birds == round(x$sum_birds)))
tf <- sciname(sort(unique(n$CommonName))); tf[, cn := sort(unique(n$CommonName))]
d <- prop_rows(n[!is.na(sum_birds)])[, taxon := tf$SPEC[match(CommonName, tf$cn)]][, y := as.integer(sum_birds)]
long <- mk(d)
stopifnot(nrow(long) == 571 * 16)
taxa <- make_taxa(tf$SPEC, tf$SCINAME, vernacularName = tf$COMMONNAME)
ds <- write_table(long, TABLE, c(list(
  title = "Counts of 16 conservation-priority bird species on repeat point-count visits to 55 wetland easements in Iowa, 2007-2009 and 2022-2023",
  abstract = "The same property visits as gapinski_2025_iowawrp_birds_occ, deposited for N-mixture and occupancy models of 16 conservation-priority species: the total number of individuals of each species counted over the property's points on each visit.",
  samplingProtocol = "Point counts at 7-10 points per wetland easement on repeat visits from 15 May to 31 July; the count is the total individuals of the species over the points surveyed on the visit (obs_n_points).",
  responseType = "count", taxonInclusion = "target", effortColumn = "obs_n_points",
  closureNote = "visits within a breeding season; period = year (2007-2009 and 2022-2023)", temporalCoverage = "2007-05/2023-07",
  notShipped = list(clusters = "Clusters4, Clusters5: spatial groupings for model selection", prop_points = "prop_points1..6: n_points / points on the property")), common),
  taxa = taxa, periods = data.table(period = 1:5, year = yrs), script = "data/gapinski_2025_iowawrp_birds.R")
stage_dict_row(TABLE,
  description = "Counts (summed over 7-10 points) of 16 conservation-priority bird species on 571 visits to 55 wetland easements in Iowa, 2007-2009 and 2022-2023, with dates, observers and points surveyed.",
  url = "https://doi.org/10.5066/P13DFQSX", reference = ref, doi_data = "10.5066/P13DFQSX", original_license = "CC0 1.0 (USGS data release)", derived_license = "CC0 1.0",
  notes = "Same visits as gapinski_2025_iowawrp_birds_occ; count > 0 exactly where that table has presence (asserted).", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (multi-species, multi-season)", sampling_protocol = "point_count",
  design = "Multi-season (5 years x up to 6 visits)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Focal species of conservation concern; counts summed over points.")
## ---- point level, 2022-2023 ----
TABLE <- "gapinski_2025_iowawrp_point_occ"
m[, sp := sub("^sp_", "", species)]
stopifnot(uniqueN(m$sp) == 54, uniqueN(m$yr_prop_pt) == 986, !anyDuplicated(m[, .(sp, yr_prop_pt)]))
mc[, key := paste0(year, "__", prop_pt)]
stopifnot(!anyDuplicated(mc$key), setequal(mc$key, m$yr_prop_pt))
ml <- melt(m, id.vars = c("sp", "yr_prop_pt"), measure.vars = paste0("visit", 1:3), variable.name = "visit", value.name = "y")
ml[, visit := as.integer(sub("visit", "", visit))]
stopifnot(ml[, all(is.na(y)) | !anyNA(y), by = .(yr_prop_pt, visit)][, all(V1)], all(ml$y %in% c(0, 1, NA)))
ml <- ml[!is.na(y)]
mcl <- melt(mc, id.vars = c("key", "year", "prop_num", "prop_pt", "emergent_veg", "water_dummy", "trees_dummy", "avg_dbh", "avg_vor", "avg_lit", "forb", "grass", "woody", "age"),
            measure.vars = patterns(time = "^time", date = "^date", obs = "^obs"), variable.name = "visit")
mcl[, visit := as.integer(visit)]
d <- merge(ml, mcl, by.x = c("yr_prop_pt", "visit"), by.y = c("key", "visit"))
stopifnot(nrow(d) == nrow(ml), !anyNA(d$date))
tp <- sciname(sort(unique(m$sp))); tp[, cn := sort(unique(m$sp))]
long <- d[, .(unit = prop_pt, taxon = tp$SPEC[match(sp, tp$cn)], y = as.integer(y), period = year - 2021L, occasion = visit,
              date = format(as.IDate(sprintf("%d-01-01", year)) + as.integer(date) - 1L), observer = as.character(obs),
              cluster_id = as.character(prop_num), period_easement_age = age, period_emergent_veg_pct = emergent_veg, period_water = water_dummy,
              period_trees = trees_dummy, period_avg_dbh_cm = avg_dbh, period_visual_obstruction_cm = avg_vor, period_litter_cm = avg_lit,
              period_forb_pct = forb, period_grass_pct = grass, period_woody_pct = woody, obs_min_after_sunrise = time)]
stopifnot(nrow(long) == nrow(ml), uniqueN(long$unit) == 494)
taxa <- make_taxa(tp$SPEC, tp$SCINAME, vernacularName = tp$COMMONNAME)
ds <- write_table(long, TABLE, c(list(
  title = "Point-level presence of 54 bird species on three visits to 494 points on wetland easements in Iowa, 2022-2023, with vegetation",
  abstract = "The 2022-2023 point counts at Iowa Wetlands Reserve Program easements, deposited at point level for a multispecies analysis of fine-scale vegetation associations: presence of 54 species at each point on each of three visits, with vegetation measured at each point.",
  samplingProtocol = "Point counts on three visits between 15 May and 31 July at 7-10 points per wetland easement; vegetation (emergent cover, water, trees, dbh, visual obstruction, litter depth, forb / grass / woody cover) measured at each point from mid-July to early September.",
  responseType = "detection", taxonInclusion = "target",
  closureNote = "three visits within a breeding season; period = year", temporalCoverage = "2022-05/2023-07"), common),
  taxa = taxa, periods = data.table(period = 1:2, year = 2022:2023), script = "data/gapinski_2025_iowawrp_birds.R")
stage_dict_row(TABLE,
  description = "Presence of 54 bird species at 494 points on 2022-2023 wetland-easement point counts in Iowa (three visits a year), with point vegetation, survey time and observers.",
  url = "https://doi.org/10.5066/P13DFQSX", reference = ref, doi_data = "10.5066/P13DFQSX", original_license = "CC0 1.0 (USGS data release)", derived_license = "CC0 1.0",
  notes = "Point-level analysis set; the property-level tables cover 123 species and 2007-2009 as well.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy", sampling_protocol = "point_count",
  design = "Multi-season (2 years x 3 visits)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Point-level vegetation covariates.")
