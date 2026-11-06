#!/usr/bin/env Rscript
# Table:  lenzi_2024_alpine_toad_cjs
# Source: Zenodo record 10908913, doi:10.5281/zenodo.10908913 (published 2024-04-02; licence as shown on the record:
#         Creative Commons Attribution 4.0 International).
#   Lenzi, O., Grossenbacher, K., Zumbach, S., Luscher, B., Althaus, S., Thoma, M., Schmocker, D., Recher, H., Ozgul, A. &
#   Schmidt, B. R. Data for: Interplay of abiotic conditions, density, and body size in shaping demography in a
#   high-elevation toad population.
# Paper:  Lenzi, O. et al. (2024). Interplay of abiotic, biotic, and individual factors in shaping individual growth and
#         demography in a high-elevation common toad population. bioRxiv doi:10.1101/2022.08.16.503739 (cited in the
#         README; not read). Study system: Peer Community Journal doi:10.24072/pcjournal.240.
# Data:   README.docx describes every file. MalesSize.csv (6,214 rows) and FemalesSize.csv (2,350 rows): one row per toad
#         per breeding season in which it was captured, 1982-2022: Tag, Year, Year_Obs (first year of observation),
#         Size (snout-vent length, mm, averaged over the season's captures), Weight (g). Tags ending in "er" are cohort
#         marks (1985-1993), not individuals. AllObservations.csv: every capture session with the field team (for a
#         measurer-bias analysis); Yearly_totals.csv, ActiveSeason.csv, two_weeks_values.csv, Prec.csv: annual and
#         daily covariates; model code and MCMC output.
# Mapping: CJS. The authors' rule (BufoBufo_Growth_Demography_Model.R, lines 38-41): drop cohort-marked tags ("er") and
#   rows whose Year_Obs is before 1993 or missing (individual PIT marking started in 1993). unit = "<sex>_<tag>" (the
#   two files are the sexes; 8 tag numbers occur in both, kept as different animals), period = year (1 = 1993 ... 30 =
#   2022), y = captured in that breeding season; obs_svl_mm, obs_mass_g (season averages). surveyEvidence
#   deposited_matrix-like: every breeding season 1993-2022 was surveyed (Yearly_totals lists captures every year), so a
#   season without a row for a toad is y = 0. Adults of unknown age caught at the breeding site: rows from 1993 (E4.4).
#   unit_sex.
# Not shipped: cohort-marked records and those before 1993; AllObservations.csv (within-season sessions; the season is
#   the authors' occasion), climatic covariates and model output; no coordinates are deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "lenzi_2024_alpine_toad_cjs"
rec <- fromJSON(download_cached("https://zenodo.org/api/records/10908913", TABLE, "record.json"))
stopifnot(identical(rec$metadata$license$id, "cc-by-4.0"))
rd <- function(f) fread(download_cached(sprintf("https://zenodo.org/api/records/10908913/files/%s/content", f), TABLE, f), colClasses = "character", na.strings = "NA", encoding = "Latin-1")
m <- rd("MalesSize.csv"); f <- rd("FemalesSize.csv")
yt <- fread(download_cached("https://zenodo.org/api/records/10908913/files/Yearly_totals.csv/content", TABLE, "Yearly_totals.csv"), sep = ";", header = TRUE)
stopifnot(nrow(m) == 6214, nrow(f) == 2350, identical(names(m), c("Tag", "Year", "Year_Obs", "Size", "Weight")))
x <- rbind(m[, sex := "M"], f[, sex := "F"])
x <- x[!grepl("er", Tag) & !is.na(Year_Obs) & as.integer(Year_Obs) >= 1993]
x[, Year := as.integer(Year)]
stopifnot(nrow(x) == 4955 + 1971, !anyDuplicated(x[, .(sex, Tag, Year)]), all(x$Year %in% 1993:2022), uniqueN(paste(x$sex, x$Tag)) == 1948 + 1169)
yrs <- as.integer(names(yt)[-1]); tot <- unlist(yt[V1 == "Total_Min", -1])
stopifnot(all(1993:2022 %in% yrs), all(tot[yrs %in% 1993:2022] > 0))
x[, unit := paste0(sex, "_", Tag)]
g <- CJ(unit = unique(x$unit), Year = 1993:2022)
g <- merge(g, x[, .(unit, Year, sex, Size, Weight, cap = 1L)], by = c("unit", "Year"), all.x = TRUE)
g[, sex := sex[!is.na(sex)][1], by = unit]
long <- g[, .(unit, taxon = "BUFBUF", y = as.integer(!is.na(cap)),
              period = Year - 1992L, unit_sex = sex, obs_svl_mm = as.numeric(Size), obs_mass_g = as.numeric(Weight))]
stopifnot(sum(long$y) == nrow(x), nrow(long) == uniqueN(x$unit) * 30)
periods <- data.table(period = 1:30, year = 1993:2022)
taxa <- make_taxa("BUFBUF", "Bufo bufo", vernacularName = "Common toad")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
dataset <- list(
  title = "Annual capture histories of 3,117 PIT-tagged common toads at a high-elevation breeding site in the Swiss Alps, 1993-2022",
  creator = "Lenzi, Omar; Grossenbacher, Kurt; Zumbach, Silvia; Luscher, Beatrice; Althaus, Sarah; Thoma, Marco; Schmocker, Daniela; Recher, Helmut; Ozgul, Arpat; Schmidt, Benedikt R.",
  pubDate = "2024", doi = "10.5281/zenodo.10908913", sourceURL = "https://doi.org/10.5281/zenodo.10908913", paperDOI = "10.1101/2022.08.16.503739",
  citation = "Lenzi, O., Grossenbacher, K., Zumbach, S., Luscher, B., Althaus, S., Thoma, M., Schmocker, D., Recher, H., Ozgul, A. & Schmidt, B. R. (2024). Data for: Interplay of abiotic conditions, density, and body size in shaping demography in a high-elevation toad population. Zenodo, https://doi.org/10.5281/zenodo.10908913.",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Common toads of an alpine population in the Swiss Alps have been captured at their breeding site every spring since 1982 and individually PIT-tagged since 1993; histories with body size support survival, breeding-probability and growth models.",
  samplingProtocol = "Capture of toads at the breeding site during each breeding season (several sessions); individuals PIT-tagged from 1993, sexed, measured (snout-vent length) and weighed; season averages of size per toad.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The deposit has one row per toad per breeding season with a capture; every season 1993-2022 was surveyed (captures in each, Yearly_totals.csv), so a season with no row for a toad is a zero.",
  responseType = "detection", unitKind = "individual", closure = "none", occasionKind = "none", taxonInclusion = "single",
  closureNote = "period = breeding season (year); within-season sessions are collapsed as in the authors' model.",
  geographicCoverage = "A high-elevation breeding site in the Swiss Alps, Switzerland (no coordinates in the deposit)",
  temporalCoverage = "1993/2022",
  notShipped = list(cohort_marks = "tags ending in 'er' (cohort marks 1985-1993) and records with Year_Obs before 1993 or missing (the authors' rule)",
                    sessions = "AllObservations.csv: individual capture sessions within seasons and field teams",
                    covariates = "climate series, yearly totals, MCMC output"),
  notes = "Units are <sex>_<tag>: the sexes come from separate files and 8 tag numbers occur in both. Females breed intermittently, so a female's zero can be a non-breeding year (the authors model breeding probability).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/lenzi_2024_alpine_toad_cjs.R")
stage_dict_row(TABLE,
  description = "Annual capture histories (1993-2022) of 3,117 PIT-tagged common toads, males and females, at an alpine breeding site in Switzerland, with season-average body length and mass.",
  url = "https://doi.org/10.5281/zenodo.10908913",
  reference = "Lenzi, O. et al. (2024). Interplay of abiotic, biotic, and individual factors in shaping individual growth and demography in a high-elevation common toad population. bioRxiv.",
  doi_paper = "10.1101/2022.08.16.503739", doi_data = "10.5281/zenodo.10908913", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Authors' filter (no cohort marks, PIT era from 1993).", source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "CJS", sampling_protocol = "visual_encounter",
  design = "Multi-season (30 breeding seasons)", realm = "Freshwater", country = "CHE", coordinates = "None in source",
  notes = "Long-term alpine population; intermittent breeding in females.")
