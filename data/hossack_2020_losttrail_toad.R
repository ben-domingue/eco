#!/usr/bin/env Rscript
# Tables: hossack_2020_losttrail_toadmale_rd, hossack_2020_losttrail_toadfem_rd
# Source: USGS ScienceBase doi:10.5066/P9C2VSF8 (USGS data release, published 2020-11-19; use
#         constraints "No use constraints"; US public domain, recorded as CC0 1.0)
#   Hossack, B.R., 2020, Mark-recapture data for a boreal toad metapopulation at the Lost Trail
#   National Wildlife Refuge, Montana (2003-2018): U.S. Geological Survey data release.
# Paper:  McCaffery, R.M., Russell, R.E., and Hossack, B.R., Enigmatic near-extinction in a boreal toad
#   metapopulation in northwestern Montana (under review at the Journal of Wildlife Management
#   when the data were released).
# Data:   LOTRrobustmales.csv: 1,232 PIT-tagged male boreal toads x 63 capture occasions (year-k:
#         16 primary periods 2003-2018 with 2 to 8 secondary occasions each), the toad's breeding site
#         (11 ponds, letters C to U), whether it moved between sites, and its number of captures; a
#         cell is the site letter where the toad was caught, 0 not caught, NA where its site was not
#         surveyed on that occasion (each pond was surveyed 0-8 times a year). AllFemCR_LostTrail.csv:
#         the same for 167 females on 64 occasions (2016 has six occasions in the female file and four
#         in the male; one female cell is coded 1, a capture with no site letter). The male header
#         names its fourth 2015 occasion "2015-3" twice; the metadata lists it as 2015-4 (renamed).
#         Male_CJS_Bd.csv: the males' annual capture (0/1) and Bd swab result (0/1, NA not swabbed)
#         per year. LOTR_BCI_males.csv and ToadSVLdata: body size and condition; BCI is a regression
#         residual. Asserted: captures per toad equal N_captures, non-movers are caught only at their
#         site, the annual captures in the Bd file equal the robust histories collapsed by year, and
#         the PITs match (one male's PIT is "Not recorded" in one file and "not recorded" in the
#         other).
# Mapping: one table per analysis set the source deposited (males, females; E4 ruling #31 keeps
#   separate analysis sets apart). unit = toad (PIT; the unrecorded one is "PIT_not_recorded"),
#   period = year (1 = 2003 ... 16 = 2018), occasion = secondary occasion within the year (the
#   column's k, numbered in column order within the year),
#   y = 1 if caught, y_raw = the site letter (or "1"), no row where the cell is NA (not surveyed:
#   surveyEvidence deposited_matrix). The deposited histories already carry zeros from 2003 for
#   every toad whose site was surveyed (adults of unknown age, E4.4). unit_site and unit_moved;
#   males: period_bd = the year's Bd swab result (1 positive, 0 negative, empty if not swabbed).
#   No coordinates are deposited.
# Not shipped: one 2006 Bd record (negative) for a male the histories show was not caught that year;
#   body size and condition files (BCI is a model residual; SVL and mass per capture-year are
#   individual measurements, not survey observations).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SRC <- "hossack_2020_losttrail_toadmale_rd"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/5fab2ba3d34eb413d5df2bbf?format=json", SRC, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
rd <- function(f) fread(download_cached(fl[[f]], SRC, filename = f), colClasses = "character", na.strings = "#none#")
mr <- rd("LOTRrobustmales.csv"); fr <- rd("AllFemCR_LostTrail.csv"); bd <- rd("Male_CJS_Bd.csv")
# the male header names the fourth 2015 occasion "2015-3" a second time; the metadata lists it as 2015-4
w <- which(names(mr) == "2015-3"); stopifnot(length(w) == 2, !"2015-4" %in% names(mr), names(mr)[w[2] + 1] == "2016-1")
names(mr)[w[2]] <- "2015-4"
letters_ok <- c("C", "D", "E", "F", "H", "J", "L", "P", "R", "T", "U")
hist_long <- function(d, n_expect) {
  oc <- grep("^20[0-9]{2}-", names(d), value = TRUE)
  stopifnot(nrow(d) == n_expect, !anyDuplicated(d$PIT), all(unlist(d[, ..oc]) %in% c("0", "NA", "1", letters_ok)))
  cap <- d[, rowSums(as.matrix(.SD) != "0" & as.matrix(.SD) != "NA"), .SDcols = oc]
  stopifnot(all(cap == as.integer(d$N_captures)))
  nm <- d[Movement == "N"]
  stopifnot(all(sapply(seq_len(nrow(nm)), function(i) all(setdiff(unlist(nm[i, ..oc]), c("0", "NA", "1")) == nm$Site[i]))))
  ocd <- data.table(col = oc, year = as.integer(substr(oc, 1, 4)))[, occasion := seq_len(.N), by = year]
  l <- melt(d[, c("PIT", "Site", "Movement", oc), with = FALSE], id.vars = c("PIT", "Site", "Movement"), variable.name = "col", value.name = "v")[v != "NA"]
  l[, col := as.character(col)]
  l[, `:=`(year = ocd$year[match(col, ocd$col)], occasion = ocd$occasion[match(col, ocd$col)])]
  l[, .(unit = ifelse(tolower(PIT) == "not recorded", "PIT_not_recorded", PIT), taxon = "ANABOR", y = as.integer(v != "0"),
        y_raw = v, period = year - 2002L, occasion, unit_site = Site, unit_moved = as.integer(Movement == "Y"))]
}
geo <- list(description = "Lost Trail National Wildlife Refuge, Flathead County, Montana, USA", boundingBox = list(west = -114.97, east = -114.78, south = 48.14, north = 48.20))
common <- list(creator = "Hossack, Blake R.", pubDate = "2020", doi = "10.5066/P9C2VSF8", sourceURL = "https://doi.org/10.5066/P9C2VSF8",
  citation = "Hossack, B.R., 2020, Mark-recapture data for a boreal toad metapopulation at the Lost Trail National Wildlife Refuge, Montana (2003-2018): U.S. Geological Survey data release, https://doi.org/10.5066/P9C2VSF8.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (no use constraints)"),
  samplingProtocol = "Night captures by hand (rarely dipnet) at up to 11 breeding ponds during the mid-May to early June breeding season, 0-8 capture sessions per pond per year; every adult toad measured, sexed and PIT-tagged if new, then released.",
  samplingProtocolCode = "hand_capture", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "robust design: secondary occasions are capture nights within one breeding season; occasion k need not be the same night at different ponds", occasionKind = "time",
  taxonInclusion = "single", geographicCoverage = geo, temporalCoverage = "2003-05/2018-06")
## ---- males ----
TABLE <- "hossack_2020_losttrail_toadmale_rd"
long <- hist_long(mr, 1232)
stopifnot(sum(long$y) == sum(as.integer(mr$N_captures)), uniqueN(long$unit) == 1232)
bd[, PIT := ifelse(tolower(PIT) == "not recorded", "PIT_not_recorded", PIT)]
yrs <- as.character(2003:2018)
bl <- melt(bd[, c("PIT", yrs, paste0("BD", yrs)), with = FALSE], id.vars = "PIT", measure.vars = list(yrs, paste0("BD", yrs)), value.name = c("cap", "bd"))
bl[, period := as.integer(variable)]
ann <- long[, .(cap = as.integer(any(y == 1))), by = .(unit, period)]
x <- merge(ann, bl[, .(unit = PIT, period, capb = as.integer(cap), bd)], by = c("unit", "period"))
stopifnot(all(x$cap == x$capb), nrow(bd) == 1232, setequal(bd$PIT, long$unit))
odd <- bl[bd != "NA" & cap != "1"]; stopifnot(nrow(odd) == 1, odd$bd == "0", odd$period == 4L)
bl <- bl[bd != "NA" & cap == "1", .(unit = PIT, period, period_bd = as.integer(bd))]
long <- merge(long, bl, by = c("unit", "period"), all.x = TRUE)
stopifnot(sum(!is.na(unique(long[, .(unit, period, period_bd)])$period_bd)) == 194)
taxa <- make_taxa("ANABOR", "Anaxyrus boreas", vernacularName = "Boreal toad")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
ds <- write_table(long, TABLE, c(list(
  title = "Robust-design capture histories of 1,232 male boreal toads at 11 breeding ponds, Lost Trail National Wildlife Refuge, Montana, 2003-2018",
  abstract = "Sixteen years of night-time capture of breeding boreal toads at the Lost Trail National Wildlife Refuge, northwestern Montana, a sentinel population of the USGS Amphibian Research and Monitoring Initiative that declined to near extinction. Males: capture histories over 63 capture nights in 16 breeding seasons, with each toad's pond and, for the toads swabbed, the year's Bd result.",
  notShipped = list(bd_uncaught = "one 2006 Bd result (negative) for a male not caught in 2006 by the histories",
                    body_size = "LOTR_BCI_males.csv and ToadSVLdata_LOTR_2003-2017.csv: individual size, mass and a regression-residual condition index"),
  notes = "period_bd is the Bd swab result for the year (up to 30 toads swabbed per year from 2005); empty where not swabbed."), common),
  taxa = taxa, periods = data.table(period = 1:16, year = 2003:2018), script = "data/hossack_2020_losttrail_toad.R")
ref <- "Hossack, B.R. (2020). Mark-recapture data for a boreal toad metapopulation at the Lost Trail National Wildlife Refuge, Montana (2003-2018). U.S. Geological Survey data release."
stage_dict_row(TABLE,
  description = "Robust-design capture histories (16 years, 2-8 nights a year) of 1,232 PIT-tagged male boreal toads at 11 breeding ponds on Lost Trail National Wildlife Refuge, Montana, 2003-2018, with pond, movement and yearly Bd status.",
  url = "https://doi.org/10.5066/P9C2VSF8", reference = ref, doi_data = "10.5066/P9C2VSF8", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Sibling table hossack_2020_losttrail_toadfem_rd (females).", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Robust design", sampling_protocol = "hand_capture",
  design = "Robust design (16 years x 2-8 nights)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Declining sentinel population; males.")
## ---- females ----
TABLE <- "hossack_2020_losttrail_toadfem_rd"
long <- hist_long(fr, 167)
stopifnot(sum(long$y_raw == "1") == 1, uniqueN(long$unit) == 167)
ds <- write_table(long, TABLE, c(list(
  title = "Robust-design capture histories of 167 female boreal toads at 11 breeding ponds, Lost Trail National Wildlife Refuge, Montana, 2003-2018",
  abstract = "Sixteen years of night-time capture of breeding boreal toads at the Lost Trail National Wildlife Refuge, northwestern Montana. Females, deposited separately because they were rarely caught in more than one year: capture histories over 64 capture nights in 16 breeding seasons, with each toad's pond.",
  notShipped = list(body_size = "ToadSVLdata_LOTR_2003-2017.csv: individual size and mass"),
  notes = "One capture (2009, occasion 3) is coded 1 rather than a pond letter (y_raw = \"1\")."), common),
  taxa = taxa, periods = data.table(period = 1:16, year = 2003:2018), script = "data/hossack_2020_losttrail_toad.R")
stage_dict_row(TABLE,
  description = "Robust-design capture histories (16 years, 2-8 nights a year) of 167 PIT-tagged female boreal toads at 11 breeding ponds on Lost Trail National Wildlife Refuge, Montana, 2003-2018, with pond and movement.",
  url = "https://doi.org/10.5066/P9C2VSF8", reference = ref, doi_data = "10.5066/P9C2VSF8", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Sibling table hossack_2020_losttrail_toadmale_rd (males).", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Robust design", sampling_protocol = "hand_capture",
  design = "Robust design (16 years x 2-8 nights)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Declining sentinel population; females rarely recaptured across years.")
