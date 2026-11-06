#!/usr/bin/env Rscript
# Table:  glorioso_2021_louisiana_turtle_count
# Source: USGS ScienceBase doi:10.5066/P90JT34K (USGS data release, published 2021-09-14; use
#         constraints "None"; US public domain, recorded as CC0 1.0)
#   Glorioso, B.M., and Waddle, J.H., 2021, Data from a 2019 occupancy survey of alligator snapping
#   turtles, Macrochelys temminckii, in south-central Louisiana: U.S. Geological Survey data release.
# Paper:  Glorioso, B.M., et al., 2023, Condition and coloration of lingual lures of alligator
#   snapping turtles. Southeastern Naturalist 22(sp12), doi:10.1656/058.022.0sp1227.
# Data:   Trap Site Conditions.csv: 119 hoop-net trap sites (first date, parish, net number) with
#         water-body width, net type, mesh, hoop diameter, bait, lentic or lotic, habitat,
#         microhabitat, bank disturbance, water temperature, salinity, canopy cover and air
#         temperature at setting. Hoop Net Data.csv: 357 net events (plus two empty rows): 119
#         settings (Date Checked "Null") and 238 checks, each one night after the net was set or
#         re-set, with set / check times, net size, bait, the turtles caught ("1 Trachemys scripta,
#         2 Sternotherus carinatus") and bycatch. AST Data.csv: the 6 alligator snapping turtle
#         captures (5 individuals, shell-notch ids) with measurements; Non-AST Data.csv: the 42
#         other turtles with measurements. Water Data.csv: water chemistry by parish and time.
#         Locations are parish only ("more specific locations were avoided due to the sensitive
#         nature of the target species"). Asserted: every check matches exactly one trap site (same
#         parish, after collapsing doubled spaces in the parish names, and net, set on or after the
#         site's first date), every site has exactly two one-night checks, and the per-species
#         totals of the catch strings equal the AST and non-AST capture files.
# Mapping: unit = trap site ("<parish>_net<NN>_<first date>"), occasion = check (1, 2 in date order),
#   taxon = turtle species, y = number caught in the net at that check (surveyEvidence
#   sample_table: a row of the hoop-net file is a check). Community count: every turtle caught was
#   recorded to species, so taxonInclusion = recorded (seven species). unit_ covariates from the
#   site file (one row per site); obs_bait, check start time and set time. unit_parish is the only
#   locator the source published; no coordinates are deposited.
# Not shipped: measurements, marks, PIT codes and samples of the captured turtles (individual
#   records, not survey observations); fish and other bycatch (not identified consistently and
#   not a turtle survey); Water Data.csv (keyed by parish and time, not linkable to a trap site).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "glorioso_2021_louisiana_turtle_count"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/611c571fd34e40dd9c000296?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
rd <- function(f) fread(download_cached(fl[[f]], TABLE, filename = f), na.strings = c("Null", ""))
h <- rd("Hoop Net Data.csv"); ts <- rd("Trap Site Conditions.csv"); ast <- rd("AST Data.csv"); non <- rd("Non-AST Data.csv")
h <- h[!is.na(Parish)]
stopifnot(nrow(h) == 357, nrow(ts) == 119, nrow(ast) == 6, nrow(non) == 42)
np <- function(x) gsub("\\s+", " ", trimws(x))
h[, `:=`(P = np(Parish), ds = as.IDate(`Date Set`, format = "%m/%d/%Y"), dc = as.IDate(`Date Checked`, format = "%m/%d/%Y"))]
ts[, `:=`(P = np(Parish), d = as.IDate(Date, format = "%m/%d/%Y"))]
stopifnot(!anyDuplicated(ts[, .(P, Net, d)]), !anyNA(h$ds), sum(is.na(h$dc)) == 119, all(is.na(h[is.na(dc), `Turtle Catch`])))
chk <- h[!is.na(dc)]
stopifnot(all(chk$dc - chk$ds == 1))
chk[, site_d := ts[.SD, on = .(P, Net, d <= ds), mult = "last", x.d]]
stopifnot(!anyNA(chk$site_d))
chk[, unit := sprintf("%s_net%02d_%s", gsub("[^A-Za-z]", "", P), as.integer(Net), format(site_d))]
setorder(chk, unit, dc)
chk[, occasion := seq_len(.N), by = unit]
stopifnot(uniqueN(chk$unit) == 119, all(chk[, .N, by = unit]$N == 2))
# parse the catch strings: "1 Macrochelys temminckii, 1 Apalone spinifera"
cs <- chk[!is.na(`Turtle Catch`), .(part = trimws(strsplit(`Turtle Catch`, ",")[[1]])), by = .(unit, occasion)]
cs[, `:=`(n = as.integer(sub("^(\\d+) .*", "\\1", part)), sci = sub("^\\d+ ", "", part))]
stopifnot(!anyNA(cs$n), !anyDuplicated(cs[, .(unit, occasion, sci)]))
code <- c("Macrochelys temminckii" = "MTEM", "Trachemys scripta" = "TSCR", "Sternotherus carinatus" = "SCAR",
          "Chelydra serpentina" = "CSER", "Apalone spinifera" = "ASPI", "Sternotherus odoratus" = "SODO", "Pseudemys concinna" = "PCON")
stopifnot(all(cs$sci %in% names(code)))
cs[, taxon := code[sci]]
tot <- cs[, .(n = sum(n)), by = taxon]
nontot <- non[, .N, by = Species]
stopifnot(tot[taxon == "MTEM", n] == nrow(ast), sum(tot[taxon != "MTEM", n]) == nrow(non),
          all(merge(tot[taxon != "MTEM"], nontot, by.x = "taxon", by.y = "Species")[, n == N]), nrow(nontot) == 6)
grid <- CJ(i = seq_len(nrow(chk)), taxon = unname(code))
grid <- cbind(chk[grid$i, .(unit, occasion, dc, Net, P, site_d, `Time Set`, `Start Time`, Bait)], taxon = grid$taxon)
grid <- merge(grid, cs[, .(unit, occasion, taxon, n)], by = c("unit", "occasion", "taxon"), all.x = TRUE)
grid[is.na(n), n := 0L]
stopifnot(sum(grid$n) == 48)
site <- ts[, .(P, Net, site_d = d, unit_parish = P, unit_water_width_m = `Width at Trap Site`, unit_net_type = `Net Type`,
               unit_mesh_size_cm = `Mesh Size`, unit_hoop_diameter_m = `Hoop Diameter`, unit_waterbody = `Lentic or Lotic`,
               unit_habitat = `Habitat Type`, unit_microhabitat = Microhabitat, unit_bank_disturbance = `Bank Habitat Disturbance`,
               unit_water_temp_c = `Water Temp`, unit_salinity_ppt = Salinity, unit_canopy_pct = `Percent Canopy Coverage`,
               unit_air_temp_c = `Air Temp`)]
long <- merge(grid, site, by = c("P", "Net", "site_d"))
long <- long[, .(unit, taxon, y = n, occasion, date = format(dc), unit_parish, unit_water_width_m, unit_net_type, unit_mesh_size_cm,
                 unit_hoop_diameter_m, unit_waterbody, unit_habitat, unit_microhabitat, unit_bank_disturbance, unit_water_temp_c,
                 unit_salinity_ppt, unit_canopy_pct, unit_air_temp_c, obs_bait = Bait, obs_time_set = `Time Set`, obs_check_start = `Start Time`)]
stopifnot(nrow(long) == 238 * 7)
taxa <- make_taxa(unname(code), names(code),
                  vernacularName = c("Alligator snapping turtle", "Pond slider", "Razorback musk turtle", "Common snapping turtle",
                                     "Spiny softshell", "Eastern musk turtle", "River cooter"))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Turtle captures in baited hoop nets at 119 trap sites in south-central Louisiana, 2019 (alligator snapping turtle occupancy survey)",
  creator = "Glorioso, Brad M.; Waddle, J. Hardin",
  pubDate = "2021", doi = "10.5066/P90JT34K", sourceURL = "https://doi.org/10.5066/P90JT34K",
  citation = "Glorioso, B.M., and Waddle, J.H., 2021, Data from a 2019 occupancy survey of alligator snapping turtles, Macrochelys temminckii, in south-central Louisiana: U.S. Geological Survey data release, https://doi.org/10.5066/P90JT34K.",
  paperDOI = "10.1656/058.022.0sp1227",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "A 2019 trapping effort for alligator snapping turtles in nine parishes of south-central Louisiana: baited hoop nets set at 119 trap sites, each checked on two consecutive mornings. Every turtle caught was identified to species; seven species were caught, including six captures of five alligator snapping turtles.",
  samplingProtocol = "Fiberglass hoop nets (1.22 m hoops) baited with carp or pogy, set at a trap site and checked the next morning, re-set and checked again the following morning; the turtles in the net at each check were counted by species.",
  samplingProtocolCode = "hoop_net", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "two consecutive one-night checks of the same net at the same site", occasionKind = "time",
  taxonInclusion = "recorded",
  geographicCoverage = list(description = "Allen, Calcasieu, Iberia, Iberville, Jefferson Davis, Lafayette, Pointe Coupee, St. Landry and St. Martin parishes, Louisiana, USA (locations published to parish only)",
                            boundingBox = list(west = -93.1888, east = -91.0506, south = 29.8025, north = 30.8445)),
  temporalCoverage = "2019-05/2019-10",
  notShipped = list(individual_records = "AST Data.csv and Non-AST Data.csv: measurements, marks, PIT codes and samples of captured turtles (totals asserted equal to the catch counts)",
                    bycatch = "fish and other non-turtle bycatch in Comments/Bycatch",
                    water_data = "Water Data.csv: chemistry keyed by parish and time, not linkable to a trap site"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/glorioso_2021_louisiana_turtle_count.R")
stage_dict_row(TABLE,
  description = "Counts of seven turtle species, including the alligator snapping turtle, caught in baited hoop nets on two consecutive nightly checks at each of 119 trap sites in south-central Louisiana, 2019, with trap-site habitat, net and bait.",
  url = "https://doi.org/10.5066/P90JT34K",
  reference = "Glorioso, B.M., and Waddle, J.H. (2021). Data from a 2019 occupancy survey of alligator snapping turtles, Macrochelys temminckii, in south-central Louisiana. U.S. Geological Survey data release.",
  doi_paper = "10.1656/058.022.0sp1227", doi_data = "10.5066/P90JT34K", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Catch strings parsed to species counts; locations to parish only, as published.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Reptiles", model_family = "Community N-mixture / occupancy", sampling_protocol = "hoop_net",
  design = "Single-season (2 nightly checks)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Target species alligator snapping turtle (IUCN VU) caught 6 times; parish is the only locator.")
