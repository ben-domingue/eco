#!/usr/bin/env Rscript
# Table:  shyvers_2020_ppr_sagegrouse_rd
# Source: Dryad doi:10.5061/dryad.nk98sf7xc, version 7 (2023-04-14), CC0 1.0 as shown on the
#         Dryad record. "Data from: Genetic mark-recapture analysis of winter faecal pellets
#         allows estimation of population size in sage grouse Centrocercus urophasianus."
#         Shyvers, Walker, Oyler-McCance, Fike & Noon.
# Paper:  Shyvers, J. E., Walker, B. L., Oyler-McCance, S. J., Fike, J. A. & Noon, B. R. (2020).
#         Genetic mark-recapture analysis of winter faecal pellets allows estimation of
#         population size in Sage Grouse Centrocercus urophasianus. Ibis 162:749-765,
#         doi:10.1111/ibi.12768 (the deposit's title). The README says the files as deposited
#         are the inputs of the follow-up, Shyvers et al. (2023) Wildlife Biology,
#         doi:10.1002/wlb3.01085 (Dryad's primary_article), a closed robust-design multi-state
#         (CRDMS, states M/F) analysis of sex ratio; that paper was not read.
#         p. 753, Methods: 1,000 candidate plots in sets of 30, two sets (60 plots) per sampling
#           occasion in a rotating panel; occasions may overlap in time, not in space; the same
#           plots, sets and order in both winters; flock-use sites searched for faecal pellets
#           and shed feathers. p. 754: "Feather samples from captures constituted our first
#           sampling occasion and the remainder of occasions were based on non-invasive
#           sampling"; region (North/South) assigned from the location of first detection.
#         p. 755, Results: "seven occasions in season 1 and eight occasions in season 2";
#           "a low number of detections in the final two occasions in season 2"; surveys
#           stopped on 14 March in both seasons. p. 756: 543 unique individuals, 62 males and
#           173 females in season 1, 154 males and 236 females in season 2, 82 (21 males, 61
#           females) in both seasons.
#         p. 759, Table 3: model-averaged p by occasion: season 1 occasions 1-7 (p 0.10-0.33),
#           season 2 occasions 1-8 with p = 0.000 at occasion 7 and 0.001 at occasion 8.
# Data:   Two MARK .inp files (CRLF), header comments then one line per bird:
#         /*GMR-ID*/ history group(=1) region(0 North, 1 South);
#           Season_1_CRDMS.inp: winter 2012-2013, header "7 Occasions 1st Occasion = Trapping",
#             N=235, histories of 9 characters (0/M/F).
#           Season_2_CRDMS.inp: winter 2013-2014, header "8 Occasions", N=390, 10 characters.
#         Which characters are the occasions: in season 1 characters 8-9 are 0 in every
#         history; in season 2 characters 7, 9 and 10 are 0 in every history and character 8 has
#         one F. Table 3 settles it: the per-character detection counts divided by the
#         paper's abundance estimates reproduce Table 3's p for characters 1-7 (season 1) and
#         1-8 (season 2), including p = 0.000 and 0.001 at season 2's occasions 7 and 8. So the
#         occasions are characters 1-7 and 1-8, and the trailing characters are padding (all 0,
#         asserted). Season 2's occasion 7 was surveyed with no detection (Results p. 755).
#         GMR-IDs are shared across the files: 82 ids in both, with the same sex and region in
#         both (asserted), matching the paper's 82 birds in both seasons.
#
# Mapping (robust design, standard E9; responseType detection, unitKind individual):
#   unit = bird (G + GMR-ID), taxon = CENURO, period = winter season (1 = 2012-13,
#   2 = 2013-14), occasion = sampling occasion within the season (1 = capture feathers from
#   birds trapped before the winter and alive at its start, 2.. = faecal-pellet / shed-feather
#   survey occasions), y = the bird's genotype detected at that occasion, y_raw = the history
#   letter as deposited (M, F, or 0). The M/F letter is the bird's sex, constant per bird
#   (asserted): it ships as unit_sex, and the CRDMS input is y_raw.
#   surveyEvidence = deposited_matrix: every occasion the paper reports (7 + 8) is a survey.
#   At-risk span (E4.4): birds are identified from genetic samples with unknown age, so each
#   of the 543 birds is at risk from the first season: rows in both seasons, zeros included
#   (the paper's per-season closed models use only the birds detected in that season;
#   eco_to_ch(by_period = TRUE) drops the all-zero seasons). No removals are deposited.
#   unit_region = North / South (region of first detection, equal across the two files for
#   the 82 shared birds). obs_sample_source = capture_feather on occasion 1, noninvasive after.
#   Coordinates: none deposited. Centrocercus urophasianus is IUCN VU (GBIF IUCN record), so
#   flagged under E7(b), but there is nothing to coarsen.
#   Not shipped: the group column (1 for every bird); the trailing all-zero characters
#   (padding, see above); the paper's estimates (abundance, p, sex ratio).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "shyvers_2020_ppr_sagegrouse_rd"
dir <- download_dryad("10.5061/dryad.nk98sf7xc", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

read_inp <- function(f, n, nch, k_hdr) {
  L <- sub("\r$", "", readLines(file.path(dir, f), warn = FALSE))
  stopifnot(any(grepl(sprintf("^/\\*\\s+%d\\s+Occasions\\s+1st\\s+Occasion\\s+=\\s+Trapping", k_hdr), L)),
            any(grepl(sprintf("N=%d", n), L, fixed = TRUE)))
  L <- grep("^/\\*[0-9]+\\*/", L, value = TRUE)
  m <- regmatches(L, regexec("^/\\*([0-9]+)\\*/\\s+([0MF]+)\\s+1\\s+([01]);", L))
  stopifnot(length(L) == n, all(lengths(m) == 4))
  d <- data.table(id = as.integer(sapply(m, `[`, 2)), ch = sapply(m, `[`, 3), region = as.integer(sapply(m, `[`, 4)))
  stopifnot(all(nchar(d$ch) == nch), !anyDuplicated(d$id))
  d
}
s1 <- read_inp("Season_1_CRDMS.inp", 235, 9, 7)
s2 <- read_inp("Season_2_CRDMS.inp", 390, 10, 8)
H1 <- do.call(rbind, strsplit(s1$ch, "")); H2 <- do.call(rbind, strsplit(s2$ch, ""))
cnt <- function(H, l) as.integer(colSums(H == l))
stopifnot(identical(cnt(H1, "M"), c(18L, 17L, 18L, 13L, 12L, 26L, 6L, 0L, 0L)),
          identical(cnt(H1, "F"), c(32L, 52L, 26L, 21L, 37L, 57L, 38L, 0L, 0L)),
          identical(cnt(H2, "M"), c(13L, 42L, 16L, 51L, 42L, 40L, 0L, 0L, 0L, 0L)),
          identical(cnt(H2, "F"), c(16L, 75L, 33L, 74L, 54L, 57L, 0L, 1L, 0L, 0L)))
# Table 3 check: detections / the paper's abundance estimates (s1 males 78, females 257; s2 total 745) reproduce p
stopifnot(all(abs(cnt(H1, "M")[1:7] / 78 - c(0.220, 0.228, 0.214, 0.157, 0.162, 0.326, 0.100)) < 0.025),
          all(abs(cnt(H1, "F")[1:7] / 257 - c(0.128, 0.200, 0.107, 0.085, 0.142, 0.225, 0.141)) < 0.01),
          all(abs((cnt(H2, "M") + cnt(H2, "F"))[1:8] / 745 - c(0.039, 0.158, 0.066, 0.168, 0.129, 0.131, 0.000, 0.001)) < 0.005))
H1 <- H1[, 1:7]; H2 <- H2[, 1:8]                       # trailing characters are all-0 padding (asserted above)
sex_of <- function(H) { m <- rowSums(H == "M") > 0; f <- rowSums(H == "F") > 0; stopifnot(!any(m & f), all(m | f)); ifelse(m, "male", "female") }
s1[, sex := sex_of(H1)]; s2[, sex := sex_of(H2)]
stopifnot(identical(as.integer(table(s1$sex)), c(173L, 62L)), identical(as.integer(table(s2$sex)), c(236L, 154L)))
sh <- merge(s1, s2, by = "id")
stopifnot(nrow(sh) == 82, all(sh$sex.x == sh$sex.y), all(sh$region.x == sh$region.y),
          identical(as.integer(table(sh$sex.x)), c(61L, 21L)))
birds <- unique(rbind(s1[, .(id, sex, region)], s2[, .(id, sex, region)]))
stopifnot(nrow(birds) == 543, !anyDuplicated(birds$id))
setorder(birds, id)

# full rectangle: every bird x 15 occasions; letters from its season file, "0" where the bird is absent from that file
R <- matrix("0", 543, 15)
R[match(s1$id, birds$id), 1:7] <- H1
R[match(s2$id, birds$id), 8:15] <- H2
Y <- (R != "0") * 1L
per <- c(rep(1L, 7), rep(2L, 8))
src <- matrix(rep(ifelse(c(1:7, 1:8) == 1L, "capture_feather", "noninvasive"), each = 543), 543)
long <- array_to_eco(Y, taxon = "CENURO", site_ids = sprintf("G%03d", birds$id), period = per,
                     site_covs = list(sex = birds$sex, region = c("North", "South")[birds$region + 1L]),
                     obs_covs = list(sample_source = src), y_raw = R)
long <- order_eco(long)
stopifnot(nrow(long) == 543 * 15, sum(long$y) == sum(R != "0"), sum(long$y) == 887L,
          uniqueN(long$unit) == 543, identical(long[, max(occasion), by = period]$V1, c(7L, 8L)),
          long[period == 2 & occasion == 7, sum(y)] == 0, long[period == 2 & occasion == 8, sum(y)] == 1,
          all(long[y == 1, y_raw] == ifelse(long[y == 1, unit_sex] == "male", "M", "F")),
          long[, .(n = uniqueN(unit[y == 1])), by = period]$n == c(235L, 390L))

periods <- data.table(period = 1:2, season = c("winter 2012-2013", "winter 2013-2014"), n_occasions = c(7L, 8L),
                      note = "occasion 1 = feather samples from birds trapped before the winter (March-May, July-November) and alive at its start; later occasions = rotating panels of 60 survey plots searched for faecal pellets and shed feathers, surveys ending 14 March")
taxa <- make_taxa("CENURO", "Centrocercus urophasianus", vernacularName = "Greater Sage-Grouse")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "VU"))

dataset <- list(
  title = "Robust-design genetic capture histories of 543 Greater Sage-Grouse from winter faecal pellets, Parachute-Piceance-Roan, Colorado, 2012-2014",
  creator = "Shyvers, Jessica E.; Walker, Brett L.; Oyler-McCance, Sara J.; Fike, Jennifer A.; Noon, Barry R.", pubDate = "2023",
  doi = "10.5061/dryad.nk98sf7xc", sourceURL = "https://doi.org/10.5061/dryad.nk98sf7xc",
  citation = "Shyvers, J. E., Walker, B. L., Oyler-McCance, S. J., Fike, J. A., & Noon, B. R. (2023). Data from: Genetic mark-recapture analysis of winter faecal pellets allows estimation of population size in sage grouse Centrocercus urophasianus [Dataset]. Dryad. https://doi.org/10.5061/dryad.nk98sf7xc",
  paperDOI = "10.1111/ibi.12768",
  relatedWorks = list("Shyvers, J. E., Walker, B. L., Oyler-McCance, S. J., Fike, J. A., & Noon, B. R. (2023). Genetic mark-recapture analysis reveals large annual variation in pre-breeding sex ratio of greater sage-grouse. Wildlife Biology. doi:10.1002/wlb3.01085"),
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Non-invasive genetic capture-recapture of Greater Sage-Grouse (Centrocercus urophasianus) in the small, isolated Parachute-Piceance-Roan population of northwest Colorado over two winters: 543 birds identified from microsatellite genotypes of faecal pellets, shed feathers and capture feathers (62 males and 173 females in 2012-13, 154 males and 236 females in 2013-14, 82 in both), across 7 and 8 sampling occasions. Sex is from the sexing locus; region (North/South) is where each bird was first detected. Used for closed-population abundance (Huggins) and robust-design multi-state sex-ratio models.",
  samplingProtocol = "Each winter, rotating panels of 60 spatially balanced random survey plots per sampling occasion were searched on foot or snowshoe along transects ~50 m apart for flock-use sites, where roost piles, faecal pellets and shed feathers were collected and genotyped at seven microsatellite loci and a sexing locus. The first occasion is feather samples from birds trapped before the winter and alive at its start.",
  samplingProtocolCode = "scat_genotyping", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "Every sampling occasion the paper reports (7 in season 1, 8 in season 2) is a survey; the history characters beyond them are all-zero padding, identified by reproducing the paper's Table 3 detection probabilities. Season 2 occasion 7 was surveyed and detected no bird.",
  responseType = "detection", unitKind = "individual",
  closure = "closed",
  closureNote = "occasion = sampling occasion within a winter season (robust design; the authors assume demographic and geographic closure within each winter). Occasions are rotating plot panels that may overlap in time; occasion 1 is the capture-feather sample of birds trapped before the winter and alive at its start. GMR-IDs are valid across both seasons.",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = "Parachute-Piceance-Roan Greater Sage-Grouse population, Garfield and Rio Blanco counties, northwest Colorado, USA (no coordinates deposited)",
  temporalCoverage = "2012/2014",
  notShipped = list(group = "the MARK group column (1 for every bird)",
                    padding = "history characters 8-9 (season 1) and 9-10 (season 2): all 0, beyond the occasions the paper reports",
                    model_estimates = "abundance, detection probability and sex-ratio estimates (model outputs)"),
  notes = "y_raw is the deposited history letter (M, F or 0) and rebuilds the CRDMS input; unit_sex is the same letter per bird. Each bird carries both seasons (E4.4: genetic identification, age unknown); the per-season closed models of the paper use only birds detected in that season, which eco_to_ch(by_period = TRUE) gives. Telemetry mortalities are not deposited, so no removals are marked. IUCN VU (flagged); no coordinates are deposited.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/shyvers_2020_ppr_sagegrouse_rd.R")

stage_dict_row(TABLE,
  description = "Robust-design genetic capture histories of 543 Greater Sage-Grouse from winter faecal pellets and capture feathers, Parachute-Piceance-Roan, Colorado, over two winters (2012-13, 2013-14; 7 and 8 occasions), with sex and region per bird.",
  url = "https://doi.org/10.5061/dryad.nk98sf7xc",
  reference = "Shyvers, J. E., Walker, B. L., Oyler-McCance, S. J., Fike, J. A., & Noon, B. R. (2020). Genetic mark-recapture analysis of winter faecal pellets allows estimation of population size in Sage Grouse Centrocercus urophasianus. Ibis, 162, 749-765.",
  doi_paper = "10.1111/ibi.12768", doi_data = "10.5061/dryad.nk98sf7xc",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "MARK CRDMS .inp files; occasions identified from the paper's Table 3 (trailing all-zero characters are padding). Follow-up paper doi:10.1002/wlb3.01085. Dryad version zip.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Robust design (genetic capture-recapture, sex as state)",
  sampling_protocol = "scat_genotyping", design = "Robust design (2 winters x 7 and 8 sampling occasions)", realm = "Terrestrial", country = "USA",
  coordinates = "None in source", notes = "Faecal-pellet genotypes; occasion 1 is capture feathers; sex and region as unit covariates.", status = "tagged")
