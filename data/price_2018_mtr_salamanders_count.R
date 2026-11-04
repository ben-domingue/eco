#!/usr/bin/env Rscript
# Table:  price_2018_mtr_salamanders_count
# Source: Dryad doi:10.5061/dryad.7278k2n (CC0 1.0, as shown on the Dryad page; published
#         2018-09-26). Price, S.J., Freytag, S.B., Bonner, S.J., Drayer, A.N., Muncy, B.L.,
#         Hutton, J.M. & Barton, C.D. (2018). Data from: Mountaintop removal mining alters
#         stream salamander population dynamics.
# Paper:  Price, S.J. et al. (2018). Mountaintop removal mining alters stream salamander
#         population dynamics. Diversity and Distributions 24, 1242-1251,
#         doi:10.1111/ddi.12760. Hierarchical N-mixture model with dynamic occupancy for
#         stream salamander species and life stages in 23 headwater reaches (forested
#         reference vs mountaintop-removal mined), south-eastern Kentucky, three years.
# Data:   "Salamander Data 12.16.2015_formatted.Rdata" with six objects: Counts (data.frame
#         230 rows: Site 1-23, Year 1-3, Visit 1-4 (4 visits in year 1, 3 in years 2-3), and
#         seven count columns DF.A, DM.A, EC.A, GP, PR, EC.L, DU.L, no NA); MTR (23-vector,
#         1 = mountaintop-removal site, 0 = reference); CoverObjects (23 x 3, cover objects
#         searched per site and year, columns C1.1-C3.1); Precip, JulianDate, Conductivity
#         (23 x 3 x 4 site x year x visit arrays; NA in the impossible visit 4 of years 2-3;
#         Conductivity NA at three surveyed visits). price_et_al_2018.R (data preparation)
#         and price_et_al_2018_jags.R (the JAGS model) are code. The deposit has no codebook:
#         the count columns are read from the paper's design as Desmognathus fuscus adults
#         (DF.A), D. monticola adults (DM.A), Eurycea cirrigera adults (EC.A), Gyrinophilus
#         porphyriticus (GP, stages pooled), Pseudotriton ruber (PR, stages pooled),
#         E. cirrigera larvae (EC.L) and Desmognathus larvae not identified to species
#         (DU.L); the model treats each column as a "species". Calendar years are not in
#         the deposit (the data file is dated December 2015); units of Precip and
#         Conductivity are not stated (Conductivity values look like uS/cm).
#
# Mapping (standard: N-mixture repeated counts with dynamic occupancy, community, E9 core):
#   unit = stream reach (site 1-23); period = study year 1-3 (__periods; calendar years
#   unknown); occasion = visit; taxon = species x life-stage item (seven codes, with
#   lifeStage (Darwin Core) in __taxa, E6; GP and PR pool all stages, so lifeStage is
#   empty and taxonRemarks says so; DESSPPL is a genus-rank record);
#   y = count. obs_: day of year, precipitation (as deposited), conductivity. period_
#   (reach x year): cover objects searched. unit_: mountaintop-removal flag. Survey
#   evidence: the deposited counts table, one row per conducted visit (row_presence; every
#   site has every visit of the design). No dates (day of year only), no coordinates.
#   v1.1: closure = closed, occasionKind = time, taxonInclusion = recorded (every item has
#   a count > 0, asserted).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "price_2018_mtr_salamanders_count"
dir <- download_dryad("10.5061/dryad.7278k2n", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- list.files(dir, "^Salamander Data 12\\.16\\.2015_formatted\\.Rdata$", recursive = TRUE, full.names = TRUE)
stopifnot(length(f) == 1)
e <- new.env(); load(f, envir = e)
stopifnot(setequal(ls(e), c("Conductivity", "Counts", "CoverObjects", "JulianDate", "MTR", "Precip")))
C <- as.data.table(e$Counts)
stopifnot(is.integer(C$Site), is.character(C$Year), is.character(C$Visit))   # Year and Visit are stored as text
C[, `:=`(Year = as.integer(Year), Visit = as.integer(Visit))]
ITEM <- c("DF.A", "DM.A", "EC.A", "GP", "PR", "EC.L", "DU.L")

# facts about the source
stopifnot(identical(names(C), c("Site", "Year", "Visit", ITEM)), nrow(C) == 230, !anyNA(C),
          !anyDuplicated(C[, .(Site, Year, Visit)]), all(C$Site %in% 1:23),
          identical(C[, .N, by = Year][order(Year), N], c(92L, 69L, 69L)),
          all(C[, max(Visit), by = Year][order(Year), V1] == c(4, 3, 3)),
          all(as.matrix(C[, ..ITEM]) >= 0), sum(as.matrix(C[, ..ITEM])) == 2481,
          length(e$MTR) == 23, all(e$MTR %in% 0:1), sum(e$MTR) == 11,
          identical(dim(e$CoverObjects), c(23L, 3L)), !anyNA(e$CoverObjects),
          all(sapply(list(e$Precip, e$JulianDate, e$Conductivity), function(a) identical(dim(a), c(23L, 3L, 4L)))))
idx <- cbind(C$Site, C$Year, C$Visit)
stopifnot(!anyNA(e$Precip[idx]), !anyNA(e$JulianDate[idx]), sum(is.na(e$Conductivity[idx])) == 3,
          all(is.na(e$Precip[, 2:3, 4])), all(e$JulianDate[idx] >= 60 & e$JulianDate[idx] <= 200))

C[, `:=`(obs_day_of_year = e$JulianDate[idx], obs_precip = e$Precip[idx], obs_conductivity = e$Conductivity[idx])]
CODE <- c(DF.A = "DESFUSA", DM.A = "DESMONA", EC.A = "EURCIRA", GP = "GYRPOR", PR = "PSERUB", EC.L = "EURCIRL", DU.L = "DESSPPL")
long <- melt(C, id.vars = c("Site", "Year", "Visit", "obs_day_of_year", "obs_precip", "obs_conductivity"),
             measure.vars = ITEM, variable.name = "item", value.name = "y", variable.factor = FALSE)
long[, taxon := CODE[item]]
cov <- data.table(Site = rep(1:23, 3), Year = rep(1:3, each = 23), period_cover_objects = as.vector(as.matrix(e$CoverObjects)))
long <- merge(long, cov, by = c("Site", "Year"))
long[, unit_mtr := e$MTR[Site]]
long <- long[, .(unit = Site, taxon, y = as.integer(y), period = as.integer(Year), occasion = as.integer(Visit),
                 obs_day_of_year, obs_precip, obs_conductivity, period_cover_objects, unit_mtr)]
stopifnot(nrow(long) == 230 * 7, sum(long$y) == 2481, all(long[, sum(y), by = taxon]$V1 > 0), !anyDuplicated(long[, .(unit, taxon, period, occasion)]))

taxa <- make_taxa(unname(CODE),
                  c("Desmognathus fuscus", "Desmognathus monticola", "Eurycea cirrigera", "Gyrinophilus porphyriticus",
                    "Pseudotriton ruber", "Eurycea cirrigera", "Desmognathus"),
                  vernacularName = c("Northern dusky salamander", "Seal salamander", "Southern two-lined salamander",
                                     "Spring salamander", "Red salamander", "Southern two-lined salamander", "Dusky salamanders"),
                  taxonRank = c(rep("species", 6), "genus"),
                  lifeStage = c("adult", "adult", "adult", NA, NA, "larva", "larva"),   # Darwin Core (E6); GP and PR pool stages
                  taxonRemarks = c(NA, NA, NA, "all life stages pooled in the deposited column", "all life stages pooled in the deposited column",
                                   NA, "Desmognathus larvae not identified to species (recorded at genus rank)"),
                  taxon_deposited_column = ITEM)
periods <- data.table(period = 1:3, study_year = 1:3, year = NA_integer_, n_visits = c(4L, 3L, 3L))

dataset <- list(
  title = "Repeated counts of stream salamander species and life stages in 23 headwater reaches in forested and mountaintop-removal-mined catchments, south-eastern Kentucky, three years",
  creator = "Price, Steven J.; Freytag, Sara Beth; Bonner, Simon J.; Drayer, Andrea N.; Muncy, Brenee' L.; Hutton, Jacob M.; Barton, Christopher D.",
  pubDate = "2018", doi = "10.5061/dryad.7278k2n", sourceURL = "https://doi.org/10.5061/dryad.7278k2n",
  citation = "Price, S. J., Freytag, S. B., Bonner, S. J., Drayer, A. N., Muncy, B. L., Hutton, J. M., & Barton, C. D. (2018). Data from: Mountaintop removal mining alters stream salamander population dynamics [Dataset]. Dryad. https://doi.org/10.5061/dryad.7278k2n",
  paperDOI = "10.1111/ddi.12760",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Counts of five stream salamander species, with adults and larvae separated for two-lined and dusky salamanders, in 23 headwater stream reaches of south-eastern Kentucky, 12 in forested reference catchments and 11 in catchments altered by mountaintop-removal coal mining, visited four times in the first year and three times in each of the next two, with cover objects searched, precipitation, conductivity and day of year. Reference reaches had higher abundance and occupancy, and most species and stages had lower occupancy, colonization, persistence and abundance in mined reaches.",
  samplingProtocol = "Repeated counts of salamanders in headwater stream reaches, searching cover objects (number per reach and year deposited); four visits in year 1 and three in years 2-3. Reach length and search method are in the paper.",
  samplingProtocolCode = "cover_object_search", surveyEvidence = "row_presence", responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "period (study year; dynamic occupancy between years, N-mixture within)",
  occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = "Headwater streams of south-eastern Kentucky, USA (Central Appalachia coalfield); no coordinates deposited",
  temporalCoverage = "three consecutive years before December 2015 (calendar years not stated in the deposit)",
  coordinatesCoarsened = NA,
  notShipped = list(`price_et_al_2018.R, price_et_al_2018_jags.R` = "analysis code; no model outputs are deposited"),
  notes = "taxon is the deposit's species x life-stage count column (taxon_deposited_column and lifeStage in __taxa): GP and PR pool all stages; DESSPPL is Desmognathus larvae not identified to species. The deposit has no codebook; the column-to-taxon reading follows the paper's species list and should be checked against it. period is the study year (calendar years not deposited); obs_day_of_year is the deposited JulianDate. obs_precip and obs_conductivity are as deposited (units not stated; the authors standardise precipitation in code). Conductivity is missing for three surveyed visits. period_cover_objects is the number of cover objects searched in the reach that year.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/price_2018_mtr_salamanders_count.R")

stage_dict_row(TABLE,
  description = "Repeated counts of five stream salamander species (adults and larvae separated for two of them) in 23 headwater reaches of south-eastern Kentucky, half in catchments altered by mountaintop-removal coal mining, over three years (4, 3 and 3 visits), with cover objects searched, precipitation, conductivity and day of year.",
  url = "https://doi.org/10.5061/dryad.7278k2n",
  reference = "Price, S. J., Freytag, S. B., Bonner, S. J., Drayer, A. N., Muncy, B. L., Hutton, J. M., & Barton, C. D. (2018). Mountaintop removal mining alters stream salamander population dynamics. Diversity and Distributions, 24(9), 1242-1251.",
  doi_paper = "10.1111/ddi.12760", doi_data = "10.5061/dryad.7278k2n",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Taxa are species x life-stage items as deposited (no codebook; read from the paper). Calendar years not deposited. No coordinates.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "N-mixture with dynamic occupancy (community, hierarchical)",
  sampling_protocol = "cover_object_search", design = "Multi-season (3 years, 3-4 visits)", realm = "Freshwater",
  country = "USA", coordinates = "None in source", notes = "2,491 animals counted; treatment = mountaintop-removal mining.")
