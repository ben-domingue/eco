#!/usr/bin/env Rscript
# Table:  dezeeuw_2024_nl_waterbeetle_nmix
# Source: Dryad doi:10.5061/dryad.p5hqbzkwm, version 282038 (version 3, 2024-03-05), CC0 1.0
#         (as shown on the Dryad landing page and in the API record).
#   de Zeeuw, M., van Strien, A., Koese, B., Stienstra, J. & Soldaat, L. (2024). Data for:
#   Trends in abundance and occupancy of the protected waterbeetle Graphoderus bilineatus in
#   the Netherlands.
# Paper:  de Zeeuw, M. et al. (2024). Trends in abundance and occupancy of the protected
#         waterbeetle Graphoderus bilineatus in the Netherlands. Journal of Insect
#         Conservation, doi:10.1007/s10841-024-00550-x.
# Data:   Data_Graphoderus_bilineatus_the_Netherlands.csv (semicolon-separated) and a
#   README.md. 2,696 rows = 337 sampling locations x 2 survey years x 4 species. Columns:
#   Site (location code 1..530, 337 used), Species name, Count1/Count2 (beetles netted at
#   visit 1 / 2), Date1/Date2 (d-m-yyyy), Observer1/Observer2 (codes 1-4), N2000 (location
#   inside a Natura2000 site, 1/0). Count2, Date2 and Observer2 are NA where the location was
#   visited only once that season (12 location-years, all four species alike).
#   Design (Dryad methods text): 68 1-km squares, 5 locations per square chosen by the first
#   observer and hand-netted in September-October; a second observer netted the same
#   location 5-8 days later; each location resurveyed once six years later (rounds
#   2011-2016 and 2017-2022). The 1-km square of a location is not in the deposit. In 10
#   location-years Date2 is 7-9 days before Date1, so "visit 1" is the observer who chose the
#   locations, not always the earlier visit.
#
# Mapping (standard E1-E5; community repeated counts, N-mixture): unit = location (Site),
#   taxon = 4 species codes, period = calendar year 2011..2022 as 1..12 (each location has
#   one year in each six-year round; year and round in __periods), occasion = visit within
#   the year ordered by date (1 = earlier), y = count, date = visit date, observer =
#   observer code, obs_selector = 1 for the visit by the observer who chose the locations
#   (the deposit's Count1), unit_n2000 = Natura2000 flag. surveyEvidence = deposited_matrix:
#   a visit exists where its date is given; Count2/Date2/Observer2 are NA together, for the
#   same location-years in all four species, and counts are never NA where a date exists.
#   No coordinates in the deposit. Graphoderus bilineatus is Habitats Directive Annex II/IV
#   and IUCN VU, so it is a flagged taxon, but there is nothing to coarsen.
#   Not shipped: nothing in the file is left out; the authors' occupancy and GLMM trend
#   estimates are in the paper, not the deposit.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "dezeeuw_2024_nl_waterbeetle_nmix"
dir <- download_dryad("doi:10.5061/dryad.p5hqbzkwm", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("Data_Graphoderus_bilineatus_the_Netherlands.csv", "README.md")))
d <- fread(file.path(dir, "Data_Graphoderus_bilineatus_the_Netherlands.csv"), sep = ";")
stopifnot(identical(names(d), c("Site", "Species name", "Count1", "Count2", "Date1", "Date2", "Observer1", "Observer2", "N2000")))
setnames(d, "Species name", "species")
sp <- data.table(species = c("Graphoderus bilineatus", "Graphoderus cinereus", "Cybister lateralimarginalis", "Hydrophilus piceus"),
                 taxon = c("GRABIL", "GRACIN", "CYBLAT", "HYDPIC"))
stopifnot(nrow(d) == 2696, setequal(d$species, sp$species), all(table(d$species) == 674), uniqueN(d$Site) == 337)
d[, d1 := as.IDate(Date1, "%d-%m-%Y")][, d2 := as.IDate(Date2, "%d-%m-%Y")]
d[, year := year(d1)]
stopifnot(!anyNA(d$d1), !anyNA(d$Count1), !anyNA(d$Observer1), all(d$N2000 %in% 0:1),
          all(year(d$d2) == d$year, na.rm = TRUE), all(month(na.omit(c(d$d1, d$d2))) %in% 8:10),
          # the second visit is missing as a whole, never one field of it
          identical(is.na(d$Count2), is.na(d$d2)), identical(is.na(d$Count2), is.na(d$Observer2)),
          sum(is.na(d$Count2)) == 48)
# one row per location x year x species; visits identical across species
stopifnot(!anyDuplicated(d[, .(Site, year, species)]))
sv <- unique(d[, .(Site, year, d1, d2, Observer1, Observer2, N2000)])
stopifnot(nrow(sv) == 674, !anyDuplicated(sv[, .(Site, year)]), sum(is.na(sv$d2)) == 12,
          uniqueN(d[, .(Site, N2000)]) == 337)
# each location: one year in 2011-2016 and one in 2017-2022
yy <- sv[, .(r1 = sum(year <= 2016), r2 = sum(year >= 2017)), by = Site]
stopifnot(all(yy$r1 == 1 & yy$r2 == 1), range(sv$year) == c(2011, 2022))
gap <- as.integer(sv$d2 - sv$d1)
stopifnot(sum(gap < 0, na.rm = TRUE) == 10, all(abs(gap) %in% 5:9 | is.na(gap)), all(sv$Observer1 != sv$Observer2, na.rm = TRUE))

v1 <- d[, .(Site, species, year, y = Count1, date = d1, observer = Observer1, obs_selector = 1L, N2000)]
v2 <- d[!is.na(Count2), .(Site, species, year, y = Count2, date = d2, observer = Observer2, obs_selector = 0L, N2000)]
v <- rbind(v1, v2)
v[, occasion := frank(list(as.integer(date), -obs_selector), ties.method = "dense"), by = .(Site, species, year)]
years <- 2011:2022
long <- v[, .(unit = Site, taxon = sp$taxon[match(species, sp$species)], y, period = match(year, years),
              occasion = as.integer(occasion), date = format(date, "%Y-%m-%d"), observer = as.character(observer),
              unit_n2000 = N2000, obs_selector)]
stopifnot(nrow(long) == 2696 * 2 - 48, all(long$occasion %in% 1:2), !anyNA(long$y), all(long$y >= 0),
          nrow(unique(long[, .(unit, period, occasion)])) * 4 == nrow(long))

taxa <- make_taxa(sp$taxon, sp$species,
                  vernacularName = c(NA, NA, NA, "Great Silver Water Beetle"),
                  taxon_iucnCategory = c("VU", NA, NA, NA),
                  taxon_habitatsDirective = c("Annex II, IV", NA, NA, NA))
periods <- data.table(period = seq_along(years), year = years, round = ifelse(years <= 2016, 1L, 2L),
                      note = "September-October survey season; each location is surveyed in one year of each six-year round")
dataset <- list(
  title = "Repeated hand-net counts of Graphoderus bilineatus and three other water beetles at 337 locations, the Netherlands, 2011-2022",
  creator = "de Zeeuw, Marnix; van Strien, Arco; Koese, Bram; Stienstra, Jelle; Soldaat, Leo",
  pubDate = "2024", doi = "10.5061/dryad.p5hqbzkwm", sourceURL = "https://doi.org/10.5061/dryad.p5hqbzkwm",
  citation = "de Zeeuw, M., van Strien, A., Koese, B., Stienstra, J., & Soldaat, L. (2024). Data for: Trends in abundance and occupancy of the protected waterbeetle Graphoderus bilineatus in the Netherlands. Dryad. https://doi.org/10.5061/dryad.p5hqbzkwm",
  paperDOI = "10.1007/s10841-024-00550-x",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "National monitoring scheme for the Habitats Directive beetle Graphoderus bilineatus: 337 locations in 68 1-km squares, each hand-netted twice within a season by two different professional observers 5-8 days apart, and resurveyed six years later (rounds 2011-2016 and 2017-2022). Counts of G. bilineatus and three co-occurring water beetles. The authors fit occupancy and Poisson GLMM trend models and found declines and strong observer effects.",
  samplingProtocol = "Standardized hand-netting at a chosen sampling location, September-October; two visits per season by different observers 5-8 days apart; locations resurveyed on a six-year cycle.",
  samplingProtocolCode = "dipnet", surveyEvidence = "deposited_matrix", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion within period (two visits 5-8 days apart in one season); state may change between the two survey years six years apart", occasionKind = "time", taxonInclusion = "target",
  geographicCoverage = "The Netherlands, mainly the western and northern peat areas (no coordinates deposited)",
  temporalCoverage = "2011/2022", coordinatesCoarsened = NA,
  notes = "Each location has two of the twelve periods (one per round); __periods gives year and round. occasion is ordered by date; obs_selector = 1 marks the visit by the observer who chose the five locations in the square (in 10 location-years that visit came second). The 1-km square of each location is not deposited.",
  notShipped = list(
    `occupancy and trend estimates` = "model outputs in the paper; not in the deposit"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/dezeeuw_2024_nl_waterbeetle_nmix.R")

stage_dict_row(TABLE,
  description = "Repeated hand-net counts (two visits by different observers per season) of four water beetles, including the Habitats Directive species Graphoderus bilineatus, at 337 locations in the Netherlands, each surveyed in one year of each six-year round 2011-2016 and 2017-2022 (de Zeeuw et al. 2024).",
  url = "https://doi.org/10.5061/dryad.p5hqbzkwm",
  reference = "de Zeeuw, M., van Strien, A., Koese, B., Stienstra, J., & Soldaat, L. (2024). Trends in abundance and occupancy of the protected waterbeetle Graphoderus bilineatus in the Netherlands. Journal of Insect Conservation.",
  doi_paper = "10.1007/s10841-024-00550-x", doi_data = "10.5061/dryad.p5hqbzkwm",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Dryad version zip (version 282038). Occasions ordered by date; obs_selector keeps the deposit's visit-1/visit-2 distinction. No coordinates in the deposit.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "dipnet", design = "Multi-season (2 of 12 years per location x 2 visits)", realm = "Freshwater",
  country = "NLD", coordinates = "None in source",
  notes = "Observer per visit; strong observer effects reported by the authors. G. bilineatus is IUCN VU / Habitats Directive Annex II and IV.")
