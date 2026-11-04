#!/usr/bin/env Rscript
# Table:  tomke_2025_hellbender_edna
# Source: Dryad doi:10.5061/dryad.9w0vt4bs2, version 436959 (published 2025-09-09), licence CC0 1.0
#         (as shown on Dryad). Tomke, S. & Price, S. "Large-scale eDNA sampling and hierarchical
#         modeling elucidates the importance of stream habitat for Eastern Hellbender
#         (Cryptobranchus a. alleganiensis) occupancy and eDNA detection".
# Paper:  Tomke, S. & Price, S. (2025). Freshwater Biology. doi:10.1111/fwb.70079 (the Dryad
#         record's primary article); analysis code Zenodo doi:10.5281/zenodo.14933337.
# Data:   Eastern Hellbender (giant salamander) eDNA survey of 90 stream sites on 73 rivers across
#         Kentucky, September 2019 - June 2021 (Dryad methods). 89 sites were sampled in the autumn
#         breeding season (site ROU only in the hatching season); 45 of them were also sampled in the
#         hatching and pre-breeding seasons; at a subset of site-seasons three spatial water samples were taken; every
#         filter was run in 9 qPCR replicates.
#         eDNAocc_fulldata__90sites.csv: one row per site x temporal sample (site abbreviation,
#         sample 1 = breeding, 2 = hatching, 3 = pre-breeding) with 27 columns pcr<spatial>.<qPCR>
#         (1 detection, 0 none, NA not run): 270 rows, of which 89 are entirely NA (season not
#         sampled at that site, including ROU's breeding season), 79 have spatial replicate 1 only, 101 have three spatial
#         replicates x 9 qPCRs and 1 has 9 + 9 + 6 qPCRs. eDNAocc_fulldata_80sites.csv and
#         eDNAocc_45sites.csv are row subsets of the 90-site file (asserted identical) used for
#         the authors' habitat and water-chemistry models: not shipped separately.
#         covariates_sample_90sites.csv: water chemistry per site x sample (conductivity, TOC,
#         turbidity, pH, temperature, flow) plus volume filtered and Strahler stream order (both
#         constant within site). covariates_site_landscape_90sites.csv: Level III ecoregion and
#         upstream-catchment land cover proportions, watershed area. covariates_site_no_nas.csv
#         and covariates_sample_80sites.csv: the stream habitat assessment for 80 sites.
#         Model outputs (posterior psi/theta/p per site or sample, *_SiteInfo_Psi, *_SampleInfo_*,
#         par_estimate_*) and qPCR standard curves (LOD_LOQ_*) are not shipped.
#
# Mapping (standard E9 experimental multi-scale occupancy / eDNA, as smith_2019_greatbasin_csf_edna
# _qpcr; responseType detection, unitKind site):
#   cluster_id = site (the occupancy scale, psi), unit = water sample "<site>_<season>_<spatial
#   replicate>" (the availability scale, theta: the authors' level-2 replicates are the temporal
#   and spatial samples together), occasion = qPCR replicate 1..9 (p), y = qPCR detection.
#   taxon = CRYALL. Survey evidence: the deposited matrix (a row exists for every qPCR cell that is
#   not NA). No period: the authors fit a single-season model and treat the three seasons as
#   replicate samples of one occupancy state; the season is unit_season, and the year of each
#   sample is not deposited (September 2019 to June 2021).
#   Covariates: unit_season, unit_spatial_rep; water chemistry of the site x season visit
#   (unit_conductivity_us, unit_toc_mg_l, unit_turbidity_ntu, unit_ph, unit_water_temp_c,
#   unit_flow_m_s); site-level covariates repeated on every sample of the site with the
#   unit_site_ prefix (ecoregion, catchment land cover proportions, watershed area, Strahler
#   order, volume filtered, and the habitat assessment for the 80 sites that have one; NA for
#   the other 10).
#   Coordinates: none in the deposit (site abbreviations only).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "tomke_2025_hellbender_edna"
dir <- download_dryad("10.5061/dryad.9w0vt4bs2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
rd <- function(f) fread(file.path(dir, f))

x <- rd("eDNAocc_fulldata__90sites.csv")
pc <- grep("^pcr", names(x), value = TRUE)
stopifnot(nrow(x) == 270L, uniqueN(x$site) == 90L, all(x[, .N, by = sample]$N == 90L), length(pc) == 27L,
          identical(pc, as.vector(outer(1:9, 1:3, function(q, s) sprintf("pcr%d.%d", s, q)))),
          all(as.matrix(x[, ..pc]) %in% c(0L, 1L, NA)),
          x[, sum(!is.na(as.matrix(.SD))), .SDcols = pc] == 3462L, x[, sum(as.matrix(.SD), na.rm = TRUE), .SDcols = pc] == 171L)
# the 80- and 45-site files are row subsets of the 90-site file
for (f in c("eDNAocc_fulldata_80sites.csv", "eDNAocc_45sites.csv")) {
  s <- rd(f); m <- merge(x, s, by = c("site", "sample"))
  stopifnot(nrow(m) == nrow(s), all(sapply(pc, function(c) identical(m[[paste0(c, ".x")]], m[[paste0(c, ".y")]]))))
}
long <- melt(x, id.vars = c("site", "sample"), measure.vars = pc, variable.name = "col", value.name = "y", na.rm = TRUE)
long[, `:=`(rep = as.integer(sub("pcr(\\d)\\.(\\d)", "\\1", col)), qpcr = as.integer(sub("pcr(\\d)\\.(\\d)", "\\2", col)))]
# sampled site-seasons: breeding at 89 sites (not ROU, sampled in the hatching season only), the two
# other seasons at 46
stopifnot(long[sample == 1L, uniqueN(site)] == 89L, long[sample == 2L, uniqueN(site)] == 46L, long[sample == 3L, uniqueN(site)] == 46L,
          identical(setdiff(x$site, long[sample == 1L, site]), "ROU"), identical(unique(long[site == "ROU", sample]), 2L),
          # qPCR replicates are contiguous from 1 within each filter
          all(long[, max(qpcr) == .N, by = .(site, sample, rep)]$V1))

cs <- rd("covariates_sample_90sites.csv")
stopifnot(nrow(cs) == 270L, all(cs[, uniqueN(volume), by = site]$V1 == 1L), all(cs[, uniqueN(stream_order), by = site]$V1 == 1L))
cl <- rd("covariates_site_landscape_90sites.csv"); stopifnot(nrow(cl) == 90L, setequal(cl$site, x$site))
ch <- rd("covariates_site_no_nas.csv"); stopifnot(nrow(ch) == 80L, all(ch$site %in% x$site))
stopifnot(all(cs[, .(site, sample)][long[, .(site, sample)], on = .(site, sample), nomatch = 0L][, .N] > 0),
          cs[unique(long[, .(site, sample)]), on = .(site, sample)][, !anyNA(conductivity)])

long <- merge(long, cs[, .(site, sample, unit_conductivity_us = conductivity, unit_toc_mg_l = toc, unit_turbidity_ntu = turb,
                           unit_ph = ph, unit_water_temp_c = temp, unit_flow_m_s = flow)], by = c("site", "sample"))
site_cov <- merge(cl[, .(site, unit_site_ecoregion = ecoregion, unit_site_prop_water = prop_water, unit_site_prop_devel = prop_devel,
                         unit_site_prop_forest = prop_forest, unit_site_prop_herb = prop_herb, unit_site_prop_agric = prop_agric,
                         unit_site_watershed_area = watershed_area, unit_site_stream_order = stream_order, unit_site_volume_l = volume)],
                  setnames(copy(ch), setdiff(names(ch), "site"), paste0("unit_site_", setdiff(names(ch), "site"))), by = "site", all.x = TRUE)
long <- merge(long, site_cov, by = "site")
seasons <- c("breeding (autumn)", "hatching", "pre-breeding")
long <- long[, c(list(unit = sprintf("%s_%d_%d", site, sample, rep), taxon = "CRYALL", y = as.integer(y), occasion = qpcr,
                      cluster_id = site, unit_season = seasons[sample], unit_spatial_rep = rep),
                 .SD), .SDcols = patterns("^unit_(conductivity|toc|turbidity|ph|water|flow|site_)")]
long <- order_eco(long)
stopifnot(nrow(long) == 3462L, sum(long$y) == 171L, uniqueN(long$unit) == 385L, uniqueN(long$cluster_id) == 90L,
          !anyDuplicated(long[, .(unit, occasion)]))
cat(sprintf("  %d qPCR rows, %d filters (units), %d sites, %d positive qPCRs at %d sites\n",
            nrow(long), uniqueN(long$unit), uniqueN(long$cluster_id), sum(long$y), long[y == 1L, uniqueN(cluster_id)]))

taxa <- make_taxa("CRYALL", "Cryptobranchus alleganiensis", vernacularName = "Eastern hellbender")

dataset <- list(
  title = "Eastern hellbender eDNA multi-scale detections: 90 Kentucky stream sites, seasonal and spatial water samples, 9 qPCR replicates each, 2019-2021",
  creator = "Tomke, Sarah (University of Pennsylvania); Price, Steven (University of Kentucky)", pubDate = "2025",
  doi = "10.5061/dryad.9w0vt4bs2", sourceURL = "https://doi.org/10.5061/dryad.9w0vt4bs2",
  citation = "Tomke, S. & Price, S. (2025). Large-scale eDNA sampling and hierarchical modeling elucidates the importance of stream habitat for Eastern Hellbender (Cryptobranchus a. alleganiensis) occupancy and eDNA detection [Dataset]. Dryad. https://doi.org/10.5061/dryad.9w0vt4bs2",
  paperDOI = "10.1111/fwb.70079", relatedWorks = c("10.5281/zenodo.14933337"),
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "qPCR-level eDNA detections of the Eastern hellbender at 90 stream sites on 73 Kentucky rivers: 89 sites sampled in the autumn breeding season, 46 sites in the hatching and pre-breeding seasons (one site, ROU, in the hatching season only); one or three spatial water samples per visit; 9 qPCR replicates per filter. 3,462 qPCR results from 385 filters, 171 positive. Three-level structure for multi-scale occupancy: cluster_id = site, unit = filter, occasion = qPCR replicate. Water chemistry per visit and catchment land cover, ecoregion and (80 sites) stream habitat per site.",
  samplingProtocol = "At each site a water sample was collected directly downstream of the highest-quality hellbender habitat within 500 m of the historic record or access point; filters processed within 10 hours and frozen; DNA extracted with Qiagen DNeasy kits; 9 qPCR replicates per extract against a hellbender assay with limits of detection and quantification from standard curves (Dryad methods; Tomke & Price 2025).",
  samplingProtocolCode = "eDNA", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The deposited detection file has one cell per site x season x spatial sample x qPCR replicate; NA cells (season not sampled at the site, single spatial sample, the 3 missing qPCRs of one filter) are not surveys and have no row.",
  responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "site occupancy closed across the study (the authors' single-season multi-scale model treats the three seasonal and the spatial samples as level-2 replicates); occasion = qPCR replicate of one filter", occasionKind = "spatial", taxonInclusion = "single",
  designNote = "Experimental list of E9 (multi-scale / eDNA): cluster_id = site is the occupancy scale (psi), unit = filter (site x season x spatial sample) the availability scale (theta), occasion = qPCR replicate (p). The season is unit_season; the calendar year of each sample is not deposited.",
  geographicCoverage = "Streams and rivers across Kentucky, USA (Interior Plateau, Western Allegheny Plateau, Central Appalachians and other Level III ecoregions); no coordinates deposited",
  temporalCoverage = "2019-09/2021-06",
  coordinatesCoarsened = NA,
  notes = "The 80-site and 45-site detection files in the deposit are row subsets of the 90-site file (asserted identical) and are not shipped separately; filter by cluster_id to reproduce the authors' habitat (80 sites with habitat covariates) and water-chemistry (45 sites with three seasons) models. Site-level covariates carry the unit_site_ prefix and repeat on every filter of a site. Model outputs (posterior psi, theta and p per site and sample, parameter summaries) are not shipped.",
  notShipped = list(`model outputs` = "Habitat/Landscape/Waterchem_SiteInfo_Psi, _SampleInfo_p, _SampleInfo_Theta, par_estimate_* (posterior summaries)",
                    `subset files` = "eDNAocc_fulldata_80sites.csv, eDNAocc_45sites.csv, covariates_sample_80sites.csv, covariates_sample.csv, covariates_sample_means.csv (subsets or summaries of shipped data)",
                    `qPCR standards` = "LOD_LOQ_Cq_Standards_Sample1/2.csv (standard curves)",
                    `julian sample dates` = "covariates_sample.csv gives day-of-year for the 45 three-season sites without the year (standard: never a bare day-of-year)"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/tomke_2025_hellbender_edna.R")
stage_dict_row(TABLE,
  description = "Eastern hellbender (Cryptobranchus alleganiensis) eDNA at 90 Kentucky stream sites, 2019-2021: 385 water filters (seasonal and spatial samples) x 9 qPCR replicates, multi-scale (cluster_id = site, unit = filter, occasion = qPCR), with water chemistry, catchment land cover and stream habitat covariates.",
  url = "https://doi.org/10.5061/dryad.9w0vt4bs2",
  reference = "Tomke, S., & Price, S. (2025). Large-scale eDNA sampling and hierarchical modeling elucidates the importance of stream habitat for Eastern Hellbender (Cryptobranchus a. alleganiensis) occupancy and eDNA detection. Freshwater Biology.",
  doi_paper = "10.1111/fwb.70079", doi_data = "10.5061/dryad.9w0vt4bs2",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Experimental (E9) multi-scale eDNA: site > filter > qPCR replicate. Seasons are replicate samples (single-season model); year of sampling not deposited. 80- and 45-site analysis subsets recoverable by filtering.",
  source_via = "Dryad")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "Multi-scale occupancy (eDNA: site, filter, qPCR replicate)",
  sampling_protocol = "eDNA", design = "Single-season", realm = "Freshwater",
  country = "USA", coordinates = "None in source", notes = "Experimental multi-scale via cluster_id = site; seasons as replicate samples.")
