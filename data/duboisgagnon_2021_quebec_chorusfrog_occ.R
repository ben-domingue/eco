#!/usr/bin/env Rscript
# Table:  duboisgagnon_2021_quebec_chorusfrog_occ
# Source: Dryad doi:10.5061/dryad.8cz8w9gr1 (source of record), CC0 1.0, fetched from its Zenodo mirror
#         doi:10.5281/zenodo.5504276 (record 5504276; licence id "cc-zero", asserted from the cached record
#         JSON). No request was made to Dryad.
#   Mazerolle, M. J., Dubois-Gagnon, M.-P., Bernatchez, L., Belisle, M. & Dubois, Y. (2021). Data for the
#   detection of the boreal chorus frog (Pseudacris maculata) using environmental DNA and call surveys at
#   180 ponds sampled in 2017-2018 in southeastern Quebec, Canada [Dataset]. Dryad.
# Paper:  Dubois-Gagnon, M.-P., Bernatchez, L., Belisle, M., Dubois, Y. & Mazerolle, M. J. (2022).
#         Distribution of the boreal chorus frog (Pseudacris maculata) in an urban environment using
#         environmental DNA. Environmental DNA 4, 326-338. doi:10.1002/edn3.254. Not needed to read the
#         deposit: the README defines every column.
# Data:   README.txt: data collected 2017-05-16 to 2017-06-19 and 2018-04-20 to 2018-06-08, Monteregie, Quebec.
#         detectData180eDNA.csv (200 rows): PondID, Detect1, Detect2 (eDNA detection at visit 1, 2; 0/1, blank
#           = missing), Snowday1, Snowday2 (visit date as days since snowmelt), Volume1, Volume2 (litres of
#           water filtered). 180 ponds; 20 ponds were sampled in both years, so PondID repeats (the row's year
#           is in the covariate file, row-aligned, asserted). Visit 2 is blank at 52 pond-years (5 in 2017,
#           47 in 2018); pond 173 (2018) has no visit-1 eDNA sample but a visit-2 one.
#         siteCovariateData180eDNA.csv (200 rows, same order): PondID, Year, Hist.presence (known occupied at
#           least once 2004-2016, yes/no), Veg1 (PCA axis-1 score of vegetation cover), Dry (pond dried up
#           in summer, 0/1), Dist.road, Dist.anthropic (m), and wetland, forest, open, anthropic cover
#           proportions and road density (m/ha) in 200, 500, 1000 and 1500 m buffers.
#         detectData-eDNA-Acoustic.csv (63 rows): 2018 ponds with eDNA and a call survey at the same visit:
#           PondID, eDNA, Acoustic (0/1), Snowday. Every row's eDNA and Snowday equal the pond's 2018 visit 1
#           (asserted; pond 173's eDNA is blank there as in the main file): the call survey is a second
#           method at visit 1, not a separate visit.
# Mapping (E9 experimental paired-method form, ruling #31: both methods at one visit = one table):
#   unit = pond (PondID), taxon = PSEMAC, period = year (1 = 2017, 2 = 2018; __periods), occasion =
#   2 * (visit - 1) + method (method 1 = eDNA, 2 = call survey; so 1 = visit-1 eDNA, 2 = visit-1 call,
#   3 = visit-2 eDNA), occasionKind = c("time", "method"); obs_visit, obs_method recover both.
#   y = the deposited 0/1. surveyEvidence = deposited_matrix: a blank cell is a visit or sample not taken
#   and has no row (52 visit-2 cells, pond 173's visit-1 eDNA); a call survey exists only at the 63
#   pond-visits of the third file.
#   obs_days_since_snowmelt = Snowday; obs_volume_l = Volume (eDNA rows only, NA on call rows).
#   Site covariates: those constant within each of the 20 ponds sampled in both years are unit_ (asserted:
#   hist_presence, veg1, dry, dist_road and the rest listed below), the eight that differ between a pond's
#   two years are period_ (dist_anthropic and some anthropic/open cover proportions; the deposit gives them
#   per pond-year).
#   No coordinates are deposited. Pseudacris maculata is IUCN LC; the population is the one Quebec lists
#   (as western chorus frog) as vulnerable, but there are no coordinates, so E7 does not arise.
#   Not shipped: the paper's occupancy and detection estimates (model output).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "duboisgagnon_2021_quebec_chorusfrog_occ"
REC <- "5504276"

zen <- function(key) download_cached(sprintf("https://zenodo.org/api/records/%s/files/%s/content", REC, URLencode(key, reserved = TRUE)), TABLE, filename = key)
meta_f <- file.path(RAW_DIR, TABLE, "zenodo_record.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file(paste0("https://zenodo.org/api/records/", REC), meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)
stopifnot(identical(meta$metadata$license$id, "cc-zero"), identical(meta$doi, "10.5061/dryad.8cz8w9gr1"),
          setequal(meta$files$key, c("siteCovariateData180eDNA.csv", "detectData180eDNA.csv", "detectData-eDNA-Acoustic.csv", "README.txt")))
d <- fread(zen("detectData180eDNA.csv"))
s <- fread(zen("siteCovariateData180eDNA.csv"))
a <- fread(zen("detectData-eDNA-Acoustic.csv"))
invisible(zen("README.txt"))

stopifnot(nrow(d) == 200L, nrow(s) == 200L, nrow(a) == 63L, identical(d$PondID, s$PondID),
          identical(names(d), c("PondID", "Detect1", "Detect2", "Snowday1", "Snowday2", "Volume1", "Volume2")),
          uniqueN(d$PondID) == 180L, d[, .N, by = PondID][N > 1, .N] == 20L,
          setequal(s$Year, c(2017L, 2018L)), !anyDuplicated(s[, .(PondID, Year)]),
          all(c(d$Detect1, d$Detect2) %in% c(0L, 1L, NA)), all(a$eDNA %in% c(0L, 1L, NA)), all(a$Acoustic %in% 0:1),
          # the NA pattern: detection, date and volume are blank together
          identical(is.na(d$Detect1), is.na(d$Snowday1)), identical(is.na(d$Detect1), is.na(d$Volume1)),
          identical(is.na(d$Detect2), is.na(d$Snowday2)), identical(is.na(d$Detect2), is.na(d$Volume2)),
          sum(is.na(d$Detect1)) == 1L, d[is.na(Detect1), PondID] == 173L, sum(is.na(d$Detect2)) == 52L,
          !anyNA(s))
d[, Year := s$Year]
stopifnot(identical(d[, .N, by = .(Year, v2 = !is.na(Detect2))][order(Year, v2)]$N, c(5L, 85L, 47L, 63L)))
# the call-survey file is visit 1 of 2018
m <- merge(a, d[Year == 2018], by = "PondID", all.x = TRUE)
stopifnot(!anyNA(m$Year), m[PondID != 173, all(eDNA == Detect1 & Snowday == Snowday1)],
          m[PondID == 173, is.na(eDNA) & is.na(Detect1) & Snowday == 31L])

ed <- rbindlist(lapply(1:2, function(v) d[, .(unit = as.character(PondID), Year, obs_visit = v,
  y = get(paste0("Detect", v)), obs_days_since_snowmelt = get(paste0("Snowday", v)), obs_volume_l = get(paste0("Volume", v)))]))
ed <- ed[!is.na(y)][, obs_method := "eDNA"]
ac <- a[, .(unit = as.character(PondID), Year = 2018L, obs_visit = 1L, y = Acoustic, obs_days_since_snowmelt = Snowday,
            obs_volume_l = NA_real_, obs_method = "call_survey")]
long <- rbindlist(list(ed, ac))
long[, `:=`(period = Year - 2016L, occasion = 2L * (obs_visit - 1L) + ifelse(obs_method == "eDNA", 1L, 2L), taxon = "PSEMAC")]
long[, y := as.integer(y)]

# site covariates: unit_ where constant within a pond across its years, else period_
cov <- copy(s); setnames(cov, gsub("\\.", "_", tolower(names(cov))))
cov[, hist_presence := as.integer(hist_presence == "yes")]
vars <- setdiff(names(cov), c("pondid", "year"))
const <- vars[sapply(vars, function(v) cov[, uniqueN(get(v)), by = pondid][, all(V1 == 1L)])]
varying <- setdiff(vars, const)
stopifnot(setequal(varying, c("dist_anthropic", "anthropic_cover200", "open_habitat_cover500", "anthropic_cover500",
                              "open_habitat_cover1000", "anthropic_cover1000", "open_habitat_cover1500", "anthropic_cover1500")))
uc <- unique(cov[, c("pondid", const), with = FALSE]); stopifnot(nrow(uc) == 180L)
setnames(uc, c("unit", paste0("unit_", const))); uc[, unit := as.character(unit)]
pc <- cov[, c("pondid", "year", varying), with = FALSE]; setnames(pc, c("unit", "Year", paste0("period_", varying)))
pc[, unit := as.character(unit)]
long <- merge(long, uc, by = "unit"); long <- merge(long, pc, by = c("unit", "Year"))
long[, Year := NULL]
long <- order_eco(long)
stopifnot(nrow(long) == 200L * 2L - 53L + 63L, uniqueN(long$unit) == 180L,
          !anyDuplicated(long[, .(unit, period, occasion)]),
          sum(long[obs_method == "eDNA"]$y) == sum(d$Detect1, d$Detect2, na.rm = TRUE),
          sum(long[obs_method == "call_survey"]$y) == 15L)
cat(sprintf("  %d rows, %d ponds, %d pond-years; eDNA detections %d, call detections %d\n", nrow(long), uniqueN(long$unit),
            uniqueN(long[, .(unit, period)]), sum(long[obs_method == "eDNA"]$y), sum(long[obs_method == "call_survey"]$y)))

taxa <- make_taxa("PSEMAC", "Pseudacris maculata", vernacularName = "Boreal chorus frog")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "LC"))
periods <- data.table(period = 1:2, year = c(2017L, 2018L), start = c("2017-05-16", "2018-04-20"), end = c("2017-06-19", "2018-06-08"))

dataset <- list(
  title = "Boreal chorus frog eDNA detections at two visits and a call survey at 180 ponds, Monteregie, Quebec, 2017-2018",
  creator = "Mazerolle, Marc J.; Dubois-Gagnon, Marie-Pier; Bernatchez, Louis; Belisle, Marc; Dubois, Yohann",
  pubDate = "2021", doi = "10.5061/dryad.8cz8w9gr1", sourceURL = "https://doi.org/10.5061/dryad.8cz8w9gr1",
  citation = "Mazerolle, M. J., Dubois-Gagnon, M.-P., Bernatchez, L., Belisle, M., & Dubois, Y. (2021). Data for the detection of the boreal chorus frog (Pseudacris maculata) using environmental DNA and call surveys at 180 ponds sampled in 2017-2018 in southeastern Quebec, Canada [Dataset]. Dryad. https://doi.org/10.5061/dryad.8cz8w9gr1",
  paperDOI = "10.1002/edn3.254",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Water samples for environmental DNA of the boreal chorus frog were taken at two visits to ponds in an urbanising landscape of southeastern Quebec in the breeding seasons of 2017 (90 ponds) and 2018 (110 ponds; 20 ponds sampled in both years). In 2018, 63 ponds also had a call survey at the first visit, used to compare the two methods. Pond-level vegetation, drying and landscape cover covariates at four buffer sizes are included.",
  samplingProtocol = "Each pond visited up to twice per breeding season; at each visit water was filtered for eDNA (volume recorded) and analysed by qPCR for Pseudacris maculata (detection call as deposited); at 63 ponds in 2018 a call survey was done at the first visit as well.",
  samplingProtocolCode = "eDNA", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site", closure = "closed",
  closureNote = "Occupancy is assumed closed within a breeding season across the two visits; the call survey and the eDNA sample of one visit are simultaneous (group by unit, period and obs_visit for a paired-method model). The 20 ponds sampled in both years carry both periods.",
  occasionKind = c("time", "method"), taxonInclusion = "single",
  designNote = "Experimental list of E9 (paired methods at one visit): occasion = 2 * (visit - 1) + method, method 1 = eDNA, 2 = call survey; obs_visit and obs_method give both components.",
  geographicCoverage = "Monteregie, southeastern Quebec, Canada (no pond coordinates deposited)",
  temporalCoverage = "2017-05/2018-06",
  covariateNote = "obs_days_since_snowmelt: visit date as days since snowmelt. obs_volume_l: litres of water filtered for eDNA (NA on call-survey rows). unit_hist_presence: 1 if the pond was known to be occupied at least once in 2004-2016. unit_veg1: PCA axis-1 score of vegetation cover. unit_dry: 1 if the pond dried up completely in summer. unit_dist_road and period_dist_anthropic: distance (m) to the nearest road and anthropic area. *_coverNNN: proportion of wetland, forest, open or anthropic area within NNN m; *_road_densityNNN: road density (m/ha) within NNN m. Covariates that the deposit gives different values for in a pond's two years are period_.",
  notShipped = list(
    missing_visits = "52 pond-years with no second visit and one first-visit eDNA sample not taken (pond 173, 2018): blank in the deposit, no rows",
    model_output = "the authors' occupancy and detection estimates"),
  notes = "The call survey was done only at the first 2018 visit of 63 ponds; the eDNA result of that visit is the same sample as in the main detection file (asserted), so it ships once.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/duboisgagnon_2021_quebec_chorusfrog_occ.R")
stage_dict_row(TABLE,
  description = "Boreal chorus frog (Pseudacris maculata) eDNA detections at up to two visits per pond, plus a call survey at the first visit of 63 ponds, 180 ponds in Monteregie, Quebec, 2017-2018, with habitat and landscape covariates.",
  url = "https://doi.org/10.5061/dryad.8cz8w9gr1",
  reference = "Dubois-Gagnon, M.-P., Bernatchez, L., Belisle, M., Dubois, Y. & Mazerolle, M. J. (2022). Distribution of the boreal chorus frog (Pseudacris maculata) in an urban environment using environmental DNA. Environmental DNA 4, 326-338. https://doi.org/10.1002/edn3.254",
  doi_paper = "10.1002/edn3.254", doi_data = "10.5061/dryad.8cz8w9gr1",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad deposit fetched from its Zenodo mirror doi:10.5281/zenodo.5504276 (record 5504276; the mirror carries the Dryad DOI). Paired eDNA / call survey at one visit as obs_method.",
  source_via = "Zenodo mirror of Dryad (file API)")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Dynamic occupancy (eDNA, paired call survey)",
  sampling_protocol = "eDNA", design = "Multi-season (2 years, 2 visits; call survey paired with eDNA at one visit)",
  realm = "Freshwater", country = "CAN", coordinates = "None in source",
  notes = "Experimental (E9): paired methods at one visit (obs_method).")
