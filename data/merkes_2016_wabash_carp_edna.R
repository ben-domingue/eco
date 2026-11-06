#!/usr/bin/env Rscript
# Table:  merkes_2016_wabash_carp_edna
# Source: USGS ScienceBase doi:10.5066/F70G3H7X (USGS data release, published 2016-10-11; use
#         constraints "none"; US public domain, recorded as CC0 1.0)
#   Merkes, C., and Erickson, R., 2016, Seasonal trends in eDNA detection and occupancy of bigheaded
#   carps, Wabash River, IN: Raw Data: U.S. Geological Survey data release.
# Paper:  Erickson, R.A., Merkes, C.M., Jackson, C.A., Goforth, R.R., and Amberg, J.J., 2017, Seasonal
#   trends in eDNA detection and occupancy of bigheaded carps. Journal of Great Lakes Research 43(4):
#   762-770, doi:10.1016/j.jglr.2017.06.003.
# Data:   clean_raw_data.csv: 2,444 qPCR results, one per sample x target x reaction: water samples
#         taken at 18 points along a transect at each of three sites on the Wabash River, Indiana
#         (Mascouten rkm 499, Americus rkm 518, French Post rkm 531) on 13 collection days of 2013
#         (Julian day 149 to 311; not every site on every day), each run in duplicate reactions of a
#         multiplex assay that detects silver carp (SVC, FAM dye) and bighead carp (BHC, JOE dye);
#         Ct value and copy number (NA where no amplification), plate id. Sample ids are
#         "<day>_<point><site letter>". Standards_Data.csv: the plates' calibration standards (not
#         samples). No field blanks are deposited (each plate had no-template controls, not
#         deposited). Asserted: every sample x target has exactly two reactions, the id encodes the
#         row's day, point and site, Ct and copies are missing together.
# Mapping (E9 eDNA form): unit = water sample ("<site>_<day>_<point>"), cluster_id = site, occasion =
#   qPCR reaction (1, 2 in file order), occasionKind spatial (PCR replicates), taxon = SVC / BHC,
#   y = 1 where the reaction amplified (a Ct value), else 0 (ruling 2026-11-06: no call is given),
#   y_raw = the Ct as deposited ("NA" where none); obs_copies = copies per reaction as deposited,
#   obs_plate = plate id. date = 2013 plus the Julian day (the release's dates run 2013-05-29 =
#   day 149 to 2013-11-07 = day 311); unit_day and unit_point carry the sampling event and
#   transect point. The multiplex assay tests both species in every reaction, so each sample has
#   rows for both. No coordinates are deposited (site names and river km in the metadata).
#   unit_rkm from the lineage. No period: each sample is collected once.
# Not shipped: Standards_Data.csv (calibration curves); Dye (determined by the target).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "merkes_2016_wabash_carp_edna"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/581e12f1e4b0dee4cc98fb06?format=json", TABLE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
d <- fread(download_cached(fl[["clean_raw_data.csv"]], TABLE, filename = "clean_raw_data.csv"), colClasses = "character")
stopifnot(nrow(d) == 2444, all(d$Target %in% c("SVC", "BHC")), all((d$Dye == "FAM") == (d$Target == "SVC")),
          identical(is.na(d$Ct.Value) | d$Ct.Value == "NA", is.na(d$Copies) | d$Copies == "NA"),
          all(d[, .N, by = .(Sample.ID, Target)]$N == 2))
let <- c(Americus = "A", `French Post` = "F", Mascouten = "M")
stopifnot(all(d$Sample.ID == paste0(d$Day, "_", d$Trans.Point, let[d$Site])), uniqueN(d$Sample.ID) == 611)
d[, occasion := seq_len(.N), by = .(Sample.ID, Target)]
d[, ct := suppressWarnings(as.numeric(Ct.Value))]
stopifnot(sum(!is.na(d$ct)) == 707)
rkm <- c(Mascouten = 499, Americus = 518, `French Post` = 531)
day <- as.integer(d$Day)
long <- d[, .(unit = sprintf("%s_%03d_%02d", gsub(" ", "", Site), as.integer(Day), as.integer(Trans.Point)), taxon = Target,
              y = as.integer(!is.na(ct)), y_raw = ifelse(is.na(ct), "NA", Ct.Value), occasion,
              date = format(as.IDate("2012-12-31") + as.integer(Day)), cluster_id = Site,
              unit_day = as.integer(Day), unit_point = as.integer(Trans.Point), unit_rkm = rkm[Site],
              obs_copies = suppressWarnings(as.numeric(Copies)), obs_plate = Plate.ID)]
stopifnot(min(long$date) == "2013-05-29", max(long$date) == "2013-11-07", nrow(long) == 2444)
taxa <- make_taxa(c("BHC", "SVC"), c("Hypophthalmichthys nobilis", "Hypophthalmichthys molitrix"), vernacularName = c("Bighead carp", "Silver carp"))
dataset <- list(
  title = "Bighead and silver carp eDNA detections in duplicate qPCR reactions of 611 water samples at three Wabash River sites, Indiana, 2013",
  creator = "Merkes, Christopher; Erickson, Richard",
  pubDate = "2016", doi = "10.5066/F70G3H7X", sourceURL = "https://doi.org/10.5066/F70G3H7X",
  citation = "Merkes, C., and Erickson, R., 2016, Seasonal trends in eDNA detection and occupancy of bigheaded carps, Wabash River, IN: Raw Data: U.S. Geological Survey data release, https://doi.org/10.5066/F70G3H7X.",
  paperDOI = "10.1016/j.jglr.2017.06.003",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
  abstract = "Water samples taken at 18 points along a transect at three Wabash River sites spanning a gradient of bigheaded carp density, on 13 days from May to November 2013, each analysed in duplicate with a new multiplex qPCR marker that detects and distinguishes silver and bighead carp DNA, to describe seasonal change in eDNA occurrence and the probability of detecting DNA within a sample.",
  samplingProtocol = "Surface water samples at 18 transect points per site and collection day, filtered and extracted; each extract run in two reactions of a multiplex qPCR assay (FAM: silver carp, JOE: bighead carp) with calibration standards on every plate.",
  samplingProtocolCode = "eDNA", surveyEvidence = "sample_table", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasions are the two qPCR reactions of one water sample", occasionKind = "spatial",
  taxonInclusion = "target",
  geographicCoverage = list(description = "Wabash River at Mascouten boat launch (rkm 499), Americus (rkm 518) and French Post (rkm 531), Tippecanoe County, Indiana, USA"),
  temporalCoverage = "2013-05/2013-11",
  notShipped = list(standards = "Standards_Data.csv: the calibration standards of each plate",
                    dye = "Dye: determined by the target (FAM silver carp, JOE bighead carp)",
                    controls = "no-template controls are described but not deposited; no field blanks are deposited"),
  notes = "y = 1 where a reaction amplified (any Ct), per the 2026-11-06 eDNA ruling; the source states no Ct cutoff.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/merkes_2016_wabash_carp_edna.R")
stage_dict_row(TABLE,
  description = "Detection of silver and bighead carp DNA in each of two qPCR reactions of 611 water samples taken along transects at three Wabash River sites, Indiana, on 13 days in 2013, with Ct, copy number and plate.",
  url = "https://doi.org/10.5066/F70G3H7X",
  reference = "Erickson, R.A., Merkes, C.M., Jackson, C.A., Goforth, R.R., and Amberg, J.J. (2017). Seasonal trends in eDNA detection and occupancy of bigheaded carps. Journal of Great Lakes Research 43(4):762-770.",
  doi_paper = "10.1016/j.jglr.2017.06.003", doi_data = "10.5066/F70G3H7X", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
  notes = "Multi-scale eDNA: unit = sample, cluster_id = site, occasion = qPCR reaction; y = amplified.", source_via = "USGS ScienceBase")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Multi-scale occupancy (eDNA)", sampling_protocol = "eDNA",
  design = "Single-season (13 collection days x 18 samples x 2 reactions)", realm = "Freshwater", country = "USA", coordinates = "None in source",
  notes = "Invasive bigheaded carps; multiplex qPCR.")
