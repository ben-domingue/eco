#!/usr/bin/env Rscript
# Tables: uherkoch_2019_npra_paloon_ms, uherkoch_2019_npra_ybloon_ms
# Source: USGS ScienceBase doi:10.5066/F7HH6J9C (USGS data release, published 2019-04-22; use
#         constraints "No use constraints ... CC0 1.0 ... public domain"; CC0 1.0)
#   Uher-Koch, B., and Schmutz, J., 2019, Pacific (Gavia pacifica) and Yellow-billed Loon (G.
#   adamsii) mark-resight encounter history data; National Petroleum Reserve-Alaska, 2011-2014:
#   U.S. Geological Survey data release.
# Paper:  Uher-Koch, B.D., Wright, K.G., and Schmutz, J.A., 2019, The influence of chick production on
#   territory retention in Arctic-breeding Pacific and Yellow-billed loons. The Condor 121(1):
#   duy021, doi:10.1093/condor/duy021.
# Data:   pacificLoon_yellowBilledLoon_markResight_ak_2011-2014.csv: 88 colour-banded breeding loons
#         (50 Pacific, 38 yellow-billed) on two study areas (Chipp North 0, Chipp South 1) with the
#         metal band suffix (3 blank), nest id ("11BSB02": year, area, lake; "NS10-..." for six
#         yellow-billed loons), a 4-digit encounter history over 2011-2014 (0 = not yet captured or
#         not resighted, 1 = non-breeder resighted on territory, 2 = unsuccessful breeder, 3 =
#         successful breeder, chicks surviving at least 3 weeks), species flags, sex (0 male, 1
#         female, 0.5 unknown), mass z-score within species x sex, lake area (km2) and whether the
#         lake holds a single territory. The histories were stored as numbers, so those starting
#         with 0 lost their leading zeros (length 3 for the 2012 nests, 2 for the 2013 nests);
#         asserted and left-padded to four digits.
# Mapping: one table per species (ruling #20). unit = loon (band suffix; "nest<id>_<sex>" where the
#   band is blank), period = year (1 = 2011 ... 4 = 2014), y = state (0 not seen, 1 non-breeder,
#   2 unsuccessful breeder, 3 successful breeder; responseType state), y_raw = the history digit.
#   Rows: adults of unknown age caught in the wild, so at risk from the study's first year (E4.4):
#   four rows per loon, y = 0 in years before capture. cluster_id = nest id (pairs share it);
#   unit_ sex, mass z-score (standardised as deposited), lake area, single-territory lake, study
#   area. No coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SRC <- "uherkoch_2019_npra_paloon_ms"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/5cbf8c9de4b09b8c0b700fac?format=json", SRC, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
f <- "pacificLoon_yellowBilledLoon_markResight_ak_2011-2014.csv"
d <- fread(download_cached(fl[[f]], SRC, filename = f), colClasses = "character")
stopifnot(nrow(d) == 88, all(as.integer(d$PALO) + as.integer(d$YBLO) == 1), sum(d$PALO == "1") == 50, sum(d$Band_Number == "") == 3,
          !anyDuplicated(d$Band_Number[d$Band_Number != ""]))
yr <- substr(d$NestID_Number, 1, 2); L <- nchar(d$Encounter_History)
stopifnot(all(L[yr == "11"] == 4), all(L[yr == "12"] == 3), all(L[yr == "13"] == 2), all(L[yr == "NS"] == 3), grepl("^[0-3]+$", d$Encounter_History))
d[, eh := formatC(as.integer(Encounter_History), width = 4, flag = "0")]
stopifnot(all(substr(d$eh, 1, 1)[yr == "12"] == "0"), all(substr(d$eh, 1, 2)[yr == "13"] == "00"), all(d$eh != "0000"))
sexl <- c(`0` = "M", `1` = "F", `0.5` = "U")
stopifnot(all(d$Sex %in% names(sexl)))
d[, unit := ifelse(Band_Number != "", Band_Number, paste0("nest", NestID_Number, "_", sexl[Sex]))]
stopifnot(!anyDuplicated(d$unit))
long_all <- d[, .(period = 1:4, y = as.integer(strsplit(eh, "")[[1]])), by = .(unit, NestID_Number, PALO, Sex, Z_Score_Mass, `Lake Size`, Whole_Lake_Territory, Study_Site)]
long_all <- long_all[, .(unit, y, period, cluster_id = NestID_Number, PALO,
                         unit_sex = sexl[Sex], unit_mass_z = as.numeric(Z_Score_Mass), unit_lake_size_km2 = as.numeric(`Lake Size`),
                         unit_single_territory_lake = as.integer(Whole_Lake_Territory), unit_study_area = ifelse(Study_Site == "1", "Chipp South", "Chipp North"))]
stopifnot(nrow(long_all) == 88 * 4)
cite <- "Uher-Koch, B., and Schmutz, J., 2019, Pacific (Gavia pacifica) and Yellow-billed Loon (G. adamsii) mark-resight encounter history data; National Petroleum Reserve-Alaska, 2011-2014: U.S. Geological Survey data release, https://doi.org/10.5066/F7HH6J9C."
for (sp in c("PALO", "YBLO")) {
  pal <- sp == "PALO"
  TABLE <- if (pal) "uherkoch_2019_npra_paloon_ms" else "uherkoch_2019_npra_ybloon_ms"
  sci <- if (pal) "Gavia pacifica" else "Gavia adamsii"; vern <- if (pal) "Pacific loon" else "Yellow-billed loon"
  long <- long_all[PALO == (if (pal) "1" else "0")][, PALO := NULL][, taxon := sp]
  n <- uniqueN(long$unit); stopifnot(n == (if (pal) 50 else 38))
  taxa <- make_taxa(sp, sci, vernacularName = vern)
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  dataset <- list(
    title = sprintf("%s breeding-state resight histories of %d colour-banded adults, National Petroleum Reserve-Alaska, 2011-2014", vern, n),
    creator = "Uher-Koch, Brian D.; Schmutz, Joel A.", pubDate = "2019", doi = "10.5066/F7HH6J9C", sourceURL = "https://doi.org/10.5066/F7HH6J9C",
    citation = cite, paperDOI = "10.1093/condor/duy021",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release marked CC0 1.0"),
    abstract = sprintf("Annual resighting of colour-banded %s on their breeding territories on the Arctic Coastal Plain of the National Petroleum Reserve-Alaska (Chipp North and Chipp South study areas), 2011-2014, recording whether each marked loon was seen on its territory and, if so, whether it was a non-breeder, an unsuccessful breeder or a successful breeder (chicks surviving three weeks), to estimate territory retention and apparent survival.", tolower(paste0(vern, "s"))),
    samplingProtocol = "Loons were caught on their territories (suspended dive-net), colour-banded and measured; each summer territories were searched from shore with spotting scopes, binoculars or telephoto cameras and banded birds identified, and nesting outcome recorded.",
    samplingProtocolCode = "resighting", surveyEvidence = "deposited_matrix", responseType = "state",
    stateCodes = list(`0` = "not resighted on territory", `1` = "non-breeder resighted on territory", `2` = "unsuccessful breeder resighted on territory", `3` = "successful breeder (chicks survived at least 3 weeks)"),
    unitKind = "individual", closure = "none", occasionKind = "none", taxonInclusion = "single",
    geographicCoverage = list(description = "Chipp River area, Arctic Coastal Plain, National Petroleum Reserve-Alaska, USA",
                              boundingBox = list(west = -155.52063, east = -155.17060, south = 70.36372, north = 70.71263)),
    temporalCoverage = "2011/2014",
    notShipped = list(other_species = sprintf("the %s in the same file ship as the sibling table", if (pal) "yellow-billed loons" else "Pacific loons")),
    notes = "Histories left-padded to four years (the deposited numbers lost leading zeros). Adults of unknown age: rows from 2011 (E4.4), y = 0 before capture.")
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = data.table(period = 1:4, year = 2011:2014), script = "data/uherkoch_2019_npra_loon_ms.R")
  stage_dict_row(TABLE,
    description = sprintf("Breeding-state resight histories (not seen, non-breeder, unsuccessful, successful breeder) of %d colour-banded %s on territories in the National Petroleum Reserve-Alaska, 2011-2014, with sex, mass z-score and lake size.", n, tolower(paste0(vern, "s"))),
    url = "https://doi.org/10.5066/F7HH6J9C",
    reference = "Uher-Koch, B.D., Wright, K.G., and Schmutz, J.A. (2019). The influence of chick production on territory retention in Arctic-breeding Pacific and Yellow-billed loons. The Condor 121(1):duy021.",
    doi_paper = "10.1093/condor/duy021", doi_data = "10.5066/F7HH6J9C", original_license = "CC0 1.0 (USGS data release)", derived_license = "CC0 1.0",
    notes = sprintf("Multi-state CJS; sibling table %s.", if (pal) "uherkoch_2019_npra_ybloon_ms" else "uherkoch_2019_npra_paloon_ms"), source_via = "USGS ScienceBase")
  stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Multi-state CJS", sampling_protocol = "resighting",
    design = "Multi-season (4 years)", realm = "Freshwater", country = "USA", coordinates = "None in source",
    notes = "Territory retention and breeding success of colour-banded loons.")
}
