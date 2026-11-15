#!/usr/bin/env Rscript
# Table:  johnson_2023_tweedsmuir_bombus_count
# WITHDRAWN 2026-11-06 (care_review, #150). Removed from the current release pending
#   consultation with the originators; may be reinstated. Kept so it can be rebuilt; its
#   tag status is do_not_publish, so the uploader refuses it. Why, and how to reinstate:
#   notes/decisions/care_e7_screen_held.md and releases/withdrawals.csv.
# Source: Dryad doi:10.5061/dryad.wdbrv15sr (CC0 1.0 as shown on the dataset JSON), version
#   215373 (version 2, published 2023-01-13). Jackson, H. M. Data for: Positive impact of
#   postfire environment on bumble bees not explained by habitat variables in a remote forested
#   ecosystem. The authors' R code is Zenodo doi:10.5281/zenodo.7532919 (MIT); its
#   4.Make_final_data.R was read to confirm the detection array (not run, not shipped).
# Paper:  Johnson, S. A., Jackson, H. M., Noth, H., & M'Gonigle, L. K. (2023). Positive impact of
#   postfire environment on bumble bees not explained by habitat variables in a remote forested
#   ecosystem. Ecology and Evolution 13: e9743, doi:10.1002/ece3.9743 (CC BY 4.0).
# Data:   TrapInfo.csv: 156 rows, one per blue vane trap per site visit: 26 sites (FireYear x
#           Plot: 2009, 2010 and 2017 fires with 4 burned S* and 4 unburned F* plots each, the
#           2018 fire with one of each) x 2 rounds x 3 traps (asserted). Site and trap
#           latitude / longitude, day of year the trap was set (TrapJulian, 2019), HoursOut and
#           a Bear flag (4 traps disturbed by a bear, HoursOut NA).
#         TrapBumbles.csv: 258 rows, one per trap x species x caste with Abundance; 60 rows
#           with Species NA and Abundance 0 are traps that caught nothing. 153 of the 156 traps
#           have a row; the other three (2017 F1 round 1 BV1, 2017 S1 round 1 BV2 and BV3, the
#           latter two bear-disturbed) have none (asserted).
#         NetBumbles.csv: 69 rows of spot-netting captures (species, caste, plant), burned sites
#           only, 60 person-minutes per visit when weather allowed (Dryad methods); no netting
#           effort file, so visits with no catch are not recorded.
#         Vegetation.csv: flower counts per plant species along four 100 m transects per site
#           visit. CanopyCover.csv: canopy openness (%) per hemispherical photo per site (11-12
#           per site; one further photo of a plot 2018 S2 with no traps is dropped).
#         README.md: column definitions.
# Mapping (community counts, responseType count, unitKind site):
#   unit = site ("2009_S1": fire year and plot), taxon = Bombus species code (10 species
#   caught in vane traps), no period (one season, June to August 2019), occasion = round 1 or
#   2 (4-6 weeks apart). y = bumble bees of the species summed over the site's vane traps in
#   that round, castes summed (the authors use y > 0 as detection in the same site x visit x
#   species array). Survey evidence: sample_table. TrapInfo lists every trap set at every
#   site visit (all 52 site-rounds have three traps) and TrapBumbles records empty traps
#   explicitly, so a species absent from a site-round's trap rows is a zero.
#   date = the day the round's traps were set (TrapJulian, day of year 2019; asserted constant
#   within a site-round). obs_trap_hours = summed HoursOut of the traps with a known duration;
#   obs_n_traps_disturbed = bear-disturbed traps. obs_flower_count and obs_flower_richness =
#   open flowers and flowering plant species on the four transects that round (the paper's
#   floral abundance and richness, from the field counts; the authors' latin-name fixes
#   applied). unit_burned = 1 for the burned sites; unit_fire_year; unit_canopy_openness_pct =
#   mean over the site's photos.
#   Coordinates: SiteLat / SiteLon as deposited (5 decimals). No species in the table is IUCN
#   CR, EN or VU (checked through GBIF); B. terricola (VU) occurs only in the netting data,
#   which is not shipped.
#   Not shipped: netting (burned sites only, no effort record; the authors' model uses traps
#   only), castes (summed), trap-level counts and trap coordinates (traps were pooled per
#   site visit by the authors, and three traps have no catch row), the netting plant records.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "johnson_2023_tweedsmuir_bombus_count"
dir <- download_dryad("10.5061/dryad.wdbrv15sr", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), attr(dir, "version") == "215373")
stopifnot(setequal(list.files(dir), c("CanopyCover.csv", "NetBumbles.csv", "README.md", "TrapBumbles.csv", "TrapInfo.csv", "Vegetation.csv")))
rd <- function(f) { x <- fread(file.path(dir, f), encoding = "UTF-8"); setnames(x, sub("^﻿", "", names(x))); x }
ti <- rd("TrapInfo.csv"); tb <- rd("TrapBumbles.csv"); nb <- rd("NetBumbles.csv"); veg <- rd("Vegetation.csv"); gla <- rd("CanopyCover.csv")

# ---- traps: the sample table ----
stopifnot(nrow(ti) == 156, names(ti)[1] == "FireYear")
ti[, unit := paste(FireYear, Plot, sep = "_")]
stopifnot(uniqueN(ti$unit) == 26, ti[, .N, by = .(unit, Round)][, all(N == 3)], setequal(ti$Round, 1:2),
          sum(ti$Bear) == 4, setequal(which(is.na(ti$HoursOut)), which(ti$Bear == 1)),
          all(ti[, uniqueN(TrapJulian), by = .(unit, Round)]$V1 == 1),
          all(ti[, .(n = uniqueN(paste(SiteLat, SiteLon, SiteType))), by = unit]$n == 1),
          all(substr(ti$Plot, 1, 1) == ifelse(ti$SiteType == "Fire", "S", "F")),
          sum(ti$SiteType == "Fire") == 78, min(ti$TrapJulian) >= 165, max(ti$TrapJulian) <= 225)
ti[, key := paste(unit, Round, Trap)]

stopifnot(nrow(tb) == 258, names(tb)[1] == "FireYear")
tb[, unit := paste(FireYear, Plot, sep = "_")]; tb[, key := paste(unit, Round, Trap)]
stopifnot(all(tb$key %in% ti$key), sum(!ti$key %in% tb$key) == 3,
          setequal(ti[!key %in% tb$key, key], c("2017_F1 1 BV1", "2017_S1 1 BV2", "2017_S1 1 BV3")),
          tb[is.na(Species), all(Abundance == 0 & is.na(Caste))], sum(is.na(tb$Species)) == 60,
          tb[!is.na(Species), all(Abundance >= 1 & Caste %in% c("queen", "worker", "male"))],
          !anyDuplicated(tb[, .(key, Species, Caste)]))
spp <- sort(unique(na.omit(tb$Species)))
stopifnot(identical(spp, c("bifarius", "flavidus", "flavifrons", "insularis", "jonellus", "kirbiellus",
                           "melanopygus", "mixtus", "rufocinctus", "sitkensis")))
stopifnot(identical(sort(unique(na.omit(nb$Species))), c("bifarius", "flavidus", "flavifrons", "insularis", "melanopygus", "mixtus", "rufocinctus", "terricola")),
          all(grepl("^S", nb$Plot)))
counts <- tb[!is.na(Species), .(y = sum(Abundance)), by = .(unit, occasion = Round, Species)]
stopifnot(sum(counts$y) == sum(tb$Abundance), sum(tb$Abundance) == 290)

# ---- survey covariates ----
sv <- ti[, .(date = format(as.IDate("2019-01-01") + floor(TrapJulian[1]) - 1L),
             obs_trap_hours = round(sum(HoursOut, na.rm = TRUE), 2), obs_n_traps_disturbed = sum(Bear)),
         by = .(unit, occasion = Round)]
stopifnot(nrow(sv) == 52)
fix <- c("Hieracium sp." = "Hieracium triste", "Pyrola uniflora" = "Moneses uniflora",
         "Parnassia fimbrata" = "Parnassia fimbriata", "Pterospora andromeda" = "Pterospora andromedea")  # the authors' 2.Cleaning.R
veg[, PlantLatinName := trimws(PlantLatinName)]
veg[PlantLatinName %in% names(fix), PlantLatinName := fix[PlantLatinName]]
veg[, unit := paste(FireYear, Plot, sep = "_")]
stopifnot(nrow(veg) == 913, all(veg$unit %in% ti$unit), !anyNA(veg$FlowerCount), all(veg$FlowerCount >= 0))
fl <- veg[, .(obs_flower_count = sum(FlowerCount), obs_flower_richness = uniqueN(PlantLatinName[!is.na(PlantLatinName) & PlantLatinName != ""])),
          by = .(unit, occasion = Round)]
stopifnot(nrow(fl) == 52)
sv <- merge(sv, fl, by = c("unit", "occasion"), all.x = TRUE)

gla <- na.omit(gla); gla[, unit := paste(FireYear, Plot, sep = "_")]
stopifnot(setequal(setdiff(gla$unit, ti$unit), "2018_S2"), sum(gla$unit == "2018_S2") == 1, all(ti$unit %in% gla$unit),
          all(gla$CanopyOpenness >= 0 & gla$CanopyOpenness <= 100))
gla <- gla[unit %in% ti$unit]   # one photo of a 2018 plot S2 that has no traps
units <- unique(ti[, .(unit, unit_fire_year = FireYear, unit_burned = as.integer(SiteType == "Fire"),
                       unit_decimalLatitude = SiteLat, unit_decimalLongitude = SiteLon)])
units <- merge(units, gla[, .(unit_canopy_openness_pct = round(mean(CanopyOpenness), 2)), by = unit], by = "unit")
stopifnot(nrow(units) == 26, sum(units$unit_burned) == 13,
          all(units$unit_decimalLatitude > 52 & units$unit_decimalLatitude < 54 & units$unit_decimalLongitude > -127 & units$unit_decimalLongitude < -125))

# ---- taxa ----
sp <- data.table(epithet = spp, binomial = paste("Bombus", spp))
sp[, taxon := toupper(paste0("BOM", substr(epithet, 1, 6)))]
stopifnot(!anyDuplicated(sp$taxon))
taxa <- make_taxa(sp$taxon, sp$binomial)
stopifnot(!anyNA(taxa$taxonID), all(taxa$gbifMatchType == "EXACT"))
iucn <- function(id) {
  key <- sub(".*/", "", id); fp <- file.path(GBIF_DIR, paste0("iucn_", key, ".json"))
  if (!file.exists(fp)) {
    txt <- paste(readLines(sprintf("https://api.gbif.org/v1/species/%s/iucnRedListCategory", key), warn = FALSE), collapse = "")
    writeLines(if (nzchar(txt)) txt else '{"code": "NE"}', fp)   # HTTP 204 = no assessment in GBIF
  }
  r <- fromJSON(fp); if (is.list(r) && length(r) && !is.null(r$code)) r$code else "NE"
}
taxa[, taxon_iucnCategory := sapply(taxonID, iucn)]
print(taxa[, .(taxon, scientificName, gbifAcceptedName, taxon_iucnCategory)])
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))

# ---- long ----
grid <- CJ(unit = units$unit, occasion = 1:2, taxon = sp$taxon)
counts[, taxon := sp$taxon[match(Species, sp$epithet)]]
long <- merge(grid, counts[, .(unit, occasion, taxon, y)], by = c("unit", "occasion", "taxon"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- merge(long, sv, by = c("unit", "occasion"))
stopifnot(nrow(long) == 26 * 2 * 10, sum(long$y) == 290)
long <- merge(long, units[, .(unit, unit_burned)], by = "unit")
long <- order_eco(long)

dataset <- list(
  title = "Blue vane trap counts of 10 bumble bee species at 26 burned and unburned forest sites, Tweedsmuir Provincial Park, British Columbia, 2019 (two visits)",
  creator = "Jackson, Hanna M.; Johnson, Sarah A.; Noth, Hutton; M'Gonigle, Leithen K.", pubDate = "2023-01-13",
  doi = "10.5061/dryad.wdbrv15sr", sourceURL = "https://doi.org/10.5061/dryad.wdbrv15sr",
  citation = "Jackson, H. M. (2023). Data for: Positive impact of postfire environment on bumble bees not explained by habitat variables in a remote forested ecosystem [Dataset]. Dryad. https://doi.org/10.5061/dryad.wdbrv15sr",
  paperDOI = "10.1002/ece3.9743",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Bumble bees caught in three blue vane traps per site (2-4 days out) on two visits 4-6 weeks apart in June to August 2019 at 13 burned and 13 adjacent unburned forest sites (100 m diameter) around four wildfires (2009, 2010, 2017, 2018) in and near Tweedsmuir Provincial Park, on the territories of the Nuxalk and Ulkatcho First Nations. The paper fits a multi-species occupancy model with burn status, floral resources and canopy openness.",
  samplingProtocol = "Three blue vane traps per site per visit, collected after 2-4 days; bees identified to species and caste (Williams et al. 2014). Open flowers counted by plant species along two perpendicular 100 m x 3 m transects (four arms) each visit; canopy openness from hemispherical photographs (Gap Light Analyzer). Supplementary spot netting at burned sites only (not shipped).",
  samplingProtocolCode = "vane_trap", occasionLength = "one site visit (three vane traps for 2-4 days)",
  surveyEvidence = "sample_table",
  surveyEvidenceNote = "TrapInfo.csv lists the three traps set at each of the 26 sites on both rounds (52 site visits), and TrapBumbles.csv records traps that caught nothing (Species NA, Abundance 0); every catch belongs to a listed trap. A species with no trap row at a site visit is a zero. Three traps (two bear-disturbed) have no catch row and are counted in the visit as empty, as the authors do.",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "within season: the two visits are treated as replicates of the season's occupancy (the paper's model); colony phenology changes over the 4-6 weeks between them", occasionKind = "time", taxonInclusion = "recorded",
  geographicCoverage = list(description = "Tweedsmuir Provincial Park and surroundings, British Columbia, Canada",
                            boundingBox = list(west = min(units$unit_decimalLongitude), east = max(units$unit_decimalLongitude),
                                               south = min(units$unit_decimalLatitude), north = max(units$unit_decimalLatitude))),
  temporalCoverage = sprintf("%s/%s", min(long$date), max(long$date)),
  coordinatesCoarsened = list(value = FALSE, method = "As published: site centre coordinates as deposited; no trapped species is IUCN CR, EN or VU (checked through GBIF)"),
  notShipped = list(netting = "NetBumbles.csv: spot netting at the 13 burned sites only, with no effort record (visits without a catch are not listed); the authors' occupancy model uses the traps only. It holds the only B. terricola (IUCN VU) records",
                    castes = "queen, worker and male counts summed into y",
                    `trap level` = "per-trap counts and trap coordinates: the authors pool traps per site visit; obs_trap_hours and obs_n_traps_disturbed keep the effort",
                    `plant records` = "the plant species each netted bee was taken from"),
  notes = "y > 0 reproduces the authors' detection array (26 sites x 2 visits x 10 species). Bear disturbance: 2009_S4 and 2010_F4 round 2 and 2017_S1 round 1 (two traps). date is the day the traps were set.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, units = units, script = "data/johnson_2023_tweedsmuir_bombus_count.R")

stage_dict_row(TABLE,
  description = "Counts of 10 bumble bee species in three blue vane traps per site on two visits in 2019 at 13 burned and 13 unburned forest sites around four wildfires, Tweedsmuir Provincial Park, British Columbia, with trap hours, bear disturbance, floral abundance and richness per visit and canopy openness per site.",
  url = "https://doi.org/10.5061/dryad.wdbrv15sr",
  reference = "Johnson, S. A., Jackson, H. M., Noth, H., & M'Gonigle, L. K. (2023). Positive impact of postfire environment on bumble bees not explained by habitat variables in a remote forested ecosystem. Ecology and Evolution, 13, e9743.",
  doi_paper = "10.1002/ece3.9743", doi_data = "10.5061/dryad.wdbrv15sr",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Traps only (netting was done at burned sites only and has no effort record). Zeros from the trap table (empty traps recorded). Castes summed.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Community occupancy (multi-species, burn status; counts reduce to detection)",
  sampling_protocol = "vane_trap", design = "Single-season (2 visits, 3 vane traps each)",
  realm = "Terrestrial", country = "CAN", coordinates = "As published",
  notes = "Bumble bees, burned vs unburned forest; one season.", status = "tagged; do_not_publish: care_review (#150), withdrawn 2026-11-06")
