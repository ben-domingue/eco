#!/usr/bin/env Rscript
# Table:  chanex_2026_swissalps_amph_count
# Source: Zenodo record 19856651, doi:10.5281/zenodo.19856651 (version 1.0.0, May 2026; licence as shown on the record
#         and in the README: Creative Commons Attribution 4.0 International).
#   Chanex, A. (2026). The ecological potential of snow-making reservoirs for amphibians in the Swiss Alps (1.0.0)
#   [Data set]. Zenodo. (Authors in the README: Arnaud Chanex, Benedikt R. Schmidt, Clara Zemp; Master thesis,
#   University of Neuchatel, 2026.)
# Data:   amphibian_data_snowmaking_reservoirs.zip (1.1 GB, mostly map layers and photos); only README.txt and
#         data/raw_data/raw_counts.csv and raw_cov.csv were read, by HTTP range requests on the zip's central
#         directory. raw_counts.csv: 79 water bodies x 4 visits (June-August 2025, two visits on each of two days):
#         counts of adults of Rana temporaria, Bufo bufo and Ichthyosaura alpestris, egg clutches / strings, tadpoles,
#         larvae and juveniles (some as ranges such as "1000+"), turbidity, start time, duration, date (dd.mm; one visit 17-06; one duration entered as a clock time, 18h15, shipped NA).
#         raw_cov.csv: vegetation cover (%), fish (YES / NO), water-body type (Reservoir / artificial / natural), latitude
#         and longitude (WGS84). The final_ files drop two sites "during cleaning" without a stated reason; the raw
#         files are used. Asserted: 79 sites in both files, adult counts all non-negative integers, dates parse.
# Mapping: community repeated counts. unit = water body (Site code), occasion = visit 1-4 (in date order), date =
#   2025 + dd.mm, taxon = RANTEM / BUFBUF / ICHALP, y = adults counted. surveyEvidence deposited_matrix (every site has
#   all four visits with a count for every species). obs_turbidity_pct, obs_start_time, obs_duration_min;
#   unit_type, unit_fish, unit_veg_cover_pct, unit_decimalLatitude / Longitude (as published; no taxon CR / EN / VU).
# Not shipped: eggs, tadpoles, larvae and juveniles (several recorded as ranges, and egg clutches only on two visits
#   for Rana); the reservoir-only files (a subset of the same surveys) and the authors' derived covariates.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "chanex_2026_swissalps_amph_count"
rec <- fromJSON(download_cached("https://zenodo.org/api/records/19856651", TABLE, "record.json"))
stopifnot(identical(rec$metadata$license$id, "cc-by-4.0"))
# the deposit is one 1.1 GB zip; the two raw files are extracted by range requests (python3, stdlib) into the cache
dir <- file.path(RAW_DIR, TABLE)
need <- c("raw_counts.csv", "raw_cov.csv")
if (!all(file.exists(file.path(dir, need)))) {
  py <- file.path(dir, "rzip.py")
  writeLines(c("import urllib.request,zipfile,io,sys",
               "UA={'User-Agent':'eco (https://github.com/ben-domingue/eco)'}",
               "class H(io.RawIOBase):",
               "    def __init__(s,u):",
               "        s.u=u; r=urllib.request.urlopen(urllib.request.Request(u,headers=UA,method='HEAD')); s.n=int(r.headers['Content-Length']); s.p=0",
               "    def seekable(s): return True",
               "    def readable(s): return True",
               "    def tell(s): return s.p",
               "    def seek(s,o,w=0):",
               "        s.p = o if w==0 else (s.p+o if w==1 else s.n+o); return s.p",
               "    def readinto(s,b):",
               "        if s.p>=s.n: return 0",
               "        e=min(s.n,s.p+len(b))-1",
               "        d=urllib.request.urlopen(urllib.request.Request(s.u,headers=dict(UA,Range='bytes=%d-%d'%(s.p,e)))).read()",
               "        b[:len(d)]=d; s.p+=len(d); return len(d)",
               "z=zipfile.ZipFile(io.BufferedReader(H(sys.argv[1]),buffer_size=1<<16))",
               "for n in sys.argv[3:]: open(sys.argv[2]+'/'+n.split('/')[-1],'wb').write(z.read(n))"), py)
  st <- system2("python3", c("-I", shQuote(py), shQuote("https://zenodo.org/api/records/19856651/files/amphibian_data_snowmaking_reservoirs.zip/content"),
                             shQuote(dir), paste0("amphibian_data_snowmaking_reservoirs/data/raw_data/", need)))
  stopifnot(st == 0, all(file.exists(file.path(dir, need))))
}
ct <- fread(file.path(dir, "raw_counts.csv"), colClasses = "character", na.strings = NULL)
cv <- fread(file.path(dir, "raw_cov.csv"), colClasses = "character", na.strings = NULL)
stopifnot(nrow(ct) == 79, nrow(cv) == 79, setequal(ct$Site, cv$Site), !anyDuplicated(ct$Site))
spc <- c(Rana = "RANTEM", Bufo = "BUFBUF", Ichthyo = "ICHALP")
L <- rbindlist(lapply(1:4, function(k) {
  d <- ct[, c("Site", paste0(names(spc), "_adults", k), paste0(c("Turbidity", "Start_time", "Time", "Date"), k)), with = FALSE]
  setnames(d, c("Site", names(spc), "turb", "start", "dur", "date")); d[, visit := k]
  melt(d, id.vars = c("Site", "visit", "turb", "start", "dur", "date"), variable.name = "sp", value.name = "y", variable.factor = FALSE)
}))
stopifnot(all(grepl("^[0-9]+$", L$y)), all(grepl("^[0-9]{1,2}[.-][0-9]{2}$", L$date)), sum(grepl("-", L$date)) == 3,   # one visit's date written 17-06
          sum(!grepl("^[0-9]+min[0-9]+$", L$dur)) == 3)                                                                   # one duration written as a clock time (18h15): NA
L[, d := as.IDate(sprintf("2025-%02d-%02d", as.integer(sub(".*[.-]", "", date)), as.integer(sub("[.-].*", "", date))))]
stopifnot(!anyNA(L$d), all(L$d >= as.IDate("2025-06-01") & L$d <= as.IDate("2025-08-31")))
stopifnot(L[sp == "Rana", all(diff(as.integer(d[order(visit)])) >= 0), by = Site][, all(V1)])
mins <- function(z) { m <- regmatches(z, regexec("^([0-9]+)min([0-9]+)$", z)); vapply(m, function(x) if (length(x)) as.numeric(x[2]) + as.numeric(x[3]) / 60 else NA_real_, 0) }
L <- merge(L, cv, by = "Site")
long <- L[, .(unit = Site, taxon = unname(spc[sp]), y = as.integer(y), occasion = visit, date = format(d),
              unit_type = tolower(Type), unit_fish = as.integer(Fishes == "YES"), unit_veg_cover_pct = as.numeric(Vege.coverage),
              unit_decimalLatitude = as.numeric(lat), unit_decimalLongitude = as.numeric(lon),
              obs_turbidity_pct = suppressWarnings(as.numeric(turb)), obs_start_time = sub("h", ":", start), obs_duration_min = round(mins(dur), 2))]
stopifnot(nrow(long) == 79 * 4 * 3)
taxa <- make_taxa(c("RANTEM", "BUFBUF", "ICHALP"), c("Rana temporaria", "Bufo bufo", "Ichthyosaura alpestris"),
                  vernacularName = c("Common frog", "Common toad", "Alpine newt"))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
dataset <- list(
  title = "Repeated visual-encounter counts of adult amphibians (three species) at 79 snow-making reservoirs and ponds, Swiss Alps, 2025",
  creator = "Chanex, Arnaud; Schmidt, Benedikt R.; Zemp, Clara",
  pubDate = "2026", doi = "10.5281/zenodo.19856651", sourceURL = "https://doi.org/10.5281/zenodo.19856651",
  citation = "Chanex, A. (2026). The ecological potential of snow-making reservoirs for amphibians in the Swiss Alps (1.0.0) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.19856651",
  intellectualRights = list(spdx = "CC-BY-4.0", url = "https://creativecommons.org/licenses/by/4.0/"),
  abstract = "Snow-making reservoirs, artificial ponds and natural ponds between 1,340 and 2,641 m in the Swiss Alps were each surveyed four times in June-August 2025 by visual encounter for common frogs, common toads and alpine newts, to assess the habitat value of snow-making reservoirs.",
  samplingProtocol = "Visual encounter surveys around each water body, four visits (two on each of two days) between June and August 2025; adults counted by species with water turbidity, start time and duration recorded.",
  samplingProtocolCode = "visual_encounter", surveyEvidence = "deposited_matrix", responseType = "count", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "target",
  closureNote = "occasion = visit; visits 1-2 and 3-4 were made on the same day each.",
  geographicCoverage = list(description = "Swiss Alps (cantons of Vaud, Valais, Bern, Obwalden and Lucerne), Switzerland",
                            boundingBox = list(west = min(long$unit_decimalLongitude), east = max(long$unit_decimalLongitude),
                                               south = min(long$unit_decimalLatitude), north = max(long$unit_decimalLatitude))),
  temporalCoverage = "2025-06/2025-08",
  coordinatesCoarsened = list(value = FALSE, method = "As published (WGS84, raw_cov.csv); no taxon CR, EN or VU."),
  notShipped = list(early_stages = "egg clutches / strings, tadpoles, larvae and juveniles (some recorded as ranges)",
                    subsets_and_derived = "raw_res_ and final_ files (a subset of the same surveys, and the authors' processed versions)"),
  notes = "The raw files are used; the authors' final files drop two of the 79 sites without a stated reason.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, script = "data/chanex_2026_swissalps_amph_count.R")
stage_dict_row(TABLE,
  description = "Counts of adult common frogs, common toads and alpine newts on four visual-encounter visits at 79 snow-making reservoirs, artificial ponds and natural ponds in the Swiss Alps, summer 2025.",
  url = "https://doi.org/10.5281/zenodo.19856651",
  reference = "Chanex, A., Schmidt, B. R. & Zemp, C. (2026). The ecological potential of snow-making reservoirs for amphibians in the Swiss Alps. Zenodo data set (Master thesis, University of Neuchatel).",
  doi_data = "10.5281/zenodo.19856651", original_license = "CC BY 4.0", derived_license = "CC BY 4.0",
  notes = "Raw files read from the 1.1 GB zip by range requests.", source_via = "Zenodo")
stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "N-mixture (community)", sampling_protocol = "visual_encounter",
  design = "Single season (4 visits)", realm = "Freshwater", country = "CHE", coordinates = "As published",
  notes = "Artificial (snow-making) vs natural water bodies.")
