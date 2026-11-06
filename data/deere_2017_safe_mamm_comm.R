#!/usr/bin/env Rscript
# Tables: deere_2017_safe_mamm_comm (coordinates coarsened) and deere_2017_safe_mamm_exact_comm (E7.3 sibling)
# Source: NERC Environmental Information Data Centre (EIDC) doi:10.5285/62774180-ae72-4873-9482-e8be3935f533,
#         published 2017-09-18, licence Open Government Licence v3 ("This resource is made available under the terms
#         of the Open Government Licence", "(c) University of Kent 2017"; catalogue record and readme.html, asserted
#         from the cached catalogue JSON). Required attribution: "Contains data supplied by UK Centre for Ecology &
#         Hydrology." OGL v3 is an attribution-only licence (compatible with CC BY 4.0).
#   Deere, N.J., Guillera-Arroita, G., Baking, E.L., Bernard, H., Pfeifer, M., Reynolds, G., Wearn, O.R., Davies,
#   Z.G. & Struebig, M.J. (2017). Mammal detection data for the SAFE project site, Sabah, Malaysian Borneo, 2015
#   [HMTF]. NERC Environmental Information Data Centre.
# Paper:  Deere, N. J. et al. (2018). High Carbon Stock forests provide co-benefits for tropical biodiversity.
#         Journal of Applied Ecology 55, 997-1008 (not read; the supporting document states the design).
# Data:   the EIDC data package zip: data/MammalDetectionData_2015.csv (3,220 rows = 115 sites x 28 species: Site,
#         Rep1-Rep6 (7-day replicates, 1 detected, 0 not, NA camera malfunction), Total_Detection (row sum, asserted),
#         Species (common name)); data/MammalDetectionSurveyEffort_2015.csv (120 sites: Site_ID, Latitude, Longitude
#         (WGS84, 5 decimals), Date_On, Time_On, Date_Off, Time_Off, Number_of_Photos, CTNs camera-trap nights, CTHs);
#         supporting-documents/DOI_SupportingDocumentation_MammalDetection.rtf: cameras (Reconyx HC500) at 130
#         locations May-September 2015 in two rotations, 42 consecutive nights each, divided into six 7-day replicates;
#         sites active < 7 days excluded, leaving 115 analytical units with 2-6 replicates; habitat classes from the
#         site prefix: CLF continuous logged forest, EA experimental area (heavily degraded forest), OPF oil palm
#         forest fragments, OP oil palm. The 5 effort sites absent from the detection file have 0-5 camera nights.
#         The NA pattern is identical across the 28 species (asserted).
# Mapping: unit = Site, taxon = a code for the species, occasion = replicate 1-6, date = Date_On + 7 * (rep - 1)
#   (the first day of the 7-day replicate), y = 0/1. surveyEvidence = deposited_matrix. unit_habitat (from the
#   prefix), unit_camera_nights (CTNs), coordinates. taxonInclusion = recorded (the 28 species identified).
#   Scientific names are assigned from the source's common names (taxonRemarks), Bornean taxa.
#   E7: the table includes IUCN CR/EN/VU species in their native range (Sunda pangolin, Bornean orangutan, Bornean
#   elephant, macaques, Sunda clouded leopard, sun bear, bearded pig, binturong, sambar), and the coordinates (5
#   decimals) are finer than 0.1 degree, so the whole table is coarsened to 0.1-degree cell centres; the _exact
#   sibling carries the unflagged species at the published precision (E7.3).
#   Not shipped: Total_Detection (an aggregate, recomputable); Number_of_Photos, CTHs, deployment times.
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
SCRIPT <- "data/deere_2017_safe_mamm_comm.R"; CACHE <- "deere_2017_safe_mamm_comm"
ID <- "62774180-ae72-4873-9482-e8be3935f533"
mf <- file.path(RAW_DIR, CACHE, "eidc_record.json"); dir.create(dirname(mf), showWarnings = FALSE, recursive = TRUE)
if (!file.exists(mf)) download.file(paste0("https://catalogue.ceh.ac.uk/documents/", ID), mf, quiet = TRUE, headers = c("User-Agent" = UA, Accept = "application/json"))
meta <- fromJSON(mf)
stopifnot(any(grepl("Open Government Licence", meta$useConstraints$value)), "10.5285/62774180-ae72-4873-9482-e8be3935f533" %in% meta$resourceIdentifiers$code)
z <- download_cached(sprintf("https://data-package.ceh.ac.uk/data/%s.zip", ID), CACHE, filename = "data_package.zip")
ex <- file.path(dirname(z), "x"); if (!dir.exists(ex)) unzip(z, exdir = ex)
d <- fread(file.path(ex, "data", "MammalDetectionData_2015.csv"))
e <- fread(file.path(ex, "data", "MammalDetectionSurveyEffort_2015.csv"))
R <- paste0("Rep", 1:6)
stopifnot(identical(names(d), c("Site", R, "Total_Detection", "Species")), nrow(d) == 3220L, uniqueN(d$Site) == 115L,
          uniqueN(d$Species) == 28L, all(d[, .N, by = Site]$N == 28L), all(unlist(d[, ..R]) %in% c(0L, 1L, NA)),
          all(d$Total_Detection == rowSums(d[, ..R], na.rm = TRUE)), nrow(e) == 120L, all(d$Site %in% e$Site_ID),
          all(e[!Site_ID %in% d$Site, CTNs] <= 5L))
nap <- d[, .(pat = paste(as.integer(is.na(.SD)), collapse = "")), by = .(Site, Species), .SDcols = R]
stopifnot(nap[, uniqueN(pat), by = Site][, all(V1 == 1L)])
sp <- data.table(
  Species = c("Banded Civet", "Bearded Pig", "Binturong", "Bornean Elephant", "Clouded Leopard", "Common Palm Civet", "Common Porcupine",
              "Greater Mousedeer", "Leopard Cat", "Lesser Mousedeer", "Long tailed Macaque", "Long tailed Porcupine", "Malayan Civet",
              "Marbled Cat", "Masked Palm Civet", "Moonrat", "Orangutan", "Pig tailed Macaque", "Red Muntjac", "Sambar Deer",
              "Short tailed Mongoose", "Stink Badger", "Sun Bear", "Sunda Pangolin", "Thick spined Porcupine", "Tufted Ground Squirrel",
              "Yellow Muntjac", "Yellow throated Marten"),
  sci = c("Hemigalus derbyanus", "Sus barbatus", "Arctictis binturong", "Elephas maximus", "Neofelis diardi", "Paradoxurus hermaphroditus",
          "Hystrix brachyura", "Tragulus napu", "Prionailurus bengalensis", "Tragulus kanchil", "Macaca fascicularis", "Trichys fasciculata",
          "Viverra tangalunga", "Pardofelis marmorata", "Paguma larvata", "Echinosorex gymnura", "Pongo pygmaeus", "Macaca nemestrina",
          "Muntiacus muntjak", "Rusa unicolor", "Herpestes brachyurus", "Mydaus javanensis", "Helarctos malayanus", "Manis javanica",
          "Hystrix crassispinis", "Rheithrosciurus macrotis", "Muntiacus atherodes", "Martes flavigula"))
stopifnot(setequal(sp$Species, d$Species))
sp[, taxon := toupper(paste0(substr(sub(" .*", "", sci), 1, 3), substr(sub(".* ", "", sci), 1, 3)))]
stopifnot(!anyDuplicated(sp$taxon))
taxa_all <- make_taxa(sp$taxon, sp$sci, vernacularName = sp$Species,
                      taxonRemarks = paste0("scientific name assigned from the source's common name '", sp$Species, "' (Bornean taxon)"))
taxa_all[, taxon_iucnCategory := iucn_category(taxonID, scientificName)]
# Herpestes brachyurus: the IUCN record behind the GBIF key is Urva brachyura, the same species under its current
# genus, assessed NT (cached record asserted); iucn_category() declines on the genus difference
ib <- fromJSON(file.path(GBIF_DIR, "iucn_2434300.json"))
stopifnot(is.na(taxa_all[taxon == "HERBRA", taxon_iucnCategory]), identical(ib$code, "NT"), grepl("^Urva brachyura", ib$acceptedName))
taxa_all[taxon == "HERBRA", taxon_iucnCategory := "NT"]
print(taxa_all[, .(taxon, scientificName, gbifMatchType, gbifAcceptedName, taxon_iucnCategory)])
stopifnot(!anyNA(taxa_all$taxon_iucnCategory))
flagged <- taxa_all[taxon_iucnCategory %in% c("CR", "EN", "VU"), taxon]
cat("  flagged (IUCN CR/EN/VU, native range):", paste(flagged, collapse = ", "), "\n")
stopifnot(length(flagged) >= 5L)

e[, `:=`(on = as.Date(Date_On, "%d/%m/%Y"))]
stopifnot(!anyNA(e$on), all(e$on >= as.Date("2015-05-01") & e$on <= as.Date("2015-09-30")))
long0 <- melt(d, id.vars = c("Site", "Species"), measure.vars = R, variable.name = "rep", value.name = "y")[!is.na(y)]
long0[, occasion := as.integer(sub("Rep", "", rep))][, rep := NULL]
long0 <- merge(long0, sp[, .(Species, taxon)], by = "Species")
long0 <- merge(long0, e[, .(Site = Site_ID, on, lat = Latitude, lon = Longitude, ctn = CTNs)], by = "Site")
long0[, `:=`(unit = Site, date = format(on + 7L * (occasion - 1L)), y = as.integer(y),
             unit_habitat = c(CLF = "continuous logged forest", EA = "experimental area (heavily degraded forest)",
                              OPF = "oil palm forest fragment", OP = "oil palm")[sub("^OM-([A-Z]+)-.*$", "\\1", Site)],
             unit_camera_nights = ctn)]
stopifnot(!anyNA(long0$unit_habitat), nrow(long0) == 28L * sum(!is.na(as.matrix(d[Species == "Binturong", ..R]))))
cc <- coarsen_coords(long0$lat, long0$lon, 0.1)
emit <- function(TABLE, exact) {
  L <- copy(long0)
  if (exact) {
    L <- L[!taxon %in% flagged]
    L[, `:=`(unit_decimalLatitude = lat, unit_decimalLongitude = lon, unit_coordinateUncertaintyInMeters = 10)]
  } else L[, `:=`(unit_decimalLatitude = cc$lat, unit_decimalLongitude = cc$lon, unit_coordinateUncertaintyInMeters = cc$uncertainty_m)]
  L <- order_eco(L[, .(unit, taxon, y, occasion, date, unit_habitat, unit_camera_nights, unit_decimalLatitude, unit_decimalLongitude, unit_coordinateUncertaintyInMeters)])
  stopifnot(!anyDuplicated(L[, .(unit, taxon, occasion)]))
  taxa <- taxa_all[taxon %in% L$taxon]
  ex_note <- sprintf("Without the %d IUCN CR/EN/VU species (%s), coordinates as published; deere_2017_safe_mamm_comm has every species with coordinates coarsened.", length(flagged), paste(flagged, collapse = ", "))
  dataset <- list(
    title = paste0("Weekly camera-trap detections of 28 medium and large mammals at 115 sites in logged forest, forest fragments and oil palm, SAFE project, Sabah, Malaysian Borneo, 2015",
                   if (exact) " (unflagged species, coordinates as published)" else ""),
    creator = "Deere, N.J.; Guillera-Arroita, G.; Baking, E.L.; Bernard, H.; Pfeifer, M.; Reynolds, G.; Wearn, O.R.; Davies, Z.G.; Struebig, M.J.",
    pubDate = "2017", doi = "10.5285/62774180-ae72-4873-9482-e8be3935f533", sourceURL = "https://doi.org/10.5285/62774180-ae72-4873-9482-e8be3935f533",
    citation = "Deere, N.J., Guillera-Arroita, G., Baking, E.L., Bernard, H., Pfeifer, M., Reynolds, G., Wearn, O.R., Davies, Z.G., & Struebig, M.J. (2017). Mammal detection data for the SAFE project site, Sabah, Malaysian Borneo, 2015 [HMTF]. NERC Environmental Information Data Centre. https://doi.org/10.5285/62774180-ae72-4873-9482-e8be3935f533. Contains data supplied by UK Centre for Ecology & Hydrology.",
    intellectualRights = list(spdx = "OGL-UK-3.0", url = "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/"),
    abstract = "Camera traps across the Stability of Altered Forest Ecosystems (SAFE) project and surrounding oil palm estates in Sabah, Malaysian Borneo, May-September 2015, stratified across continuous logged forest, heavily degraded forest, forest fragments in oil palm and oil palm; detection matrices of 28 medium and large mammal species in six 7-day replicates at the 115 sites active for at least 7 days, used for occupancy modelling.",
    samplingProtocol = "One camera trap (Reconyx HC500 Hyperfire, 30 cm height, high sensitivity, 10 images per trigger) per location for 42 consecutive nights, in two rotations of 65 locations; on and off trails; the 42 days split into six 7-day replicates, NA where the camera had failed.",
    samplingProtocolCode = "camera_trap", surveyEvidence = "deposited_matrix",
    responseType = "detection", unitKind = "site", closure = "closed",
    closureNote = "Occupancy assumed closed across the six weekly replicates of a site's 42-day deployment.",
    occasionKind = "time", taxonInclusion = "recorded",
    geographicCoverage = "SAFE project and Benta Wawasan oil palm estates, Kalabakan Forest Reserve, and Ulu Segama Forest Reserve, Sabah, Malaysian Borneo (about 4.77 N, 117.0 E)",
    temporalCoverage = "2015-05/2015-09",
    coordinatesCoarsened = if (exact) list(value = FALSE, method = paste("As published (5 decimals).", ex_note)) else
      list(value = TRUE, method = "coarsen_coords() to 0.1-degree cell centres: the table includes IUCN CR/EN/VU mammals in their native range and the deposited coordinates (5 decimals) are finer than 0.1 degree (E7)"),
    covariateNote = "unit_habitat: the site's habitat class from its id prefix. unit_camera_nights: operational camera-trap nights (CTNs). date: first day of the 7-day replicate (deployment date + 7 x (replicate - 1)).",
    notShipped = c(list(total_detection = "Total_Detection: the row sum of the replicates (asserted)",
                        effort_extras = "Number_of_Photos, camera-trap hours and deployment times",
                        unused_sites = "5 effort-table sites with 0-5 camera nights, which the authors excluded (no detection data)"),
                   if (exact) list(flagged_taxa = ex_note) else list()),
    notes = if (exact) ex_note else "Coordinates coarsened for threatened species; deere_2017_safe_mamm_exact_comm has the unflagged species at published precision. Scientific names assigned from common names.")
  ds <- write_table(L, TABLE, dataset, taxa = taxa, script = SCRIPT)
  stage_dict_row(TABLE,
    description = paste0("Weekly camera-trap detections of ", if (exact) "the unflagged " else "28 ", "medium and large mammals at 115 sites across logged forest, fragments and oil palm in the SAFE landscape, Sabah, 2015",
                         if (exact) ", coordinates as published." else ", coordinates coarsened to 0.1 degree."),
    url = "https://doi.org/10.5285/62774180-ae72-4873-9482-e8be3935f533", reference = "", doi_paper = "",
    doi_data = "10.5285/62774180-ae72-4873-9482-e8be3935f533",
    original_license = "Open Government Licence v3 (attribution: Contains data supplied by UK Centre for Ecology & Hydrology; (c) University of Kent 2017)",
    derived_license = "OGL-UK-3.0", notes = if (exact) "E7.3 sibling without flagged species." else "Coarsened (IUCN CR/EN/VU species).",
    source_via = "EIDC data package (zip)")
  stage_tag_row(TABLE, ds, taxon_group = "Mammals", model_family = "Community occupancy",
    sampling_protocol = "camera_trap", design = "Single-season (115 sites, six weekly replicates)",
    realm = "Terrestrial", country = "MYS", coordinates = if (exact) "As published" else "Coarsened (0.1 deg)",
    notes = if (exact) "Unflagged species only." else "Threatened mammals; coordinates coarsened.")
}
emit("deere_2017_safe_mamm_comm", exact = FALSE)
emit("deere_2017_safe_mamm_exact_comm", exact = TRUE)
