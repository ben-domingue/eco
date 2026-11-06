#!/usr/bin/env Rscript
# Tables: glorioso_2026_bayouteche_hsqu_cjs, glorioso_2026_bayouteche_hchr_cjs,
#         glorioso_2026_bayouteche_hcin_cjs, glorioso_2026_bayouteche_pcru_cjs
# Source: USGS ScienceBase doi:10.5066/P97QPY0E (USGS data release, published 2026-01-14; use
#         constraints "None"; US public domain, recorded as CC0 1.0)
#   Glorioso, B.M., and Waddle, J.H., 2026, Data from a capture-mark-recapture survey of native
#   treefrogs in Bayou Teche National Wildlife Refuge, Louisiana from 2017 to 2023: U.S.
#   Geological Survey data release.
# Data:   the release built as glorioso_2026_bayouteche_pipe_count (see that script for the pipe
#         and survey files). Sample Data.csv: 248 site surveys, one a month at each of four sites
#         (October 2017 to May 2023), two of them (2019-07-18 at North Bend West and Centerville)
#         abandoned for flooding. Frog Capture Data.csv: 8,290 treefrog captures in the pipes:
#         sample id, pipe, species code (HSQU Hyla squirella, HCHR H. chrysoscelis, HCIN H. cinerea,
#         PCRU Pseudacris crucifer), alphanumeric tag number and colour (orange, green: a frog's
#         identity is the pair), Recap Y/N, sex (U/F/M), SVL (mm) and comments. Asserted: two
#         untagged rows ("frog died before it was tagged"); two rows of one tag-sample (W92 orange,
#         put on an HSQU and an HCHR the same day); three tags recorded under two species (L94,
#         W92, V58 orange); every tag is recorded at one site only; no capture comes from a flooded
#         survey.
# Mapping: one table per species (ruling #20). unit = the frog ("<colour>_<tag>"), cluster_id =
#   its site, period = study month (1 = October 2017 ... 68 = May 2023, as in the pipe table),
#   y = captured in a pipe at that month's survey of its site. Frogs are wild-caught of unknown
#   age, so each history begins at its site's first survey (E4.4) and has a row for every survey
#   of the site while at risk; the two flooded surveys are not surveys of their sites (no rows).
#   surveyEvidence sample_table: the survey list is Sample Data.csv.
#   Removals (E4.4): a comment "found dead (in pipe) on <date>" (written on the frog's last
#   capture row, including "possibly / probably found dead ... definite tag loss on dead
#   individual that matched details") ends the history at the last survey of its site before
#   that date, obs_removed = 1 there, and unit_found_dead_date carries the date; a comment that
#   the frog was dead, or presumed dead, at release ends it at that capture (obs_removed = 1)
#   when no later capture exists. obs_ pipe, sex as recorded, SVL; unit_retagged = 1 for a
#   frog whose first capture comment records the loss of an earlier tag ("definite / possible /
#   probable tag loss, tagging R leg").
# Not shipped: the three tags with two species and the two untagged rows (identity unknown);
#   the second W92 row (the same tag on two frogs on one day; both of W92's rows go with the tag);
#   tag-condition comments. The earlier tag of a retagged frog is rarely named ("probably Y37"),
#   so the lost tag's history is not truncated at the loss (the rule that a lost mark ends the
#   history can be applied only where the old tag is known; the source's "probably" names are
#   not certain enough to act on), which biases apparent survival of those few tags low.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
CACHE <- "glorioso_2026_bayouteche_frog_cjs"
it <- fromJSON(download_cached("https://www.sciencebase.gov/catalog/item/655250cfd34ee4b6e05c3679?format=json", CACHE, filename = "item.json"))
fl <- setNames(it$files$url, it$files$name)
rd <- function(f, ...) fread(download_cached(fl[[f]], CACHE, filename = f), na.strings = c("NULL", ""), ...)
s <- rd("Sample Data.csv"); f <- rd("Frog Capture Data.csv", colClasses = list(character = c("Tag Number", "Pipe Number")))
ins <- rd("Installed.csv")
s[, d := as.IDate(Date, format = "%m/%d/%Y")]
s[, mon := (year(d) - 2017L) * 12L + month(d) - 9L]
flood <- s[grepl("could not complete survey due to extreme flooding", Comments), ID]
stopifnot(nrow(s) == 248, length(flood) == 2, nrow(f) == 8290, !anyDuplicated(s[, .(`Site Name`, mon)]))
s <- s[!ID %in% flood]
stopifnot(!any(f$`Sample ID` %in% flood), all(f$`Sample ID` %in% s$ID))
f <- merge(f, s[, .(`Sample ID` = ID, site = `Site Name`, d, mon)], by = "Sample ID")
untag <- f[is.na(`Tag Number`)]
stopifnot(nrow(untag) == 2, all(untag$Comments == "frog died before it was tagged"))
f <- f[!is.na(`Tag Number`)]
stopifnot(!anyNA(f$`Tag Color`))
f[, unit := paste0(`Tag Color`, "_", `Tag Number`)]
two_sp <- f[, uniqueN(Species), by = unit][V1 > 1, unit]
stopifnot(setequal(two_sp, c("Orange_L94", "Orange_W92", "Orange_V58")))
stopifnot(f[, anyDuplicated(.SD), .SDcols = c("unit", "Sample ID")] > 0, f[!unit %in% two_sp, !anyDuplicated(.SD), .SDcols = c("unit", "Sample ID")])
n_two <- nrow(f[unit %in% two_sp]); stopifnot(n_two == 8)
f <- f[!unit %in% two_sp]
stopifnot(f[, uniqueN(site), by = unit][, all(V1 == 1)])
f[is.na(Comments), Comments := ""]
# removals
dd <- regmatches(f$Comments, regexec("found dead (?:in pipe (?:\\d+ )?|in plastic bag )?on (\\d{1,2}/\\d{1,2}/\\d{2,4})", f$Comments, perl = TRUE))
f[, dead_txt := vapply(dd, function(x) if (length(x)) x[2] else NA_character_, "")]
f[, dead_d := as.IDate(ifelse(nchar(sub(".*/", "", dead_txt)) == 2, format(as.IDate(dead_txt, format = "%m/%d/%y")),
                              format(as.IDate(dead_txt, format = "%m/%d/%Y"))))]
stopifnot(all(is.na(f$dead_txt) == is.na(f$dead_d)))
f[grepl("found dead on 03/09/20 in pipe", Comments), dead_d := as.IDate("2020-03-09")]
stopifnot(sum(grepl("found dead", f$Comments)) == sum(!is.na(f$dead_d)))
dead <- f[!is.na(dead_d), .(dead_d = unique(dead_d), last_cap = max(f$d[f$unit == .BY$unit])), by = unit]
stopifnot(!anyDuplicated(dead$unit), all(dead$dead_d > dead$last_cap))
f[, rel_dead := grepl("dead at release|presumed dead$|appears dead, left on pipe", Comments) & is.na(dead_d)]
f[, last := d == max(d), by = unit]
n_rel_dead_later <- f[rel_dead & !last, .N]
reldead <- f[rel_dead & last, .(unit, rel_d = d)]
f[, retag := grepl("tag loss", Comments) & !grepl("on dead individual", Comments)]
first_retag <- f[order(d)][, .(retag = retag[1]), by = unit]
stopifnot(nrow(dead) == 225, nrow(reldead) == 23, n_rel_dead_later == 1, sum(first_retag$retag) == 222)
long_all <- list()
sites <- s[, .(site = `Site Name`, ID, d, mon)]
for (sp in c("HSQU", "HCHR", "HCIN", "PCRU")) {
  fs <- f[Species == sp]
  frogs <- unique(fs[, .(unit, site)])
  g <- merge(frogs, sites, by = "site", allow.cartesian = TRUE)
  g <- merge(g, dead[, .(unit, dead_d)], by = "unit", all.x = TRUE)
  g <- merge(g, reldead, by = "unit", all.x = TRUE)
  g <- g[(is.na(dead_d) | d < dead_d) & (is.na(rel_d) | d <= rel_d)]
  g <- merge(g, fs[, .(unit, ID = `Sample ID`, pipe = `Pipe Number`, sex = Sex, svl = SVL)], by = c("unit", "ID"), all.x = TRUE)
  g[, y := as.integer(!is.na(pipe))]
  stopifnot(sum(g$y) == nrow(fs))
  g <- g[order(unit, mon)]
  g[, removed := as.integer((!is.na(dead_d) | !is.na(rel_d)) & mon == max(mon)), by = unit]
  g <- merge(g, first_retag, by = "unit")
  long <- g[, .(unit, taxon = sp, y, period = mon, date = format(d), cluster_id = site,
                unit_retagged = as.integer(retag), unit_found_dead_date = ifelse(is.na(dead_d), NA_character_, format(dead_d)),
                obs_pipe = pipe, obs_sex = sex, obs_svl_mm = svl, obs_removed = removed)]
  long_all[[sp]] <- long
}
stopifnot(sum(sapply(long_all, function(x) sum(x$y))) == nrow(f), sum(sapply(long_all, function(x) uniqueN(x$unit))) == uniqueN(f$unit))
mons <- data.table(period = 1:68)[, `:=`(year = 2017L + (period + 8L) %/% 12L, month = (period + 8L) %% 12L + 1L)]
nm <- c(HSQU = "Hyla squirella", HCHR = "Hyla chrysoscelis", HCIN = "Hyla cinerea", PCRU = "Pseudacris crucifer")
vn <- c(HSQU = "Squirrel treefrog", HCHR = "Cope's gray treefrog", HCIN = "Green treefrog", PCRU = "Spring peeper")
cat(sprintf("removed: found dead later %d, dead at release %d (later recaptured %d); retagged %d\n",
            nrow(dead), nrow(reldead), n_rel_dead_later, sum(first_retag$retag)))
for (sp in names(long_all)) {
  long <- long_all[[sp]]; TABLE <- sprintf("glorioso_2026_bayouteche_%s_cjs", tolower(sp))
  taxa <- make_taxa(sp, nm[[sp]], vernacularName = vn[[sp]])
  taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
  stopifnot(!any(taxa$taxon_iucnCategory %in% c("CR", "EN", "VU")))
  periods <- mons[period %in% long$period]
  nu <- uniqueN(long$unit)
  dataset <- list(
    title = sprintf("Capture histories of %s tagged %s in PVC pipe refugia at four sites, Bayou Teche National Wildlife Refuge, Louisiana, 2017-2023",
                    format(nu, big.mark = ","), tolower(vn[[sp]])),
    creator = "Glorioso, Brad M.; Waddle, J. Hardin",
    pubDate = "2026", doi = "10.5066/P97QPY0E", sourceURL = "https://doi.org/10.5066/P97QPY0E",
    citation = "Glorioso, B.M., and Waddle, J.H., 2026, Data from a capture-mark-recapture survey of native treefrogs in Bayou Teche National Wildlife Refuge, Louisiana from 2017 to 2023: U.S. Geological Survey data release, https://doi.org/10.5066/P97QPY0E.",
    intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/", note = "USGS data release; US public domain (use constraints: none)"),
    abstract = "Treefrogs sheltering in 200 PVC pipes hung on trees at four sites in Bayou Teche National Wildlife Refuge, Louisiana, were tagged with alphanumeric elastomer tags and recaptured on monthly pipe checks from October 2017 to May 2023.",
    samplingProtocol = "Each month all four sites were visited and each of 50 PVC pipes per site was checked; frogs inside were identified, sexed where possible, measured (SVL), given an alphanumeric tag on first capture and released.",
    samplingProtocolCode = "pvc_pipe", surveyEvidence = "sample_table", responseType = "detection", unitKind = "individual",
    closure = "none", occasionKind = "none", taxonInclusion = "single",
    closureNote = "Open population; one survey per site per study month. A frog's rows are its site's surveys.",
    geographicCoverage = list(description = "Bayou Teche National Wildlife Refuge, St. Mary Parish, Louisiana, USA",
                              boundingBox = list(west = min(ins$Longitude), east = max(ins$Longitude), south = min(ins$Latitude), north = max(ins$Latitude))),
    temporalCoverage = "2017-10/2023-05",
    notShipped = list(two_species_tags = sprintf("%d captures of three tags (orange L94, W92, V58) recorded under two species", n_two),
                      untagged = "two frogs that died before being tagged",
                      tag_condition = "comments on tag condition (flipped, obscure, bloody) other than loss and death"),
    notes = paste("Removals: a frog later found dead in a pipe ends at its site's last survey before that date (obs_removed = 1, unit_found_dead_date);",
                  "one dead or presumed dead at release ends at that capture. Most deaths are from the February 2021 freeze.",
                  "unit_retagged = 1: the frog's first capture records the loss of an earlier tag; that earlier tag's history is not truncated because the source rarely names it."))
  ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/glorioso_2026_bayouteche_frog_cjs.R")
  stage_dict_row(TABLE,
    description = sprintf("Monthly capture histories of %s tagged %s in PVC pipe refugia at four sites in Bayou Teche National Wildlife Refuge, Louisiana, October 2017 to May 2023, with sex, SVL and deaths.", format(nu, big.mark = ","), tolower(vn[[sp]])),
    url = "https://doi.org/10.5066/P97QPY0E",
    reference = "Glorioso, B.M., and Waddle, J.H. (2026). Data from a capture-mark-recapture survey of native treefrogs in Bayou Teche National Wildlife Refuge, Louisiana from 2017 to 2023. U.S. Geological Survey data release.",
    doi_data = "10.5066/P97QPY0E", original_license = "US public domain (USGS data release)", derived_license = "CC0 1.0",
    notes = "CJS per species; companion of glorioso_2026_bayouteche_pipe_count (same surveys).", source_via = "USGS ScienceBase")
  stage_tag_row(TABLE, ds, taxon_group = "Amphibians", model_family = "CJS", sampling_protocol = "pvc_pipe",
    design = "Multi-session (62 monthly surveys)", realm = "Terrestrial", country = "USA", coordinates = "None in source",
    notes = "Artificial refugia (PVC pipes); elastomer alphanumeric tags.")
}
