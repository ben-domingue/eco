#!/usr/bin/env Rscript
# Table:  laytonmatthews_2024_hornoya_gull_cjs
# Source: Dryad doi:10.5061/dryad.t4b8gtj9k (CC0 1.0, as shown on the Dryad page; published
#         2024-07-19). Layton-Matthews, K., Erikstad, K.E., Sandvik, H. et al. Path analysis
#         reveals combined winter climate and pollution effects on the survival of a marine top
#         predator.
# Paper:  Layton-Matthews, K. et al. (2024). Journal of Animal Ecology, doi:10.1111/1365-2656.14159.
#         Great black-backed gulls (Larus marinus) caught on nests at Hornoya, northern Norway, in
#         2001-2002, colour-ringed and blood-sampled for organochlorines; annual resighting
#         2001-2017 (SEAPOP; Dryad methods).
# Data:   Individ_Dat_forDryad.csv (each line quoted as a whole, with doubled inner quotes: 158
#         birds: ch = 17-character history 2001-2017, sex F/M, Weight_sc (scaled), pc1 (first PC of
#         log contaminant levels), oxyklorlog (scaled log oxychlordane)); Covariate_Dat_forDryad.csv
#         (";"-separated, one row per interval 2001_02 .. 2016_17: standardized regional climate
#         covariates by season: sea-level pressure, SST, air temperature, NAO, Atlantic water
#         inflow); README.md describes both. Path-model script.
# Mapping (standard: CJS, E9 core): unit = bird (G001, file order); taxon = LARMAR; period = year
#   1..17 (2001-2017); y = 0/1. Full rectangle from 2001 (E4.4: adults caught in the wild in 2001
#   or 2002). unit_: sex, scaled weight, contaminant PC1 and oxychlordane (laboratory
#   measurements, not detections). __periods: year and the interval's climate covariates
#   (regional weather from separate sources, processing guide). Survey evidence:
#   deposited_matrix. IUCN LC; no coordinates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "laytonmatthews_2024_hornoya_gull_cjs"
dir <- download_dryad("10.5061/dryad.t4b8gtj9k", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Individ_Dat_forDryad\\.csv$", recursive = TRUE, full.names = TRUE); stopifnot(length(f) == 1)
L <- readLines(f, warn = FALSE); L <- L[nzchar(L)]
L <- ifelse(startsWith(L, "\""), gsub("\"\"", "\"", substr(L, 2, nchar(L) - 1)), L)
d <- fread(text = paste(L, collapse = "\n"), colClasses = list(character = "ch"))
stopifnot(identical(names(d), c("0", "ch", "sex", "Weight_sc", "pc1", "oxyklorlog")), nrow(d) == 158, all(nchar(d$ch) == 17),
          all(grepl("^[01]+$", d$ch)), all(d$sex %in% c("F", "M")), all(substr(d$ch, 1, 2) != "00"))
cv <- fread(list.files(dir, "^Covariate_Dat_forDryad\\.csv$", recursive = TRUE, full.names = TRUE), sep = ";")
stopifnot(identical(cv$year, sprintf("%d_%02d", 2001:2016, 2:17)))
H <- do.call(rbind, strsplit(d$ch, "")); storage.mode(H) <- "integer"
ids <- sprintf("G%03d", seq_len(158))
long <- data.table(unit = rep(ids, 17), period = rep(1:17, each = 158), y = as.vector(H), taxon = "LARMAR",
                   unit_sex = rep(d$sex, 17), unit_weight_sc = rep(d$Weight_sc, 17), unit_contaminant_pc1 = rep(d$pc1, 17), unit_oxychlordane_log_sc = rep(d$oxyklorlog, 17))
long <- order_eco(long)
stopifnot(nrow(long) == 158 * 17, sum(long$y) == sum(H))
pcov <- copy(cv)[, period := seq_len(.N)][, interval := year][, year := NULL]
setnames(pcov, setdiff(names(pcov), c("period", "interval")), paste0("period_", setdiff(names(pcov), c("period", "interval"))))
periods <- merge(data.table(period = 1:17, period_year = 2001:2017), pcov[, c("period", "interval", grep("^period_", names(pcov), value = TRUE)), with = FALSE], by = "period", all.x = TRUE)
setnames(periods, "interval", "period_interval")
taxa <- make_taxa("LARMAR", "Larus marinus", vernacularName = "Great black-backed gull")
dataset <- list(
  title = "Resighting histories of 158 great black-backed gulls ringed at Hornøya, Norway, 2001-2017, with contaminant levels",
  creator = "Layton-Matthews, Kate; Erikstad, Kjell Einar; Sandvik, Hanno; Ballesteros, Manuel; Hodges, Kevin; Mesquita, Michel; Reiertsen, Tone; Yoccoz, Nigel; Bustnes, Jan Ove", pubDate = "2024",
  doi = "10.5061/dryad.t4b8gtj9k", sourceURL = "https://doi.org/10.5061/dryad.t4b8gtj9k",
  citation = "Layton-Matthews, K. et al. (2024). Path analysis reveals combined winter climate and pollution effects on the survival of a marine top predator [Dataset]. Dryad. https://doi.org/10.5061/dryad.t4b8gtj9k",
  paperDOI = "10.1111/1365-2656.14159",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Annual resighting histories of 158 colour-ringed adult great black-backed gulls (Larus marinus) caught on nests at Hornøya, northern Norway, in 2001-2002 and resighted through 2017, with sex, body weight and blood organochlorine levels, and regional winter climate covariates per year.",
  samplingProtocol = "Breeding adults caught with nest traps during incubation (May-June 2001 and 2002), metal and colour ringed and blood-sampled; annual visual searches for ringed birds, mainly at the ringing colony (SEAPOP).",
  samplingProtocolCode = "tag_resight", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "individual",
  closure = "none", closureNote = "one record per bird per year; open between years (CJS)", occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Hornøya, Finnmark, northern Norway; no coordinates deposited", temporalCoverage = "2001/2017",
  notShipped = list(model_script = "the CMR-path model script"),
  notes = "The CSV is quoted line by line with doubled inner quotes and is unwrapped before reading. Weight and the contaminant variables are scaled as deposited. __periods carries the climate covariates of the interval starting in each year (none for 2017).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/laytonmatthews_2024_hornoya_gull_cjs.R")
stage_dict_row(TABLE, description = "CJS resighting histories of 158 great black-backed gulls at Hornøya, Norway, 2001-2017, with contaminant levels and winter climate covariates.",
  url = "https://doi.org/10.5061/dryad.t4b8gtj9k", reference = "Layton-Matthews, K. et al. (2024). Path analysis reveals combined winter climate and pollution effects on the survival of a marine top predator. Journal of Animal Ecology.",
  doi_paper = "10.1111/1365-2656.14159", doi_data = "10.5061/dryad.t4b8gtj9k", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "CJS with individual contaminant covariates.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Cormack-Jolly-Seber",
  sampling_protocol = "tag_resight", design = "Multi-season (17 years)", realm = "Marine",
  country = "NOR", coordinates = "None in source", notes = "Seabird survival and pollution.")
