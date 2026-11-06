#!/usr/bin/env Rscript
# Table:  cox_2018_qubs_treeswallow_cjs
# Source: Borealis (Canadian Dataverse) doi:10.5683/SP2/9RRIYY, deposited 2018-11-22, licence CC0 1.0 (the dataset's
#         license field, asserted from the cached dataset JSON).
#   Cox, A. (2018). Female Fledgling MARK Data.rda [Dataset]. Borealis.
# Paper:  none named. The deposit is from Queen's University (tree swallow nest-box population at the Queen's
#         University Biological Station, Ontario, per the queue row; the deposit itself names no place).
# Data:   "Female Fledgling MARK Data.rda" (datafile 72713): despite the extension, an R serialised object (readRDS):
#         a data.frame of 17,749 rows: ch (43-character 0/1 history, 1975-2017), AgeAtFirstSight (HY nestling, SY
#         1-year-old, ASY older female, AHY after hatch year), Sex (F known female, U "captured only as nestling"),
#         age (0 nestling, 1 one-year-old (SY and AHY), 2 older (ASY)). The dataset description: "only half of all
#         fledglings that never returned subsequently have been included--the other half have been assumed to be
#         male". Every history has a capture (asserted).
# Mapping (CJS): unit = row ("ts_<n>"), taxon = TACBIC, period = year (1 = 1975 ... 43 = 2017), y = 0/1. At-risk
#   span (E4.4): a bird first caught as a nestling (HY) was marked at hatching and has rows from that year; a bird
#   first caught as an adult (SY, ASY, AHY) has rows from 1975 (wild, of unknown exact age). unit_age_first
#   (AgeAtFirstSight), unit_sex (F / U) as deposited. surveyEvidence = deposited_matrix. No coordinates.
#   The authors' halving of never-returning fledglings is carried as deposited and stated in notes: the table holds
#   the individuals the authors analysed, not every bird banded.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "cox_2018_qubs_treeswallow_cjs"
meta_f <- file.path(RAW_DIR, TABLE, "dataverse_dataset.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file("https://borealisdata.ca/api/datasets/:persistentId/?persistentId=doi:10.5683/SP2/9RRIYY",
                                        meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- fromJSON(meta_f)$data$latestVersion
stopifnot(identical(meta$license$name, "CC0 1.0"), identical(meta$files$dataFile$id, 72713L))
f <- download_cached("https://borealisdata.ca/api/access/datafile/72713", TABLE, filename = "Female_Fledgling_MARK_Data.rds")
x <- as.data.table(readRDS(f))
stopifnot(identical(names(x), c("ch", "AgeAtFirstSight", "Sex", "age")), nrow(x) == 17749L,
          all(nchar(x$ch) == 43L), all(grepl("^[01]+$", x$ch)), all(grepl("1", x$ch)),
          setequal(as.character(x$AgeAtFirstSight), c("AHY", "ASY", "HY", "SY")), setequal(as.character(x$Sex), c("F", "U")),
          x[, all((age == 0) == (AgeAtFirstSight == "HY"))], sum(x$AgeAtFirstSight == "HY") == 13743L)
H <- do.call(rbind, strsplit(x$ch, ""))
first <- apply(H == "1", 1, function(r) which(r)[1])
start <- ifelse(x$AgeAtFirstSight == "HY", first, 1L)
long <- data.table(unit = rep(sprintf("ts_%05d", seq_len(nrow(x))), 44L - start),
                   period = unlist(lapply(start, function(s) s:43L)),
                   unit_age_first = rep(as.character(x$AgeAtFirstSight), 44L - start),
                   unit_sex = rep(as.character(x$Sex), 44L - start))
long[, y := as.integer(H[cbind(match(unit, sprintf("ts_%05d", seq_len(nrow(x)))), period)])]
long[, taxon := "TACBIC"]
long <- order_eco(long)
stopifnot(sum(long$y) == sum(H == "1"), uniqueN(long$unit) == nrow(x), nrow(long) == sum(44L - start))
cat(sprintf("  %d birds (%d first caught as nestlings), %d rows, %d captures\n", nrow(x), sum(x$AgeAtFirstSight == "HY"), nrow(long), sum(long$y)))
taxa <- make_taxa("TACBIC", "Tachycineta bicolor", vernacularName = "Tree swallow")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "LC"))
periods <- data.table(period = 1:43, year = 1975:2017)
dataset <- list(
  title = "Annual capture histories of 17,749 female and nestling tree swallows, Queen's University Biological Station nest boxes, 1975-2017",
  creator = "Cox, Amelia", pubDate = "2018", doi = "10.5683/SP2/9RRIYY", sourceURL = "https://doi.org/10.5683/SP2/9RRIYY",
  citation = "Cox, A. (2018). Female Fledgling MARK Data.rda [Dataset]. Borealis. https://doi.org/10.5683/SP2/9RRIYY",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Annual capture histories (1975-2017) of female tree swallows and of fledglings banded as nestlings in a long-term nest-box population, prepared for Program MARK survival analysis with age at first capture. Only half of the fledglings never recaptured are included; the authors assumed the other half were males.",
  samplingProtocol = "Nest-box monitoring: breeding females captured at their boxes each year and nestlings banded; one annual capture occasion.",
  samplingProtocolCode = "nest_box", surveyEvidence = "deposited_matrix",
  responseType = "detection", unitKind = "individual", closure = "none", closureNote = "one annual occasion per year",
  occasionKind = "none", taxonInclusion = "single",
  geographicCoverage = "Queen's University Biological Station, Ontario, Canada (no coordinates deposited)",
  temporalCoverage = "1975/2017",
  covariateNote = "unit_age_first: age at first capture (HY nestling, SY one-year-old, ASY older female, AHY after hatch year). unit_sex: F known female, U not known (as deposited).",
  notShipped = list(age_numeric = "age (0/1/2): a recode of AgeAtFirstSight (asserted for nestlings)",
                    males = "adult males and the half of never-returning fledglings the authors assumed male are not in the deposit"),
  notes = "The source includes only half of all fledglings that never returned (the other half assumed male), so the nestling cohort is a subsample chosen by the authors. Nestlings have rows from their hatching year; adults from 1975 (E4.4).")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/cox_2018_qubs_treeswallow_cjs.R")
stage_dict_row(TABLE,
  description = "Annual CJS capture histories of 17,749 female and nestling tree swallows (Tachycineta bicolor), Queen's University Biological Station, Ontario, 1975-2017, with age at first capture.",
  url = "https://doi.org/10.5683/SP2/9RRIYY", reference = "", doi_paper = "", doi_data = "10.5683/SP2/9RRIYY",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "The .rda file is an RDS object. Half of never-returning fledglings omitted by the authors (assumed male).",
  source_via = "Borealis Dataverse (access API)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "CJS capture-recapture (age at first capture)",
  sampling_protocol = "nest_box", design = "Multi-season (43 years, 1975-2017)",
  realm = "Terrestrial", country = "CAN", coordinates = "None in source",
  notes = "Nestling cohort subsampled by the authors (half of non-returners kept).")
