#!/usr/bin/env Rscript
# Table:  olimpi_2024_calfarms_nmix
# Source: Dryad doi:10.5061/dryad.ns1rn8pz2 (CC0 1.0, as shown on the Dryad page), version
#   306971 (published 2024-07-23). Olimpi, E. M. & Karp, D. S. Data from: Ungrazed seminatural
#   habitats around farms benefit bird conservation without enhancing infectious disease risks.
# Paper:  Olimpi, E. M., et al. (2024). Ungrazed seminatural habitats around farms benefit bird
#         conservation without enhancing infectious disease risks. Landscape Ecology,
#         doi:10.1007/s10980-024-01907-y
# Data:   pointcount.csv (5,806 rows): one row per bird record on a 5-minute point count:
#         ID (farm code, point replicate number, year; 2019 IDs carry a stray space,
#         "Farm01 _1_point_count_2019"), Date (m/d/yy), Site (farm, 30 farms), Year (2019,
#         2020), StartTime, Species (4-letter alpha code, 111 codes), No.Birds (>= 1),
#         IDtype (S / H / S/H), Flyover (0/1), Outside (beyond 50 m, 0/1), Veg1/Veg2
#         (microhabitat of the bird), weather, temp_begin/end (F), windquant_begin/end (mph),
#         noise_binary, noise_description.
#         pointcount_covars.csv (227 rows): one row per point-year (ID): fencing, cropdiv,
#         weed_state_weighted, strata, seminatural (within 50 m), localdiv (farm), and
#         SemiNoGrazing_1km / SemiGrazing_1km (landscape fractions).
#         species_traits.csv (91 codes): common and scientific names, NABCI conservation
#         score, pathogen-carriage traits from Smith et al. (2022), flocking.
#         diversity_occ.RDS, diversity_Nmix.RDS, diversity_processed.csv: posterior
#         occupancy / abundance / diversity from the authors' models. pathogen_*.csv:
#         faecal pathogen samples from transects (not detection data).
#         Checked: every one of the 227 point-years has exactly three dates (three visits);
#         weather, temperature, wind and noise are constant within a visit; one visit
#         (Farm09_2, 2020-06-02) carries two start times (10:28 for 6 rows, 10:48 for 3).
#
# Mapping (N-mixture, multi-species community abundance, standard E9):
#   unit = point-year (the source ID with the space removed). The readme does not say
#   whether replicate number k at a farm is the same location in 2019 and 2020 (55 of
#   172 farm-replicate labels occur in both years, and their 50 m habitat covariates
#   differ between years), so the table does not claim it: each point-year is its own
#   unit with unit_year, and cluster_id = farm. occasion = visit (1-3, by date within the
#   point-year). taxon = alpha code. y = number of individuals recorded (sum of No.Birds)
#   excluding flyovers (Flyover = 1; 2,242 records, mostly swallows and waterbirds),
#   inside and beyond 50 m, as in margenau_2021_rowsongbirds_nmix.
#   Survey evidence: row_presence. A survey is a point-year x date with at least one
#   record; the protocol is three visits per point-year and all 227 point-years have
#   exactly three, so no visit is missing for lack of a record. Taxa are the codes with
#   at least one non-flyover record; a code recorded only as flyovers is not a taxon.
#   Covariates: unit_ = the point-year habitat covariates (pointcount_covars.csv, as
#   deposited) and unit_year; obs_ = start time (the earlier of the two at Farm09_2
#   2020-06-02), weather, temperatures, wind, noise_binary. date per row.
#   Taxa: scientific names from species_traits.csv; the 20 codes absent from it (birds
#   the authors left out of their models, mostly waterbirds and raptors) are resolved by
#   their IBP alpha code in the script (ORJU, Oregon Junco, is Junco hyemalis). Twelve
#   codes, among them "Blackbird spp.", "Gull spp." and MADU (the IBP code for Mandarin
#   Duck), occur only as flyovers and so have no taxon. taxon_iucnCategory is NA for four
#   names where GBIF's accepted name differs from the IUCN-assessed one (Himantopus
#   mexicanus, Icterus bullockii, Circus hudsonius, Pica nuttalli); no coordinates are
#   deposited, so nothing turns on it.
#   Coordinates: none deposited. Not shipped: the authors' occupancy, abundance and
#   diversity posteriors (model outputs), the traits file's pathogen and conservation
#   scores (from other studies), per-record IDtype, Outside and microhabitat (lost by
#   aggregation), noise_description, and the pathogen transect data (not detections).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "olimpi_2024_calfarms_nmix"
dir <- download_dryad("10.5061/dryad.ns1rn8pz2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(all(c("pointcount.csv", "pointcount_covars.csv", "species_traits.csv") %in% list.files(dir)))
raw <- fread(file.path(dir, "pointcount.csv"), na.strings = "NA")
cov <- fread(file.path(dir, "pointcount_covars.csv"))
tr  <- fread(file.path(dir, "species_traits.csv"))
stopifnot(nrow(raw) == 5806, nrow(cov) == 227, nrow(tr) == 91, uniqueN(raw$Site) == 30,
          all(raw$Year %in% 2019:2020), all(raw$No.Birds >= 1), !anyNA(raw$No.Birds),
          all(raw$Flyover %in% 0:1), all(raw$Outside %in% 0:1), uniqueN(raw$Species) == 111)
raw[, unit := gsub(" ", "", ID, fixed = TRUE)]
raw[, date := as.Date(Date, "%m/%d/%y")]
stopifnot(!anyNA(raw$date), all(year(raw$date) == raw$Year), setequal(raw$unit, cov$ID), !anyDuplicated(cov$ID))

# surveys: point-year x date; exactly three per point-year
vis <- c("weather", "temp_begin", "temp_end", "windquant_begin", "windquant_end", "noise_binary")
stopifnot(raw[, lapply(.SD, uniqueN), by = .(unit, date), .SDcols = vis][, all(unlist(.SD) == 1), .SDcols = vis])
st <- raw[, .(n = uniqueN(StartTime)), by = .(unit, date)]
stopifnot(nrow(st) == 681, st[n > 1, .N] == 1, st[n > 1, unit] == "Farm09_2_point_count_2020", st[n > 1, date] == as.Date("2020-06-02"))
surveys <- raw[, c(list(start = min(StartTime)), lapply(.SD, `[`, 1)), by = .(unit, Site, Year, date), .SDcols = vis]
setorder(surveys, unit, date)
surveys[, occasion := seq_len(.N), by = unit]
stopifnot(surveys[, .N, by = unit][, all(N == 3)])

fly <- raw$Flyover == 1L
stopifnot(sum(fly) == 2242)
det <- raw[!fly]
counts <- det[, .(y = sum(No.Birds)), by = .(unit, date, taxon = Species)]
species <- sort(unique(counts$taxon))
flyonly <- setdiff(unique(raw$Species), species)
cat(sprintf("  %d codes with a non-flyover record; %d flyover-only codes not shipped: %s\n",
            length(species), length(flyonly), paste(flyonly, collapse = ", ")))
stopifnot(length(species) == 99)

long <- surveys[, .(unit, cluster_id = Site, occasion, date = format(date), unit_year = Year,
                    obs_start_time = start, obs_weather = weather, obs_temp_begin_f = temp_begin,
                    obs_temp_end_f = temp_end, obs_wind_begin_mph = windquant_begin,
                    obs_wind_end_mph = windquant_end, obs_noise = noise_binary)]
long <- long[rep(seq_len(.N), each = length(species))][, taxon := rep(species, times = nrow(surveys))]
long <- merge(long, counts[, .(unit, date = format(date), taxon, y)], by = c("unit", "date", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
cv <- cov[, .(unit = ID, unit_fencing_m = fencing, unit_cropdiv = cropdiv, unit_weed_state = weed_state_weighted,
              unit_strata = strata, unit_seminatural = seminatural, unit_localdiv = localdiv,
              unit_seminat_nograze_1km = SemiNoGrazing_1km, unit_seminat_graze_1km = SemiGrazing_1km)]
long <- merge(long, cv, by = "unit")
setcolorder(long, c("unit", "taxon", "occasion", "y", "date", "cluster_id"))
stopifnot(nrow(long) == 681 * length(species), sum(long$y) == sum(det$No.Birds))

# taxa
extra <- data.table(
  Species = c("ALHU", "AWPE", "BCNH", "BNST", "DCCO", "GBHE", "GHOW", "GREG", "GRHE", "MADU", "MALL",
              "ORJU", "OSPR", "TUVU", "WILL", "WTKI", "WTSW", "YBMA", "Blackbird spp.", "Gull spp."),
  CommonName = c("Allen's Hummingbird", "American White Pelican", "Black-crowned Night Heron", "Black-necked Stilt",
                 "Double-crested Cormorant", "Great Blue Heron", "Great Horned Owl", "Great Egret", "Green Heron",
                 "Mandarin Duck", "Mallard", "Dark-eyed Junco (Oregon)", "Osprey", "Turkey Vulture", "Willet",
                 "White-tailed Kite", "White-throated Swift", "Yellow-billed Magpie", "blackbirds", "gulls"),
  ScientificName = c("Selasphorus sasin", "Pelecanus erythrorhynchos", "Nycticorax nycticorax", "Himantopus mexicanus",
                     "Nannopterum auritum", "Ardea herodias", "Bubo virginianus", "Ardea alba", "Butorides virescens",
                     "Aix galericulata", "Anas platyrhynchos", "Junco hyemalis", "Pandion haliaetus", "Cathartes aura",
                     "Tringa semipalmata", "Elanus leucurus", "Aeronautes saxatalis", "Pica nuttalli", "Icteridae", "Laridae"))
stopifnot(!any(extra$Species %in% tr$Species), setequal(c(tr$Species, extra$Species), unique(raw$Species)))
nm <- rbind(tr[, .(Species, CommonName, ScientificName)], extra)[match(species, Species)]
stopifnot(!anyNA(nm$ScientificName))
rank <- ifelse(nm$Species %in% c("Blackbird spp.", "Gull spp."), "family", "species")
taxa <- make_taxa(species, nm$ScientificName, vernacularName = nm$CommonName, taxonRank = rank,
                  allow_higher = intersect(species, c("Blackbird spp.", "Gull spp.")))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]

dataset <- list(
  title = "Bird point counts on 30 farms in California, 2019-2020 (three visits per point-year)",
  creator = "Olimpi, Elissa M.; Karp, Daniel S.", pubDate = "2024", doi = "10.5061/dryad.ns1rn8pz2",
  sourceURL = "https://doi.org/10.5061/dryad.ns1rn8pz2",
  citation = "Olimpi, E. M., & Karp, D. S. (2024). Data from: Ungrazed seminatural habitats around farms benefit bird conservation without enhancing infectious disease risks [Dataset]. Dryad. https://doi.org/10.5061/dryad.ns1rn8pz2",
  paperDOI = "10.1007/s10980-024-01907-y",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Point counts of birds at points on 30 farms, each point-year counted on three dates, with point-level habitat (fencing, crop diversity, weediness, vegetation strata, seminatural cover) and landscape cover of grazed and ungrazed seminatural habitat, used to relate bird abundance and diversity to surrounding seminatural habitat.",
  samplingProtocol = "Point counts, three visits per point per year in May-July 2019 and 2020; every bird seen or heard recorded with number of individuals, flyover status and whether beyond 50 m; y is the number of individuals per species per count excluding flyovers, all distances.",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "occasion = visit within one breeding season; unit = point-year (whether a replicate number is the same location across years is not stated)",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Farms in California, USA (farm codes only; no coordinates deposited)", temporalCoverage = "2019-05/2020-07",
  notShipped = list(diversity_occ.RDS = "posterior occupancy from the authors' model (model output)",
                    diversity_Nmix.RDS = "posterior abundance from the authors' N-mixture model (model output)",
                    diversity_processed.csv = "posterior diversity summaries (model output)",
                    flyovers = sprintf("2,242 flyover records excluded from y; %d codes seen only as flyovers have no taxon: %s", length(flyonly), paste(flyonly, collapse = ", ")),
                    per_record = "IDtype, Outside (beyond 50 m), Veg1/Veg2 microhabitat: per record, lost by aggregation",
                    noise_description = "free text",
                    species_traits = "conservation score and pathogen-carriage probabilities (from other studies)",
                    pathogen_files = "faecal pathogen transects, not detection data"),
  notes = "unit is the point-year: 55 farm-replicate labels recur across 2019 and 2020 but the readme does not say they are the same location; cluster_id is the farm. One visit (Farm09_2, 2020-06-02) has two recorded start times; obs_start_time is the earlier. Habitat covariates are shipped as deposited (some are indices, see the paper's Methods).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/olimpi_2024_calfarms_nmix.R")

stage_dict_row(TABLE,
  description = "Counts of 99 bird species on point counts at 227 point-years on 30 farms in California (2019-2020), three visits each, with point-level habitat and landscape seminatural cover; built from per-record counts, flyovers excluded.",
  url = "https://doi.org/10.5061/dryad.ns1rn8pz2",
  reference = "Olimpi, E. M., et al. (2024). Ungrazed seminatural habitats around farms benefit bird conservation without enhancing infectious disease risks. Landscape Ecology.",
  doi_paper = "10.1007/s10980-024-01907-y", doi_data = "10.5061/dryad.ns1rn8pz2",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Zeros from row presence: all 227 point-years have exactly three dated visits. Flyovers excluded from y; model posteriors not shipped. Fetched as the Dryad version zip.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "N-mixture (multi-species)",
  sampling_protocol = "point_count", design = "Single-season repeated visits (3 per point-year)", realm = "Terrestrial", country = "USA",
  coordinates = "None in source", notes = "Agricultural landscape; unit = point-year.", status = "tagged")
