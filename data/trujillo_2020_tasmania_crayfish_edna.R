#!/usr/bin/env Rscript
# Table:  trujillo_2020_tasmania_crayfish_edna  (stream site > water sample > qPCR replicate; giant
#         freshwater crayfish Astacopsis gouldi, six streams in northern Tasmania, November 2019)
# Source: Zenodo record 4692079, doi:10.5281/zenodo.4692079, version 1 (published 2020-11-26); licence
#         as shown on the record: CC BY 4.0 (asserted from the API). Trujillo, A., Hinlo, R., Godwin, S.,
#         Barmuta, L. A., Watson, A., Koch, A., Turner, P. and Gleeson, D. (2020). Environmental DNA
#         detection of the giant freshwater crayfish (Astacopsis gouldi) [Data set]. Zenodo.
# Paper:  Trujillo-Gonzalez, A., Hinlo, R., Godwin, S., Barmuta, L., Watson, A., Koch, A., Turner, P. and
#         Gleeson, D. (2021). Environmental DNA detection of the giant freshwater crayfish (Astacopsis
#         gouldi). Environmental DNA 3(5): 950-958. doi:10.1002/edn3.204. Read (sections 2.3, 2.4, 3.2):
#         eight 1 L samples and one 1 L field control (sterile bottle of UV-filtered water opened at the
#         site) per stream site; five streams with known A. gouldi populations and one (West Arm Creek)
#         with none known; two captive facilities (Lobster Ponds Haven tanks, Huon Aquaculture trough);
#         samples run in triplicate; "We considered samples as positive if amplification crossed a
#         common threshold determined individually within each qPCR run and if detections had CT values
#         <= 55 in any of the replicates"; positive replicates confirmed by Sanger sequencing. Results
#         count 24 qPCR replicates per site (Lowries Creek 4/24, Minnow Creek 3/24, Agro tank 2/24),
#         which this table reproduces.
# Data as deposited (Zenodo):
#   Amplification metadata.xlsx (Supplementary S1): sheet Metadata (authors, the detection rule
#     above); CONCATENATED (336 well rows: Sample Name, CT, Ct Mean, Ct SD, copy no, ...), the stack
#     of the four run sheets; run sheets 2020-04-30_crayfish eDNA (96 wells), 2020-05-01_crayfish
#     eDNA (96), 2020-05-01_2_crayfish eDNA (96), 2020-05-26_crayfish eDNA (48, captive samples
#     only, neat and 1:10); Standard curve. Sample Name = "Site <code>-<stream> <k>", k = 1-4.
#     QUIRK: sheet 2020-05-01_2 is a second copy of run 2020-04-30: same run end time
#     (2020-05-01 08:59:59), and all 96 wells have the same position, sample name and CT (asserted).
#     It is counted once. Each field sample then has 6 wells (3 in each of two runs), 24 per site,
#     the paper's denominator. Minnow River is spelled "IW-Minnow river" in one run and
#     "IW- Minnow River" in the other.
#   Inhibition tests metadata.xlsx (Supplementary S2): duplicate neat / 1:10 / spiked inhibition
#     tests (sample quality control, not detections; not shipped).
# AUTHOR-SUPPLIED FILES (A. Trujillo-Gonzalez, email to Ben 2026-11-11), staged at
#   .cache/author_supplied/trujillo_crayfish/ (not public; md5s asserted below):
#   "Amplification metadata.xlsx": the same workbook as the deposit (every sheet identical, asserted).
#     The email says CONCATENATED column A names "each site and associated replicate code" and that
#     each row is a site|replicate collected during the study: this settles that k = 1-4 is the field
#     sample within the site, the reason the deposit was held (queue/human_review.csv, 2026-11-02).
#   "TAS_GFC project 2020_Metadata.xlsx" (135 rows): one row per bottle or blank: location, sample
#     identifier (S1P, SA, SD, S1V, S1W.1, S UBR + 1-8 for stream samples; EB = equipment blank;
#     FC = field control), latitude / longitude (to 1e-5 to 1e-6 degree), "Positive Site" /
#     "Negative Site", collection and filtering dates, filter volumes. It lists eight water samples
#     per stream site; the amplification data has four per site, and neither file nor the paper says
#     which four of the eight were amplified (or whether bottles were pooled). Used here only for
#     what is constant within a site: coordinates, collection date, and the site label.
# Mapping (standard E9 experimental multi-scale / eDNA): cluster_id = stream site, as the deposit's
#   code (1P, A, D, IV, IW, UBR); unit = water sample, "<code>_<k>"; occasion = qPCR replicate 1-6
#   (1-3 = wells of run 2020-04-30 in plate order, 4-6 = run 2020-05-01); taxon = ASTGOU.
#   y = 1 where the well has a CT (the authors' call: crossed the run threshold, CT <= 55; every CT
#   in the field wells is <= 55, asserted), 0 where "Undetermined"; y_raw = CT as deposited.
#   surveyEvidence = deposited_matrix: every sample has three wells in each of the two runs.
#   date = the site's collection date (2019-11-07 or -08). obs_qpcr_run = run date.
#   obs_blank_positive (ruling 2026-11-06): field controls were run only for two sites. "FC SA" is
#   Site A's (the metadata codes Site A bottles "SA"); it amplified in 2 of 6 wells (CT 37.2, 37.7).
#   "FC NEG" / "FC Neg" is read as the field control of the negative site, UBR (labelled "Negative
#   Site"; the only other field control run); it amplified in 1 of 6 wells (CT 38.6). Both sites'
#   rows carry 1; every other row 0 (the field controls of 1P, D, IV and IW were not run).
#   The FC NEG -> UBR reading is an inference from the labels; it is in notes.
#   unit_known_population = 1 at the five streams the paper and the metadata call positive sites
#   (A. gouldi populations known before the survey), 0 at UBR (none known): a design fact, not an
#   estimate. unit_decimalLatitude / unit_decimalLongitude: site coordinates coarsened to 0.1 degree.
#   Astacopsis gouldi is IUCN EN (asserted from the IUCN check in make_taxa's lookup, see below),
#   endemic to northern Tasmania, so E7 coarsening applies and (E7.4) stream names are not shipped.
# Not shipped: the captive samples (four Lobster Ponds Haven tanks, three Huon Aquaculture trough
#   samples, their neat / 1:10 re-runs on 2020-05-26): captive animals of known presence, not a
#   survey of a wild population; lab controls (NTC, positive controls, the standard curve); the
#   duplicate run sheet; stream names (E7.4); per-sample filter volumes and equipment blanks (the
#   metadata's samples 1-8 cannot be matched to the amplified samples 1-4); Ct Mean, Ct SD and copy
#   number (per-sample summaries of the shipped CTs, and a standard-curve estimate); the inhibition
#   tests.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "trujillo_2020_tasmania_crayfish_edna"
SCRIPT <- "data/trujillo_2020_tasmania_crayfish_edna.R"
REC <- "4692079"
zen <- function(key) download_cached(sprintf("https://zenodo.org/api/records/%s/files/%s/content", REC, URLencode(key, reserved = TRUE)), TABLE, filename = key)
meta_f <- file.path(RAW_DIR, TABLE, "zenodo_record.json"); dir.create(dirname(meta_f), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(meta_f)) download.file(paste0("https://zenodo.org/api/records/", REC), meta_f, quiet = TRUE, headers = c("User-Agent" = UA))
meta <- jsonlite::fromJSON(meta_f)
stopifnot(identical(meta$metadata$license$id, "cc-by-4.0"), identical(meta$doi, "10.5281/zenodo.4692079"),
          identical(meta$metadata$publication_date, "2020-11-26"),
          setequal(meta$files$key, c("Amplification metadata.xlsx", "Inhibition tests metadata.xlsx")))
amp_f <- zen("Amplification metadata.xlsx")
invisible(zen("Inhibition tests metadata.xlsx"))
read_x <- function(f, s) as.data.table(suppressMessages(readxl::read_excel(f, s, col_names = FALSE, col_types = "text")))

# --- author-supplied files (A. Trujillo-Gonzalez, 2026-11-11) ---
AUTH <- file.path(dirname(RAW_DIR), "author_supplied", "trujillo_crayfish")
auth_f <- file.path(AUTH, c("Amplification metadata.xlsx", "TAS_GFC project 2020_Metadata.xlsx"))
if (!all(file.exists(auth_f)))
  stop("Author-supplied files missing: ", paste(auth_f[!file.exists(auth_f)], collapse = ", "),
       ". A. Trujillo-Gonzalez sent them to Ben on 2026-11-11 and they are not public; ask Ben for them.")
stopifnot(identical(unname(tools::md5sum(auth_f)), c("013ca15f2c16d0b1e55086836f616283", "857cc4326d4a07235ba69544e9003700")))
sheets <- readxl::excel_sheets(amp_f)
stopifnot(identical(sheets, c("Metadata", "CONCATENATED", "2020-04-30_crayfish eDNA", "2020-05-01_crayfish eDNA",
                              "2020-05-01_2_crayfish eDNA", "2020-05-26_crayfish eDNA", "Standard curve")),
          identical(readxl::excel_sheets(auth_f[1]), sheets),
          all(vapply(sheets, function(s) identical(read_x(amp_f, s), read_x(auth_f[1], s)), logical(1))))
md <- read_x(amp_f, "Metadata")
stopifnot(any(grepl("detections had CT values ≤ 55 in any of the replicates", unlist(md), fixed = TRUE)))

# --- run sheets: header row, then wells ---
run_sheet <- function(s) {
  x <- read_x(amp_f, s)
  h <- which(x[[1]] %in% c("Well Position", "Sample Name"))[1]
  hdr <- unlist(x[h]); y <- x[(h + 1):nrow(x)]
  end <- x[[2]][which(x[[1]] == "Experiment Run End Time")]
  stopifnot(length(end) == 1L)
  data.table(sheet = s, run_end = end, well = if (hdr[1] == "Well Position") y[[1]] else NA_character_,
             name = trimws(gsub("\\s+", " ", y[[which(hdr == "Sample Name")]])), ct = y[[which(hdr == "CT")]])
}
R <- rbindlist(lapply(sheets[3:6], run_sheet))
R <- R[!is.na(name)]
stopifnot(identical(R[, .N, keyby = sheet]$N, c(96L, 96L, 96L, 48L)), !anyNA(R$ct))
# the duplicate: 2020-05-01_2 is run 2020-04-30 again
r1 <- R[sheet == sheets[3]]; r2 <- R[sheet == sheets[5]]
stopifnot(identical(unique(r1$run_end), "2020-05-01 08:59:59 AM EST"), identical(unique(r2$run_end), unique(r1$run_end)),
          identical(r1[, .(well, name, ct)], r2[, .(well, name, ct)]))
R <- R[sheet != sheets[5]]
# stack check: CONCATENATED holds the four run sheets (the duplicate included)
cc <- read_x(amp_f, "CONCATENATED")
stopifnot(identical(cc[[1]][1], "Sample Name"), nrow(cc) == 337L)

# --- field samples ---
R[, name := sub("IW-Minnow river", "IW- Minnow River", name, fixed = TRUE)]
S <- R[startsWith(name, "Site ")]
S[, code := sub("^Site ([0-9A-Z]+)-.*$", "\\1", name)]
S[, k := as.integer(sub("^.* ([1-4])$", "\\1", name))]
stopifnot(setequal(S$code, c("1P", "A", "D", "IV", "IW", "UBR")), !anyNA(S$k),
          identical(S[, .N, keyby = sheet]$N, c(72L, 72L)),
          S[, .N, by = .(code, k, sheet)][, all(N == 3L) && .N == 48L],
          S[, uniqueN(sub(" [1-4]$", "", name)), by = code][, all(V1 == 1L)])
S[, ctn := suppressWarnings(as.numeric(ct))]
stopifnot(all(S$ct == "Undetermined" | !is.na(S$ctn)), all(S$ctn <= 55, na.rm = TRUE))
S[, y := as.integer(!is.na(ctn))]
# the paper's counts per site (out of 24): Lowries Creek (1P) 4, Minnow (IW) 3, West Arm Creek (UBR) 0
pos <- S[, .(n = .N, pos = sum(y)), keyby = code]
stopifnot(all(pos$n == 24L), identical(pos$pos, c(4L, 18L, 13L, 15L, 3L, 0L)))
S[, run := fifelse(sheet == sheets[3], 1L, 2L)]
setorder(S, code, k, run, well)
S[, occasion := seq_len(.N), by = .(code, k)]
S[, rows_well := paste0(substr(well, 1, 1), sprintf("%02d", as.integer(substring(well, 2))))]
stopifnot(S[, all(occasion == (run - 1L) * 3L + rank(rows_well)), by = .(code, k, run)]$V1)

# --- field controls and other samples in the runs ---
fc <- R[startsWith(name, "FC ")]
fc[, ctn := suppressWarnings(as.numeric(ct))]
stopifnot(identical(fc[, .N, keyby = .(n = toupper(name))]$N, c(6L, 6L)),
          identical(fc[!is.na(ctn), .(name, sheet, round(ctn, 1))],
                    data.table(name = c("FC Neg", "FC SA", "FC SA"), sheet = sheets[4], V3 = c(38.6, 37.2, 37.7))))
other <- R[!startsWith(name, "Site ") & !startsWith(name, "FC ")]
stopifnot(all(grepl("^(NTC|pos|POS 269[fF]|Lobster ponds-|LP |Huon Aqua Farm-)", other$name)))

# --- site metadata (author-supplied) ---
sm <- as.data.table(suppressMessages(readxl::read_excel(auth_f[2])))
stopifnot(nrow(sm) == 135L, sum(sm[["Sample Type"]] == "Environmental Water", na.rm = TRUE) == 51L)
st <- sm[!is.na(`Location Identifier`) & startsWith(`Location Identifier`, "Site")]
st[, code := c("Site 1P" = "1P", "Site A" = "A", "Site D" = "D", "Site IV" = "IV", "Site IW.1" = "IW",
               "Site West Arm Creek on Upper Bridge Road (UBR)" = "UBR")[`Location Identifier`]]
stopifnot(!anyNA(st$code), identical(st[`Sample Type` == "Environmental Water", .N, keyby = code]$N, rep(8L, 6)),
          st[, .(uniqueN(Latitude), uniqueN(Longitude), uniqueN(`Collection Date`), uniqueN(NOTES)), by = code][, all(V1 == 1L & V2 == 1L & V3 == 1L & V4 == 1L)])
site <- unique(st[, .(code, lat = Latitude, lon = Longitude, date = as.character(as.Date(`Collection Date`)), label = NOTES)])
stopifnot(nrow(site) == 6L, all(site$lat %between% c(-42, -40.5)), all(site$lon %between% c(145, 149)),
          setequal(site$date, c("2019-11-07", "2019-11-08")),
          identical(site[order(code), label], c(rep("Positive Site", 5), "Negative Site")),
          identical(sort(unique(st[grepl("^SA ", `Sample Identifier`), code])), "A"))
crd <- coarsen_coords(site$lat, site$lon)
site[, `:=`(clat = crd$lat, clon = crd$lon)]
# 1P and A carry identical coordinates in the metadata (to 1e-6 degree; two different streams): kept, and noted
stopifnot(site[code == "1P", .(lat, lon)][, identical(unlist(.SD), unlist(site[code == "A", .(lat, lon)]))],
          uniqueN(site[, .(lat, lon)]) == 5L, uniqueN(site[, .(clat, clon)]) == 4L)   # 1P, A, D share a 0.1-degree cell
S <- merge(S, site, by = "code")
S[, unit := paste0(code, "_", k)]

long <- S[, .(unit, taxon = "ASTGOU", occasion, y, y_raw = ct, date, cluster_id = code,
              obs_qpcr_run = fifelse(run == 1L, "2020-04-30", "2020-05-01"),
              obs_blank_positive = as.integer(code %in% c("A", "UBR")),
              unit_known_population = as.integer(label == "Positive Site"),
              unit_decimalLatitude = clat, unit_decimalLongitude = clon)]
long <- order_eco(long)
stopifnot(nrow(long) == 144L, uniqueN(long$unit) == 24L, uniqueN(long$cluster_id) == 6L, sum(long$y) == 53L,
          long[, .N, by = unit][, all(N == 6L)])

taxa <- make_taxa("ASTGOU", "Astacopsis gouldi", vernacularName = "Giant freshwater crayfish")
iucn <- iucn_category(taxa$taxonID, taxa$scientificName)
message("  IUCN category: ", iucn)
stopifnot(identical(unname(iucn), "EN"))

coarse_note <- "Site coordinates (to 1e-5 to 1e-6 degree in the authors' sampling metadata) coarsened to 0.1 degree with coarsen_coords(): Astacopsis gouldi is IUCN EN in its native range (northern Tasmania). Stream names not shipped (E7.4); cluster_id is the deposit's site code."
dataset <- list(
  title = "Giant freshwater crayfish eDNA: six qPCR replicates of four water samples at each of six northern Tasmanian streams, November 2019",
  creator = "Trujillo, Alejandro; Hinlo, Rheyda; Godwin, Sam; Barmuta, Leon A.; Watson, Anne; Koch, Amy; Turner, Perpetua; Gleeson, Dianne",
  pubDate = "2020", doi = "10.5281/zenodo.4692079", sourceURL = "https://doi.org/10.5281/zenodo.4692079",
  citation = "Trujillo, A., Hinlo, R., Godwin, S., Barmuta, L. A., Watson, A., Koch, A., Turner, P., & Gleeson, D. (2020). Environmental DNA detection of the giant freshwater crayfish (Astacopsis gouldi) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.4692079",
  paperDOI = "10.1002/edn3.204",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/",
                            note = "Zenodo record licence. Site coordinates and dates come from the authors' sampling metadata, sent by A. Trujillo-Gonzalez on 2026-11-11 for this purpose; not in the public record."),
  abstract = "Water samples from five northern Tasmanian streams with known populations of the endangered giant freshwater crayfish and one stream with none known, tested with a species-specific TaqMan qPCR assay. Four 1 L samples per stream were amplified in three wells in each of two runs (six qPCR replicates). The authors called a well positive if it crossed the run threshold with CT <= 55 and confirmed positives by Sanger sequencing. Detections came from all five known-population streams and none from the sixth. cluster_id = stream site, unit = water sample, occasion = qPCR replicate.",
  samplingProtocol = "Environmental DNA: eight 1 L surface water samples and one 1 L field control per stream, about 50 cm from opposing banks along about 100 m, upstream direction; filtered within 24 h on 1.2 um cellulose nitrate (two or three filters per sample, an equipment blank before each), DNeasy extraction, inhibition screening (neat, 1:10, spiked); TaqMan assay 269F/489R/292P (COI, 219 bp), 55 cycles; three wells per sample per run, two runs. Four samples per stream appear in the amplification data.",
  samplingProtocolCode = "eDNA", responseType = "detection", unitKind = "site",
  closure = "closed", closureNote = "occasion = six qPCR replicates of one water sample's extract; samples nest in stream sites (cluster_id); one visit per site",
  occasionKind = "spatial", taxonInclusion = "single", surveyEvidence = "deposited_matrix",
  temporalCoverage = "2019-11-07/2019-11-08",
  geographicCoverage = "Six streams in northern Tasmania, Australia (about 40.9 to 41.5 S, 146 to 148 E); coordinates coarsened to 0.1 degree",
  coordinatesCoarsened = list(value = TRUE, method = coarse_note, rule = "taxon"), crs = "EPSG:4326",
  designNote = "Experimental list of E9 (multi-scale / eDNA): cluster_id = stream site, unit = water sample, occasion = qPCR replicate.",
  notShipped = list(
    captive_samples = "Lobster Ponds Haven tanks (Agro, Bazza, Danny, Max) and the Huon Aquaculture trough (three samples), with their neat and 1:10 re-runs of 2020-05-26: captive animals of known presence (the paper's assay validation), not a survey of a wild population",
    duplicate_run_sheet = "sheet 2020-05-01_2_crayfish eDNA, a second copy of run 2020-04-30 (same run end time and all 96 wells identical); CONCATENATED stacks it too, so it counts every field well of that run twice",
    lab_controls = "no-template controls, positive controls (POS 269F, pos) and the standard curve",
    site_names = "stream names (E7.4: coordinates are coarsened for an endangered species)",
    sample_volumes_and_equipment_blanks = "per-sample filter volumes and equipment blanks in the authors' sampling metadata: it lists eight samples per site, numbered 1-8, and does not say which four were amplified",
    ct_summaries = "Ct Mean, Ct SD and copy number per sample (summaries of the shipped CTs; copy number is a standard-curve estimate)",
    inhibition_tests = "Inhibition tests metadata.xlsx: neat / 1:10 / spiked inhibition screening of each extract (quality control)"),
  notes = "The authors' detection rule (crossed the run threshold, CT <= 55) is y; every CT in the field wells is <= 55, so it equals any amplification; y_raw is the CT as deposited. Many positive wells have CT above the paper's LOD (CT 41); positives were confirmed by Sanger sequencing. Per-site positives out of 24 wells match the paper (Lowries Creek 4/24, Minnow 3/24, none at the negative site). The amplification data has four samples per site and the sampling metadata eight; which four were amplified is not stated. obs_blank_positive: only two field controls were run. 'FC SA' (Site A, the metadata's code) amplified in 2 of 6 wells (CT 37.2, 37.7). 'FC NEG' amplified in 1 of 6 wells (CT 38.6); it is read as the field control of the negative site (UBR), an inference from its label. Field controls of the other four sites were not run, so 0 there means not tested, not clean. Site coordinates and collection dates are from the authors' sampling metadata (sent 2026-11-11, not in the public record). In that metadata Site 1P (Lowries Creek) and Site A (Great Forester River) have identical coordinates to 1e-6 degree, probably one copied from the other; both are shipped as given, and at 0.1 degree they fall in the same cell as Site D.")

ds <- write_table(long, TABLE, dataset, taxa = taxa, script = SCRIPT)
stage_dict_row(TABLE,
  description = "Environmental DNA survey of the endangered giant freshwater crayfish (Astacopsis gouldi) in six northern Tasmanian streams, November 2019: six qPCR replicates of four water samples per stream, five streams with known populations and one without; coordinates coarsened.",
  url = "https://doi.org/10.5281/zenodo.4692079",
  reference = "Trujillo-Gonzalez, A., Hinlo, R., Godwin, S., Barmuta, L., Watson, A., Koch, A., Turner, P., & Gleeson, D. (2021). Environmental DNA detection of the giant freshwater crayfish (Astacopsis gouldi). Environmental DNA, 3(5), 950-958.",
  doi_paper = "10.1002/edn3.204", doi_data = "10.5281/zenodo.4692079",
  original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Multi-scale eDNA (cluster_id stream, unit water sample, occasion qPCR replicate); a duplicated run sheet in the deposit counted once; site coordinates and dates from the authors' sampling metadata (sent 2026-11-11); coordinates coarsened, stream names withheld (IUCN EN).",
  source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Invertebrates", model_family = "Multi-scale occupancy (stream > sample > qPCR replicate, eDNA)",
  sampling_protocol = "eDNA", design = "Single-season (one visit, 4 samples per stream, 6 qPCR replicates)", realm = "Freshwater",
  country = "Australia", coordinates = "Coarsened (0.1 deg)",
  notes = "Endangered Tasmanian crayfish; one stream with no known population; captive validation samples not shipped.")
