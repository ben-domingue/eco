#!/usr/bin/env Rscript
# Table:  dougherty_2016_rustycrayfish_edna
# Source: Dryad doi:10.5061/dryad.3hp15 (CC0 1.0, shown on the dataset page and in the API
#         record), version 8099 (published 2017-02-01).
#   Dougherty, M. M., Larson, E. R., Renshaw, M. A., Gantz, C. A., Egan, S. P., Erickson, D. M.
#   & Lodge, D. M. (2017). Data from: Environmental DNA (eDNA) detects the invasive rusty
#   crayfish (Orconectes rusticus) at low abundances. Dryad.
# Paper:  Dougherty, M. M. et al. (2016). Environmental DNA (eDNA) detects the invasive rusty
#         crayfish Orconectes rusticus at low abundances. Journal of Applied Ecology 53(3),
#         722-732. doi:10.1111/1365-2664.12621.
# Data:   Dougherty_etal_Orusticus_eDNA.xlsx with two sheets.
#         Trap_eDNA: one row per baited-trap location (262 rows, 12 inland lakes in northern
#         Wisconsin / Michigan, July-September 2014; a group-header row above the column names):
#         Lake, DateTrapsIn, DateTrapsOut (one overnight set), Latitude / Longitude of the trap
#         (decimal degrees, NAD83/WGS84, 8 decimals), Trap#, O. rusticus trapped by class (males
#         Form I, Form II, females) and total, O. propinquus total, O. virilis total, TrapNotes
#         ("Trap missing" twice), qPCR1-qPCR3 and "pPCR4" (sic: copies of O. rusticus DNA per 4 ul
#         of extract in four qPCR replicates of a water sample taken at the trap; blank where no
#         water sample was taken, at every other trap), qPCRAve (their mean), and Sanger
#         sequencing confirmation of positives (length, identity, sequence).
#         SecchiData: 645 Secchi depth readings by lake and date, 2001-2015, from the sources in
#         the paper's supporting information.
#         README_for_Dougherty_etal_Orusticus_eDNA.pdf defines the columns.
#
# Mapping (standard E9 experimental: multi-scale / eDNA with a second method, as
#   lafferty_2024_socal_estuary_edna; responseType detection, unitKind site):
#   cluster_id = lake, unit = trap location ("<Lake>_<Trap#>"), taxon = ORCRUS (Orconectes =
#   Faxonius rusticus), occasion 1-4 = qPCR replicate of the location's water sample (y = 1 if
#   copies > 0; y_raw = copies per 4 ul), occasion 5 = the baited trap (y = 1 if any O. rusticus
#   was caught; y_raw = number caught); obs_method = "qPCR" / "baited trap". Rows exist where the
#   assay was run or the trap recovered: 118 locations with water samples (4 rows each), 260
#   recovered traps; a missing trap has no occasion-5 row, a location without a water sample no
#   occasion 1-4 rows (Spider trap 14: neither, no rows).
#   Covariates: unit_decimalLatitude / unit_decimalLongitude (as published; the species is an
#   invasive, not a flagged taxon), unit_date_set, unit_date_retrieved; on the trap row
#   obs_rusticus_male_form1 / _form2 / _female (the catch by class) and obs_propinquus_caught /
#   obs_virilis_caught (other crayfish in the same trap; NA on qPCR rows).
#   Survey evidence = deposited_matrix: blank qPCR cells (no water sample) and "Trap missing"
#   are distinct from zeros.
#   Not shipped: qPCRAve (mean of the replicates), Sanger confirmation columns (sequence
#   identity of positives: all 100% O. rusticus, asserted), the SecchiData sheet (lake water
#   clarity from many years and third-party sources; the authors summarise it per lake in their
#   model, which is not deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "dougherty_2016_rustycrayfish_edna"
dir <- download_dryad("10.5061/dryad.3hp15", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "Dougherty_etal_Orusticus_eDNA.xlsx")
stopifnot(identical(excel_sheets(f), c("Trap_eDNA", "SecchiData")))
d <- as.data.table(read_excel(f, "Trap_eDNA", skip = 1))
stopifnot(identical(names(d), c("Lake", "DateTrapsIn", "DateTrapsOut", "Latitude", "Longitude", "Trap#", "OrusticusFormI",
                                "OrusticusFormII", "OrusticusFemale", "OrusticusTotal", "OpropinquusTotal", "OvirilisTotal",
                                "TrapNotes", "qPCR1", "qPCR2", "qPCR3", "pPCR4", "qPCRAve", "SequenceLength(bp)", "Result", "Sequence")))
setnames(d, c("Trap#", "pPCR4"), c("trap", "qPCR4"))
stopifnot(nrow(d) == 262L, uniqueN(d$Lake) == 12L, !anyDuplicated(d[, .(Lake, trap)]), !anyNA(d[, .(Latitude, Longitude, DateTrapsIn, DateTrapsOut)]),
          identical(sort(unique(na.omit(d$TrapNotes))), "Trap missing"), sum(!is.na(d$TrapNotes)) == 2L,
          # a missing trap has no catch; every recovered trap has all catch columns
          d[!is.na(TrapNotes), all(is.na(OrusticusTotal))], d[is.na(TrapNotes), !anyNA(.SD), .SDcols = OrusticusFormI:OvirilisTotal],
          d[is.na(TrapNotes), all(OrusticusTotal == OrusticusFormI + OrusticusFormII + OrusticusFemale)],
          # the four qPCR replicates are all present or all absent; 118 water samples
          d[, all(is.na(qPCR1) == is.na(qPCR2) & is.na(qPCR1) == is.na(qPCR3) & is.na(qPCR1) == is.na(qPCR4))], sum(!is.na(d$qPCR1)) == 118L,
          all(unlist(d[!is.na(qPCR1), .(qPCR1, qPCR2, qPCR3, qPCR4)]) >= 0),
          d[!is.na(qPCR1), all(abs(qPCRAve - (qPCR1 + qPCR2 + qPCR3 + qPCR4) / 4) < 0.01)],
          d[!is.na(Result), all(grepl("100% identity to Orconectes rusticus", Result))])
d[, `:=`(unit = sprintf("%s_%02d", Lake, as.integer(trap)), set = format(as.Date(DateTrapsIn)), out = format(as.Date(DateTrapsOut)))]
stopifnot(d[, all(as.numeric(as.Date(out) - as.Date(set)) %in% 1:2)])
covs <- d[, .(unit, cluster_id = Lake, unit_decimalLatitude = Latitude, unit_decimalLongitude = Longitude,
              unit_date_set = set, unit_date_retrieved = out)]
q <- rbindlist(lapply(1:4, function(k) d[!is.na(qPCR1), .(unit, occasion = k, y_raw = get(paste0("qPCR", k)), obs_method = "qPCR")]))
q[, y := as.integer(y_raw > 0)]
tr <- d[is.na(TrapNotes), .(unit, occasion = 5L, y_raw = OrusticusTotal, y = as.integer(OrusticusTotal > 0), obs_method = "baited trap",
                            obs_rusticus_male_form1 = as.integer(OrusticusFormI), obs_rusticus_male_form2 = as.integer(OrusticusFormII),
                            obs_rusticus_female = as.integer(OrusticusFemale), obs_propinquus_caught = as.integer(OpropinquusTotal),
                            obs_virilis_caught = as.integer(OvirilisTotal))]
long <- rbindlist(list(q, tr), fill = TRUE)
long <- merge(long, covs, by = "unit")
long[, taxon := "ORCRUS"]
long <- order_eco(long)
stopifnot(nrow(long) == 118L * 4L + 260L, uniqueN(long$unit) == 261L, !anyDuplicated(long[, .(unit, occasion)]),
          !any(grepl("^unit_unit_", names(long))))
cat(sprintf("  %d rows, %d trap locations in %d lakes; qPCR positive replicates %d of %d; traps with O. rusticus %d of %d\n",
            nrow(long), uniqueN(long$unit), uniqueN(long$cluster_id), q[, sum(y)], nrow(q), tr[, sum(y)], nrow(tr)))
taxa <- make_taxa("ORCRUS", "Orconectes rusticus", vernacularName = "Rusty crayfish")
dataset <- list(
  title = "Rusty crayfish eDNA qPCR replicates and paired baited traps at 261 locations in 12 upper-Midwest lakes, 2014",
  creator = "Dougherty, Matthew M.; Larson, Eric R.; Renshaw, Mark A.; Gantz, Crysta A.; Egan, Scott P.; Erickson, Daniel M.; Lodge, David M.",
  pubDate = "2017", doi = "10.5061/dryad.3hp15", sourceURL = "https://doi.org/10.5061/dryad.3hp15", paperDOI = "10.1111/1365-2664.12621",
  citation = "Dougherty, M. M., Larson, E. R., Renshaw, M. A., Gantz, C. A., Egan, S. P., Erickson, D. M., & Lodge, D. M. (2017). Data from: Environmental DNA (eDNA) detects the invasive rusty crayfish (Orconectes rusticus) at low abundances [Data set]. Dryad. https://doi.org/10.5061/dryad.3hp15",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Invasive rusty crayfish (Orconectes rusticus) sampled in 12 inland lakes of northern Wisconsin and Michigan, July-September 2014, by 12-36 baited traps per lake set overnight and by water samples taken at every other trap location and analysed in four qPCR replicates (copies per 4 ul of extract). Occasions 1-4 are the qPCR replicates (detected if copies > 0), occasion 5 the baited trap at the same location (detected if any O. rusticus was caught); cluster_id = lake. The paper models eDNA detection against trap-based relative abundance and lake water clarity; eDNA detected the species in every lake where trapping did and in two where trapping did not.",
  samplingProtocol = "Baited minnow traps set overnight along the littoral zone; 250 ml water samples taken at alternate trap locations, filtered, extracted and analysed with a species-specific qPCR assay in four replicates; positives confirmed by Sanger sequencing.",
  samplingProtocolCode = "eDNA", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "site",
  closure = "lake and location state closed over the 1-2 day survey; occasion = qPCR replicate (1-4) or the trap (5)",
  occasionCodes = list(`1` = "qPCR replicate 1", `2` = "qPCR replicate 2", `3` = "qPCR replicate 3", `4` = "qPCR replicate 4", `5` = "baited trap, one overnight set"),
  designNote = "Experimental list of E9 (multi-scale / eDNA, multi-method): cluster_id = lake, unit = trap location, occasion = assay replicate or trap, obs_method distinguishes the two detection processes. The trap is a different sample from the water sample at the same location.",
  geographicCoverage = "12 inland lakes, Vilas County, Wisconsin, and Gogebic County, Michigan, USA (about 46.0-46.3 N, 89.5-89.9 W)",
  coordinatesCoarsened = "Not coarsened: trap coordinates as published (O. rusticus is an invasive species; no flagged taxon)",
  temporalCoverage = "2014-07-28/2014-09-07",
  notes = "y_raw is copies per 4 ul of extract on qPCR rows and the number of O. rusticus caught on trap rows. obs_propinquus_caught and obs_virilis_caught are the other crayfish species in the same trap (competitor covariates; not modelled as taxa because the qPCR assay targets O. rusticus only). Spider Lake trap 14 (missing trap, no water sample) has no rows; VanVliet trap 1 (missing trap) has qPCR rows only.",
  notShipped = list(qPCRAve = "mean of the four replicates (derived)",
                    sanger = "Sanger confirmation of positives: sequence length, identity (all 100% O. rusticus) and sequence",
                    secchi = "SecchiData sheet: 645 Secchi readings by lake, 2001-2015, compiled from third-party sources; lake clarity summaries used in the paper's model are not deposited"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/dougherty_2016_rustycrayfish_edna.R")
stage_dict_row(TABLE,
  description = "Invasive rusty crayfish (Orconectes rusticus) in 12 upper-Midwest lakes, 2014: four eDNA qPCR replicates of water samples at alternate trap locations plus the paired overnight baited trap (multi-method, cluster_id = lake), with catches of two other crayfish species.",
  url = "https://doi.org/10.5061/dryad.3hp15",
  reference = "Dougherty, M. M., Larson, E. R., Renshaw, M. A., Gantz, C. A., Egan, S. P., Erickson, D. M., & Lodge, D. M. (2016). Environmental DNA (eDNA) detects the invasive rusty crayfish Orconectes rusticus at low abundances. Journal of Applied Ecology, 53(3), 722-732.",
  doi_paper = "10.1111/1365-2664.12621", doi_data = "10.5061/dryad.3hp15",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Experimental E9 (multi-scale eDNA, multi-method): qPCR replicates as occasions 1-4, baited trap as occasion 5 (obs_method). First freshwater invertebrate eDNA table.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Multi-scale occupancy (eDNA qPCR with trap)",
  sampling_protocol = "eDNA", design = "Single-season (12 lakes, one survey each)", realm = "Freshwater",
  country = "USA", coordinates = "As published",
  notes = "Invasive crayfish; qPCR replicates plus baited trap at the same locations.")
