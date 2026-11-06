#!/usr/bin/env Rscript
# Tables: belder_2020_nsw_<species>_cjs, one per species (ruling #20): superbfairywren,
#         yrthornbill, yellowthornbill, redbrowedfinch, flamerobin, brthornbill,
#         greyshrikethrush, williewagtail, wbbabbler, rufouswhistler, speckledwarbler,
#         redcappedrobin, diamondfiretail (13 tables).
# Source: Dryad doi:10.5061/dryad.m0cfxpp2b, version 1 (2020-11-19), CC0 1.0 as shown on the
#         Dryad record. "Survival and home ranges of woodland birds in restoration plantings."
#         Belder, Pierson, Rudder & Lindenmayer.
# Paper:  Belder, D. J., Pierson, J. C., Rudder, A. C. & Lindenmayer, D. B. (2021). Ongoing
#         declines of woodland birds: Are restoration plantings making a difference? Ecological
#         Applications 31:e2268, doi:10.1002/eap.2268 (accepted manuscript, page numbers of the
#         PDF as supplied).
#         Methods, "Study sites": 12 restoration plantings, 6 similar-sized remnants, 3 large
#           (>47 ha) remnant reference sites in the South-west Slopes bioregion of NSW.
#         Methods, "Bird banding and recaptures": initial banding July-October 2015, recapture
#           and banding June-August 2016 and 2017; about equal net hours per site, the same net
#           sites in all three years; two consecutive banding days per site per year. "Ten
#           species also received a combination of colored plastic and/or metal leg bands. These
#           were the Superb Fairywren (Malurus cyaneus), Yellow-rumped Thornbill (Acanthiza
#           chrysorrhoa), Buff-rumped Thornbill (A. reguloides), Grey Shrikethrush (Colluricincla
#           harmonica), Rufous Whistler (Pachycephala rufiventris), Red-capped Robin (Petroica
#           goodenovii), Willie Wagtail (Rhipidura leucophrys), White-browed Babbler
#           (Pomatostomus superciliosus), Speckled Warbler (Pyrrholaemus sagittatus), and Diamond
#           Firetail (Stagonopleura guttata)."
#         Methods, "Resightings": incidental sightings of colour-banded birds in 2015, monthly
#           area searches September-November 2016, targeted playback for Rufous Whistlers 2017.
#         Methods, "Statistical analyses": CJS for the assemblage, Barker models (with the
#           resightings) for colour-banded birds; one dead bird recovered.
#         Results, "General": 1,261 birds of 38 species banded; "The most commonly caught species
#           were the Superb Fairywren, Yellow-rumped Thornbill, Yellow Thornbill, Red-browed Finch,
#           and Flame Robin". "Survival and site fidelity": recapture rates 18.3% (2016) and
#           6.8% (2017); 943 banded in the first two years, 386 recaptured or resighted.
# Data:   resight_recap_R5.csv: 1,269 rows, one per bird x site: band_no, species (a code), sex
#         (F/M/U), cb (colour-band combination), cb_class (yes/no colour-banded), site, and the
#         Barker LD history 2015_banding, 2015-2016_resighting, 2016_banding,
#         2016-2017_resighting, 2017_banding, 2017-2018_resighting (live capture 1/0; resighting
#         2 = resighted alive, 1 = found dead), A_ch (the same, pasted), movement (note on 10
#         rows). Ten birds that moved site have a second row at the new site whose only entry is
#         a 2016-2017 resighting; for 2 of them the sex differs between the rows.
#         resight_recap_R5_CJS.csv: the same 1,269 rows with the three banding columns only:
#         rebuilt exactly from resight_recap_R5.csv (asserted), so it is not shipped separately.
#         site_characteristics_v2.csv: 21 sites (type, size class, shape, area, lat/long,
#         fenced, perimeter, width, growth type, planting age). One site code in the capture
#         file, PARS-1 (2 Yellow-rumped Thornbills), is not in it: its covariates are NA.
#         movementdist_SFW.csv, movementdist_WW.csv, territories.csv: home-range tracking of
#         Superb Fairywrens (SFW) and Willie Wagtails (WW): not encounter histories.
#         Species codes: 38 codes (the paper: 38 species), never expanded in the deposit (the paper's Appendix S1 species
#         table is not in the supplied PDF). Thirteen are fixed by the paper and the deposit:
#         the ten codes with colour-banded birds (cb_class = yes) are exactly SFW, YRT, BRT, GST,
#         RUW, RCR, WW, WBB, SW, DF, one per colour-banded species the paper names, with matching
#         initials (SFW and WW also name the tracking files of Superb Fairywren and Willie
#         Wagtail); and the five most-caught codes, in order SFW, YRT, YET, RBF, FR, are the
#         paper's five most commonly caught species, which adds YET (Yellow Thornbill), RBF
#         (Red-browed Finch) and FR (Flame Robin). The other 25 codes (208 birds) are undefined:
#         no table (processing guide: a code the source does not define gets no row).
#         Counts: the deposit has 1,259 birds (paper 1,261), 938 first banded in 2015-2016
#         (paper 943); recapture rates 18.3% (88 of 480) and 6.9% (65 of 938) (paper 18.3%, 6.8%).
#
# Mapping (CJS capture-recapture, standard E9; responseType detection, unitKind individual):
#   unit = bird (band number), taxon = the species code, period = banding year (1 = 2015,
#   2 = 2016, 3 = 2017), no occasion (the two banding days per site are not deposited), y =
#   captured in that year's mist-netting. One row per bird: the movers' second (new-site)
#   rows have no capture and are dropped (asserted 10); a bird's site and sex are those of
#   its banding row. surveyEvidence = deposited_matrix: every site was netted in each of the
#   three years (the paper; asserted: every listed site has captures in every year). At-risk
#   span (E4.4): wild-caught, age not deposited, so at risk from 2015; the one bird found dead
#   (YRT 016-52473, between 2015 and 2016) has its 2015 row only. cluster_id = site;
#   unit_ covariates: sex, colour_banded, and the site attributes. Coordinates: site lat/long as
#   deposited; Diamond Firetail is IUCN VU, so its table's coordinates are coarsened to the 0.1
#   degree cell (E7); the other twelve are LC and keep the published coordinates.
#   Not shipped: the resightings (Barker-model live resightings between banding sessions: the
#   CJS table has no cell for them), the colour-band combination, the 25 undefined codes, the
#   tracking files.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
CACHE <- "belder_2020_nsw_woodbird_cjs"
dir <- download_dryad("10.5061/dryad.m0cfxpp2b", CACHE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
SCRIPT <- "data/belder_2020_nsw_woodbird_cjs.R"

r <- fread(file.path(dir, "resight_recap_R5.csv"), colClasses = "character")
cj <- fread(file.path(dir, "resight_recap_R5_CJS.csv"), colClasses = "character")
sites <- fread(file.path(dir, "site_characteristics_v2.csv"))
stopifnot(nrow(r) == 1269, nrow(cj) == 1269, nrow(sites) == 21, !anyDuplicated(sites$site))
setnames(r, c("2015_banding", "2015-2016_resighting", "2016_banding", "2016-2017_resighting", "2017_banding", "2017-2018_resighting"),
         c("c15", "r15", "c16", "r16", "c17", "r17"))
# the CJS file is the banding columns of R5 (a recode: not shipped separately)
stopifnot(identical(cj$band_no, r$band_no), identical(cj$site, r$site), identical(cj$species, r$species),
          identical(cj[["2015_banding"]], r$c15), identical(cj[["2016_banding"]], r$c16), identical(cj[["2017_banding"]], r$c17),
          identical(cj$A_ch, paste0("A", r$c15, r$c16, r$c17)), identical(r$A_ch, paste0("A", r$c15, r$r15, r$c16, r$r16, r$c17, r$r17)))
stopifnot(all(c(r$c15, r$c16, r$c17) %in% c("0", "1")), identical(sort(unique(r$r15)), c("0", "1", "2")),
          identical(sort(unique(r$r16)), c("0", "2")), all(r$r17 == "0"), sum(r$r15 == "1") == 1,
          all(r$sex %in% c("F", "M", "U")), all(r$cb_class %in% c("yes", "no")))
# movers: second row at the new site, no capture, only a 2016-2017 resighting
r[, mover_row := nzchar(movement)]
stopifnot(sum(r$mover_row) == 10, all(r[mover_row == TRUE, c15 == "0" & c16 == "0" & c17 == "0" & r15 == "0" & r16 == "2"]),
          setequal(r[mover_row == TRUE, band_no], r[duplicated(band_no), band_no]), sum(duplicated(r$band_no)) == 10)
sexdiff <- merge(r[mover_row == FALSE, .(band_no, s1 = sex)], r[mover_row == TRUE, .(band_no, s2 = sex)], by = "band_no")[s1 != s2]
stopifnot(nrow(sexdiff) == 2)
moved_resight <- r[mover_row == TRUE, .(band_no, moved_resight = 1L)]
b <- r[mover_row == FALSE]
stopifnot(nrow(b) == 1259, !anyDuplicated(b$band_no), all(b[, c15 == "1" | c16 == "1" | c17 == "1"]))
b[, first := fifelse(c15 == "1", 1L, fifelse(c16 == "1", 2L, 3L))]
stopifnot(identical(as.integer(table(b$first)), c(480L, 458L, 321L)),
          b[first == 1, sum(c16 == "1")] == 88L, b[first <= 2, sum(c17 == "1")] == 65L,   # 88/480 = 18.3% (paper 18.3%), 65/938 = 6.9% (paper 6.8%)
          b[r15 != "0", all(first == 1L)], b[r16 != "0", all(first <= 2L)])   # no resighting before first banding
# every listed site netted in every year: captures at each site in each year
yr <- b[, .(n15 = sum(c15 == "1"), n16 = sum(c16 == "1"), n17 = sum(c17 == "1")), by = site]
stopifnot(all(yr[site %in% sites$site, n15 > 0 & n16 > 0 & n17 > 0]), setequal(setdiff(b$site, sites$site), "PARS-1"),
          b[site == "PARS-1", .N] == 2)

codes <- data.table(
  code = c("SFW", "YRT", "YET", "RBF", "FR", "BRT", "GST", "WW", "WBB", "RUW", "SW", "RCR", "DF"),
  token = c("superbfairywren", "yrthornbill", "yellowthornbill", "redbrowedfinch", "flamerobin", "brthornbill", "greyshrikethrush",
            "williewagtail", "wbbabbler", "rufouswhistler", "speckledwarbler", "redcappedrobin", "diamondfiretail"),
  sci = c("Malurus cyaneus", "Acanthiza chrysorrhoa", "Acanthiza nana", "Neochmia temporalis", "Petroica phoenicea", "Acanthiza reguloides",
          "Colluricincla harmonica", "Rhipidura leucophrys", "Pomatostomus superciliosus", "Pachycephala rufiventris",
          "Pyrrholaemus sagittatus", "Petroica goodenovii", "Stagonopleura guttata"),
  common = c("Superb Fairywren", "Yellow-rumped Thornbill", "Yellow Thornbill", "Red-browed Finch", "Flame Robin", "Buff-rumped Thornbill",
             "Grey Shrikethrush", "Willie Wagtail", "White-browed Babbler", "Rufous Whistler", "Speckled Warbler", "Red-capped Robin", "Diamond Firetail"),
  n = c(450L, 169L, 80L, 77L, 58L, 50L, 45L, 35L, 34L, 16L, 14L, 12L, 11L),
  colour = c(TRUE, TRUE, FALSE, FALSE, FALSE, rep(TRUE, 8)))
codes[, plural := ifelse(code == "GST", "Grey Shrikethrushes", paste0(common, "s"))]
spn <- b[, .N, by = species]
stopifnot(nrow(spn) == 38, identical(spn[match(codes$code, species), N], codes$n), sum(spn$N) == 1259,
          setequal(b[cb_class == "yes", unique(species)], codes[colour == TRUE, code]),     # the ten colour-banded species
          identical(spn[order(-N)][1:5, species], c("SFW", "YRT", "YET", "RBF", "FR")))     # the paper's five most commonly caught
undefined <- spn[!species %in% codes$code]
stopifnot(nrow(undefined) == 25, sum(undefined$N) == 208)
undef_txt <- paste(sprintf("%s (%d)", undefined[order(-N)]$species, undefined[order(-N)]$N), collapse = ", ")

taxa_all <- make_taxa(codes$code, codes$sci, vernacularName = codes$common)
taxa_all[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa_all$taxon_iucnCategory, c(rep("LC", 12), "VU")))

setnames(sites, c("type", "size", "shape", "size_ha", "lat", "long", "fenced", "perimeter", "width", "growth_type", "year.planted"),
         c("site_type", "site_size_class", "site_shape", "site_area_ha", "lat", "lon", "site_fenced", "site_perimeter_m", "site_width_m",
           "site_growth_type", "site_planting_age_yr"))
periods <- data.table(period = 1:3, year = 2015:2017, banding_months = c("July-October", "June-August", "June-August"),
                      note = "annual mist-netting session: two consecutive banding days per site (days not deposited)")
paper <- "10.1002/eap.2268"
ref <- "Belder, D. J., Pierson, J. C., Rudder, A. C., & Lindenmayer, D. B. (2021). Ongoing declines of woodland birds: Are restoration plantings making a difference? Ecological Applications, 31, e2268."

for (i in seq_len(nrow(codes))) {
  cd <- codes[i]; TABLE <- sprintf("belder_2020_nsw_%s_cjs", cd$token)
  stopifnot(nchar(TABLE) <= 40)
  bb <- b[species == cd$code][order(band_no)]
  CH <- as.matrix(bb[, .(as.integer(c15), as.integer(c16), as.integer(c17))])
  st <- sites[match(bb$site, site)]
  flagged <- taxa_all[taxon == cd$code, taxon_iucnCategory] %in% c("CR", "EN", "VU")
  lat <- st$lat; lon <- st$lon; unc <- rep(NA_real_, nrow(st))
  if (flagged) { cc <- coarsen_coords(lat, lon); lat <- cc$lat; lon <- cc$lon; unc <- cc$uncertainty_m }
  cl <- bb$site
  if (flagged) {                                       # E7.4: a place-naming cluster_id is replaced by a sequential id
    ord <- unique(data.table(site = bb$site, lat, lon, a = st$site_area_ha)[order(lat, lon, a, site)]$site)
    cl <- sprintf("site%02d", match(bb$site, ord))
    stopifnot(!anyNA(cl), uniqueN(cl) == uniqueN(bb$site))
  }
  covs <- list(cluster_id = cl, sex = c(F = "female", M = "male", U = "unknown")[bb$sex],
               colour_banded = as.integer(bb$cb_class == "yes"),
               site_type = st$site_type, site_size_class = st$site_size_class, site_shape = st$site_shape,
               site_area_ha = st$site_area_ha, site_fenced = st$site_fenced, site_perimeter_m = st$site_perimeter_m,
               site_width_m = st$site_width_m, site_growth_type = st$site_growth_type, site_planting_age_yr = st$site_planting_age_yr,
               decimalLatitude = lat, decimalLongitude = lon)
  if (flagged) covs$coordinateUncertaintyInMeters <- unc
  long <- array_to_eco(CH, taxon = cd$code, site_ids = bb$band_no, period = 1:3, site_covs = covs)
  setnames(long, "unit_cluster_id", "cluster_id")
  long[, occasion := NULL]
  dead <- bb[r15 == "1", band_no]                      # found dead between 2015 and 2016: not at risk after 2015
  if (length(dead)) long <- long[!(unit %in% dead & period > 1)]
  long <- order_eco(long)
  stopifnot(uniqueN(long$unit) == cd$n, nrow(long) == 3L * cd$n - 2L * length(dead), sum(long$y) == sum(CH),
            all(long[, uniqueN(cluster_id), by = unit]$V1 == 1), length(dead) == (cd$code == "YRT"))
  n_res <- bb[r15 == "2" | r16 == "2", .N]; n_mres <- sum(bb$band_no %in% moved_resight$band_no)
  taxa <- taxa_all[taxon == cd$code]
  sib <- if (cd$code == "SFW") list(undefined_codes = sprintf("25 species codes the deposit never expands and the paper does not fix (208 birds), so no table: %s", undef_txt)) else list()
  dataset <- list(
    title = sprintf("Mist-net capture histories of %d %s in restoration plantings and woodland remnants, South-west Slopes, New South Wales, 2015-2017", cd$n, cd$plural),
    creator = "Belder, Donna J.; Pierson, Jennifer C.; Rudder, Alexander C.; Lindenmayer, David B.", pubDate = "2020",
    doi = "10.5061/dryad.m0cfxpp2b", sourceURL = "https://doi.org/10.5061/dryad.m0cfxpp2b",
    citation = "Belder, D. J., Pierson, J. C., Rudder, A. C., & Lindenmayer, D. B. (2020). Survival and home ranges of woodland birds in restoration plantings [Dataset]. Dryad. https://doi.org/10.5061/dryad.m0cfxpp2b",
    paperDOI = paper,
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
    abstract = sprintf("Annual mist-net capture histories of %d %s (%s) banded at 21 restoration plantings, woodland remnants and large reference remnants in the South-west Slopes bioregion of New South Wales, Australia, 2015-2017, one of 13 per-species tables from a woodland-bird survival study (CJS and Barker models). Site attributes (planting or remnant, size, shape, fencing, planting age) are unit covariates.", cd$n, cd$plural, cd$sci),
    samplingProtocol = "Mist netting (two 6 m and four 9 m nets at fixed net sites) over two consecutive days per site each year, about four hours before sunset and four hours after dawn; initial banding July-October 2015, recapture and banding June-August 2016 and 2017; birds banded with metal bands, ten species also colour-banded.",
    samplingProtocolCode = "mist_net", surveyEvidence = "deposited_matrix",
    surveyEvidenceNote = "Every site was netted in each of the three years with the same net sites (paper, Methods); every listed site has captures in every year (asserted). y = 0 is a banding year in which the bird was not caught.",
    responseType = "detection", unitKind = "individual",
    closure = "none", closureNote = "one annual banding session per period (two netting days per site, not deposited separately)", occasionKind = "none", taxonInclusion = "single",
    geographicCoverage = "21 woodland sites (12 restoration plantings, 6 remnants, 3 reference remnants) in the South-west Slopes bioregion, New South Wales, Australia (about 35.2-35.9 S, 147.1-147.7 E)",
    temporalCoverage = "2015/2017",
    coordinatesCoarsened = if (flagged) list(value = TRUE, method = "IUCN VU (Diamond Firetail): site coordinates generalised to the 0.1 degree cell centre with coarsen_coords(); unit_coordinateUncertaintyInMeters is the cell half-diagonal; the site names in cluster_id are replaced by sequential ids (site01.., ordered by coarsened position and area), E7.4")
                           else list(value = FALSE, method = "site coordinates as deposited; IUCN LC, not flagged"),
    notShipped = c(list(resightings = sprintf("Barker-model resightings of colour-banded birds between banding sessions (%d birds of this species resighted alive%s%s): ad hoc and area-search sightings with no cell in a CJS table; in resight_recap_R5.csv",
                                         n_res, if (n_mres) sprintf(", %d of them only at a new site after moving, whose all-zero second row is dropped", n_mres) else "",
                                         if (cd$code == "YRT") "; one bird found dead between 2015 and 2016, whose rows end in 2015" else ""),
                        cjs_file = "resight_recap_R5_CJS.csv: the banding columns of resight_recap_R5.csv (rebuilt and asserted identical)",
                        colour_combination = "the colour-band combination (an identifier; colour_banded carries whether a bird had one)",
                        tracking = "movementdist_SFW.csv, movementdist_WW.csv, territories.csv: home-range tracking, not encounter histories",
                        model_estimates = "survival, fidelity and home-range model outputs"), sib),
    notes = paste0("Species code ", cd$code, " is fixed by the paper and deposit, not expanded in the deposit: ",
                   if (cd$colour) "the ten codes with colour-banded birds match one to one the ten colour-banded species the paper names. " else "the five most-caught codes, in order, match the paper's five most commonly caught species. ",
                   "Wild-caught birds of unknown age carry all three years (E4.4); condition on first capture for CJS. cluster_id is the site; a bird's site and sex are those of its banding row (10 birds that moved site have a dropped second row; 2 of them have a different sex on it). ",
                   if (cd$code == "YRT") "Site PARS-1 (2 birds) is not in the site file: its covariates are NA. Bird 016-52473 was found dead between 2015 and 2016 and has its 2015 row only. " else "",
                   "The deposit has 1,259 birds of 38 codes (paper: 1,261 birds of 38 species); 13 codes ship as tables."))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = SCRIPT)
  stage_dict_row(TABLE,
    description = sprintf("Annual mist-net (CJS) capture histories of %d %s (%s) at 21 restoration plantings and woodland remnants, South-west Slopes, NSW, Australia, 2015-2017, with sex and site attributes.", cd$n, cd$plural, cd$sci),
    url = "https://doi.org/10.5061/dryad.m0cfxpp2b", reference = ref, doi_paper = paper, doi_data = "10.5061/dryad.m0cfxpp2b",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = sprintf("One of 13 per-species tables from resight_recap_R5.csv (species code %s fixed from the paper); resightings not shipped. %s Dryad version zip.", cd$code,
                    if (flagged) "IUCN VU: coordinates coarsened to 0.1 deg." else ""),
    source_via = "Dryad")
  stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture",
    sampling_protocol = "mist_net", design = "Multi-session (3 annual banding sessions)", realm = "Terrestrial", country = "AUS",
    coordinates = if (flagged) "Coarsened (0.1 deg)" else "As published (site centroids)",
    notes = sprintf("%s; one of 13 per-species tables from one woodland-bird banding study.", cd$common), status = "tagged")
}
