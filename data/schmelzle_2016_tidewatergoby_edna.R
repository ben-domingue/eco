#!/usr/bin/env Rscript
# Table:  schmelzle_2016_tidewatergoby_edna
# Source: Dryad doi:10.5061/dryad.6rs23 (CC0 1.0, as shown on the dataset page and in the API
#         record), version 5828 (published 2015-12-11).
#   Schmelzle, M. C. & Kinziger, A. P. (2015). Data from: Using occupancy modeling to compare
#   environmental DNA to traditional field methods for regional-scale monitoring of an
#   endangered aquatic species. Dryad.
# Paper:  Schmelzle, M. C. & Kinziger, A. P. (2016). Using occupancy modelling to compare
#         environmental DNA to traditional field methods for regional-scale monitoring of an
#         endangered aquatic species. Molecular Ecology Resources 16(4), 895-908.
#         doi:10.1111/1755-0998.12501. What the paper supplies (page numbers of the journal PDF):
#         p. 3 Methods "Study area and sampling": every site visited once between August and
#         December 2014 (per-site dates are in Table S2, not deposited); 2-23 sub-sampling
#         locations per site, about 100 m apart; one 2 L water sample per location, taken
#         before a 7-10 m seine haul; p. 5 "eDNA methods": six replicate qPCRs per water sample;
#         p. 6 "Hierarchical occupancy analysis: water only": 39 sites, N = 358 sub-sampling
#         locations (site / water sample / qPCR replicate); p. 6-7 Results: "Target DNA was not
#         detected in any of the negative controls to include trip blanks, site blanks, filter
#         blanks, extraction blanks and qPCR blanks", and "All qPCR amplifications were
#         considered positive" (the authors' call: any amplification); p. 7 naive eDNA
#         occupancy 19 of 39 sites. p. 2 the goby was listed as endangered under the US ESA in 1994.
# Data:   Sub_sampling_data_eDNA_TWG_occupancy.xlsx ("raw field and lab data"): 359 rows, one per
#         sub-sampling location, 41 site labels: Site (place name), Sub-sampling replicate (1..n;
#         Ocean Ranch and Salt River carry labels such as "6 North (13)"), Latitude / Longitude
#         (WGS84, 4-6 decimals), Vegetation, Substrate (free text), TWG CPUE (goby per seine haul,
#         free text such as "51 A / 4 L", "No Seine" 3 times), Other Fishes CPUE (free text of
#         other species), Average Salinity (ppt), Average Temp. C, Average DO (mg/L) ("NA" once),
#         Filter time (sec) ("Dropped Sample" once; 0.0388889 once at Hunter Creek, an Excel
#         time 0:56, set NA), qPCR 1 and qPCR 2 (three-character strings of well calls, "011" =
#         wells 1-3 of the run; "NA" for the dropped sample), DNA Copy Number / ul.
#         Hierarchical Occupancy Model Input Data.xls (sheet edna_p6: the authors' WinBUGS input,
#         39 sites x 23 padded rows x pcr1-pcr6; eDNA_pcov6: site covariates, standardised),
#         Multi-method occupancy analysis input data PRESENCE 7.5.xlsx (site x replicate eDNA /
#         seine detection histories and standardised covariates for the 29 paired sites),
#         GLM_Data.xls (the 144-sample concentration GLM input), Hierarchical Occupancy Model R
#         Code.docx (analysis code).
#         The 41 raw labels are the paper's 39 sites: "Gannon Pond" (1 sample) and "Davis Pond" (3)
#         are part of Gannon Slough and Davis Lake in edna_p6 (asserted from the sample counts).
#         The raw calls and edna_p6 disagree in some wells (count asserted below); the raw sheet
#         is believed because it is the deposited lab record and reproduces the paper's counts
#         (358 samples, 19 of 39 sites positive), which edna_p6 does not (20 sites positive).
# Mapping (standard E9 experimental multi-scale / eDNA, as martel_2020_tidewatergoby_edna):
#         cluster_id = site (sequential S01..S39 in deposit order; names withheld, E7.4), unit =
#         water sample ("<site>_<nn>", nn = row order within site), occasion 1-6 = qPCR replicate
#         (1-3 = wells of qPCR run 1, 4-6 = wells of run 2; obs_qpcr_run), y = the well's call
#         0/1 as deposited (the authors' rule: any amplification is a detection). No period: one
#         visit per site in August-December 2014 (temporalCoverage). surveyEvidence =
#         deposited_matrix: the dropped Noyo River sample ("Dropped Sample", qPCR "NA") has no rows.
#         unit_ covariates: unit_vegetation, unit_substrate (text as deposited), unit_salinity_ppt,
#         unit_temp_c, unit_do_mgl, unit_filter_time_s (turbidity proxy), unit_dna_copies_per_ul
#         (standard-curve quantity of the sample's positive wells), unit_subsite (2 = the pond
#         sample(s) of Gannon Slough / Davis Lake, 1 otherwise), unit_sample_label (the deposit's
#         replicate label), coordinates coarsened.
#         Coordinates: the tidewater goby is listed as endangered under the US ESA, as the source
#         states (p. 2), so locations are coarsened to 0.1 degree with coarsen_coords() and site
#         names are not shipped (E7.4). The cell is that of the site's median sample position,
#         given to every sample of the site, because 11 deposited sample positions are keying
#         errors (asserted: 11 more than 0.04 degree from the site median; the rest within 0.04).
# Not shipped: the seine hauls. The paper pairs a seine haul with 254 of the water samples at 29
#         sites, but the deposit does not say which samples were seined: the raw sheet records
#         "0" CPUE at the 10 water-only sites as well, marks only 3 samples "No Seine", and gives
#         265 samples with a CPUE at the 29 paired sites; the PRESENCE input has 256 seine hauls
#         and drops samples at four sites (Ten Mile River, Navarro River, Virgin Creek, Gannon
#         Slough) without saying which. The seine detections therefore have no survey set at the
#         sample level (held; question for the batch log). Also not shipped: TWG CPUE and Other
#         Fishes CPUE (the seine catch), site names, the PRESENCE / WinBUGS / GLM inputs
#         (standardised copies and model inputs), model output.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "schmelzle_2016_tidewatergoby_edna"
dir <- download_dryad("10.5061/dryad.6rs23", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))

d <- as.data.table(read_excel(file.path(dir, "Sub_sampling_data_eDNA_TWG_occupancy.xlsx"), col_types = "text"))
stopifnot(identical(names(d), c("Site", "Sub-sampling replicate", "Latitude", "Longitude", "Vegetation", "Substrate",
                                "TWG CPUE", "Other Fishes CPUE", "Average Salinity (ppt)", "Average Temp. C",
                                "Average DO (mg/L)", "Filter time (sec)", "qPCR 1", "qPCR 2", "DNA Copy Number / µl")))
setnames(d, c("site", "rep", "lat", "lon", "veg", "substrate", "twg_cpue", "other_cpue", "sal", "temp", "do",
              "ft", "q1", "q2", "copies"))
stopifnot(nrow(d) == 359L, uniqueN(d$site) == 41L, !anyDuplicated(d[, .(site, rep)]),
          sum(d$twg_cpue == "No Seine") == 3L)
# the one dropped sample: no qPCR, no filter time
drop <- d[q1 == "NA" | q2 == "NA"]
stopifnot(nrow(drop) == 1L, drop$site == "Noyo River", drop$q1 == "NA", drop$q2 == "NA", drop$ft == "Dropped Sample")
d <- d[!(q1 == "NA" | q2 == "NA")]
stopifnot(all(grepl("^[01]{3}$", d$q1)), all(grepl("^[01]{3}$", d$q2)))

# the paper's 39 sites: the two pond labels belong to Gannon Slough and Davis Lake (edna_p6)
d[, site39 := fcase(site == "Gannon Pond", "Gannon Slough", site == "Davis Pond", "Davis Lake", default = site)]
d[, unit_subsite := as.integer(site %in% c("Gannon Pond", "Davis Pond")) + 1L]
e <- as.data.table(read_excel(file.path(dir, "Hierarchical Occupancy Model Input Data.xls"), sheet = "edna_p6", col_types = "text"))
stopifnot(identical(names(e), c("site", "Sample", paste0("pcr", 1:6))), nrow(e) == 39L * 23L)
for (v in paste0("pcr", 1:6)) e[get(v) == "NA", (v) := NA_character_]
e <- e[!(is.na(pcr1) & is.na(pcr4))]
e[, site := fcase(site == "Hwy 101 ditch", "101 Ditch", site == "Jughandle Creek", "Jug Handle Creek", default = site)]
n_raw <- d[, .N, keyby = site39]; n_hie <- e[, .N, keyby = site]
stopifnot(uniqueN(d$site39) == 39L, identical(n_raw$site39, n_hie$site), identical(n_raw$N, n_hie$N), nrow(d) == 358L)
# well-level disagreement between the raw sheet and the model input (raw believed, see header)
d[, calls := paste0(q1, q2)]
e[, calls := paste0(fcoalesce(pcr1, "-"), fcoalesce(pcr2, "-"), fcoalesce(pcr3, "-"), fcoalesce(pcr4, "-"), fcoalesce(pcr5, "-"), fcoalesce(pcr6, "-"))]
d[, pond_first := -unit_subsite]; setorder(d, site39, pond_first); d[, k := seq_len(.N), by = site39]   # pond samples come first in edna_p6
e[, k := seq_len(.N), by = site]
cmp <- merge(d[, .(site39, k, calls)], e[, .(site39 = site, k, hcalls = calls)], by = c("site39", "k"))
ndiff <- sum(mapply(function(a, b) sum(strsplit(a, "")[[1]] != strsplit(b, "")[[1]]), cmp$calls, cmp$hcalls))
stopifnot(nrow(cmp) == 358L, sum(cmp$calls != cmp$hcalls) == 27L, ndiff == 45L, sum(grepl("-", cmp$hcalls)) == 2L)
# the paper's counts (p. 6-7): 358 samples at 39 sites, eDNA at 19 of 39 sites
d[, pos := grepl("1", calls)]
stopifnot(d[, any(pos), by = site39][, sum(V1)] == 19L)

# covariates
DO_NA <- 119L   # DO recorded as "NA" at 119 samples
num <- function(x) suppressWarnings(as.numeric(x))
stopifnot(sum(d$do == "NA") == DO_NA, all(!is.na(num(d$do[d$do != "NA"]))), sum(d$veg == "NA") == 18L, sum(d$substrate == "NA") == 1L, !anyNA(num(d$sal)), !anyNA(num(d$temp)),
          sum(num(d$ft) < 1) == 1L, d[num(d$ft) < 1, site == "Hunter Creek" & abs(num(ft) - 56 / 1440) < 1e-9],
          !anyNA(num(d$ft)), !anyNA(num(d$copies)), all(num(d$copies) >= 0),
          d[num(copies) > 0, all(pos)])
d[, ft_s := num(ft)][ft_s < 1, ft_s := NA_real_]
d[, `:=`(la = num(lat), lo = num(lon))]
# The sample coordinates carry keying errors (a latitude of 71.25, positive longitudes, -1123.8,
# a longitude that repeats the latitude, first samples of Eel River / Klopp Lake / Mad River
# Slough / Big River placed at another site): 11 samples lie more than 0.04 degree from their
# site's median position (by deposit label), against a within-site spread under 0.04 degree for the rest. Rather than
# guess corrections, every sample gets the 0.1-degree cell of its site's median position (the
# table is coarsened to 0.1 degree anyway for the endangered goby, E7).
stopifnot(!anyNA(d$la), !anyNA(d$lo))
d[, `:=`(mla = median(la), mlo = median(lo)), by = site]   # by deposit label: the ponds keep their own position
d[, dev := pmax(abs(la - mla), abs(lo - mlo))]
stopifnot(sum(d$dev > 0.04) == 11L, all(d$dev[d$dev <= 0.04] < 0.0399),
          all(d$mla %between% c(38.9, 42.4)), all(d$mlo %between% c(-124.5, -123.6)))
cc <- coarsen_coords(d$mla, d$mlo)
d[, `:=`(clat = cc$lat, clon = cc$lon, cunc = cc$uncertainty_m)]

# sequential site ids in deposit order (north to south), unit = site id + sample number
ord <- unique(d[order(match(site39, unique(read_excel(file.path(dir, "Sub_sampling_data_eDNA_TWG_occupancy.xlsx"))$Site)))]$site39)
d[, cluster_id := sprintf("S%02d", match(site39, ord))]
d[, unit := sprintf("%s_%02d", cluster_id, k)]

long <- rbindlist(lapply(1:6, function(j) d[, .(
  unit, taxon = "EUCNEW", occasion = j,
  y = as.integer(substr(if (j <= 3) q1 else q2, (j - 1) %% 3 + 1, (j - 1) %% 3 + 1)),
  cluster_id, obs_qpcr_run = if (j <= 3) 1L else 2L,
  unit_sample_label = rep, unit_subsite,
  unit_vegetation = ifelse(veg == "NA", NA_character_, veg), unit_substrate = ifelse(substrate == "NA", NA_character_, substrate),
  unit_salinity_ppt = num(sal), unit_temp_c = num(temp), unit_do_mgl = num(do), unit_filter_time_s = ft_s,
  unit_dna_copies_per_ul = num(copies),
  unit_decimalLatitude = clat, unit_decimalLongitude = clon, unit_coordinateUncertaintyInMeters = cunc)]))
long <- order_eco(long)
stopifnot(nrow(long) == 358L * 6L, uniqueN(long$unit) == 358L, uniqueN(long$cluster_id) == 39L,
          !anyDuplicated(long[, .(unit, occasion)]), sum(long$y) == 734L,
          long[, any(y == 1), by = cluster_id][, sum(V1)] == 19L, long[, any(y == 1), by = unit][, sum(V1)] == 162L)
cat(sprintf("  %d rows, %d water samples at %d sites; %d of %d qPCR wells positive; %d samples and %d sites positive\n",
            nrow(long), uniqueN(long$unit), uniqueN(long$cluster_id), sum(long$y), nrow(long),
            long[, any(y == 1), by = unit][, sum(V1)], long[, any(y == 1), by = cluster_id][, sum(V1)]))

taxa <- make_taxa("EUCNEW", "Eucyclogobius newberryi", vernacularName = "Tidewater goby")
iucn <- iucn_category(taxa$taxonID, taxa$scientificName)
message("  IUCN category of Eucyclogobius newberryi: ", iucn)
coarse_note <- sprintf("Coordinates (4-6 decimals per sample in the deposit) given as the 0.1-degree cell (coarsen_coords()) of each site's median sample position, for every sample of the site, because 11 deposited sample positions look like keying errors (more than 0.04 degree from their site's median): the tidewater goby is listed as endangered under the US Endangered Species Act, as the source states (IUCN category via GBIF: %s). Site names withheld (E7.4); cluster_id is a sequential site id S01..S39 in the deposit's order.", iucn)

dataset <- list(
  title = "Tidewater goby eDNA: six qPCR replicates of 358 water samples at 39 northern California and southern Oregon coastal sites, 2014",
  creator = "Schmelzle, Molly C.; Kinziger, Andrew P.", pubDate = "2015", doi = "10.5061/dryad.6rs23",
  sourceURL = "https://doi.org/10.5061/dryad.6rs23", paperDOI = "10.1111/1755-0998.12501",
  citation = "Schmelzle, M. C., & Kinziger, A. P. (2015). Data from: Using occupancy modeling to compare environmental DNA to traditional field methods for regional-scale monitoring of an endangered aquatic species [Dataset]. Dryad. https://doi.org/10.5061/dryad.6rs23",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Sloughs, estuaries and lagoons along 400 km of the northern California and southern Oregon coast, each visited once between August and December 2014. At 2 to 23 sub-sampling locations per site, about 100 m apart, a 2 L water sample was filtered and assayed for the endangered tidewater goby in six qPCR replicates (two runs of three wells). cluster_id = site, unit = water sample, occasion = qPCR replicate; eDNA detected the goby at 19 of the 39 sites. Seine hauls paired with the water samples at 29 sites are not in this table (the deposit does not record which samples were seined).",
  samplingProtocol = "Environmental DNA: one 2 L water sample per sub-sampling location (2-23 per site, about 100 m apart, within 1-2 h of low tide), filtered on a 3 um polycarbonate filter, extracted, and assayed with a species-specific TaqMan qPCR assay (cytochrome b) in six replicates; any amplification is a detection.",
  samplingProtocolCode = "eDNA", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "one visit per site; occasion = qPCR replicate of one water sample; water samples nest in sites (cluster_id)",
  occasionKind = "spatial", taxonInclusion = "single",
  designNote = "Experimental list of E9 (multi-scale / eDNA): cluster_id = site (occupancy), unit = water sample (availability), occasion = qPCR replicate (detection), as the paper's hierarchical model.",
  geographicCoverage = "Coastal sloughs, estuaries and lagoons from Curry County, Oregon, to Mendocino County, California, USA (about 38.9-42.4 N); coordinates coarsened to 0.1 degree",
  temporalCoverage = "2014-08/2014-12",
  coordinatesCoarsened = list(value = TRUE, method = coarse_note), crs = "EPSG:4326",
  notShipped = list(
    seine = "the seine hauls paired with 254 water samples at 29 sites (paper): the deposit does not record which samples were seined (CPUE 0 is also given at the 10 water-only sites; 265 raw samples with a CPUE at the 29 paired sites against 256 hauls in the PRESENCE input and 254 in the paper), so the seine has no sample-level survey set",
    `TWG CPUE and Other Fishes CPUE` = "the seine catch per haul (free text), withheld with the seine",
    site_names = "place names (E7.4: coordinates are coarsened for the endangered goby)",
    model_inputs = "the PRESENCE multi-method input, the WinBUGS input (edna_p6, eDNA_pcov6) and the GLM input: standardised copies of the shipped values and analysis inputs",
    noyo_dropped_sample = "one Noyo River sample recorded as 'Dropped Sample' with no qPCR (no rows)",
    model_output = "occupancy, availability and detection estimates"),
  notes = "The raw lab sheet and the authors' WinBUGS input disagree in 27 samples (45 wells, 6 of them wells the WinBUGS input leaves empty in two samples); the raw sheet is shipped because it reproduces the paper's counts (19 of 39 sites positive). The paper reports no amplification in any field, filter, extraction or qPCR blank (blanks are not deposited per sample). Coordinates are the 0.1-degree cell of the site's median sample position, the same for every sample of a site: the deposited sample coordinates carry keying errors at about 11 samples (more than 0.04 degree from the site median: a latitude of 71.25, positive longitudes, a longitude of -1123.8, first samples placed at another site), and the other samples of a site spread up to 0.04 degree, so a sample may lie in a neighbouring cell. unit_filter_time_s is NA for one Hunter Creek sample entered as an Excel time (0:56). unit_vegetation is NA where the deposit has NA (18 samples), unit_do_mgl where it has NA (119). unit_subsite = 2 marks the pond samples (one at Gannon Slough, three at Davis Lake) that the deposit labels as separate sites and the paper merges.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/schmelzle_2016_tidewatergoby_edna.R")
stage_dict_row(TABLE,
  description = "Endangered tidewater goby (Eucyclogobius newberryi) eDNA: six qPCR replicates of 358 water samples at 39 coastal sites in northern California and southern Oregon, August-December 2014 (multi-scale, cluster_id = site); coordinates coarsened, site names withheld.",
  url = "https://doi.org/10.5061/dryad.6rs23",
  reference = "Schmelzle, M. C., & Kinziger, A. P. (2016). Using occupancy modelling to compare environmental DNA to traditional field methods for regional-scale monitoring of an endangered aquatic species. Molecular Ecology Resources, 16(4), 895-908.",
  doi_paper = "10.1111/1755-0998.12501", doi_data = "10.5061/dryad.6rs23",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Multi-scale eDNA (site / water sample / qPCR well); paired seine hauls not shipped (no sample-level seine survey set in the deposit); coordinates coarsened (endangered).",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Multi-scale occupancy (eDNA)",
  sampling_protocol = "eDNA", design = "Single-season (one visit per site, samples within sites, 6 qPCR replicates)",
  realm = "Freshwater", country = "USA", coordinates = "Coarsened (0.1 deg)",
  notes = "Endangered estuarine goby; seine pairing not shipped.")
