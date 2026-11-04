#!/usr/bin/env Rscript
# Table:  fukaya_2022_kasumigaura_fish_mb
# Source: Dryad doi:10.5061/dryad.3bk3j9kkm (CC0 1.0, as shown on the Dryad page and in the API
#         record), version 141498 (published 2021-09-22).
#   Fukaya, K., Kondo, N. I., Matsuzaki, S. S. & Kadoya, T. (2021). Data from: Multispecies site
#   occupancy modeling and study design for spatially replicated environmental DNA
#   metabarcoding. Dryad.
#   The analysis scripts (1_model_fitting.R, model.jags, ...) are a separate Zenodo software record,
#   doi:10.5281/zenodo.5515373 (MIT); they were read, not used.
# Paper:  Fukaya, K., Kondo, N. I., Matsuzaki, S. S. & Kadoya, T. (2022). Multispecies site occupancy
#         modelling and study design for spatially replicated environmental DNA metabarcoding.
#         Methods in Ecology and Evolution 13(1), 183-193. doi:10.1111/2041-210X.13732 (preprint
#         doi:10.1101/2021.02.14.431192, read for the design).
# Data:   data.Rdata (README.txt describes it), three objects:
#         y: integer array 50 species groups x 50 sites x 3 replicates (dimnames: scientific names
#            as the authors' taxa, sites "1".."50", replicates "L", "C", "R"), MiFish-U 12S MiSeq
#            sequence read counts per species group per replicate sample. No NA; six replicate
#            samples have zero reads for every taxon (sites 8, 16, 49 replicate L; 30, 38, 44
#            replicate R): the preprint says "we omitted six of the 150 samples as no sequence reads
#            were obtained", and 1_model_fitting.R sets them to NA ("missing replicates").
#         riverbank: 0/1 per site, "whether the riverbank at site j lacks aquatic and riparian
#            vegetation" (preprint), the site covariate of occupancy in the authors' model.
#         mismatch: integer per species group, total mismatched bases in the priming regions of the
#            forward and reverse primers (preprint Table S1), the species covariate of read share.
#         Design (preprint): "In August 2017, we collected three environmental samples (i.e.,
#         replicates) at 50 sites across the watershed" (Lake Kasumigaura watershed, Ibaraki,
#         Japan); a separate library per replicate. Neither the deposit nor the preprint defines
#         the L / C / R labels; they ship as obs_replicate_label. No coordinates are deposited.
#
# Mapping (community detection, unitKind site; the multi-scale eDNA form of E9 with one level of
#   replication, as lafferty_2024_estuaryfish_mb):
#   unit = site ("1".."50"), occasion = replicate sample (1 = L, 2 = C, 3 = R, the deposited order),
#   taxon = the authors' 50 species groups (33 species, 9 subspecies and 8 genus-level "spp."
#   groups, each its own taxon at the rank the source gives, E6), y = 1 if the group has any reads
#   in the replicate, y_raw = read count. unit_riverbank_unvegetated = riverbank;
#   taxon_primer_mismatches = mismatch (in __taxa); obs_replicate_label = L / C / R.
#   Survey evidence = deposited_matrix: a replicate sample is surveyed iff its sequencing depth (reads
#   summed over the 50 groups) is > 0, the authors' rule for missing replicates; 144 of 150 samples,
#   each with a row for all 50 groups. Every group has reads in at least one sample (asserted), so
#   taxonInclusion = recorded.
#   Not shipped: none of the deposit; the authors' sequencing depth per sample is the sum of y_raw
#   over taxa and is not repeated. Model outputs (psi, theta, z) are not deposited.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "fukaya_2022_kasumigaura_fish_mb"
dir <- download_dryad("10.5061/dryad.3bk3j9kkm", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
stopifnot(setequal(list.files(dir), c("data.Rdata", "README.txt")))
e <- new.env(); load(file.path(dir, "data.Rdata"), envir = e)
stopifnot(setequal(ls(e), c("y", "riverbank", "mismatch")))
y <- e$y; riverbank <- e$riverbank; mismatch <- e$mismatch

# facts about the source
stopifnot(identical(dim(y), c(50L, 50L, 3L)), identical(dimnames(y)[[2]], as.character(1:50)),
          identical(dimnames(y)[[3]], c("L", "C", "R")), !anyNA(y), all(y >= 0), all(y == round(y)),
          length(riverbank) == 50L, all(riverbank %in% 0:1), length(mismatch) == 50L,
          identical(names(mismatch), dimnames(y)[[1]]), all(mismatch %in% 0:10), !anyDuplicated(dimnames(y)[[1]]))
depth <- apply(y, c(2, 3), sum)
miss <- which(depth == 0, arr.ind = TRUE)
stopifnot(nrow(miss) == 6L,
          identical(sort(paste(rownames(depth)[miss[, 1]], colnames(depth)[miss[, 2]])),
                    sort(c("8 L", "16 L", "49 L", "30 R", "38 R", "44 R"))),
          all(rowSums(depth > 0) >= 2))                                   # every site has >= 2 sequenced replicates
det_any <- apply(y > 0, 1, any)
stopifnot(all(det_any))                                                    # every group recorded somewhere

sp <- dimnames(y)[[1]]
stopifnot(sum(grepl(" spp\\.$", sp)) == 8L, sum(lengths(strsplit(sp, " ")) == 3L) == 9L,
          sum(lengths(strsplit(sp, " ")) == 2L & !grepl(" spp\\.$", sp)) == 33L)
gen <- sub(" .*", "", sp)
ep <- ifelse(grepl(" spp\\.$", sp), "SPP", toupper(substr(sub("^\\S+ (\\S+).*$", "\\1", sp), 1, 3)))
code <- paste0(toupper(substr(gen, 1, 3)), ep)
stopifnot(!anyDuplicated(code))

long <- data.table(unit = rep(dimnames(y)[[2]], times = 50L * 3L),
                   taxon = rep(rep(code, each = 50L), times = 3L),
                   y_raw = as.integer(as.vector(aperm(y, c(2, 1, 3)))),
                   occasion = rep(1:3, each = 50L * 50L),
                   obs_replicate_label = rep(c("L", "C", "R"), each = 50L * 50L))
# array order check: one cell
stopifnot(long[unit == "7" & taxon == code[11] & occasion == 2L, y_raw] == y[11, 7, 2])
long[, depth := as.vector(depth)[match(paste(unit, occasion), paste(rep(rownames(depth), 3), rep(1:3, each = 50)))]]
stopifnot(!anyNA(long$depth))
long <- long[depth > 0]
long[, depth := NULL]
long[, y := as.integer(y_raw > 0)]
long[, unit_riverbank_unvegetated := as.integer(riverbank[as.integer(unit)])]
long <- order_eco(long)
stopifnot(nrow(long) == 144L * 50L, !anyDuplicated(long[, .(unit, taxon, occasion)]),
          all(long[, uniqueN(taxon), by = .(unit, occasion)]$V1 == 50L), sum(long$y_raw) == sum(y),
          uniqueN(long$unit) == 50L)
cat(sprintf("  %d rows: 50 sites, 144 replicate samples, 50 taxa; %d detections; %s reads\n",
            nrow(long), sum(long$y), format(sum(long$y_raw), big.mark = ",")))

rank <- ifelse(grepl(" spp\\.$", sp), "genus", ifelse(lengths(strsplit(sp, " ")) == 3L, "subspecies", "species"))
lookup <- ifelse(grepl(" spp\\.$", sp), gen, sp)
lookup[sp == "Opsariichthys platypus"] <- "Zacco platypus"   # GBIF backbone holds the species under Zacco
remarks <- ifelse(rank == "genus", "Genus-level group as recorded by the source (MiFish 12S reads not resolved to species); taxonID is the genus", NA_character_)
remarks[sp == "Opsariichthys platypus"] <- "Matched on GBIF as Zacco platypus (the backbone name for this species)"
taxa <- make_taxa(code, sp, taxonRank = rank, lookupName = lookup, taxonRemarks = remarks,
                  taxon_primer_mismatches = as.integer(mismatch), allow_higher = code[rank == "genus"])
dataset <- list(
  title = "Freshwater fish eDNA metabarcoding (MiFish 12S) read counts for 50 taxa in three replicate samples at 50 sites, Lake Kasumigaura watershed, Japan, August 2017",
  creator = "Fukaya, Keiichi; Kondo, Natsuko Ito; Matsuzaki, Shin-ichiro S.; Kadoya, Taku",
  pubDate = "2021", doi = "10.5061/dryad.3bk3j9kkm", sourceURL = "https://doi.org/10.5061/dryad.3bk3j9kkm", paperDOI = "10.1111/2041-210X.13732",
  citation = "Fukaya, K., Kondo, N. I., Matsuzaki, S. S., & Kadoya, T. (2021). Data from: Multispecies site occupancy modeling and study design for spatially replicated environmental DNA metabarcoding [Data set]. Dryad. https://doi.org/10.5061/dryad.3bk3j9kkm",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Sequence read counts of 50 freshwater fish taxa (species, subspecies and genus-level groups) from eDNA metabarcoding with the MiFish-U primers of three replicate water samples at each of 50 sites in the Lake Kasumigaura watershed, Japan, August 2017, with a site covariate (riverbank without aquatic and riparian vegetation) and a per-taxon count of primer mismatches. Six samples yielded no reads and are not surveys. The authors fit a multispecies site occupancy model of the reads (site occupancy, per-replicate sequence availability, read share) and used it to weigh sites, replicates and sequencing depth in study design.",
  samplingProtocol = "Three environmental (water) samples per site collected in August 2017; DNA amplified with the universal fish primer set MiFish-U, a separate library prepared per replicate and sequenced on an Illumina MiSeq; reads assigned to fish taxa. Laboratory details are in the paper's Appendix S2.",
  samplingProtocolCode = "eDNA",
  surveyEvidence = "deposited_matrix",
  surveyEvidenceNote = "The deposited array has no NA; a replicate sample with zero reads for every taxon (six of 150) is a sample for which no sequence reads were obtained, omitted by the authors (preprint; 1_model_fitting.R sets them to NA), and has no rows. The other 144 samples carry a row for every taxon.",
  responseType = "detection", unitKind = "site",
  closure = "closed", occasionKind = "spatial", taxonInclusion = "recorded",
  closureNote = "occasion = replicate water sample taken at the site at one visit; the authors' model treats site occupancy as constant across the replicates",
  occasionCodes = list(`1` = "replicate L", `2` = "replicate C", `3` = "replicate R"),
  designNote = "E9 multi-scale eDNA form with one replication level: unit = site, occasion = replicate sample (each with its own library); the authors' read-count model is a further level that y_raw supports.",
  geographicCoverage = "Lake Kasumigaura watershed, Ibaraki Prefecture, Japan (50 sites; no coordinates deposited)",
  temporalCoverage = "2017-08/2017-08",
  notes = "y = 1 where the taxon has at least one read in the replicate sample; y_raw = the read count (no read threshold is applied by the source). Sequencing depth per sample is the sum of y_raw over the 50 taxa. The replicate labels L, C and R are not defined in the deposit or the preprint; occasion follows the deposited order. Eight taxa are genus-level groups (Carassius, Gnathopogon, Hemibarbus, Hypophthalmichthys, Misgurnus, Pseudogobio, Rhinogobius, Tridentiger: see __taxa) and Carassius cuvieri is also its own taxon, so a zero for a species does not exclude reads assigned to its genus group. taxon_primer_mismatches (in __taxa) is the authors' species covariate of read share.",
  notShipped = list(`sequencing depth` = "per-sample total reads; the sum of y_raw over taxa, not repeated",
                    `six empty samples` = "replicate samples with no reads (no sequence data obtained): not surveys, no rows"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/fukaya_2022_kasumigaura_fish_mb.R")
stage_dict_row(TABLE,
  description = "Freshwater fish community (50 taxa) detected by MiFish 12S eDNA metabarcoding in three replicate water samples at 50 sites of the Lake Kasumigaura watershed, Japan, August 2017; read counts as y_raw, riverbank vegetation site covariate, primer mismatches per taxon.",
  url = "https://doi.org/10.5061/dryad.3bk3j9kkm",
  reference = "Fukaya, K., Kondo, N. I., Matsuzaki, S. S., & Kadoya, T. (2022). Multispecies site occupancy modelling and study design for spatially replicated environmental DNA metabarcoding. Methods in Ecology and Evolution, 13(1), 183-193.",
  doi_paper = "10.1111/2041-210X.13732", doi_data = "10.5061/dryad.3bk3j9kkm",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Replicate samples as occasions within sites; six samples without reads have no rows. Analysis scripts are a separate MIT Zenodo record (doi:10.5281/zenodo.5515373), not shipped.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Fish", model_family = "Community occupancy (eDNA metabarcoding, replicate samples)",
  sampling_protocol = "eDNA", design = "Single-season (3 replicate samples per site)", realm = "Freshwater",
  country = "JPN", coordinates = "None in source",
  notes = "Read counts in y_raw support read-count occupancy models; eight genus-level taxa.")
