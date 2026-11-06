#!/usr/bin/env Rscript
# Table:  poessel_2026_coso_mgs_rd
# Source: USGS ScienceBase doi:10.5066/P145OSD8 (USGS data release, 2026; use constraints "No use
#         constraints. Public domain data from the U.S. Government are freely redistributable with
#         proper metadata and source attribution"; recorded as CC0 1.0)
#   Poessel, S.A., Duerr, A.E., Leitner, P., Leitner, B.M. and Katzner, T.E., 2026, Capture-recapture
#   data of Mohave ground squirrels, 1988-2021: U.S. Geological Survey data release.
# Paper:  Relationships between climatic variation and population dynamics of the threatened Mohave
#         ground squirrel (cited in the release metadata; not needed to read the file).
# Data:   MGSData_Covariates.csv: 5,495 capture rows (animal id, date, trap check number 1-5 within
#         the day, age JUV / ADU, sex, site, winter rainfall before the session at the Haiwee power
#         plant, NDVI at the site on the date) of 1,404 squirrels at four sites in the Coso Range,
#         California (Cactus Peak, Coso Basin, Pumice Mine, Rose Valley), 1988-2021. Asserted: 22 rows
#         are exact duplicates; sex is constant per animal; one animal is recorded at two sites;
#         age is constant within an animal-year; rainfall is constant per site-year and NDVI per
#         site-date. The trapping schedule is not deposited: the metadata say only that squirrels
#         were trapped at four sites; the file shows several sessions per site-year (February to
#         June) until 1996 and one 3-5 day session a year from 1997.
# Mapping: robust design. unit = squirrel, cluster_id = site, period = calendar year (1 = 1988 ...
#   34 = 2021), occasion = trapping day within the site-year (1, 2, ... in date order), y =
#   captured that day (any check; obs_n_checks = number of checks it was caught on that day).
#   surveyEvidence inferred: a trapping day is a day on which any squirrel was captured at the
#   site, and a site-year is trapped when it has a capture; trapping days and years with no
#   capture are absent. At risk (E4.4): a squirrel first caught as an adult from its site's first
#   trapped year; one first caught as a juvenile (born that spring) from its year of marking;
#   to 2021. unit_sex, unit_age_first (JUV / ADU at first capture); obs_age (age class in that
#   year, where caught); period-site facts rainfall and NDVI are site-level so they ship as
#   obs_rainfall_mm and obs_ndvi (constant within site-year and site-day respectively).
# Not shipped: the 22 duplicate rows; the one squirrel recorded at two sites (its identity is
#   ambiguous); site coordinates (in the metadata only, not in the file; the species is listed as
#   threatened by California, and none are needed: cluster_id names the site).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "poessel_2026_coso_mgs_rd"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/697bc6b4b66b0197c3043d7c?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
x <- fread(download_cached(fl[["MGSData_Covariates.csv"]], TABLE, filename = "MGSData_Covariates.csv"), encoding = "UTF-8")
setnames(x, 1, "id")
stopifnot(nrow(x) == 5495, uniqueN(x$id) == 1404, setequal(unique(x$Check), 1:5), setequal(unique(x$Age), c("JUV", "ADU")),
          setequal(unique(x$Sex), c("F", "M")), uniqueN(x$Site) == 4)
stopifnot(sum(duplicated(x)) == 22); x <- unique(x)
x[, d := as.IDate(Date, format = "%m/%d/%Y")][, yr := year(d)]
stopifnot(!anyNA(x$d), x[, uniqueN(Sex), by = id][, all(V1 == 1)], x[, uniqueN(Age), by = .(id, yr)][, all(V1 == 1)],
          x[, uniqueN(Rainfall), by = .(Site, yr)][, all(V1 == 1)], x[, uniqueN(NDVI), by = .(Site, d)][, all(V1 == 1)])
two <- x[, uniqueN(Site), by = id][V1 > 1, id]; stopifnot(length(two) == 1)
n_two <- nrow(x[id %in% two]); x <- x[!id %in% two]
days <- unique(x[, .(Site, d, yr, rain = Rainfall)])[order(Site, d)]
days[, occasion := seq_len(.N), by = .(Site, yr)]
nd <- unique(x[, .(Site, d, ndvi = NDVI)])
caps <- x[, .(n_checks = uniqueN(Check), age = Age[1]), by = .(id, Site, d)]
an <- x[order(d)][, .(Site = Site[1], sex = Sex[1], age1 = Age[1], y1 = yr[1]), by = id]
first_site_yr <- days[, .(fy = min(yr)), by = Site]
an <- merge(an, first_site_yr, by = "Site")
an[, start := ifelse(age1 == "JUV", y1, fy)]
g <- merge(an[, .(id, Site, sex, age1, start)], days, by = "Site", allow.cartesian = TRUE)[yr >= start]
g <- merge(g, caps, by = c("id", "Site", "d"), all.x = TRUE)
g <- merge(g, nd, by = c("Site", "d"))
g[, y := as.integer(!is.na(n_checks))]
stopifnot(sum(g$y) == nrow(caps), uniqueN(g$id) == 1403)
long <- g[, .(unit = id, taxon = "XERMOH", y, period = yr - 1987L, occasion, date = format(d), cluster_id = Site,
              unit_sex = sex, unit_age_first = age1, obs_age = age, obs_n_checks = n_checks,
              obs_rainfall_mm = as.numeric(rain), obs_ndvi = as.numeric(ndvi))]
periods <- data.table(period = sort(unique(long$period)))[, year := period + 1987L]
taxa <- make_taxa("XERMOH", "Xerospermophilus mohavensis", vernacularName = "Mohave ground squirrel")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Capture histories of 1,403 Mohave ground squirrels on trapping days at four sites in the Coso Range, California, 1988-2021",
  creator = "Poessel, Sharon A.; Duerr, Adam E.; Leitner, Philip; Leitner, Barbara M.; Katzner, Todd E.",
  pubDate = "2026", doi = "10.5066/P145OSD8", sourceURL = "https://doi.org/10.5066/P145OSD8",
  citation = "Poessel, S.A., Duerr, A.E., Leitner, P., Leitner, B.M. and Katzner, T.E., 2026, Capture-recapture data of Mohave ground squirrels, 1988-2021: U.S. Geological Survey data release, https://doi.org/10.5066/P145OSD8.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Mohave ground squirrels, a California state-threatened species, were live-trapped and marked (ear tags in 1988-1989, PIT tags from 1990) at four sites in the Coso Range from 1988 to 2021; captures carry age, sex, trap check, winter rainfall and NDVI.",
  samplingProtocol = "Live-trapping grids at four study sites, traps checked up to five times a day during trapping sessions (several a spring until 1996, one 3-5 day session a year from 1997); each squirrel sexed, aged and permanently marked.",
  samplingProtocolCode = "live_trap", surveyEvidence = "inferred",
  surveyEvidenceNote = "The trapping schedule is not deposited. A trapping day is a day on which any squirrel was captured at the site, and a site-year is trapped when it has any capture; trapping days, and whole site-years, with no capture are absent.",
  responseType = "detection", unitKind = "individual", closure = "open", occasionKind = "time",
  closureNote = "period = year, occasion = trapping day at the squirrel's site. Until 1996 the days of a site-year span several sessions from February to June (open within the year); from 1997 one 3-5 day session a year. Ids are valid across the whole study.",
  taxonInclusion = "single",
  geographicCoverage = list(description = "Coso Range, Inyo County, California, USA (four study sites)",
                            boundingBox = list(west = -117.9877, east = -117.7185, south = 35.9825, north = 36.1290)),
  temporalCoverage = "1988/2021",
  notShipped = list(duplicates = "22 exact duplicate capture rows", two_sites = sprintf("one squirrel recorded at two sites (%d rows)", n_two),
                    coordinates = "site coordinates (metadata only); cluster_id names the site"),
  notes = "obs_n_checks: checks (1-5) on which the squirrel was caught that day. obs_rainfall_mm: winter (October-March) rainfall before the session at the Haiwee Power Plant; obs_ndvi: site NDVI on the date (both as deposited).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/poessel_2026_coso_mgs_rd.R")
stage_dict_row(TABLE,
  description = "Daily capture histories of 1,403 Mohave ground squirrels at four Coso Range sites, California, 1988-2021, by year and trapping day, with sex, age, rainfall and NDVI.",
  url = "https://doi.org/10.5066/P145OSD8",
  reference = "Poessel, S.A., Duerr, A.E., Leitner, P., Leitner, B.M. and Katzner, T.E. (2026). Capture-recapture data of Mohave ground squirrels, 1988-2021. U.S. Geological Survey data release.",
  doi_data = "10.5066/P145OSD8", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Robust design with trapping days inferred from captures.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Robust design", sampling_protocol = "live_trap",
  design = "Multi-season (31 trapped years 1988-2021, trapping days within years)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
  notes = "California state-threatened; survey days inferred from captures.")
