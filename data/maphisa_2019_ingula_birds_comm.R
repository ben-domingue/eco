#!/usr/bin/env Rscript
# Table:  maphisa_2019_ingula_birds_comm
# Source: Dryad doi:10.5061/dryad.pn3623b (CC0 1.0 as shown on the dataset JSON), version 23402
#   (published 2019-02-21). Maphisa, D. H., Smit-Robinson, H. & Altwegg, R. Data from: Dynamic
#   multi-species occupancy models reveal individualistic habitat preferences in a high-altitude
#   grassland bird community.
# Paper:  Maphisa, D. H., Smit-Robinson, H. & Altwegg, R. (2019). PeerJ 7, e6276,
#   doi:10.7717/peerj.6276 (open access; Europe PMC PMC6378914). Methods: 19 random 500 m x 500 m
#   plots at Eskom's Ingula Pumped Storage Scheme and neighbouring farms (P03A, P10, P50, P54, P57,
#   P63, P64 on private land), KwaZulu-Natal / Free State, South Africa; one observer (DHM) walked
#   a fixed route inside each plot for 30 min recording all birds seen in the plot and those heard
#   from within it; in November 2011 to February 2012 each plot was visited three times a month,
#   the third visit also recording vegetation. The paper models 12 common species month by month.
# Data:   Birds_veg_plot data seasons all rvsn.xlsx, one sheet, 3,936 rows, one per bird record:
#           Date (Excel serial), Month, Season (Autumn 2010 ... Summer 2011-12), Surv-Type (birds /
#           vegetation: the third visit of a month, when vegetation was also measured), Survey
#           (1-3), Plot (20 labels: the paper's 19 plus P04, surveyed in 2010 only), Where / Farm
#           (land owner and farm; not constant within plot on a few records), Weather, Wind, two
#           visibility readings, Species (English names, family name first: "Pipit African"),
#           Time (min) into the walk, Status / Category / Breeding / desired / unimportant /
#           negative indicators (species attributes and breeding evidence), Start time (fraction
#           of a day), Day (time-of-day label), grid (min), Animals (livestock present / absent),
#           Total (1 on every row that has it). 2010-2011 seasons: 4 to 12 plots per survey;
#           November 2011 to February 2012: the 19 plots, 3 surveys a month, except P66, not surveyed in November (asserted).
#         Study plots vegetation Summers 2010-12.xlsx: quadrat-level grass height and cover per plot
#           and survey (summers only).
# Mapping (community occupancy, multi-season): unit = plot, period = calendar month in time order
#   (11 months from March 2010 to February 2012, __periods gives year and month; 351 surveys), occasion = the
#   source's survey number within the month (1-3; in the 2010 seasons a month can hold only survey
#   1 or only survey 2 of the season), y = 1 if the species has at least one record in the survey,
#   y_raw = the number of records. A survey (plot x month x survey number) exists where the sheet
#   has at least one record for it: surveyEvidence = row_presence (a 30-minute walk that recorded
#   no bird would have no row; the record table has no other list of visits). date = the survey's
#   first date; obs_survey_days = 2 for the 12 surveys whose records span two dates.
#   obs_vegetation_visit = 1 on the surveys typed "vegetation" (the visit that also measured
#   grass), 0 otherwise.
#   Taxa: English names resolved to scientific names by hand (the table below), after normalising
#   case and spacing. Spelling variants of one name are one taxon ("Kite Blackshouldered",
#   "Cisticola Levallaint's", "cliff-swallow South African"); so are the source's two names for
#   one species: Fan-tailed and Zitting Cisticola (Cisticola juncidis), White-bellied Bustard and
#   White-bellied Korhaan (Eupodotis senegalensis), Wattled and African Wattled Lapwing (Vanellus
#   senegallus), Pied Crow. Names that do not identify one species are their own taxa at the rank
#   they do identify (E6): "Bishop Southern Golden" (Euplectes, genus), "Swift African" and "Swift
#   Black" (Apus, genus; neither is a current southern African name and they may be African Black
#   Swift or another Apus), "Swallow banded" (Hirundinidae, family). Merged taxa keep a row per
#   survey with y = 1 if any of their names was recorded and y_raw the summed records.
#   Coordinates: none deposited (the paper's map only). Several species are IUCN-listed
#   (Grey Crowned Crane, Secretarybird, Martial Eagle, Black Harrier EN; Blue and Wattled Crane,
#   Southern Bald Ibis, Cape Vulture, Yellow-breasted Pipit VU), so nothing locates a plot more
#   finely than the source does; farm names are not shipped (they are inconsistent within plot).
# Not shipped: Weather, Wind, visibility, Start time, Day (they vary between records of one survey,
#   so they are not survey covariates as deposited); Time (min) and grid (record-level timing);
#   Status, Category, Breeding, desired, unimportant, negative indicators (species attributes and
#   per-record breeding notes); Animals (livestock, recorded per record); Where / Farm; the
#   vegetation workbook (quadrat-level measurements: plot-survey summaries would be derived).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
suppressPackageStartupMessages(library(readxl))
TABLE <- "maphisa_2019_ingula_birds_comm"
dir <- download_dryad("10.5061/dryad.pn3623b", TABLE)
stopifnot(identical(attr(dir, "license"), "https://spdx.org/licenses/CC0-1.0.html"))
f <- file.path(dir, "Birds_veg_plot data seasons all rvsn.xlsx")
stopifnot(file.exists(f), length(excel_sheets(f)) == 1L)
d <- as.data.table(read_excel(f, col_types = "text"))
setnames(d, make.names(names(d), unique = TRUE))
stopifnot(nrow(d) == 3936L, !anyNA(d$Species), !anyNA(d$Plot), !anyNA(d$Date), !anyNA(d$Survey),
          all(d$Survey %in% c("1", "2", "3")), all(d$Surv.Type %in% c("birds", "vegetation")),
          all(d[Surv.Type == "vegetation"]$Survey == "3"), uniqueN(d$Plot) == 20L, all(d$Total %in% c("1", NA)))
d[, dt := as.IDate(as.numeric(Date), origin = "1899-12-30")]
d[, ym := format(dt, "%Y-%m")]
stopifnot(all(d$dt %between% as.IDate(c("2010-03-01", "2012-02-29"))))
months <- sort(unique(d$ym))
stopifnot(identical(months, c("2010-03", "2010-04", "2010-06", "2010-07", "2010-10", "2010-12", "2011-03",
                              "2011-11", "2011-12", "2012-01", "2012-02")))
# Nov 2011 - Feb 2012: the 19 paper plots, three surveys a month (P66 not surveyed in November)
s <- unique(d[ym >= "2011-11", .(Plot, ym, Survey)])
stopifnot(nrow(s) == 19L * 4L * 3L - 3L, identical(setdiff(unique(s$Plot), s[ym == "2011-11"]$Plot), "P66"), setequal(s$Plot, c("P01", "P03", "P03A", "P07", "P10", "P22", "P38", "P39", "P40",
          "P41", "P42", "P50", "P54", "P57", "P63", "P64", "P65", "P66", "P70")))
stopifnot(all(d[, uniqueN(Surv.Type), by = .(Plot, ym, Survey)]$V1 == 1L))

# species names -> taxa
d[, sp := tolower(gsub("\\s+", " ", trimws(Species)))]
S <- fread(text = "
name|taxon|scientificName|vernacularName|taxonRank
bishop southern golden|EUPLEC|Euplectes|bishop (recorded as Southern Golden Bishop)|genus
bishop southern-red|EUPORI|Euplectes orix|Southern Red Bishop|species
bishop yellow-crowned|EUPAFE|Euplectes afer|Yellow-crowned Bishop|species
bustard denham's|NEODEN|Neotis denhami|Denham's Bustard|species
bustard white-bellied|EUPSEN|Eupodotis senegalensis|White-bellied Bustard|species
korhaan white-bellied|EUPSEN|Eupodotis senegalensis|White-bellied Bustard|species
buzzard jackal|BUTRUF|Buteo rufofuscus|Jackal Buzzard|species
buzzard steppe|BUTBUT|Buteo buteo|Common (Steppe) Buzzard|species
canary cape|SERCAN|Serinus canicollis|Cape Canary|species
chat ant-eating|MYRFOR|Myrmecocichla formicivora|Ant-eating Chat|species
cisticola cloud|CISTEX|Cisticola textrix|Cloud Cisticola|species
cisticola croaking|CISNAT|Cisticola natalensis|Croaking Cisticola|species
cisticola fan-tailed|CISJUN|Cisticola juncidis|Zitting Cisticola|species
cisticola zitting|CISJUN|Cisticola juncidis|Zitting Cisticola|species
cisticola levaillant's|CISTIN|Cisticola tinniens|Levaillant's Cisticola|species
cisticola levallaint's|CISTIN|Cisticola tinniens|Levaillant's Cisticola|species
cisticola pale-crowned|CISCIN|Cisticola cinnamomeus|Pale-crowned Cisticola|species
cisticola wing-snapping|CISAYR|Cisticola ayresii|Wing-snapping Cisticola|species
common fiscal|LANCOL|Lanius collaris|Southern Fiscal|species
crane blue|GRUPAR|Grus paradisea|Blue Crane|species
crane grey crowned|BALREG|Balearica regulorum|Grey Crowned Crane|species
crane wattled|BUGCAR|Bugeranus carunculatus|Wattled Crane|species
crow cape|CORCAP|Corvus capensis|Cape Crow|species
crow pied|CORALB|Corvus albus|Pied Crow|species
pied crow|CORALB|Corvus albus|Pied Crow|species
cuckoo-finch african|ANOIMB|Anomalospiza imberbis|Cuckoo-finch|species
dove cape-turtle|STRCAP|Streptopelia capicola|Ring-necked (Cape Turtle) Dove|species
duck white-faced|DENVID|Dendrocygna viduata|White-faced Whistling Duck|species
duck yellow-billed|ANAUND|Anas undulata|Yellow-billed Duck|species
eagle black|AQUVER|Aquila verreauxii|Verreaux's (Black) Eagle|species
eagle martial|POLBEL|Polemaetus bellicosus|Martial Eagle|species
egret cattle|BUBIBI|Bubulcus ibis|Cattle Egret|species
falcon amur|FALAMU|Falco amurensis|Amur Falcon|species
falcon lanner|FALBIA|Falco biarmicus|Lanner Falcon|species
francolin red-winged|SCLLEV|Scleroptila levaillantii|Red-winged Francolin|species
goose spur-winged|PLEGAM|Plectropterus gambensis|Spur-winged Goose|species
harrier african marsh|CIRRAN|Circus ranivorus|African Marsh Harrier|species
harrier black|CIRMAU|Circus maurus|Black Harrier|species
harrier montagu|CIRPYG|Circus pygargus|Montagu's Harrier|species
harrier-hawk african|POLTYP|Polyboroides typus|African Harrier-Hawk|species
heron black-headed|ARDMEL|Ardea melanocephala|Black-headed Heron|species
heron grey|ARDCIN|Ardea cinerea|Grey Heron|species
ibis hadeda|BOSHAG|Bostrychia hagedash|Hadada Ibis|species
ibis sacred|THRAET|Threskiornis aethiopicus|African Sacred Ibis|species
ibis southern bald|GERCAL|Geronticus calvus|Southern Bald Ibis|species
kestrel rock|FALRUP|Falco rupicolus|Rock Kestrel|species
kite black-shouldered|ELACAE|Elanus caeruleus|Black-winged (Black-shouldered) Kite|species
kite blackshouldered|ELACAE|Elanus caeruleus|Black-winged (Black-shouldered) Kite|species
lapwing african wattled|VANSEN|Vanellus senegallus|African Wattled Lapwing|species
lapwing wattled|VANSEN|Vanellus senegallus|African Wattled Lapwing|species
lapwing black-smith|VANARM|Vanellus armatus|Blacksmith Lapwing|species
lapwing black-winged|VANMEL|Vanellus melanopterus|Black-winged Lapwing|species
lapwing crowned|VANCOR|Vanellus coronatus|Crowned Lapwing|species
lark eastern long-billed|CERSEM|Certhilauda semitorquata|Eastern Long-billed Lark|species
lark pink-billed|SPICON|Spizocorys conirostris|Pink-billed Lark|species
lark red-capped|CALCIN|Calandrella cinerea|Red-capped Lark|species
lark rufous-naped|MIRAFR|Mirafra africana|Rufous-naped Lark|species
lark spike-heeled|CHEALB|Chersomanes albofasciata|Spike-heeled Lark|species
longclaw cape|MACCAP|Macronyx capensis|Cape Longclaw|species
martin banded|RIPCIN|Riparia cincta|Banded Martin|species
pigeon speckled|COLGUI|Columba guinea|Speckled Pigeon|species
pipit african|ANTCIN|Anthus cinnamomeus|African Pipit|species
pipit plain-backed|ANTLEU|Anthus leucophrys|Plain-backed Pipit|species
pipit yellow-breasted|ANTCHL|Anthus chloris|Yellow-breasted Pipit|species
quail common|COTCOT|Coturnix coturnix|Common Quail|species
quailfinch african|ORTATR|Ortygospiza atricollis|African Quailfinch|species
raven white-necked|CORALC|Corvus albicollis|White-necked Raven|species
secretarybird|SAGSER|Sagittarius serpentarius|Secretarybird|species
snipe african|GALNIG|Gallinago nigripennis|African Snipe|species
starling pied|LAMBIC|Lamprotornis bicolor|Pied Starling|species
stock black|CICNIG|Ciconia nigra|Black Stork|species
stonechat african|SAXTOR|Saxicola torquatus|African Stonechat|species
stork white|CICCIC|Ciconia ciconia|White Stork|species
sunbird malachite|NECFAM|Nectarinia famosa|Malachite Sunbird|species
swallow barn|HIRRUS|Hirundo rustica|Barn Swallow|species
swallow greater-striped|CECCUC|Cecropis cucullata|Greater Striped Swallow|species
swallow white-throated|HIRALB|Hirundo albigularis|White-throated Swallow|species
swallow banded|HIRUND|Hirundinidae|swallows and martins (recorded as 'Swallow banded')|family
swallow-cliff south african|PETSPI|Petrochelidon spilodera|South African Cliff Swallow|species
cliff-swallow south african|PETSPI|Petrochelidon spilodera|South African Cliff Swallow|species
swift african|APUSSP|Apus|swifts (recorded as 'Swift African' or 'Swift Black')|genus
swift black|APUSSP|Apus|swifts (recorded as 'Swift African' or 'Swift Black')|genus
swift african black|APUBAR|Apus barbatus|African Black Swift|species
swift alpine|TACMEL|Tachymarptis melba|Alpine Swift|species
swift horus|APUHOR|Apus horus|Horus Swift|species
swift white-rumped|APUCAF|Apus caffer|White-rumped Swift|species
tern whikered|CHLHYB|Chlidonias hybrida|Whiskered Tern|species
thick-knee spotted|BURCAP|Burhinus capensis|Spotted Thick-knee|species
thrush sentinel rock|MONEXP|Monticola explorator|Sentinel Rock Thrush|species
vulture cape|GYPCOP|Gyps coprotheres|Cape Vulture|species
wagtail cape|MOTCAP|Motacilla capensis|Cape Wagtail|species
warbler little-rush|BRABAB|Bradypterus baboecala|Little Rush Warbler|species
waxbill common|ESTAST|Estrilda astrild|Common Waxbill|species
waxbill orange-breasted|AMASUB|Amandava subflava|Orange-breasted (Zebra) Waxbill|species
weaver cape|PLOCAP|Ploceus capensis|Cape Weaver|species
wheater mountain|MYRMON|Myrmecocichla monticola|Mountain Wheatear|species
whydah pin-tailed|VIDMAC|Vidua macroura|Pin-tailed Whydah|species
widowbird fan-tailed|EUPAXI|Euplectes axillaris|Fan-tailed Widowbird|species
widowbird long-tailed|EUPPRO|Euplectes progne|Long-tailed Widowbird|species
woodpecker ground|GEOOLI|Geocolaptes olivaceus|Ground Woodpecker|species
", sep = "|")
stopifnot(!anyDuplicated(S$name), setequal(S$name, unique(d$sp)), all(S[, uniqueN(scientificName), by = taxon]$V1 == 1L),
          all(S[, uniqueN(taxon), by = scientificName]$V1 == 1L))
d[, taxon := S$taxon[match(sp, S$name)]]

# surveys and records
sv <- d[, .(date = min(dt), days = uniqueN(dt), veg = as.integer(Surv.Type[1] == "vegetation")), by = .(Plot, ym, Survey)]
stopifnot(nrow(sv) == 351L, sum(sv$days == 2L) == 12L, all(sv$days %in% 1:2))
rec <- d[, .N, by = .(Plot, ym, Survey, taxon)]
tx <- sort(unique(S$taxon))
long <- CJ(k = seq_len(nrow(sv)), taxon = tx)
long <- cbind(sv[long$k], taxon = long$taxon)
long <- merge(long, rec, by = c("Plot", "ym", "Survey", "taxon"), all.x = TRUE)
long[is.na(N), N := 0L]
stopifnot(sum(long$N) == nrow(d), nrow(long) == 351L * length(tx))
long <- long[, .(unit = Plot, taxon, y = as.integer(N > 0), y_raw = as.character(N), period = match(ym, months),
                 occasion = as.integer(Survey), date = as.character(date), obs_survey_days = days, obs_vegetation_visit = veg)]
long <- order_eco(long)

tt <- unique(S[, .(taxon, scientificName, vernacularName, taxonRank)])[order(taxon)]
names_by <- S[, .(names = paste0("'", paste(unique(name), collapse = "', '"), "'")), by = taxon]
tt[, taxonRemarks := ifelse(taxon %in% names_by[grepl(",", names), taxon] | taxonRank != "species",
                            paste0("source names (case-normalised): ", names_by$names[match(taxon, names_by$taxon)]), NA_character_)]
tt[taxon == "CISJUN", taxonRemarks := paste(taxonRemarks, "- Fan-tailed Cisticola is the former southern African name of the Zitting Cisticola")]
tt[taxon == "EUPLEC", taxonRemarks := paste(taxonRemarks, "- not a current name; Golden Bishop has been used for E. afer and Yellow Bishop is E. capensis, so kept at genus rank")]
tt[taxon == "APUSSP", taxonRemarks := paste(taxonRemarks, "- neither name identifies one species (Black Swift has been used for A. barbatus, which the source also records as 'Swift African Black'), so kept at genus rank")]
tt[taxon == "HIRUND", taxonRemarks := paste(taxonRemarks, "- no swallow of this name; possibly Banded Martin (Riparia cincta, recorded separately as 'Martin Banded'), kept at family rank")]
# GBIF strict matching needs the authority for the genus Apus (also a crustacean genus name)
tt[, lookupName := ifelse(scientificName == "Apus", "Apus Scopoli, 1777", scientificName)]
taxa <- make_taxa(tt$taxon, tt$scientificName, vernacularName = tt$vernacularName, taxonRank = tt$taxonRank,
                  lookupName = tt$lookupName, taxonRemarks = tt$taxonRemarks)
periods <- data.table(period = seq_along(months), year = as.integer(substr(months, 1, 4)), month = as.integer(substr(months, 6, 7)))

dataset <- list(
  title = "Grassland bird surveys on 20 plots at Ingula, KwaZulu-Natal / Free State, South Africa: 30-minute walks, March 2010 to February 2012, three a month in the 2011-12 summer",
  creator = "Maphisa, David H.; Smit-Robinson, Hanneline; Altwegg, Res",
  pubDate = "2019", doi = "10.5061/dryad.pn3623b", sourceURL = "https://doi.org/10.5061/dryad.pn3623b",
  citation = "Maphisa, D. H., Smit-Robinson, H., & Altwegg, R. (2019). Data from: Dynamic multi-species occupancy models reveal individualistic habitat preferences in a high-altitude grassland bird community [Dataset]. Dryad. https://doi.org/10.5061/dryad.pn3623b",
  paperDOI = "10.7717/peerj.6276",
  intellectualRights = list(spdx = "CC0-1.0", url = "https://creativecommons.org/publicdomain/zero/1.0/"),
  abstract = "Bird records from 30-minute walked surveys of 500 m x 500 m plots in the high-altitude grasslands of the Ingula Important Bird and Biodiversity Area and neighbouring farms, South Africa. All the paper's study plots (every plot but P04) were surveyed three times a month from November 2011 to February 2012 (P66 not in November), the season the paper models with a dynamic multi-species occupancy model; earlier surveys from March 2010 to March 2011 cover 4 to 12 plots in single months of each season.",
  samplingProtocol = "One observer walked a fixed route 150 m inside the edge of a 500 m x 500 m plot at constant pace for 30 minutes, recording all birds seen inside the plot and birds heard calling from within it; up to three surveys per plot per month, the third also measuring grass height and cover.",
  samplingProtocolCode = "transect_count", surveyEvidence = "row_presence",
  responseType = "detection", unitKind = "site",
  closure = "closed", occasionKind = "time", taxonInclusion = "recorded",
  closureNote = "surveys within a calendar month are the replicates (the paper's primary period is the month and the repeat surveys were close together); months are periods",
  geographicCoverage = "Ingula Pumped Storage Scheme and neighbouring farms, near Van Reenen, on the KwaZulu-Natal / Free State escarpment, South Africa (about 28.2 S, 29.6 E); no plot coordinates deposited",
  temporalCoverage = "2010-03/2012-02",
  notShipped = list(record_conditions = "Weather, Wind, visibility, Start time and Day: they vary between records of one survey in the sheet, so they are not survey covariates as deposited",
                    record_timing = "Time (min) and grid (min): timing of each record within the walk",
                    species_attributes = "Status, Category, desired, unimportant, negative indicators (species attributes) and Breeding (per-record breeding evidence)",
                    livestock = "Animals (livestock present / absent, per record)",
                    land = "Where and Farm (land owner and farm, inconsistent within plot on a few records)",
                    vegetation_workbook = "Study plots vegetation Summers 2010-12.xlsx: quadrat-level grass height and cover; plot-survey summaries would be derived values"),
  notes = "y_raw is the number of records of the taxon on the survey (each record has Total = 1; whether a record is one bird is not stated). Taxa resolved from English names by hand; spelling variants and the source's two names for one species are merged and taxonRemarks lists the names. Three ambiguous names are kept at genus or family rank. A survey with no bird record would be missing (the sheet is the only record of visits). P04 was surveyed in 2010 only and is not one of the paper's 19 plots.")
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = "data/maphisa_2019_ingula_birds_comm.R")

stage_dict_row(TABLE,
  description = "Detection of 92 grassland bird taxa on 30-minute walked surveys of 20 plots at Ingula, KwaZulu-Natal / Free State, South Africa, in 11 months from March 2010 to February 2012, with the paper's study plots (all but P04) surveyed three times a month in the 2011-12 breeding season.",
  url = "https://doi.org/10.5061/dryad.pn3623b",
  reference = "Maphisa, D. H., Smit-Robinson, H., & Altwegg, R. (2019). Dynamic multi-species occupancy models reveal individualistic habitat preferences in a high-altitude grassland bird community. PeerJ, 7, e6276.",
  doi_paper = "10.7717/peerj.6276", doi_data = "10.5061/dryad.pn3623b",
  original_license = "CC0 1.0", derived_license = "CC0 1.0",
  notes = "Community occupancy from a record table (row_presence); English names resolved by hand, synonyms merged, three ambiguous names at genus or family rank; y_raw = records per survey.",
  source_via = "Dryad (version zip)")
stage_tag_row(TABLE, ds, taxon_group = "Birds", model_family = "Community occupancy (multi-season; months as periods)",
  sampling_protocol = "transect_count", design = "Multi-season (11 months, 2010-2012; up to 3 surveys a month)",
  realm = "Terrestrial", country = "ZAF", coordinates = "None in source",
  notes = "High-altitude grassland IBA; several threatened species (cranes, Southern Bald Ibis, Yellow-breasted Pipit).")
