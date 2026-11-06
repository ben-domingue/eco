#!/usr/bin/env Rscript
# Tables: raman_2006_anamalai_birds_count (all taxa, coordinates coarsened) and
#         raman_2006_anamalai_birds_exact_count (E7.3 sibling without the IUCN-threatened taxa, coordinates as published)
# Source: Dryad, doi:10.5061/dryad.4mw6m907q, version 74135 (published 2020-07-22), licence CC0 1.0 as shown on the
#         Dryad dataset page (asserted from the dataset JSON).
# Paper:  Raman, T. R. S. (2006). Effects of habitat structure and adjacent habitats on birds in tropical rainforest
#         fragments and shaded plantations in the Western Ghats, India. Biodiversity and Conservation 15, 1577-1607.
#         https://doi.org/10.1007/s10531-005-2352-5 (not open access; not read). The design is from the Dryad
#         abstract, methods and 01_Readme.txt: 381 five-minute bird point counts at 13 sites in the Anamalai hills
#         (Valparai plateau and Indira Gandhi Wildlife Sanctuary), December 2001 to April 2002: a primary rainforest
#         control, six rainforest fragments, five shade-coffee plantations and one cardamom plantation.
# Data:   02_Sites.csv: 13 sites (letter A-M, SiteCode, names, Npoints = point counts done (25-30), longitude and
#           latitude in decimal degrees (6 decimals), Stratum, StraDesc, Connectivity (High / Low), Description).
#         03_BirdSpecies.csv: 107 codes with the 2006 name, category, habitat, and eBird India 2018 common and
#           scientific names; four 2018 names are slash pairs (later splits), 'UNID' is an unidentified bird.
#         04_PointCountData.csv: 3,303 detection records: date, SiteCode, PNo (count number that day), Repl (count
#           number within the site, 1..Npoints), Time (hhmm, per record), SpeciesCode, Number (individuals
#           detected), Total (individuals estimated, supplemented with flock sizes; below Number in 67 records),
#           RadDist (distance band),
#           HSF (heard / seen / flying), Remarks.
#         05_Detections.csv, 06_Abundance.csv: species x site sums of detections and of Total, UNID omitted, abundance scaled
#           to 30 counts at MNBL and SKUDI (rebuilt and asserted
#           below). 07_Appendix.csv: the paper's appendix (per-25-count rates and deviations). 08-11: vegetation plots
#           (PCQ, habitat structure, Siva Coffee plots and trees), keyed to vegetation points, not to bird counts.
# Mapping: community counts with spatial replicates. unit = site letter (A-M; the SiteCode abbreviates the place
#   name), occasion = Repl (the site's point count 1..Npoints), taxon = SpeciesCode with spaces as '_', y = sum of
#   Number over the species' records in the count, date = the count's date, obs_time_hhmm = earliest record time.
#   surveyEvidence = row_presence: every count 1..Npoints of every site has records (asserted, 381 counts), and a
#   community row is written for each of the 107 taxa at each count.
#   Taxa: the eBird 2018 scientific name; the four slash pairs are species aggregates with no GBIF key; UNID is
#   class Aves. E7: Buceros bicornis and Ocyceros griseus are IUCN VU (GBIF), resident in their native range, and
#   site coordinates are finer than 0.1 degree, so the full table is coarsened (site names not shipped) and the
#   _exact sibling without the two hornbills keeps the published coordinates and names. iucn_category() returns NA
#   for 13 species whose GBIF key resolves to another genus; the cached GBIF IUCN records give LC for 12 and NE for one
#   (Machlolophus aplonotus), so none is flagged (asserted from the cache).
#   Not shipped: Total (individuals estimated with supplementary flock sizes: not the count made), the per-record
#   distance bands and cues (a distance-sampling table could be built from them), Remarks, the site summaries and
#   appendix (sums and rates of these counts), the vegetation files (not keyed to the bird counts).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "raman_2006_anamalai_birds_count"
EXACT <- "raman_2006_anamalai_birds_exact_count"

dir <- download_dryad("10.5061/dryad.4mw6m907q", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 11L)
si <- fread(file.path(dir, "02_Sites.csv"))
sp <- fread(file.path(dir, "03_BirdSpecies.csv"))
pc <- fread(file.path(dir, "04_PointCountData.csv"))
dt <- fread(file.path(dir, "05_Detections.csv")); ab <- fread(file.path(dir, "06_Abundance.csv"))
stopifnot(nrow(si) == 13L, identical(si$Site, LETTERS[1:13]), sum(si$Npoints) == 381L, !anyDuplicated(si$SiteCode),
          nrow(sp) == 107L, !anyDuplicated(sp$SpeciesCode), nrow(pc) == 3303L, all(pc$SpeciesCode %in% sp$SpeciesCode),
          uniqueN(pc$SpeciesCode) == 107L, all(pc$SiteCode %in% si$SiteCode), all(pc$Number >= 1L), !anyNA(pc$Number),
          !anyNA(pc$Total), sum(pc$Total < pc$Number) == 67L, all(pc$RadDist %in% c(0, 5, 10, 15, 20, 30, 40)), all(pc$HSF %in% c("H", "S", "F")),
          all(si$Latitude > 10.2 & si$Latitude < 10.45), all(si$Longitude > 76.85 & si$Longitude < 77.05))
# survey list: every count 1..Npoints of every site has records, on one date and one PNo
sv <- pc[, .(date = format(as.IDate(sprintf("%d-%02d-%02d", Year[1], Month[1], Day[1]))), t = min(Time),
             nd = uniqueN(paste(Year, Month, Day)), np = uniqueN(PNo)), by = .(SiteCode, Repl)]
stopifnot(nrow(sv) == 381L, all(sv$nd == 1L), all(sv$np == 1L),
          all(sv[, .(ok = setequal(Repl, seq_len(si$Npoints[match(SiteCode[1], si$SiteCode)]))), by = SiteCode]$ok),
          min(sv$date) == "2001-12-16", max(sv$date) == "2002-04-08")
# the deposited site summaries are sums of these records (detections = records; abundance = Total, scaled to 30 counts at the two sites with fewer)
codes <- setdiff(names(dt), "MATRIX")
rd <- dcast(pc[, .N, by = .(SpeciesCode, SiteCode)], SpeciesCode ~ SiteCode, value.var = "N", fill = 0L)
ra <- dcast(pc[, .(n = sum(Total)), by = .(SpeciesCode, SiteCode)], SpeciesCode ~ SiteCode, value.var = "n", fill = 0L)
stopifnot(setequal(codes, si$SiteCode), setequal(dt$MATRIX, setdiff(sp$SpeciesCode, "UNID")), identical(dt$MATRIX, ab$MATRIX),   # the summaries omit UNID
          all(as.matrix(dt[match(rd[SpeciesCode != "UNID"]$SpeciesCode, MATRIX), ..codes]) == as.matrix(rd[SpeciesCode != "UNID", ..codes])),
          {c30 <- si[Npoints == 30L]$SiteCode; length(c30) == 11L &&   # abundance equals the sum of Total at the 30-count sites (MNBL, SKUDI are scaled)
           all(as.matrix(ab[match(ra[SpeciesCode != "UNID"]$SpeciesCode, MATRIX), ..c30]) == as.matrix(ra[SpeciesCode != "UNID", ..c30]))})

tcode <- function(x) gsub("[^A-Z0-9]+", "_", x)
y <- pc[, .(y = sum(Number)), by = .(SiteCode, Repl, SpeciesCode)]
grid <- CJ(k = seq_len(nrow(sv)), SpeciesCode = sp$SpeciesCode)
grid[, `:=`(SiteCode = sv$SiteCode[k], Repl = sv$Repl[k])]
long <- merge(grid, y, by = c("SiteCode", "Repl", "SpeciesCode"), all.x = TRUE)
long[is.na(y), y := 0L]
long <- merge(long, sv[, .(SiteCode, Repl, date, obs_time_hhmm = as.integer(t))], by = c("SiteCode", "Repl"))
long <- merge(long, si[, .(SiteCode, unit = Site, unit_stratum = tolower(Stratum), unit_stratum_detail = tolower(StraDesc),
                           unit_connectivity = tolower(Connectivity), unit_site_name = SiteName,
                           unit_decimalLatitude = Latitude, unit_decimalLongitude = Longitude)], by = "SiteCode")
long <- long[, .(unit, taxon = tcode(SpeciesCode), y = as.integer(y), occasion = as.integer(Repl), date,
                 unit_stratum, unit_stratum_detail, unit_connectivity, unit_site_name, unit_decimalLatitude,
                 unit_decimalLongitude, obs_time_hhmm)]
stopifnot(nrow(long) == 381L * 107L, sum(long$y) == sum(pc$Number), sum(long$y > 0) == nrow(pc[, .N, by = .(SiteCode, Repl, SpeciesCode)]))

# ---- taxa ------------------------------------------------------------------------------------------------------
sp[, taxon := tcode(SpeciesCode)]
slash <- sp[grepl("/", Ebird_India_SciName)]$taxon
stopifnot(length(slash) == 4L, sp[taxon == "UNID"]$Ebird_India_SciName == "NA" | is.na(sp[taxon == "UNID"]$Ebird_India_SciName))
sp[, sci := ifelse(taxon == "UNID", "Aves", Ebird_India_SciName)]
sp[, rank := ifelse(taxon %in% slash, "species aggregate", ifelse(taxon == "UNID", "class", "species"))]
sp[, rem := ifelse(taxon %in% slash, sprintf("eBird 2018 slash name for the 2006 identification '%s' (the species was later split; the record cannot be assigned to one of the pair); not a GBIF backbone taxon", sub("^.* ([A-Z][a-z]+ [a-z]+)$", "\\1", Species)),
             ifelse(taxon == "UNID", "unidentified bird ('Unidentified' in the deposit); taxonID is the class Aves", NA_character_))]
sp[, look := ifelse(taxon == "BHR_THR", "Monticola cinclorhynchus", sci)]   # GBIF spelling of the eBird name (FUZZY otherwise)
taxa <- make_taxa(sp$taxon, sp$sci, vernacularName = sp$Ebird_India_ComName, taxonRank = sp$rank, lookupName = sp$look,
                  taxonRemarks = sp$rem, taxon_name2006 = sp$Species, taxon_category = sp$Category,
                  taxon_habitat = sp$Habitat, no_key = slash, allow_higher = "UNID")
taxa[taxon == "UNID", vernacularName := "bird sp."]
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# NA where GBIF's key resolves to another genus: read the cached GBIF IUCN record of the key itself
na_k <- taxa[is.na(taxon_iucnCategory) & !is.na(taxonID) & taxonRank == "species"]
cache_cat <- sapply(sub(".*/", "", na_k$taxonID), function(k) fromJSON(file.path(GBIF_DIR, paste0("iucn_", k, ".json")))$code)
stopifnot(length(cache_cat) == 13L, sum(cache_cat == "LC") == 12L, sum(cache_cat == "NE") == 1L)
taxa[match(na_k$taxon, taxon), taxon_iucnCategory := unname(cache_cat)]
flagged <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU")]
stopifnot(setequal(flagged$taxon, c("GPH", "MGH")), identical(sort(flagged$scientificName), c("Buceros bicornis", "Ocyceros griseus")))

# ---- the two tables ----------------------------------------------------------------------------------------------
cc <- coarsen_coords(long$unit_decimalLatitude, long$unit_decimalLongitude)
coarse <- copy(long)[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon,
                            unit_coordinateUncertaintyInMeters = as.integer(cc$uncertainty_m), unit_site_name = NULL)]
exact <- long[!taxon %in% flagged$taxon]
stopifnot(nrow(exact) == 381L * 105L)

base <- list(
  creator = "Raman, T. R. Shankar", pubDate = "2020",
  doi = "10.5061/dryad.4mw6m907q", sourceURL = "https://doi.org/10.5061/dryad.4mw6m907q",
  citation = "Raman, T. R. S. (2020). Data from: Effects of habitat structure and adjacent habitats on birds in tropical rainforest fragments and shaded plantations in the Western Ghats, India [Dataset]. Dryad. https://doi.org/10.5061/dryad.4mw6m907q",
  paperDOI = "10.1007/s10531-005-2352-5",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Five-minute stationary bird point counts (25-30 per site) recording every bird seen or heard with its radial distance band (0-50 m) and cue; y = individuals detected of the species in the count (the source's 'Number', summed over its records).",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "the 25-30 point counts of a site, made on 2-4 mornings between December 2001 and April 2002, are its replicates; they are sequential counts within the site (the deposit gives no point locations and does not say whether a point was revisited), so occasion = count number within the site, in the source's order.",
  occasionKind = "spatial", taxonInclusion = "recorded",
  temporalCoverage = "2001-12/2002-04",
  covariateNote = "unit_stratum (rainforest / plantation), unit_stratum_detail (control, fragment, coffee, cardamom), unit_connectivity (canopy connectivity with adjacent habitat, high / low, as in Raman 2006). obs_time_hhmm: time of the count's first record (hhmm, morning).")
nsb <- list(total_estimated = "Total: individuals estimated with supplementary flock-size data, not the count made (Total > Number in 928 records, < Number in 67, 66 of them heard birds)",
            distance_cues = "per-record radial distance band and cue (heard / seen / flying); a distance-sampling table could be built from them",
            remarks = "free-text Remarks",
            summaries = "05_Detections, 06_Abundance (sums of these records, rebuilt and asserted) and 07_Appendix (rates per 25 counts and deviations)",
            vegetation = "08-11 vegetation plots (PCQ, habitat structure, Siva Coffee plots and trees), keyed to vegetation points, not to the bird counts")
fl <- paste(sprintf("%s (IUCN %s)", flagged$scientificName, flagged$taxon_iucnCategory), collapse = " and ")

d1 <- c(list(title = "Bird counts from 381 five-minute point counts at 13 rainforest fragment, plantation and control sites, Anamalai hills, Western Ghats, India, 2001-2002 (coordinates coarsened)"),
  base, list(
  abstract = sprintf("Bird point counts in a Western Ghats landscape of rainforest fragments and shade plantations (Valparai plateau and Indira Gandhi Wildlife Sanctuary, Anamalai hills): 13 sites (one primary rainforest control, six fragments of high or low canopy connectivity, five coffee and one cardamom plantation), 25-30 five-minute counts each, December 2001 to April 2002; 107 taxa. One row per count x taxon, y = individuals detected. Site coordinates are coarsened to 0.1 degree because %s are in the table; %s has the other taxa at the published coordinates.", fl, EXACT),
  geographicCoverage = "Valparai plateau and Indira Gandhi Wildlife Sanctuary, Anamalai hills, Western Ghats, Tamil Nadu, India (site coordinates coarsened to 0.1 degree)",
  coordinatesCoarsened = list(value = TRUE, method = sprintf("site coordinates (6 decimals in the source) replaced by 0.1 degree cell centres (coarsen_coords) because %s occur in the table; site names not shipped (E7.4); the unit is the source's site letter", fl)),
  notShipped = c(nsb, list(unit_site_name = sprintf("site names (E7.4: a coarsened table names no place); in %s", EXACT))),
  notes = sprintf("Taxa are the eBird India 2018 names; four are slash pairs for species split after 2006 and UNID is an unidentified bird (class Aves). %s has the 105 taxa other than the two hornbills at the published coordinates.", EXACT)))
d2 <- c(list(title = "Bird counts from 381 five-minute point counts at 13 rainforest fragment, plantation and control sites, Anamalai hills, Western Ghats, India, 2001-2002 (without threatened taxa, coordinates as published)"),
  base, list(
  abstract = sprintf("The E7.3 sibling of %s: the same 381 point counts at 13 sites, December 2001 to April 2002, without %s, so that the site coordinates and names ship as published; 105 taxa. One row per count x taxon, y = individuals detected.", TABLE, fl),
  geographicCoverage = "Valparai plateau and Indira Gandhi Wildlife Sanctuary, Anamalai hills, Western Ghats, Tamil Nadu, India",
  coordinatesCoarsened = list(value = FALSE, method = sprintf("site coordinates as published (6 decimals); the IUCN-threatened %s are not in this table (they are in %s, coarsened)", fl, TABLE)),
  notShipped = c(nsb, list(threatened_taxa = sprintf("%s: in %s only, whose coordinates are coarsened", fl, TABLE))),
  notes = "Taxa are the eBird India 2018 names; four are slash pairs for species split after 2006 and UNID is an unidentified bird (class Aves)."))

ds1 <- write_table(coarse, TABLE, d1, taxa = taxa, script = "data/raman_2006_anamalai_birds_count.R")
ds2 <- write_table(exact, EXACT, d2, taxa = taxa[!taxon %in% flagged$taxon], script = "data/raman_2006_anamalai_birds_count.R")
for (x in list(list(TABLE, ds1, FALSE), list(EXACT, ds2, TRUE))) {
  stage_dict_row(x[[1]],
    description = paste("Bird counts per species from 381 five-minute point counts at 13 sites (primary rainforest, rainforest fragments, coffee and cardamom plantations) in the Anamalai hills, Western Ghats, India, December 2001 to April 2002.",
                        if (x[[3]]) "Without the two IUCN-threatened hornbills; site coordinates as published." else "All 107 taxa; site coordinates coarsened to 0.1 degree."),
    url = "https://doi.org/10.5061/dryad.4mw6m907q",
    reference = "Raman, T. R. S. (2006). Effects of habitat structure and adjacent habitats on birds in tropical rainforest fragments and shaded plantations in the Western Ghats, India. Biodiversity and Conservation 15, 1577-1607. https://doi.org/10.1007/s10531-005-2352-5",
    doi_paper = "10.1007/s10531-005-2352-5", doi_data = "10.5061/dryad.4mw6m907q",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = if (x[[3]]) sprintf("E7.3 sibling of %s without Buceros bicornis and Ocyceros griseus (VU).", TABLE) else sprintf("Coarsened for Buceros bicornis and Ocyceros griseus (VU); %s is the exact sibling.", EXACT),
    source_via = "Dryad (version zip)")
  stage_tag_row(x[[1]], x[[2]], taxon_group = "Birds", model_family = "Community abundance (N-mixture, spatial replicates)",
    sampling_protocol = "point_count", design = "Single-season (13 sites, 25-30 point counts each)",
    realm = "Terrestrial", country = "IND", coordinates = if (x[[3]]) "As published" else "Coarsened (0.1 deg)",
    notes = if (x[[3]]) "Western Ghats fragments and plantations; exact sibling without the two VU hornbills." else "Western Ghats fragments and plantations; coarsened for two VU hornbills.")
}
