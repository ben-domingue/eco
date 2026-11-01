#!/usr/bin/env Rscript
# Table:  palacio_2020_pampasbirds_comm
# Source: Dryad doi:10.5061/dryad.cvdncjt22 (CC0 1.0), files from the Zenodo mirror
#         https://zenodo.org/records/4728255
#   Palacio, F.X., Maragliano, R.E. & Montalti, D. (2021). Data from: The costs of
#   ignoring species detectability on functional diversity estimation. Dryad.
# Paper:  Palacio, Maragliano & Montalti (2020). The costs of ignoring species
#         detectability on functional diversity estimation. The Auk 137(4), ukaa057,
#         doi:10.1093/auk/ukaa057
# Data:   multispecies_occupancy_model.csv: 43 species x 200 columns `point<i>.<season><v>`
#         = presence/absence (0/1) of the species at point count i on visit v of that
#         season; 10 points x 4 seasons (fall, winter, spring, summer, in that column
#         order) x 5 visits; every cell filled. bird_functional_traits.csv: body mass,
#         diet (6 binary), foraging stratum (5 binary) and foraging behaviour (7 binary)
#         per species. README.docx gives the species code -> name key.
#
# Mapping (standard sections 3.5 + 3.6, multi-season community occupancy):
#   unit = point 1..10, taxon = species code, period = season 1..4 (fall..summer),
#   occasion = visit 1..5, y = 0/1. Season label is a function of period alone, so it
#   goes in the periods side table (section 5.4), not the core file. Traits go in the
#   taxa side table as taxon_* (section 5.1); they are not copied into the core.
# Floor: 10 points is below the proposed 30-unit floor; built as a case for that
#   decision (the species dimension, 43, is where this table's information is).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "palacio_2020_pampasbirds_comm"
BASE <- "https://zenodo.org/api/records/4728255/files/%s/content"
occ <- fread(download_cached(sprintf(BASE, "multispecies_occupancy_model.csv"), TABLE))
tr  <- fread(download_cached(sprintf(BASE, "bird_functional_traits.csv"), TABLE))
stopifnot(nrow(occ) == 43, ncol(occ) == 201, setequal(occ$species, tr$species))

# species code -> scientific name, transcribed from README.docx (three entries had
# stray spaces in the docx and are completed from the same list)
SPP <- c(agebad = "Agelaioides badius", amabra = "Amazonetta brasiliensis", bascul = "Basileuterus culicivorus",
  carpla = "Caracara plancus", chlluc = "Chlorostilbon lucidus", colmel = "Colaptes melanochloros",
  cycguj = "Cyclarhis gujanensis", elapar = "Elaenia parvirostris", furruf = "Furnarius rufus",
  geoaeq = "Geothlypis aequinoctialis", guigui = "Guira guira", ictpyr = "Icterus pyrrhopterus",
  lepang = "Lepidocolaptes angustirostris", macrix = "Machetornis rixosa", micmel = "Microspingus melanoleucus",
  milchi = "Milvago chimango", mimsat = "Mimus saturninus", molbon = "Molothrus bonariensis",
  myimac = "Myiodynastes maculatus", myimon = "Myiopsitta monachus", pacpol = "Pachyramphus polychopterus",
  parcor = "Paroaria coronata", patpic = "Patagioenas picazuro", phastr = "Phacellodomus striaticollis",
  pitsul = "Pitangus sulphuratus", poldum = "Polioptila dumicola", poonig = "Poospiza nigrorufa",
  rossoc = "Rosthramus sociabilis", rupmag = "Rupornis magnirostris", schphr = "Schoeniophylax phryganophilus",
  sersub = "Serpophaga subcristata", sicfla = "Sicalis flaveola", siclut = "Sicalis luteola",
  spimag = "Spinus magellanicus", spocae = "Sporophila caerulescens", synspi = "Synallaxis spixi",
  troaed = "Troglodytes aedon", turama = "Turdus amaurochalinus", turruf = "Turdus rufiventris",
  vanchi = "Vanellus chilensis", viroli = "Vireo olivaceus", zenaur = "Zenaida auriculata", zoncap = "Zonotrichia capensis")
stopifnot(setequal(names(SPP), occ$species))

cols <- setdiff(names(occ), "species")
key <- data.table(col = cols,
                  point = as.integer(sub("^point([0-9]+)\\..*$", "\\1", cols)),
                  season = sub("^point[0-9]+\\.([a-z]+)[0-9]$", "\\1", cols),
                  visit = as.integer(sub("^.*[a-z]([0-9])$", "\\1", cols)))
SEASONS <- c("fall", "winter", "spring", "summer")      # column order in the file = chronological
stopifnot(setequal(key$season, SEASONS), key[, .N, by = .(point, season, visit)][, all(N == 1)])
key[, period := match(season, SEASONS)]

long <- melt(occ, unit.vars = "species", variable.name = "col", value.name = "y", variable.factor = FALSE)
long <- merge(long, key, by = "col")
stopifnot(all(long$y %in% c(0L, 1L)))
long <- long[, .(unit = point, taxon = toupper(species), y = as.integer(y), period, occasion = visit)]
stopifnot(nrow(long) == 43 * 200)

# the README spells the snail kite "Rosthramus"; GBIF knows it as Rostrhamus sociabilis
lookup <- unname(SPP); lookup[lookup == "Rosthramus sociabilis"] <- "Rostrhamus sociabilis"
taxa <- make_taxa(toupper(names(SPP)), unname(SPP), lookupName = lookup)
trait_cols <- setdiff(names(tr), "species")
tr2 <- copy(tr)[, taxon := toupper(species)][, species := NULL]
setnames(tr2, trait_cols, paste0("taxon_", gsub("\\.", "_", trait_cols)))
taxa <- merge(taxa, tr2, by = "taxon", sort = FALSE)
periods <- data.table(period = 1:4, season = SEASONS, note = "austral season; survey years not stated in the deposit")
dataset <- list(
  title = "Bird community point counts, 10 points x 4 seasons x 5 visits, east-central Argentina (Palacio et al. 2020)",
  creator = "Palacio, Facundo X.; Maragliano, Rene E.; Montalti, Diego", pubDate = "2021",
  doi = "10.5061/dryad.cvdncjt22", sourceURL = "https://doi.org/10.5061/dryad.cvdncjt22",
  mirrorURL = "https://zenodo.org/records/4728255",
  citation = "Palacio, F. X., Maragliano, R. E., & Montalti, D. (2020). The costs of ignoring species detectability on functional diversity estimation. The Auk, 137(4), ukaa057. https://doi.org/10.1093/auk/ukaa057",
  paperDOI = "10.1093/auk/ukaa057",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Multi-species occupancy data used to obtain detection-corrected functional diversity metrics for bird communities in east-central Argentina; detection related to body mass, diet and foraging stratum.",
  samplingProtocol = "Point counts, five visits per season in each of four seasons; presence/absence per species per visit.",
  samplingProtocolCode = "point_count", responseType = "detection", unitKind = "site",
  closure = "occasion (visits within a season); state may change between seasons (period)",
  itemCovariates = "19 functional traits in the taxa side table (body mass; diet, foraging stratum and foraging behaviour as 0/1)",
  geographicCoverage = "east-central Argentina (Pampas; no coordinates deposited)", temporalCoverage = "not stated in deposit",
  coordinatesCoarsened = NA)
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/palacio_2020_pampasbirds_comm.R")

stage_dict_row(TABLE,
  description = "Presence/absence of 43 bird species at 10 point-count stations in east-central Argentina over 4 seasons x 5 visits (200 surveys per point), with 19 species-level functional traits (body mass, diet, foraging stratum, foraging behaviour) in the taxa side table.",
  url = "https://doi.org/10.5061/dryad.cvdncjt22",
  reference = "Palacio, F. X., Maragliano, R. E., & Montalti, D. (2020). The costs of ignoring species detectability on functional diversity estimation. The Auk, 137(4), ukaa057.",
  doi_paper = "10.1093/auk/ukaa057", doi_data = "10.5061/dryad.cvdncjt22",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Files fetched from the Zenodo mirror (record 4728255). 10 sites: below the proposed 30-unit floor, but 43 species x 20 surveys per site.",
  source_via = "Dryad via Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (multi-season)",
  sampling_protocol = "point_count", design = "Multi-season (4 seasons x 5 visits)", realm = "Terrestrial",
  country = "ARG", coordinates = "None in source", notes = "Fully balanced; traits as taxon_ in taxa table.",
  status = "tagged; hold: below sample floor")
