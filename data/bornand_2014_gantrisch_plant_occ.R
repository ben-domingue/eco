#!/usr/bin/env Rscript
# Table:  bornand_2014_gantrisch_plant_occ
# Source: Dryad doi:10.5061/dryad.v2c17, version 15317 (published 2015-01-13), CC0 1.0 (asserted from the
#         Dryad metadata). Bornand, C. N., Kéry, M., Bueche, L. & Fischer, M. Data from: Hide and seek in
#         vegetation: time-to-detection is an efficient design for estimating detectability and occurrence.
#         Raw files read from batch 35's cache (no Dryad request in batch 47).
# Paper:  Bornand, C. N., Kéry, M., Bueche, L. & Fischer, M. (2014). Hide and seek in vegetation:
#         time-to-detection is an efficient design for estimating detectability and occurrence. Methods in
#         Ecology and Evolution 5, 433-442. doi:10.1111/2041-210X.12171 (PDF supplied by Ben, not committed).
#         Study area: Gurnigel-Gantrisch region, Swiss Alps (46°44'20"N, 7°26'45"E), 1450-1510 m, wet meadows,
#         fens and bogs grazed by cattle; 44 randomly placed 10 m x 10 m quadrats; 17 plant species chosen for
#         differing conspicuousness (Table 1, names after Lauber & Wagner 2007); fieldwork 16-31 August 2011.
#         Two observers (CNB and LB; which is A is not stated) each searched every quadrat independently for
#         all 17 species at once for at most 8 minutes, pausing a stopwatch at each first detection; species
#         visible at a glance before entering were given 1 s.
# Data:   SuppInfo_TimeToDetectionData.txt: 748 rows = 44 quadrats (plot 1a ... 11d) x 17 species, Adetected,
#         Bdetected (0/1), Atime, Btime (seconds to first detection, 480 where not detected).
#         SuppInfo_DetectionNondetectionData.txt: plot, species, Adetected, Bdetected: the same detections
#         (asserted equal, so it ships once). Species are given by one word: the genus, or for the two Carex
#         species the epithet (Echinata, Nigra); Table 1 of the paper names all 17 (asserted: the observed
#         counts oA, oB and otot per species in Table 1 equal the deposit's).
# Mapping (double-observer occupancy with time to detection, ruling 2026-11-06): unit = quadrat, taxon =
#   species (taxonInclusion target, 17 study species), occasion = observer (1 = A, 2 = B; occasionKind
#   observer, closure closed: the two searches of a quadrat were made in the same visit window), observer =
#   "A" / "B", y = detected within 8 min, obs_ttd_s = seconds to first detection or 480 where not detected,
#   obs_ttd_censored = 1 where not detected. surveyEvidence = deposited_matrix: every quadrat x species x
#   observer is present (the full 44 x 17 x 2). No per-quadrat coordinates deposited.
# Not shipped: the extra search after 15-30 min of abundance assessment (oextra in Table 1; not deposited),
#   subquadrat frequency and cover (not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "bornand_2014_gantrisch_plant_occ"
dir <- download_dryad("10.5061/dryad.v2c17", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), attr(dir, "version") == "15317")
t <- fread(file.path(dir, "SuppInfo_TimeToDetectionData.txt"))
dn <- fread(file.path(dir, "SuppInfo_DetectionNondetectionData.txt"))
stopifnot(nrow(t) == 748L, identical(names(t), c("plot", "species", "Adetected", "Bdetected", "Atime", "Btime")),
          uniqueN(t$plot) == 44L, uniqueN(t$species) == 17L, !anyDuplicated(t[, .(plot, species)]),
          all(t[, .N, by = species]$N == 44L), all(c(t$Adetected, t$Bdetected) %in% 0:1),
          all(t[Adetected == 0, Atime] == 480), all(t[Bdetected == 0, Btime] == 480),
          all(t[Adetected == 1, Atime] >= 1 & t[Adetected == 1, Atime] < 480),
          all(t[Bdetected == 1, Btime] >= 1 & t[Bdetected == 1, Btime] < 480))
m <- merge(t, dn, by = c("plot", "species"), suffixes = c("", ".dn"))
stopifnot(nrow(m) == 748L, nrow(dn) == 748L, identical(m$Adetected, m$Adetected.dn), identical(m$Bdetected, m$Bdetected.dn))
# Table 1 of the paper: code, name, oA, oB, otot
tab1 <- fread(text = "word,code,name,oA,oB,otot
Ajuga,AJUREP,Ajuga reptans,8,16,18
Blysmus,BLYCOM,Blysmus compressus,18,19,19
Echinata,CARECH,Carex echinata,44,44,44
Nigra,CARNIG,Carex nigra,37,43,44
Dactylorhiza,DACMAJ,Dactylorhiza majalis,42,43,43
Leontodon,LEOHIS,Leontodon hispidus,36,36,38
Linum,LINCAT,Linum catharticum,27,29,29
Lotus,LOTCOR,Lotus corniculatus,26,27,30
Lysimachia,LYSNEM,Lysimachia nemorum,17,18,19
Myosotis,MYONEM,Myosotis nemorosa,21,24,26
Parnassia,PARPAL,Parnassia palustris,36,39,39
Pinguicula,PINVUL,Pinguicula vulgaris,26,37,38
Prunella,PRUVUL,Prunella vulgaris,44,44,44
Selaginella,SELSEL,Selaginella selaginoides,28,30,32
Swertia,SWEPER,Swertia perennis,32,34,34
Tofieldia,TOFCAL,Tofieldia calyculata,31,31,32
Trifolium,TRIPRA,Trifolium pratense,43,43,43")
obs <- t[, .(oA = sum(Adetected), oB = sum(Bdetected), otot = sum(pmax(Adetected, Bdetected))), by = .(word = species)]
chk <- merge(tab1, obs, by = "word", suffixes = c("", ".d"))
stopifnot(nrow(chk) == 17L, all(chk$oA == chk$oA.d), all(chk$oB == chk$oB.d), all(chk$otot == chk$otot.d))
t[, taxon := tab1$code[match(species, tab1$word)]]
long <- rbind(t[, .(unit = plot, taxon, y = Adetected, occasion = 1L, observer = "A", obs_ttd_s = Atime, obs_ttd_censored = 1L - Adetected)],
              t[, .(unit = plot, taxon, y = Bdetected, occasion = 2L, observer = "B", obs_ttd_s = Btime, obs_ttd_censored = 1L - Bdetected)])
long[, y := as.integer(y)]
long <- order_eco(long)
stopifnot(nrow(long) == 44L * 17L * 2L, sum(long$y) == sum(t$Adetected) + sum(t$Bdetected))
taxa <- make_taxa(tab1$code, tab1$name)
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
print(taxa[, .(taxon, scientificName, gbifMatchType, taxon_iucnCategory)])
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
dataset <- list(
  title = "Double-observer time-to-detection surveys of 17 grassland plant species in 44 quadrats, Gurnigel-Gantrisch, Swiss Alps, August 2011",
  creator = "Bornand, Christophe N.; Kéry, Marc; Bueche, Lena; Fischer, Markus", pubDate = "2015",
  doi = "10.5061/dryad.v2c17", sourceURL = "https://doi.org/10.5061/dryad.v2c17",
  citation = "Bornand, C. N., Kéry, M., Bueche, L. & Fischer, M. (2015). Data from: Hide and seek in vegetation: time-to-detection is an efficient design for estimating detectability and occurrence [Dataset]. Dryad. https://doi.org/10.5061/dryad.v2c17",
  paperDOI = "10.1111/2041-210X.12171",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Two experienced botanists independently searched 44 randomly placed 10 m x 10 m quadrats in grazed wet meadows and fens of the Gurnigel-Gantrisch region, Swiss Alps, for 17 plant species of differing conspicuousness, each for at most 8 minutes, recording the time to first detection of each species. The authors compared traditional (double-observer) and time-to-detection occupancy models.",
  samplingProtocol = "Each of two observers searched each 10 m x 10 m quadrat independently for all 17 target species at once, for at most 8 minutes, moving freely within it and pausing a stopwatch at each first detection; species visible at a glance before the start were given 1 s. 16-31 August 2011.",
  samplingProtocolCode = "botanical_survey", surveyEvidence = "deposited_matrix", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion = observer: two independent searches of each quadrat within the 16-31 August 2011 field period, during which the authors judged occurrence and phenology stable",
  occasionKind = "observer", taxonInclusion = "target",
  geographicCoverage = "Gurnigel-Gantrisch region, canton of Bern, Swiss Alps (about 46.74 N, 7.45 E), 1450-1510 m; no quadrat coordinates deposited",
  temporalCoverage = "2011-08/2011-08",
  covariateNote = "observer: A or B (the paper's two observers, CNB and LB; which is which is not stated). obs_ttd_s: seconds to first detection, or 480 (the 8-minute search) where the species was not detected. obs_ttd_censored: 1 where not detected (censored at 480 s), else 0.",
  notShipped = list(detection_file = "SuppInfo_DetectionNondetectionData.txt: the same detections as the time-to-detection file (asserted equal)",
                    extra_search = "the extra detections during the later abundance assessment (oextra in the paper's Table 1) are not deposited"),
  notes = "Time to detection (ruling 2026-11-06) with two independent observers as occasions. Species names from the paper's Table 1 (the deposit gives one word per species; its observed counts per observer equal Table 1's, asserted).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/bornand_2014_gantrisch_plant_occ.R")
stage_dict_row(TABLE,
  description = "Detection and time to first detection (seconds, censored at 8 min) of 17 grassland plant species by two independent observers in 44 quadrats in the Swiss Alps, August 2011.",
  url = "https://doi.org/10.5061/dryad.v2c17",
  reference = "Bornand, C. N., Kéry, M., Bueche, L. & Fischer, M. (2014). Hide and seek in vegetation: time-to-detection is an efficient design for estimating detectability and occurrence. Methods in Ecology and Evolution 5, 433-442. https://doi.org/10.1111/2041-210X.12171",
  doi_paper = "10.1111/2041-210X.12171", doi_data = "10.5061/dryad.v2c17", original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Species names from the paper's Table 1 (PDF supplied by Ben); read from batch 35's cache.", source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Plants", model_family = "Community occupancy (double observer, time to detection)",
  sampling_protocol = "botanical_survey", design = "Single-season (two independent observers, time to detection)", realm = "Terrestrial",
  country = "CHE", coordinates = "None in source", notes = "Search experiment: 8-minute searches by two botanists.")
