#!/usr/bin/env Rscript
# Tables: roberts_2019_sierranevada_birds_count (all taxa, coordinates coarsened) and
#         roberts_2019_sierrane_birds_exact_count (E7.3 sibling without the VU taxon, coordinates as published)
# Source: Dryad, doi:10.5061/dryad.rm2n805, version 23126 (published 2018-12-17), licence CC0 1.0 as shown on the
#         Dryad dataset page (asserted from the dataset JSON).
# Paper:  Roberts, L. J., Burnett, R., Tietz, J. & Veloz, S. (2019). Recent drought and tree mortality effects on the
#         avian community in southern Sierra Nevada: a glimpse of the future? Ecological Applications 29(2), e01848.
#         https://doi.org/10.1002/eap.1848 (not read). Design from the Dryad abstract and file notes: avian point
#         counts in the southern Sierra Nevada, California (the Sierra Nevada Bioregional Monitoring project), points
#         on 5-point transects, transects paired into sites, one to three visits a year, 2009 to 2016.
# Data:   'data formatted for analysis_Roberts et al. 2019 EcoApps.csv' (234,229 records): one row per detection of a
#           species at a distance: PointYrID, Point, Transect, Site, Year, Rep2 (visit number across years), Rep1
#           (visit within the year; 1 or 2 in the file), Date (M/D/YYYY), DOY, TOD (decimal hours), Count, Spp
#           (4-letter AOU alpha code), Detection Cue, Distance (m at first detection), Temp (deg C), Wind (Beaufort).
#           A visit with no detection has one row with Spp '---' and Count 0 (3 visits).
#         'Site covs.Roberts et al. 2019 EcoApps.csv': 1,288 point-years at 184 points, 2010-2016: forest condition,
#           conifer die-off (GIS and field estimates, %), CWHR forest type, MaxOfVisit, latitude, longitude,
#           elevation, terrain, shrub and tree cover, basal area, snags, max DBH, pine proportion, NDWI and
#           climate (cwd, tmn, tmx) with their differences from 2009.
#         'Site covs CNRM85b / GFDLB1b / MIROC85b.csv': the same covariates with projected future temperatures (model
#           inputs for projections). 'species list.csv': the 48 species the authors modelled, with the detection
#           function chosen (model output).
# Mapping: community counts. unit = Point, cluster_id = Transect, unit_site = Site (pair of transects), period = Year
#   (1 = 2009 ... 8 = 2016), occasion = Rep1, taxon = alpha code, y = sum of Count over the species' records at the
#   visit (all distances), date (ISO, from Date), obs_tod_h, obs_temp_c, obs_wind_bft (one value per visit,
#   asserted; one visit has two TOD values, the earlier is kept). surveyEvidence = row_presence: a visit is a
#   PointYrID x Rep1 in the record file, which writes an explicit '---' row for a visit with no detection.
#   The site-covariate file's MaxOfVisit disagrees with the record file at 119 of its 1,288 point-years (and 30 of
#   its point-years have no records); the record file is believed, because it is the record of the counts made and
#   carries explicit empty visits; the counts are asserted below.
#   Site covariates (184 points only; NA elsewhere) ship as unit_ where constant across a point's years, else
#   period_ (decided per column and asserted); coordinates as unit_decimalLatitude / Longitude.
#   Taxa: codes resolved in the IBP-AOS alpha-code list (IBP-AOS-LIST21, Pyle & DeSante, via
#   github.com/trashbirdecology/bbsAssistant, downloaded to the cache); WESJ (Western Scrub-Jay, split 2016) and
#   GRAJ (Gray Jay, renamed Canada Jay) are superseded codes for single species and are given here; WEFL and SAGS
#   are slash pairs in the list (species aggregates, no GBIF key). Codes the deposit and the list do not define
#   (XX.. and X... groups, '---') get no rows; their records are counted in notShipped.
#   E7: Coccothraustes vespertinus (evening grosbeak) is IUCN VU and native here, and coordinates are finer than
#   0.1 degree, so the full table is coarsened (elevation rounded to 100 m, its residual not shipped) and the
#   _exact sibling roberts_2019_sierrane_birds_exact_count (name cut to 40 characters) omits it at published
#   precision. iucn_category() returns NA for BUOR, NOHA, PIWO, RCKI (key resolves to another genus); their
#   cached GBIF records are LC (asserted).
#   Not shipped: distances and cues per record (a distance-sampling table could be built), Rep2 and DOY (from date),
#   the future-climate covariate files (projection inputs), the species list's detection functions (model output).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "roberts_2019_sierranevada_birds_count"
EXACT <- "roberts_2019_sierrane_birds_exact_count"   # E7.3 sibling; segment cut to fit 40 characters

dir <- download_dryad("10.5061/dryad.rm2n805", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"), length(list.files(dir)) == 6L)
d <- fread(file.path(dir, "data formatted for analysis_Roberts et al. 2019 EcoApps.csv"))
sc <- fread(file.path(dir, "Site covs.Roberts et al. 2019 EcoApps.csv"))
ibp_f <- download_cached("https://raw.githubusercontent.com/trashbirdecology/bbsAssistant/main/data-raw/IBP-AOS-LIST21.csv",
                         TABLE, "IBP-AOS-LIST21.csv")
ibp <- fread(ibp_f, fill = TRUE)
setnames(d, make.names(names(d)))
stopifnot(nrow(d) == 234229L, nrow(sc) == 1288L, uniqueN(sc$Point) == 184L, !anyDuplicated(sc$PointYrID),
          nrow(ibp) == 2281L, !anyDuplicated(ibp$SPEC),
          all(d$Year %in% 2009:2016), all(d$Rep1 %in% 1:2), all(d[, uniqueN(Year), by = PointYrID]$V1 == 1L),
          all(d[, uniqueN(Point), by = PointYrID]$V1 == 1L), all(d[, uniqueN(Transect), by = Point]$V1 == 1L),
          all(d[, uniqueN(Site), by = Transect]$V1 == 1L), identical(d$PointYrID, paste(d$Point, d$Year, sep = ".")),
          sum(d$Spp == "---") == 3L, all(d[Spp == "---"]$Count == 0L), all(d[Spp != "---"]$Count >= 1L))

# ---- visits ------------------------------------------------------------------------------------------------
v <- d[, .(nd = uniqueN(Date), ntd = uniqueN(TOD), nt = uniqueN(Temp), nw = uniqueN(Wind), tod = min(TOD),
           Date = Date[1], Temp = Temp[1], Wind = Wind[1], Point = Point[1], Year = Year[1]), by = .(PointYrID, Rep1)]
stopifnot(nrow(v) == 15182L, all(v$nd == 1L), all(v$nt == 1L), all(v$nw == 1L), sum(v$ntd > 1L) == 1L,
          !anyNA(v$Temp), !anyNA(v$Wind))
v[, date := format(as.IDate(Date, format = "%m/%d/%Y"))]
stopifnot(!anyNA(v$date), all(substr(v$date, 1, 4) == as.character(v$Year)))
# the site-covariate file's MaxOfVisit against the visits in the record file
nv <- v[, .N, by = PointYrID]
mm <- merge(sc[, .(PointYrID, MaxOfVisit)], nv, by = "PointYrID", all.x = TRUE)
stopifnot(sum(is.na(mm$N)) == 30L, sum(mm$N != mm$MaxOfVisit, na.rm = TRUE) == 119L)

# ---- taxa --------------------------------------------------------------------------------------------------
codes <- sort(unique(d$Spp))
extra <- data.table(SPEC = c("WESJ", "GRAJ"), COMMONNAME = c("Western Scrub-Jay", "Gray Jay"),
                    SCINAME = c("Aphelocoma californica", "Perisoreus canadensis"))
stopifnot(!any(extra$SPEC %in% ibp$SPEC))
def <- rbind(ibp[SPEC %in% codes, .(SPEC, COMMONNAME, SCINAME)], extra)
undef <- setdiff(codes, def$SPEC)
stopifnot(all(grepl("^X", undef) | undef == "---"), length(undef) == 25L)
n_undef <- sum(d$Spp %in% setdiff(undef, "---"))
stopifnot(n_undef == 3438L)
def <- def[match(intersect(codes, def$SPEC), SPEC)]
slash <- def[grepl("/", SCINAME)]$SPEC
stopifnot(setequal(slash, c("WEFL", "SAGS")))
taxa <- make_taxa(def$SPEC, def$SCINAME, vernacularName = def$COMMONNAME,
                  taxonRank = ifelse(def$SPEC %in% slash, "species aggregate", "species"), no_key = slash,
                  taxonRemarks = ifelse(def$SPEC %in% slash, "IBP-AOS slash code for a species pair (formerly one species); not a GBIF backbone taxon",
                                 ifelse(def$SPEC == "WESJ", "superseded IBP code WESJ (Western Scrub-Jay, split in 2016); in the Sierra Nevada the California Scrub-Jay, Aphelocoma californica",
                                 ifelse(def$SPEC == "GRAJ", "superseded IBP code GRAJ (Gray Jay, renamed Canada Jay, CAJA)", NA_character_))))
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
na_k <- taxa[is.na(taxon_iucnCategory) & !is.na(taxonID)]   # GBIF key resolves to another genus: read the key's cached record
cache_cat <- sapply(sub(".*/", "", na_k$taxonID), function(k) fromJSON(file.path(GBIF_DIR, paste0("iucn_", k, ".json")))$code)
stopifnot(setequal(na_k$taxon, c("BUOR", "NOHA", "PIWO", "RCKI")), all(cache_cat == "LC"))
taxa[match(na_k$taxon, taxon), taxon_iucnCategory := unname(cache_cat)]
flagged <- taxa[taxon_iucnCategory %in% c("CR", "EN", "VU")]
stopifnot(identical(flagged$taxon, "EVGR"), flagged$taxon_iucnCategory == "VU")

# ---- long table ----------------------------------------------------------------------------------------------
y <- d[Spp %in% taxa$taxon, .(y = sum(Count)), by = .(PointYrID, Rep1, Spp)]
grid <- CJ(k = seq_len(nrow(v)), Spp = taxa$taxon)
grid[, `:=`(PointYrID = v$PointYrID[k], Rep1 = v$Rep1[k])][, k := NULL]
long <- merge(grid, y, by = c("PointYrID", "Rep1", "Spp"), all.x = TRUE)
long[is.na(y), y := 0L]
tr <- unique(d[, .(Point, Transect, Site)])
long <- merge(long, v[, .(PointYrID, Rep1, Point, Year, date, obs_tod_h = tod, obs_temp_c = Temp, obs_wind_bft = Wind)],
              by = c("PointYrID", "Rep1"))
long <- merge(long, tr, by = "Point")
# site covariates: unit_ where constant within a point, else period_
cv <- c(forested = "Forested", conifer_dieoff_gis_pct = "ConDieOffGIS", conifer_dieoff_field_pct = "ConDieOfffield",
        cwhr_type = "CWHR1", decimalLatitude = "latitude", decimalLongitude = "longitude", elevation_m = "elevation",
        elev_residual_m = "elevres", aspect_deg = "aspect", slope_pct = "slope", sri = "SRI", southness = "southness",
        shrub_cover_pct = "ShrubCov", tree_cover_pct = "TreeCov", basal_area_ft2ac = "BA", snags_gt30cm = "g30SNAGS",
        snags_gt10cm = "totSNAGS", max_dbh_in = "MaxDBH", pine_prop = "PineProp", ndwi = "NDWI", d_ndwi = "dNDWI",
        cwd_mm = "cwd", d_cwd_mm = "dCWD", tmn_june_c = "tmn", tmx_june_c = "tmx", d_tmn_june_c = "dtmn", d_tmx_june_c = "dtmx")
stopifnot(all(cv %in% names(sc)))
lev <- sapply(cv, function(cn) if (all(sc[, uniqueN(get(cn)), by = Point]$V1 == 1L)) "unit_" else "period_")
stopifnot(all(lev[c("decimalLatitude", "decimalLongitude", "elevation_m")] == "unit_"))
ucov <- unique(sc[, c("Point", cv[lev == "unit_"]), with = FALSE]); setnames(ucov, c("Point", paste0("unit_", names(cv)[lev == "unit_"])))
pcov <- sc[, c("PointYrID", cv[lev == "period_"]), with = FALSE]; setnames(pcov, c("PointYrID", paste0("period_", names(cv)[lev == "period_"])))
stopifnot(!anyDuplicated(ucov$Point))
long <- merge(long, ucov, by = "Point", all.x = TRUE)
long <- merge(long, pcov, by = "PointYrID", all.x = TRUE)
setnames(long, c("Point", "Spp", "Rep1", "Transect", "Site"), c("unit", "taxon", "occasion", "cluster_id", "unit_site"))
long[, `:=`(period = Year - 2008L, occasion = as.integer(occasion), Year = NULL, PointYrID = NULL)]
long <- order_eco(long)
stopifnot(nrow(long) == 15182L * nrow(taxa), sum(long$y) == sum(d[Spp %in% taxa$taxon]$Count), uniqueN(long$unit) == 1353L,
          !anyNA(long$unit_site))
cat(sprintf("  %d rows; %d points, %d visits, %d taxa; %d records in undefined codes not shipped; period_ covariates: %s\n",
            nrow(long), uniqueN(long$unit), nrow(v), nrow(taxa), n_undef, paste(names(lev)[lev == "period_"], collapse = ", ")))
periods <- data.table(period = 1:8, year = 2009:2016, n_visits = as.integer(table(factor(v$Year, 2009:2016))))

fl <- sprintf("%s (IUCN %s)", flagged$scientificName, flagged$taxon_iucnCategory)
cc <- coarsen_coords(long$unit_decimalLatitude, long$unit_decimalLongitude)
coarse <- copy(long)[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon,
                            unit_coordinateUncertaintyInMeters = ifelse(is.na(cc$lat), NA_integer_, as.integer(cc$uncertainty_m)),
                            unit_elevation_m = round(unit_elevation_m, -2), unit_elev_residual_m = NULL)]
exact <- long[taxon != "EVGR"]
stopifnot(nrow(exact) == 15182L * (nrow(taxa) - 1L), !"unit_elev_residual_m" %in% names(coarse))

base <- list(
  creator = "Roberts, Lance Jay; Burnett, Ryan; Tietz, James; Veloz, Sam", pubDate = "2018",
  doi = "10.5061/dryad.rm2n805", sourceURL = "https://doi.org/10.5061/dryad.rm2n805",
  citation = "Roberts, L. J., Burnett, R., Tietz, J., & Veloz, S. (2018). Data from: Recent drought and tree mortality effects on the avian community in southern Sierra Nevada: a glimpse of the future? [Dataset]. Dryad. https://doi.org/10.5061/dryad.rm2n805",
  paperDOI = "10.1002/eap.1848",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Point counts at points on 5-point transects, one or two visits a year in the breeding season; each detection recorded with count, cue and distance at first detection; y = individuals of the taxon detected at the visit, summed over its records at all distances.",
  samplingProtocolCode = "point_count", surveyEvidence = "row_presence",
  responseType = "count", unitKind = "site",
  closure = "closed", closureNote = "the one or two visits to a point within a breeding season are the occasions; years are periods.",
  occasionKind = "time", taxonInclusion = "recorded",
  temporalCoverage = "2009/2016",
  covariateNote = "obs_tod_h: time of day (decimal hours); obs_temp_c: temperature (deg C); obs_wind_bft: wind (Beaufort). unit_site: pair of transects. Site covariates (from the site-covariate file, 184 points, NA elsewhere): forest condition, conifer die-off from GIS and from field crews (% of standing trees within 100 m dead), CWHR forest type, elevation (and, in the exact table, its residual on latitude), aspect, slope, solar radiation index, southness, shrub and tree cover (%), basal area (ft2/acre), snags > 30 cm and > 10 cm, max DBH (inches, within 50 m), pine proportion, NDWI and its change from 2009, climatic water deficit (mm) and June min / max temperature with their changes from 2009. Each is unit_ when constant across a point's years, otherwise period_.",
  notes = "Visits are taken from the record file, which carries an explicit row for a visit with no detection; 30 point-years of the site-covariate file have no records and are not in the table, and its MaxOfVisit differs from the record file's visit count at 119 point-years. Taxa resolved through the IBP-AOS alpha-code list; WESJ and GRAJ are superseded codes, WEFL and SAGS slash pairs. Coordinates exist for the 184 points of the site-covariate file only.")
nsb <- list(
    undefined_codes = sprintf("%d records in 24 codes neither the deposit nor the IBP-AOS list defines (XX.. and X... groups such as XXWO, XXSA, XXEM, XXXX); the 3 '---' rows mark visits with no detection and become rows of zeros", n_undef),
    distances_cues = "distance at first detection and detection cue per record (a distance-sampling table could be built)",
    visit_keys = "Rep2 and DOY (recoverable from period, occasion and date)",
    max_of_visit = "MaxOfVisit of the site-covariate file, which disagrees with the record file at 119 point-years (the record file is believed)",
    future_covariates = "the three future-climate covariate files (inputs to the authors' projections)",
    model_output = "the modelled species list's detection functions, abundance estimates and projections")
abs0 <- "Avian point counts in the southern Sierra Nevada, California, used to model the effects of temperature, water deficit and drought-driven tree mortality on 45 bird species. Points on 5-point transects (transects paired into sites) counted once or twice a year from 2009 to 2016; every bird detected was recorded with its distance. One row per point visit x taxon, y = individuals detected (all distances). Habitat, tree-mortality and climate covariates for 184 of the points (2010-2016)."
d1 <- c(list(title = "Bird point counts at 1,353 points over 15,182 visits, southern Sierra Nevada, California, 2009 to 2016 (coordinates coarsened)"), base, list(
  abstract = paste(abs0, sprintf("Coordinates coarsened to 0.1 degree because %s is in the table; %s has the other taxa at the published coordinates.", fl, EXACT)),
  geographicCoverage = "Southern Sierra Nevada, California, USA (coordinates, for 184 points, coarsened to 0.1 degree)",
  coordinatesCoarsened = list(value = TRUE, method = sprintf("point coordinates replaced by 0.1 degree cell centres (coarsen_coords) because %s, native here, is in the table; elevation rounded to 100 m and its residual not shipped (E7.4)", fl)),
  notShipped = c(nsb, list(elev_residual = sprintf("elevres (elevation residual, a locator with latitude; E7.4); in %s", EXACT)))))
d2 <- c(list(title = "Bird point counts at 1,353 points over 15,182 visits, southern Sierra Nevada, California, 2009 to 2016 (without threatened taxa, coordinates as published)"), base, list(
  abstract = paste(abs0, sprintf("The E7.3 sibling of %s without %s, so coordinates and elevations ship as published.", TABLE, fl)),
  geographicCoverage = "Southern Sierra Nevada, California, USA (coordinates for the 184 points of the site-covariate file)",
  coordinatesCoarsened = list(value = FALSE, method = sprintf("as published (WGS84/NAD83, 184 points); the IUCN-threatened %s is not in this table (it is in %s, coarsened)", fl, TABLE)),
  notShipped = c(nsb, list(threatened_taxa = sprintf("%s: in %s only, whose coordinates are coarsened", fl, TABLE)))))

ds1 <- write_table(coarse, TABLE, d1, taxa = taxa, periods = periods, script = "data/roberts_2019_sierranevada_birds_count.R")
ds2 <- write_table(exact, EXACT, d2, taxa = taxa[taxon != "EVGR"], periods = periods, script = "data/roberts_2019_sierranevada_birds_count.R")
for (x in list(list(TABLE, ds1, FALSE), list(EXACT, ds2, TRUE))) {
  stage_dict_row(x[[1]],
    description = paste("Bird point counts (individuals per species per visit) at 1,353 points in the southern Sierra Nevada, California, 2009-2016, with habitat, tree-mortality and climate covariates for 184 points.",
                        if (x[[3]]) "Without the IUCN-VU evening grosbeak; coordinates as published." else "All taxa; coordinates coarsened to 0.1 degree."),
    url = "https://doi.org/10.5061/dryad.rm2n805",
    reference = "Roberts, L. J., Burnett, R., Tietz, J. & Veloz, S. (2019). Recent drought and tree mortality effects on the avian community in southern Sierra Nevada: a glimpse of the future? Ecological Applications 29, e01848. https://doi.org/10.1002/eap.1848",
    doi_paper = "10.1002/eap.1848", doi_data = "10.5061/dryad.rm2n805",
    original_license = "CC0 1.0", derived_license = "CC0 1.0",
    notes = paste("Detection records summed per visit; explicit empty visits in the source; alpha codes via the IBP-AOS list (cached download from GitHub).",
                  if (x[[3]]) sprintf("E7.3 sibling of %s.", TABLE) else sprintf("Coarsened for Coccothraustes vespertinus (VU); %s is the exact sibling.", EXACT)),
    source_via = "Dryad (version zip)")
  stage_tag_row(x[[1]], x[[2]], taxon_group = "Birds", model_family = "Community abundance (N-mixture, multi-season)",
    sampling_protocol = "point_count", design = "Multi-season (8 years; 1,353 points, 1-2 visits a year)",
    realm = "Terrestrial", country = "USA", coordinates = if (x[[3]]) "As published (184 points)" else "Coarsened (0.1 deg) for the 184 points with coordinates",
    notes = if (x[[3]]) "Sierra Nevada drought bird counts; exact sibling without the VU evening grosbeak." else "Sierra Nevada drought bird counts; coarsened for the VU evening grosbeak.")
}
