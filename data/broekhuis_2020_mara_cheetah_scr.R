#!/usr/bin/env Rscript
# Table:  broekhuis_2020_mara_cheetah_scr
# Source: Dryad doi:10.5061/dryad.z34tmpgc2, version 94532 (version 2, published 2020-12-04),
#         licence CC0 1.0 (as shown on the Dryad landing page and in the API record; the deposited
#         ReadMe asks users to contact the authors before using the data in a report or
#         publication, a courtesy request, not a licence term).
#         Broekhuis, F., Elliot, N., Keiwua, K., Koinet, K., Macdonald, D., Mogensen, N., Thuo, D.
#         & Gopalaswamy, A. "Resource pulses influence the spatio-temporal dynamics of a large
#         carnivore population".
# Paper:  Broekhuis, F., Elliot, N. B., Keiwua, K., Koinet, K., Macdonald, D. W., Mogensen, N.,
#         Thuo, D. & Gopalaswamy, A. M. (2021). Resource pulses influence the spatio-temporal
#         dynamics of a large carnivore population. Ecography 44(3), 358-369,
#         doi:10.1111/ecog.05154 (open access, CC BY 3.0; the design below is from the ReadMe and
#         the Dryad abstract).
# Data:   ReadMe.txt, Habitat.csv (the SECR state space: 51,912 pixel centres, suitable 1/0), and
#         for each of 8 sessions (2015-2018 x S1 = out of the migration, 1 February-2 May, S2 =
#         during the migration, 1 August-30 October) four files:
#   AAAA_BB_CH.csv     one line per detection: LOC_ID (pixel), ANIMAL_ID, SO (sampling occasion
#                      1..90). Animal ids are assigned per session (ReadMe: "the ID given to an
#                      individual cheetah varies across the sampling sessions"). A few lines are
#                      exact duplicates (same animal, pixel, occasion; counted and asserted).
#   AAAA_BB_Traps.csv  pixel x occasion operation matrix (LOC_ID, X_COORD, Y_COORD in UTM, then
#                      90 columns, 1 = searched, 0 = not).
#   AAAA_BB_Effort.csv same shape: log of kilometres driven in the pixel on the occasion; -20 = no
#                      effort, exactly where Traps is 0 (asserted).
#   AAAA_BB_Sex.csv    ANIMAL_ID, SEX (0 female, 1 male).
#   Unstructured search-encounter survey: observers drove the reserve and conservancies and
#   photographed cheetahs; each pixel driven on a day is a "trap" operated on that occasion.
#
# Mapping (standard E9 experimental, spatial capture-recapture; responseType detection,
# unitKind individual):
#   unit = session-scoped animal id (2015S1_08), taxon = ACIJUB, trap = session-scoped pixel id
#   (2015S1_893; LOC_ID numbering and the searched pixel set are per session), period = session
#   1..8 (__periods), occasion = SO 1..90, y = 1 if the animal was detected in that pixel on that
#   occasion. obs_log_km = the deposited effort (log km driven). unit_sex = the deposited sex.
#   Survey set (surveyEvidence = effort_table): every pixel x occasion with Traps = 1 (effort >
#   -20). At-risk span: identities are not linked across sessions, so an animal id exists only in
#   its own session (giving it rows in other sessions would duplicate the same cheetah under
#   another id); within its session it is at risk at every searched pixel-occasion.
#   Coordinates: Acinonyx jubatus is IUCN VU in its native range (E7(b)); pixel centres are ~1 km
#   UTM positions of a search grid on which cheetahs were detected, so __traps carries them
#   centred on the all-session centroid in local metres (exact UTM withheld), and the centroid
#   is given at 0.1 degree in geographicCoverage (as curveirasantos_2026_phinda_cheetah_scr).
#   Not shipped: Habitat.csv (the SECR state-space mask, a model input derived by the authors),
#   exact UTM pixel coordinates (coarsened, above), duplicate detection lines (one y = 1 row).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "broekhuis_2020_mara_cheetah_scr"
dir <- download_dryad("doi:10.5061/dryad.z34tmpgc2", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"),
          identical(attr(dir, "version"), "94532"), length(list.files(dir)) == 34L)
SESS <- CJ(year = 2015:2018, s = c("S1", "S2"))
SESS[, `:=`(period = .I, code = paste0(year, "_", s), key = paste0(year, s),
            season = ifelse(s == "S1", "out of the migration (1 February-2 May)", "during the migration (1 August-30 October)"))]

utm_to_ll <- function(E, N, zone) {           # WGS 84 / UTM, southern hemisphere handled by the caller
  a <- 6378137; f <- 1 / 298.257223563; k0 <- 0.9996; e2 <- f * (2 - f); ep2 <- e2 / (1 - e2)
  x <- E - 500000; M <- N / k0; mu <- M / (a * (1 - e2 / 4 - 3 * e2^2 / 64 - 5 * e2^3 / 256))
  e1 <- (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
  phi1 <- mu + (3 * e1 / 2 - 27 * e1^3 / 32) * sin(2 * mu) + (21 * e1^2 / 16 - 55 * e1^4 / 32) * sin(4 * mu) + (151 * e1^3 / 96) * sin(6 * mu)
  N1 <- a / sqrt(1 - e2 * sin(phi1)^2); T1 <- tan(phi1)^2; C1 <- ep2 * cos(phi1)^2
  R1 <- a * (1 - e2) / (1 - e2 * sin(phi1)^2)^1.5; D <- x / (N1 * k0)
  lat <- phi1 - (N1 * tan(phi1) / R1) * (D^2 / 2 - (5 + 3 * T1 + 10 * C1 - 4 * C1^2 - 9 * ep2) * D^4 / 24 +
                                          (61 + 90 * T1 + 298 * C1 + 45 * T1^2 - 252 * ep2 - 3 * C1^2) * D^6 / 720)
  lon <- (D - (1 + 2 * T1 + C1) * D^3 / 6 + (5 - 2 * C1 + 28 * T1 - 3 * C1^2 + 8 * ep2 + 24 * T1^2) * D^5 / 120) / cos(phi1)
  lon0 <- (zone - 1) * 6 - 180 + 3
  list(lat = lat * 180 / pi, lon = lon0 + lon * 180 / pi)
}

N_ID  <- c(19L, 20L, 22L, 34L, 34L, 43L, 43L, 43L)
N_DUP <- c(0L, 1L, 0L, 0L, 3L, 0L, 0L, 0L)
parts <- list(); trapl <- list(); per <- list()
for (i in seq_len(nrow(SESS))) {
  s <- SESS[i]
  rd <- function(kind) fread(file.path(dir, sprintf("%s_%s.csv", s$code, kind)))
  tr <- rd("Traps"); ef <- rd("Effort"); ch <- rd("CH"); sx <- rd("Sex")
  occ <- as.character(1:90)
  stopifnot(identical(names(tr), c("LOC_ID", "X_COORD", "Y_COORD", occ)), identical(names(ef), names(tr)),
            identical(tr$LOC_ID, ef$LOC_ID), identical(tr$X_COORD, ef$X_COORD), !anyDuplicated(tr$LOC_ID),
            identical(names(ch), c("LOC_ID", "ANIMAL_ID", "SO")), identical(names(sx), c("ANIMAL_ID", "SEX")))
  T <- as.matrix(tr[, ..occ]); E <- as.matrix(ef[, ..occ])
  stopifnot(all(T %in% 0:1), identical(T == 1, E != -20), all(E[T == 1] > -20))
  stopifnot(nrow(sx) == N_ID[i], identical(sx$ANIMAL_ID, seq_len(N_ID[i])), all(sx$SEX %in% 0:1),
            setequal(ch$ANIMAL_ID, sx$ANIMAL_ID), all(ch$LOC_ID %in% tr$LOC_ID), all(ch$SO %in% 1:90),
            sum(duplicated(ch)) == N_DUP[i])
  ch <- unique(ch)
  stopifnot(all(T[cbind(match(ch$LOC_ID, tr$LOC_ID), ch$SO)] == 1L))      # every detection on a searched pixel-day
  w <- which(T == 1L, arr.ind = TRUE)
  sv <- data.table(LOC_ID = tr$LOC_ID[w[, 1]], occasion = w[, 2], obs_log_km = E[w])
  long <- CJ(ANIMAL_ID = sx$ANIMAL_ID, k = seq_len(nrow(sv)))
  long <- cbind(long[, .(ANIMAL_ID)], sv[long$k])
  long <- merge(long, ch[, .(ANIMAL_ID, LOC_ID, occasion = SO, y = 1L)], by = c("ANIMAL_ID", "LOC_ID", "occasion"), all.x = TRUE)
  long[is.na(y), y := 0L]
  stopifnot(sum(long$y) == nrow(ch), nrow(long) == nrow(sv) * nrow(sx))
  long <- merge(long, sx, by = "ANIMAL_ID")
  parts[[i]] <- long[, .(unit = sprintf("%s_%02d", s$key, ANIMAL_ID), taxon = "ACIJUB", y,
                         trap = paste0(s$key, "_", LOC_ID), period = s$period, occasion,
                         unit_sex = ifelse(SEX == 1L, "M", "F"), obs_log_km)]
  trapl[[i]] <- tr[, .(trap = paste0(s$key, "_", LOC_ID), E = X_COORD, N = Y_COORD, period = s$period,
                       loc_id = LOC_ID, n_occasions_searched = as.integer(rowSums(T)))]
  per[[i]] <- data.table(period = s$period, year = s$year, session = s$s, season = s$season,
                         n_pixels = nrow(tr), n_pixel_days_searched = nrow(sv), n_animals = nrow(sx),
                         n_detections = nrow(ch), n_female = sum(sx$SEX == 0L), n_male = sum(sx$SEX == 1L))
}
long <- order_eco(rbindlist(parts))
traps <- rbindlist(trapl)
periods <- rbindlist(per)
stopifnot(nrow(long) == 2206029L, uniqueN(long$unit) == sum(N_ID), sum(long$y) == sum(periods$n_detections))
cat(sprintf("  %d rows, %d animal-sessions, %d detections\n", nrow(long), uniqueN(long$unit), sum(long$y)))

# coordinates: centred local metres (VU taxon), centroid at 0.1 degree
cx <- mean(traps$E); cy <- mean(traps$N)
ctr <- utm_to_ll(cx, cy - 1e7, zone = 36)
stopifnot(ctr$lat < -1 & ctr$lat > -2, ctr$lon > 34.5 & ctr$lon < 36)
ctr_c <- coarsen_coords(ctr$lat, ctr$lon)
traps <- traps[, .(trap, x_m = round(E - cx), y_m = round(N - cy), period, loc_id, n_occasions_searched)]
stopifnot(max(abs(traps$x_m)) < 60000, max(abs(traps$y_m)) < 60000)

taxa <- make_taxa("ACIJUB", "Acinonyx jubatus", vernacularName = "Cheetah")
taxa[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
stopifnot(identical(taxa$taxon_iucnCategory, "VU"))

dataset <- list(
  title = "Spatial capture-recapture (search-encounter) of cheetahs in the Maasai Mara, Kenya: 8 seasonal sessions in and out of the wildebeest migration, 2015-2018",
  creator = "Broekhuis, Femke; Elliot, Nicholas; Keiwua, Kosiom; Koinet, Kelvin; Macdonald, David; Mogensen, Niels; Thuo, David; Gopalaswamy, Arjun",
  pubDate = "2020", doi = "10.5061/dryad.z34tmpgc2", sourceURL = "https://doi.org/10.5061/dryad.z34tmpgc2",
  citation = "Broekhuis, F., Elliot, N., Keiwua, K., Koinet, K., Macdonald, D., Mogensen, N., Thuo, D., & Gopalaswamy, A. (2020). Resource pulses influence the spatio-temporal dynamics of a large carnivore population [Dataset]. Dryad. https://doi.org/10.5061/dryad.z34tmpgc2",
  paperDOI = "10.1111/ecog.05154",
  abstract = "Unstructured search-encounter data on individually identified cheetahs collected during eight 90-day sessions in the Maasai Mara, four out of (February-May) and four during (August-October) the annual wildebeest migration, 2015-2018. The paper fits Bayesian SECR models with sex-specific detection to relate cheetah density and space use to the resource pulse.",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  samplingProtocol = "Search-encounter survey: observers drove through the Maasai Mara National Reserve and surrounding conservancies, photographing cheetahs and identifying them from coat patterns. The study area is divided into pixels; a pixel driven on a day is a trap operated on that occasion, with the distance driven recorded as effort. 90 daily occasions per session.",
  samplingProtocolCode = "search_encounter", surveyEvidence = "effort_table", effortColumn = "obs_log_km",
  responseType = "detection", unitKind = "individual",
  closure = "closed", closureNote = "period (population assumed closed within a 90-day session; identities not linked across sessions)",
  occasionKind = "time", taxonInclusion = "single", lossesOnCapture = "none",
  temporalCoverage = "2015-02/2018-10",
  geographicCoverage = sprintf("Maasai Mara National Reserve and adjacent conservancies, Kenya; search-pixel centroid %.2f, %.2f (0.1 degree cell centre)", ctr_c$lat, ctr_c$lon),
  crs = "local metres centred on the pixel centroid (source: WGS 84 / UTM zone 36S)",
  coordinatesCoarsened = list(value = TRUE, method = "pixel coordinates centred on the all-session centroid by the processor (local metres; exact UTM 36S positions withheld) because Acinonyx jubatus is IUCN VU in its native range; the centroid is given at 0.1 degree in geographicCoverage"),
  designNote = "Experimental list of E9: spatial capture-recapture with a trap key and __traps, here a search-encounter design (pixels as traps, daily occasions, km driven as effort). Animal ids and pixel ids are session-scoped: the source assigned animal ids per session, so each animal has rows only in its own session.",
  notes = "Session-scoped animal ids (the same cheetah may appear under different ids in different sessions). A detection line repeated in the deposit is one y = 1 row (4 such lines). The deposited ReadMe asks users to contact the authors before using the data in a report or publication. obs_log_km is the natural log of km driven in the pixel that day, as deposited.",
  notShipped = list(Habitat.csv = "the SECR state-space mask (51,912 pixel centres, suitable 1/0): a model input built by the authors",
                    utm_coordinates = "exact UTM pixel centres (VU taxon); shipped centred in local metres",
                    duplicate_lines = "4 exact duplicate detection lines collapsed"))

ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, traps = traps, script = "data/broekhuis_2020_mara_cheetah_scr.R")
stage_dict_row(TABLE,
  description = "Search-encounter spatial capture-recapture of cheetahs in the Maasai Mara, Kenya: animal x 1-km search pixel x day over eight 90-day sessions in and out of the wildebeest migration, 2015-2018, with km driven per pixel-day; session-scoped ids; pixel coordinates centred (VU taxon).",
  url = "https://doi.org/10.5061/dryad.z34tmpgc2",
  reference = "Broekhuis, F., Elliot, N. B., Keiwua, K., Koinet, K., Macdonald, D. W., Mogensen, N., Thuo, D., & Gopalaswamy, A. M. (2021). Resource pulses influence the spatio-temporal dynamics of a large carnivore population. Ecography, 44(3), 358-369.",
  doi_paper = "10.1111/ecog.05154", doi_data = "10.5061/dryad.z34tmpgc2",
  original_license = "CC0 1.0 (Dryad; ReadMe asks re-users to contact the authors)", derived_license = "CC0 1.0",
  notes = "Search-encounter SCR; effort table = pixel-day operation matrix with log km driven. IUCN VU; coordinates centred.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Spatial capture-recapture (search-encounter, multi-session)",
  sampling_protocol = "search_encounter", design = "Multi-session (8 seasonal sessions x 90 days)",
  realm = "Terrestrial", country = "KEN", coordinates = "Coarsened (trap coordinates centred on the search grid, local metres; VU taxon)",
  notes = "Experimental (E9): search pixels as traps; session-scoped animal ids.",
  status = "tagged; do_not_publish: search-encounter SCR awaits Ben's ruling (batch 21 held the right whale line-transect SCR for a rule; here the source already discretised the search into pixel x day traps with effort)")
