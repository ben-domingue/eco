#!/usr/bin/env Rscript
# Table:  gustafson_2024_seward_gyrfalcon_dynocc
# Source: Dryad doi:10.5061/dryad.djh9w0w94 (CC0 1.0, as shown on the Dryad page; published
#         2024-12-19). Gustafson, M. et al. Gyrfalcon prey abundance and their habitat
#         associations in a changing Arctic.
# Paper:  Gustafson, M., McCabe, J., Rolek, B., Booms, T., Henderson, M., Dunn, L., Anderson, D.
#         & Cruz, J. (2025). Ecology and Evolution, doi:10.1002/ece3.70763. Seward Peninsula,
#         Alaska; multi-season occupancy of 97 Gyrfalcon breeding territories from helicopter
#         surveys 2016-2022, plus prey point counts (README).
# Data:   widedf.csv (565 territory-years: terrXyear, territory, year (2016-2019, 2021, 2022),
#         pres_1 / pres_2 = occupancy status at the early (May) / late (June) helicopter survey,
#         jday_1 / jday_2 = day of year of each survey; NA = "a survey was not conducted").
#         Asserted: NA in pres exactly where jday is NA. pres takes 0, 1 and, once in each
#         column, 2, a code the README does not define.
#         ropt.csv, wipt.csv, squir.csv: male rock / willow ptarmigan and Arctic ground squirrel
#         counts in five 2-minute intervals at 988 point-count sites, each surveyed once (ids
#         unique), with standardized covariates: single-visit point counts, not built
#         (replication ruling 2026-11-06: within-visit intervals do not make a visit
#         replicated).
# Mapping (standard: dynamic occupancy, E9 core): unit = territory (97); taxon = FALRUS;
#   period = year (6 survey years, __periods); occasion = survey round 1 (early, May) / 2
#   (late, June); y = pres (0/1); date = year + jday (exact). Survey evidence: deposited_matrix
#   (NA = not surveyed). The two cells coded 2 get no row (undefined code; notShipped).
#   No coordinates. Gyrfalcon is IUCN LC.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "gustafson_2024_seward_gyrfalcon_dynocc"
dir <- download_dryad("10.5061/dryad.djh9w0w94", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^widedf\\.csv$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
w <- fread(f)
YRS <- c(2016L, 2017L, 2018L, 2019L, 2021L, 2022L)
stopifnot(nrow(w) == 565, uniqueN(w$territory) == 97, !anyDuplicated(w[, .(territory, year)]),
          identical(w$terrXyear, paste(w$year, w$territory, sep = "_")), setequal(unique(w$year), YRS),
          identical(is.na(w$pres_1), is.na(w$jday_1)), identical(is.na(w$pres_2), is.na(w$jday_2)),
          all(w$pres_1 %in% c(0, 1, 2, NA)), all(w$pres_2 %in% c(0, 1, 2, NA)),
          sum(w$pres_1 == 2, na.rm = TRUE) == 1, sum(w$pres_2 == 2, na.rm = TRUE) == 1)
long <- rbind(w[, .(unit = territory, year, occasion = 1L, y = pres_1, jd = jday_1)],
              w[, .(unit = territory, year, occasion = 2L, y = pres_2, jd = jday_2)])
long <- long[!is.na(y) & y != 2]
long[, `:=`(taxon = "FALRUS", period = match(year, YRS), date = format(as.IDate(paste0(year - 1L, "-12-31")) + as.integer(jd)),
            y = as.integer(y))]
long <- order_eco(long[, .(unit, taxon, y, period, occasion, date)])
stopifnot(nrow(long) == 565 * 2 - 47 - 13 - 2, all(substr(long$date, 6, 7) %in% c("04", "05", "06", "07")))
periods <- data.table(period = seq_along(YRS), period_year = YRS)
taxa <- make_taxa("FALRUS", "Falco rusticolus", vernacularName = "Gyrfalcon")
dataset <- list(
  title = "Gyrfalcon territory occupancy from early and late helicopter surveys of 97 territories on the Seward Peninsula, Alaska, 2016-2022",
  creator = "Gustafson, Michaela; McCabe, Jennifer; Rolek, Brian; Booms, Travis; Henderson, Michael; Dunn, Leah; Anderson, David; Cruz, Jennyffer",
  pubDate = "2024", doi = "10.5061/dryad.djh9w0w94", sourceURL = "https://doi.org/10.5061/dryad.djh9w0w94",
  citation = "Gustafson, M. et al. (2024). Gyrfalcon prey abundance and their habitat associations in a changing Arctic [Dataset]. Dryad. https://doi.org/10.5061/dryad.djh9w0w94",
  paperDOI = "10.1002/ece3.70763",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Occupancy status of 97 Gyrfalcon (Falco rusticolus) breeding territories on the Seward Peninsula, Alaska, from an early (May) and a late (June) helicopter survey in each of six years (2016-2019, 2021, 2022), with survey dates; the input of the authors' multi-season occupancy model.",
  samplingProtocol = "Helicopter surveys of known Gyrfalcon breeding territories, an early survey in May and a late survey in June each year; each survey records whether the territory was occupied.",
  samplingProtocolCode = "aerial_survey", surveyEvidence = "deposited_matrix", responseType = "detection",
  unitKind = "site", closure = "closed", closureNote = "closed within a breeding season (two surveys), open between years (multi-season occupancy)",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Seward Peninsula, Alaska, USA; no coordinates deposited", temporalCoverage = "2016-05/2022-06",
  notShipped = list(code_2 = "one early and one late survey with occupancy status 2, a code the README does not define",
                    prey_point_counts = "ropt.csv, wipt.csv, squir.csv: single-visit point counts at 988 sites (replication ruling 2026-11-06)"),
  notes = "Years 2016-2019, 2021 and 2022; no 2020 survey. date = year + the deposited day of year. 'Occupancy status' is the authors' per-survey record of an occupied territory.")
dataset$temporalCoverage <- paste(substr(min(long$date), 1, 7), substr(max(long$date), 1, 7), sep = "/")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/gustafson_2024_seward_gyrfalcon_dynocc.R")
stage_dict_row(TABLE,
  description = "Gyrfalcon territory occupancy from two helicopter surveys per year at 97 territories on the Seward Peninsula, Alaska, 2016-2022.",
  url = "https://doi.org/10.5061/dryad.djh9w0w94",
  reference = "Gustafson, M. et al. (2025). Gyrfalcon prey abundance and their habitat associations in a changing Arctic. Ecology and Evolution.",
  doi_paper = "10.1002/ece3.70763", doi_data = "10.5061/dryad.djh9w0w94", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dynamic occupancy; prey point counts are single-visit and not built.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Dynamic occupancy",
  sampling_protocol = "aerial_survey", design = "Multi-season (6 years x 2 surveys)", realm = "Terrestrial",
  country = "USA", coordinates = "None in source", notes = "Raptor territory occupancy.")
