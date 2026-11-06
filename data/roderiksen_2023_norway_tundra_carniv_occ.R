#!/usr/bin/env Rscript
# Table:  roderiksen_2023_norway_tundra_carniv_occ
# Source: Dryad, doi:10.5061/dryad.63xsj3v66, version 211252 (version 3, published 2022-12-16), licence CC0 1.0
#         as shown on the Dryad dataset page (asserted from the dataset JSON).
# Paper:  Rød-Eriksen, L., Killengreen, S. T., Ehrich, D., Ims, R. A., Herfindal, I., Landa, A. M. & Eide, N. E.
#         (2023). Predator co-occurrence in alpine and Arctic tundra in relation to fluctuating prey.
#         Journal of Animal Ecology. https://doi.org/10.1111/1365-2656.13875 (not read; the design is from the
#         deposit's abstract, methods, usage notes and README).
#         Design: a network of baited camera traps (reindeer slaughter scraps, 15-20 kg, simulating a carcass) in
#         four alpine regions and one Arctic region (Varanger) of Norway, active each late winter (March-May)
#         2011-2020; bait replaced once after about three weeks; time-lapse every 5 minutes, aggregated by the
#         authors to daily presence/absence per species. The deposit says 98 sites; the two files hold 96 stations.
# Data:   data_alpine.csv (314 station-years, 52 stations, region prefixes bfj, bsl, dfj, ksf) and
#           data_arctic.csv (354 station-years, 44 stations, prefixes gsn, ifj, kom, nky, nyb, stj): station, YEAR,
#           siteyear (= station-YEAR), rod_idx (small-rodent snap-trapping index, rodents per 100 trap nights,
#           constant within region-year), lalo (station longitude x latitude), then left-packed blocks of 54
#           (alpine) / 37 (Arctic) columns: doy1.. = the day of year of each active camera-day, carc1.. = bait
#           Present/Absent that day, rf1.., af1.., wv1.., ge1.. = red fox, Arctic fox, wolverine, golden eagle
#           detected (1) or not (0) that day. NA = camera not active; the NA pattern is identical across doy,
#           carc and the four species (asserted), and a station-year's active days come first, in increasing
#           day of year, with gaps where the camera was down (asserted).
#         Occupancy.R (the authors' unmarked occuMulti analysis; not used). README.md.
# Mapping: community occupancy of four predators at baited cameras, two regions in one table (one protocol,
#   ruling #31; the authors model the regions separately, unit_region carries it). unit = station,
#   taxon = VULVUL / VULLAG / GULGUL / AQUCHR, period = year (1 = 2011 .. 10 = 2020), occasion = the deposited
#   column index k (the k-th active camera-day of the station-year, as in the authors' occuMulti frame),
#   date = YEAR-01-01 + doy - 1 (exact), y = daily detection 0/1. obs_bait_present = carc (1 Present,
#   0 Absent). period_rodent_index = rod_idx (a separate snap-trapping survey, not derived from these
#   detections; it varies by region-year so it is a unit x period covariate). unit_region = alpine / arctic,
#   unit_area = the station-code prefix. surveyEvidence = deposited_matrix (NA = camera not active): a
#   station-day exists iff its doy is not NA, and all four species carry a row there.
#   No coordinates deposited. All four species are IUCN LC globally; the Arctic fox is listed as critically
#   endangered on the Norwegian red list, so `lalo` (a function of station coordinates) is not shipped.
#   Not shipped: lalo; the analysis script; occupancy and co-occurrence estimates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "roderiksen_2023_norway_tundra_carniv_occ"

dir <- download_dryad("10.5061/dryad.63xsj3v66", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          setequal(list.files(dir), c("data_alpine.csv", "data_arctic.csv", "Occupancy.R", "README.md")))

SP <- c(rf = "VULVUL", af = "VULLAG", wv = "GULGUL", ge = "AQUCHR")
read_region <- function(f, region, nk, nrow_expect, nst_expect) {
  d <- fread(file.path(dir, f), encoding = "UTF-8")
  blk <- function(p) unname(as.matrix(d[, paste0(p, seq_len(nk)), with = FALSE]))
  stopifnot(ncol(d) == 5L + 6L * nk, nrow(d) == nrow_expect, uniqueN(d$station) == nst_expect,
            !anyDuplicated(d$siteyear), all(d$siteyear == paste0(d$station, "-", d$YEAR)),
            all(d$YEAR %in% 2011:2020), !anyNA(d$rod_idx), all(d$rod_idx >= 0))
  doy <- blk("doy"); carc <- blk("carc"); NAp <- is.na(doy)
  stopifnot(identical(is.na(carc), NAp), all(carc[!NAp] %in% c("Present", "Absent")),
            all(apply(doy, 1, function(r) { a <- r[!is.na(r)]; length(a) >= 1 && all(diff(a) > 0) &&
                                                     all(is.na(r[-seq_along(a)])) })),
            all(doy[!NAp] >= 1 & doy[!NAp] <= 366))
  Y <- lapply(names(SP), function(p) { m <- blk(p); stopifnot(identical(is.na(m), NAp), all(m[!NAp] %in% 0:1)); m })
  area <- sub("[0-9_].*$", "", d$station)
  stopifnot(d[, uniqueN(rod_idx), by = .(area = sub("[0-9_].*$", "", station), YEAR)][, all(V1 == 1L)])
  cell <- which(!NAp, arr.ind = TRUE)   # row = station-year, col = k
  base <- data.table(unit = d$station[cell[, 1]], unit_region = region, unit_area = area[cell[, 1]],
                     year = d$YEAR[cell[, 1]], occasion = cell[, 2], doy = doy[cell],
                     obs_bait_present = as.integer(carc[cell] == "Present"),
                     period_rodent_index = d$rod_idx[cell[, 1]])
  out <- rbindlist(lapply(seq_along(SP), function(i) copy(base)[, `:=`(taxon = SP[[i]], y = Y[[i]][cell])]))
  list(long = out, n_cells = sum(!NAp), det = sapply(Y, sum, na.rm = TRUE))
}
A <- read_region("data_alpine.csv", "alpine", 54L, 314L, 52L)
R <- read_region("data_arctic.csv", "arctic", 37L, 354L, 44L)
stopifnot(A$n_cells == 12914L, R$n_cells == 10559L,
          identical(unname(A$det), c(1938L, 1395L, 726L, 650L)), identical(unname(R$det), c(2162L, 399L, 418L, 530L)))
long <- rbindlist(list(A$long, R$long))
stopifnot(!anyDuplicated(long[, .(unit, year, occasion, taxon)]), uniqueN(long$unit) == 96L)
long[, date := as.IDate(sprintf("%d-01-01", year)) + doy - 1L]
stopifnot(all(month(long$date) %in% 2:6), all(year(long$date) == long$year))
long[, period := year - 2010L]
long[, c("year", "doy") := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 4L * (12914L + 10559L))
cat(sprintf("  %d rows, %d station-days, %d station-years\n", nrow(long), nrow(long) / 4L,
            uniqueN(long[, .(unit, period)])))

taxa <- make_taxa(c("VULVUL", "VULLAG", "GULGUL", "AQUCHR"),
                  c("Vulpes vulpes", "Vulpes lagopus", "Gulo gulo", "Aquila chrysaetos"),
                  vernacularName = c("Red fox", "Arctic fox", "Wolverine", "Golden eagle"))
iu <- iucn_category(taxa$taxonID, taxa$scientificName)
stopifnot(all(iu == "LC"))
periods <- data.table(period = 1:10, year = 2011:2020, season = "late winter (March-May)")

dataset <- list(
  title = "Daily detections of red fox, Arctic fox, wolverine and golden eagle at 96 baited camera stations in alpine and Arctic tundra, Norway, late winters 2011-2020",
  creator = "Rød-Eriksen, Lars; Killengreen, Siw; Ehrich, Dorothee; Ims, Rolf; Herfindal, Ivar; Landa, Arild; Eide, Nina",
  pubDate = "2022", doi = "10.5061/dryad.63xsj3v66", sourceURL = "https://doi.org/10.5061/dryad.63xsj3v66",
  citation = "Rød-Eriksen, L., Killengreen, S., Ehrich, D., Ims, R., Herfindal, I., Landa, A., & Eide, N. (2022). Data for: Predator co-occurrence in alpine and Arctic tundra in relation to fluctuating prey [Dataset]. Dryad. https://doi.org/10.5061/dryad.63xsj3v66",
  paperDOI = "10.1111/1365-2656.13875",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Baited camera traps in four alpine regions and one Arctic region of Norway, run each late winter (March-May) 2011-2020, used to model the occurrence and co-occurrence of Arctic fox and red fox in relation to wolverine, golden eagle and small-rodent abundance. Daily detection/non-detection of each species per active camera-day.",
  samplingProtocol = "One camera per station, baited with 15-20 kg of reindeer slaughter scraps simulating a carcass, active March-May each year, checked and re-baited once after about three weeks, time-lapse every 5 minutes; the authors aggregated images to daily presence/absence per species.",
  samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasions are the active camera-days of one late-winter season (up to 54 alpine, 37 Arctic); the authors treat occupancy as constant within a station-year. occasion k is the k-th active day, so the same k is a different calendar day at different stations; date gives the day.",
  occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "Alpine tundra (four regions, station prefixes bfj, bsl, dfj, ksf) and Arctic tundra (Varanger, prefixes gsn, ifj, kom, nky, nyb, stj), Norway (no coordinates deposited)",
  temporalCoverage = "2011/2020",
  covariateNote = "obs_bait_present: 1 if the simulated carcass was present that day (source carc 'Present'), 0 if absent. period_rodent_index: small-rodent snap-trapping index (rodents per 100 trap nights) for the station's area and year, from a separate survey. unit_region: alpine / arctic (the authors model them separately). unit_area: station-code prefix (sub-region).",
  notShipped = list(
    lalo = "the product of station longitude and latitude (a spatial-autocorrelation covariate); a function of station coordinates for a species on the Norwegian red list (Arctic fox), and coordinates were not deposited",
    analysis_script = "Occupancy.R (unmarked occuMulti models)",
    model_output = "occupancy and co-occurrence estimates"),
  notes = "The deposit says 98 sites; its two files hold 96 stations. The alpine and Arctic data are one protocol and one table; filter on unit_region to reproduce the authors' separate models.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods,
                  script = "data/roderiksen_2023_norway_tundra_carniv_occ.R")
stage_dict_row(TABLE,
  description = "Daily camera-trap detections of red fox, Arctic fox, wolverine and golden eagle at 96 baited stations in alpine and Arctic tundra, Norway, late winters (March-May) 2011-2020, with bait status and a rodent index.",
  url = "https://doi.org/10.5061/dryad.63xsj3v66",
  reference = "Rød-Eriksen, L., Killengreen, S. T., Ehrich, D., Ims, R. A., Herfindal, I., Landa, A. M. & Eide, N. E. (2023). Predator co-occurrence in alpine and Arctic tundra in relation to fluctuating prey. Journal of Animal Ecology. https://doi.org/10.1111/1365-2656.13875",
  doi_paper = "10.1111/1365-2656.13875", doi_data = "10.5061/dryad.63xsj3v66",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Alpine and Arctic files in one table (unit_region); station lon x lat product not shipped (Arctic fox nationally red-listed).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Multiple", model_family = "Dynamic occupancy (multi-species)",
  sampling_protocol = "camera_trap", design = "Multi-season (10 late winters, up to 54 daily occasions; 96 stations)",
  realm = "Terrestrial", country = "NOR", coordinates = "None in source",
  notes = "Baited cameras; tundra predator guild co-occurrence (Rota-style multi-species occupancy).")
