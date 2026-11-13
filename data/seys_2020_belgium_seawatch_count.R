#!/usr/bin/env Rscript
# Tables: seys_2020_belgium_seawatch_count (push-net trawl, community), seys_2020_belgium_patella_count (limpets in
#         groyne quadrats) and seys_2020_belgium_arenicola_count (lugworm casts on the low beach); one script, one deposit.
# Source: VLIZ IPT (eurobis) resource seawatch-b, Darwin Core Archive (EML pubDate 2020-11-05, version 1.3); GBIF dataset
#         3b91f3e4-17da-4965-a8d5-4e8c9296477b, doi:10.14284/401; EurOBIS / EMODnet Biology IMIS dataset 6380 (found on
#         EDITO, the European Digital Twin of the Ocean). Licence: the IMIS record says CC BY-NC-SA 4.0, the EML and GBIF
#         say CC BY-NC 4.0; the stricter (CC BY-NC-SA 4.0) governs and propagates (intake policy, conflicts).
#         Citation: Seys J, Pint S, Vervaele K, Vanhaecke P, Van Landschoot W, Saevels M, Goossens H, Berkers M, Balcaen R,
#         Coppens S, Vanden Eede S, Fabrice A, Willaert M, Nelen L, Colpaert N, Quartier M, Verbeke D; Flanders Marine
#         Institute (VLIZ) (2020). SeaWatch-B: citizens monitoring the Belgian North Sea from the beach (2014-2018).
#         Marine Data Archive. doi:10.14284/401
# Paper:  none peer reviewed; Seys J et al. (2019) Hoe is de Noordzee eraan toe? VLIZ-Rapportage 2014-2018 (55 pp.) and
#         Seys J (2015) De Grote Rede 41: 28 describe the programme. Protocol from the EML: volunteers visit a beach about
#         once a season at low tide and, besides other counts, pull a small push net ('kruien', 'garnaalnet') along the
#         shore over a measured length (mostly 100 m), counting every animal of a fixed list of fish, crabs, shrimps and
#         jellyfish.
# Data:   Darwin Core Archive, event core (stationVisit -> sample) with occurrence and extendedMeasurementOrFact extensions.
#   event.txt (580 rows): 101 station visits (one per beach-date; 14 beaches, one coordinate pair each) and 479 samples,
#     one per method per visit: trawl (99), arenicula (101), beach (98), jelly (94), patella (87).
#   occurrence.txt (10,304 rows): trawl samples carry a row per code of the field sheet, present or absent: 96 codes in 95
#     trawls (95 in Duinbergen_17), and partial lists in three (Blankenberge_57: 11 codes all absent; Koksijde_49 and
#     Koksijde_53: one code each, absent). Flatfish codes are split by size class (<2.5, 2.5-5, 5-15, 15-25, >25 cm, and
#     'x' = not sized); the occurrenceID is <visit>_<code>.
#   extendedmeasurementorfact.txt (18,689 rows): the count of each occurrence ('Count (in assayed sample)'), size-class
#     limits, trawl length (m; 96 trawls) and duration (min; 51), and visit facts (air temperature, low tide time).
#   Counts are integers except four: '1 (11 cm)' (one Palaemon, length noted), '0 (maar daarna talrijk)' and '0 (erna
#     talrijk: op 2 kg garnaal. 800 gram Steurgarnaal)' (Palaemon: none in the counted haul, abundant afterwards; status
#     present) and '>1000' (Pleurobrachia pileus). Two absent occurrences have no count.
# Mapping (repeated counts, push-net community; responseType count): unit = beach (14), period = calendar year
#   (1 = 2014 ... 5 = 2018), occasion = trawl within the beach-year in date order, date = visit date. taxon = the 50
#   species and groups of the field sheet (taxonInclusion = target): flatfish size classes are summed within a trawl, and
#   the per-class counts ship as obs_len_* columns on those rows (NA for taxa the sheet does not size). The sheet's
#   'either A or B' and higher-rank boxes (unidentified flatfish, Scophthalmus turbot-or-brill, Pleuronectinae
#   flounder-or-dab, Clupeidae herring-or-sprat, Scyphozoa, Portunidae, Palaemon, amphipods) are their own taxa at the
#   rank given, with the source wording in taxonRemarks. y = individuals counted; '>1000' ships as 1000 with
#   obs_count_estimated = 1 (a lower bound; rulings 17/18); the text values are in y_raw; the two Palaemon '0 (abundant
#   afterwards)' rows ship as 0 (the count of the haul) with y_raw; two absent occurrences with no count ship as 0.
#   surveyEvidence = sample_table: the event core lists every trawl and the sheet has a row for every code at each.
#   obs_trawl_length_m, obs_trawl_duration_min (NA where not recorded), obs_air_temp_c (visit). unit coordinates as
#   published (one point per beach, public beaches; no flagged taxon).
# Not shipped: the three partial trawls; Duinbergen_17 (no row for one box, KKwaSpec: the net surveys every taxon at
#   once, so the trawl is dropped for all, shared-detector ruling 2026-11-06); the washed-up jellyfish and strandline
#   'beach' counts (other methods; wash-up, the E9 question held with ANEMOON); the Patella and Arenicola counts are the
#   two tables built at the end of this script (ruling 2026-11-13); individual lengths (4 rows); low tide time and trawl
#   start/end times.
# Protocol of the two sibling tables (SeaWatch-B field brochure, VLIZ, 'SEAWA folder.pdf', and Seys et al. 2019 pp.
#   10-11, 33): 'Schaalhorens op strandhoofd': on the groyne chosen at the first survey (kept on later visits unless
#   sanded over), at low tide as far seaward as possible, ten 0.5 x 0.5 m quadrats placed haphazardly over crest, east
#   and west flank; every Patella > 1 cm counted; sheet has one line per quadrat. 'Zeepieren': lugworm casts counted
#   just after low water on a 2 m wide strip, 100 m long, at 10 m and again at 30 m from the waterline; both counts and
#   areas summed ('.. zeepierhoopjes op .. m2 (normaliter: 400 m2)'); with very many casts a narrower or shorter strip may
#   be counted and scaled.
#   Deposit: one 'quadrat' event per Patella survey (87, no quadrat-level records) with a single occurrence
#   <visit>_Schaalh_TOT_2.5m2 (Patella vulgata, the total over the ten quadrats, area 2.5 m2 in the eMoF); one sample
#   event per Arenicola survey (101, every visit) with a single occurrence <visit>_PierAantal (Arenicola, genus) and the
#   area counted (200, 300, 400 or 800 m2). 83 Patella values are integers; four (2.19, 2.375, 2.77, 3.39) are means.
#   Mapping (both): unit = beach (the same 14 keys as the trawl table; the groyne is not identified beyond the beach
#   point), period = calendar year, occasion = survey within the beach-year in date order, date = visit date,
#   surveyEvidence = sample_table (the event core lists each survey). Quadrats are not occasions: the deposit has only
#   the visit total, so y = limpets > 1 cm in the ten quadrats (2.5 m2). Arenicola: y = casts counted (a sign of the
#   animal, not worms), effort obs_area_m2. Not shipped: the four Patella means (the count behind them is not
#   recoverable), and the per-quadrat counts and photos (never deposited).
for (p in c("lib/eco_common.R", "../lib/eco_common.R")) if (file.exists(p)) { source(p); break }
TABLE <- "seys_2020_belgium_seawatch_count"
zip <- download_cached("https://ipt.vliz.be/eurobis/archive.do?r=seawatch-b", TABLE, "dwca.zip")
dwca <- file.path(dirname(zip), "dwca")
if (!file.exists(file.path(dwca, "event.txt"))) unzip(zip, exdir = dwca)
stopifnot(setequal(list.files(dwca), c("event.txt", "occurrence.txt", "extendedmeasurementorfact.txt", "eml.xml", "meta.xml")))
eml <- paste(readLines(file.path(dwca, "eml.xml"), warn = FALSE, encoding = "UTF-8"), collapse = " ")
stopifnot(grepl("creativecommons.org/licenses/by-nc/4.0", eml, fixed = TRUE), grepl("2020-11-05", eml, fixed = TRUE))

rd <- function(f) fread(file.path(dwca, f), quote = "", colClasses = "character", na.strings = NULL, encoding = "UTF-8")
ev <- rd("event.txt"); oc <- rd("occurrence.txt"); mf <- rd("extendedmeasurementorfact.txt")
stopifnot(nrow(ev) == 580L, nrow(oc) == 10304L, nrow(mf) == 18689L, !anyDuplicated(ev$eventID), !anyDuplicated(oc$occurrenceID))
vis <- ev[type == "stationVisit"]
stopifnot(nrow(vis) == 101L, uniqueN(vis$locationID) == 14L,
          vis[, uniqueN(paste(decimalLatitude, decimalLongitude)), by = locationID][, all(V1 == 1L)],
          all(grepl("^\\d{4}-\\d{2}-\\d{2}$", vis$eventDate)))
tr <- ev[grepl("_trawl$", eventID)]
stopifnot(nrow(tr) == 99L, all(tr$type == "sample"), all(tr$parentEventID %in% vis$eventID), !anyDuplicated(tr$parentEventID),
          all(tr$eventDate == vis$eventDate[match(tr$parentEventID, vis$eventID)]))

# occurrences of the trawls, code = occurrenceID minus the visit prefix; counts from the eMoF
o <- oc[eventID %in% tr$eventID]
o[, visit := tr$parentEventID[match(eventID, tr$eventID)]]
stopifnot(all(startsWith(o$occurrenceID, paste0(o$visit, "_"))))
o[, code := substring(occurrenceID, nchar(visit) + 2L)]
cnt <- mf[measurementType == "Count (in assayed sample) of biological entity specified elsewhere", .(occurrenceID, v = measurementValue)]
stopifnot(!anyDuplicated(cnt$occurrenceID))
o <- merge(o, cnt, by = "occurrenceID", all.x = TRUE)
nper <- o[, .N, by = eventID]
stopifnot(sum(nper$N == 96L) == 95L, setequal(nper[N != 96L, paste(eventID, N)],
          c("Duinbergen_17_trawl 95", "Blankenberge_57_trawl 11", "Koksijde_49_trawl 1", "Koksijde_53_trawl 1")))
PARTIAL <- c("Blankenberge_57_trawl", "Koksijde_49_trawl", "Koksijde_53_trawl")
stopifnot(all(o[eventID %in% PARTIAL, occurrenceStatus == "absent"]))
allcodes <- unique(o[!eventID %in% PARTIAL, code])
# Duinbergen_17 lacks one box (KKwaSpec, unidentified jellyfish): the net surveys every taxon at once, so the trawl is
# dropped for all taxa (shared-detector ruling, 2026-11-06)
stopifnot(length(allcodes) == 96L, identical(setdiff(allcodes, o[eventID == "Duinbergen_17_trawl", code]), "KKwaSpec"))
DROPPED <- c(PARTIAL, "Duinbergen_17_trawl")
o <- o[!eventID %in% DROPPED]

# size classes of the flatfish boxes
SZ <- c("\\.2\\.5" = "lt2_5", "2\\.5[._]5" = "2_5to5", "5[._]15" = "5to15", "15[._]25" = "15to25", "\\.25" = "gt25", "x" = "unsized")
SIZED <- c("KBot", "KBotSch", "KGriet", "KPlatv", "KSchar", "KSchol", "KTarb", "KTarbGr", "KTong", "KZeeb")
o[, `:=`(base = code, size = NA_character_)]
for (b in SIZED) for (k in names(SZ)) o[grepl(paste0("^", b, k, "$"), code), `:=`(base = b, size = SZ[[k]])]
stopifnot(o[base %in% SIZED, .N] == o[!is.na(size), .N], o[!is.na(size), uniqueN(code), by = base][, all(V1 == fifelse(base == "KBotSch", 2L, 6L))],
          uniqueN(o$base) == 50L, o[, uniqueN(scientificName), by = base][, all(V1 == 1L)])

# counts: plain integers, four text values, two absent rows with no count
txt <- o[!is.na(v) & !grepl("^\\d+$", v), .(code, v, occurrenceStatus)]
stopifnot(setequal(txt$v, c("1_(11_cm)", "0_(maar_daarna_talrijk)", "0_(erna_talrijk:_op_2_kg_garnaal._800_gram_Steurgarnaal)", ">1000")),
          all(txt$occurrenceStatus == "present"), setequal(txt$code, c("KStGarn", "KZeeDruif")),
          o[is.na(v), .N] == 2L, all(o[is.na(v), occurrenceStatus] == "absent"))
o[, n := suppressWarnings(fcase(is.na(v), 0L, grepl("^\\d+$", v), as.integer(v), v == ">1000", 1000L, default = as.integer(sub("_.*", "", v))))]
o[, est := as.integer(!is.na(v) & v == ">1000")]
o[, raw := fifelse(!is.na(v) & !grepl("^\\d+$", v), gsub("_", " ", v), NA_character_)]
stopifnot(all((o$n > 0L) == (o$occurrenceStatus == "present") | o$raw %like% "^0 \\("))

# taxa of the field sheet
TX <- fread(text = "
base|taxon|sci|rank|lookup|remark
K3_puntsGarn|PHITRI|Philocheras trispinosus|species||
K5Meun|CILMUS|Ciliata mustela|species||
KAmRib|MNELEI|Mnemiopsis leidyi|species||
KBlHaarkw|CYALAM|Cyanea lamarckii|species||
KBlaasjeskrab|HEMSAN|Hemigrapsus sanguineus|species||
KBot|PLAFLE|Platichthys flesus|species||
KBotSch|PLEURN|Pleuronectinae|subfamily||field-sheet box 'bot/schar' (flounder or dab); source remark: either Platichthys flesus or Limanda limanda; GBIF backbone has no Pleuronectinae, so no taxonID
KBreedpKrab|PORLAT|Portumnus latipes|species||
KDwerginktvis|SEPATL|Sepiola atlantica|species||
KGGarn|CRACRA|Crangon crangon|species||
KGHerem|PAGBER|Pagurus bernhardus|species||
KGewZwemkr|LIOHOL|Liocarcinus holsatus|species||
KGrZeedonderpad|TAUBUB|Taurulus bubalis|species||
KGrZeenaald|SYNACU|Syngnathus acus|species||
KGriet|SCORHO|Scophthalmus rhombus|species||
KGrijzZwk|LIOVER|Liocarcinus vernalis|species||
KHarSprot|CLUPEI|Clupeidae|family||field-sheet box 'haring/sprot'; source remark: either Clupea harengus or Sprattus sprattus
KHaring|CLUHAR|Clupea harengus|species||
KHooiwkrab|MACROS|Macropodia rostrata|species||
KKHerem|DIOPUG|Diogenes pugilator|species||
KKompas|CHRHYS|Chrysaora hysoscella|species||
KKoornaarvis|ATHPRE|Atherina presbyter|species||
KKwaSpec|SCYPHO|Scyphozoa|class||field-sheet box 'kwal spec.': jellyfish not identified to species
KNZKrab|CANPAG|Cancer pagurus|species||
KParasolletje|EUTIND|Eutonina indicans|species||
KPieterman|ECHVIP|Echiichthys vipera|species||
KPitvis|CALLYR|Callionymus lyra|species||
KPlatv|PLEURF|Pleuronectiformes|order||field-sheet box 'platvis': flatfish not identified further
KSchKokW|LANCON|Lanice conchilega|species||
KSchar|LIMLIM|Limanda limanda|species||
KSchol|PLEPLA|Pleuronectes platessa|species||
KSlangster|OPHOPH|Ophiura ophiura|species||
KSlibanemoon|SAGTRO|Sagartia troglodytes|species||
KSpiering|OSMEPE|Osmerus eperlanus|species||
KSprot|SPRSPR|Sprattus sprattus|species||
KStGarn|PALAEM|Palaemon|genus||field-sheet box 'steurgarnaal' (Palaemon prawns), identified to genus
KStrKrab|CARMAE|Carcinus maenas|species||
KTarb|SCOMAX|Scophthalmus maximus|species||
KTarbGr|SCOPHT|Scophthalmus|genus||field-sheet box 'tarbot/griet'; source remark: either Scophthalmus maximus or Scophthalmus rhombus
KTong|SOLSOL|Solea solea|species||
KVlokreeftje|AMPHIP|Marinogammarus sp. & Haustorius arenarius|order|Amphipoda|field-sheet box 'vlokreeftje' (amphipods), source name 'Marinogammarus sp. & Haustorius arenarius' (WoRMS 101540 and 102317); keyed at Amphipoda
KZandspiering|AMMMAR|Ammodytes marinus|species||
KZeeDruif|PLEPIL|Pleurobrachia pileus|species||
KZeeappel|PSAMIL|Psammechinus miliaris|species||
KZeeb|DICLAB|Dicentrarchus labrax|species||
KZeeklit|ECHCOR|Echinocardium cordatum|species||
KZeepadd|RHICUV|Rhizostoma cuvieri|species||
KZeepissebed|IDOBAL|Idotea balthica|species||
KZeester|ASTRUB|Asterias rubens|species||
KZwKrbspec|PORTUN|Portunidae|family||field-sheet box 'zwemkrab spec.': swimming crabs not identified to species
", sep = "|", na.strings = "")
stopifnot(nrow(TX) == 50L, !anyDuplicated(TX$taxon), setequal(TX$base, o$base))
nm <- unique(o[, .(base, scientificName)]); nm <- merge(nm, TX, by = "base")
print(nm[scientificName != sci, .(base, scientificName, sci)])
stopifnot(nm[base != "KVlokreeftje", all(scientificName == sci)])

# per trawl x taxon: summed count, size-class counts as obs_len_* on sized taxa
o <- merge(o, TX[, .(base, taxon)], by = "base")
y <- o[, .(y = sum(n), est = max(est), y_raw = if (any(!is.na(raw))) paste(na.omit(raw), collapse = "; ") else NA_character_), by = .(eventID, taxon)]
szw <- dcast(o[!is.na(size)], eventID + taxon ~ size, value.var = "n", fun.aggregate = sum)
setnames(szw, setdiff(names(szw), c("eventID", "taxon")), paste0("obs_len_", setdiff(names(szw), c("eventID", "taxon"))))
y <- merge(y, szw, by = c("eventID", "taxon"), all.x = TRUE)
stopifnot(y[!is.na(obs_len_unsized), all(y == obs_len_lt2_5 + obs_len_2_5to5 + obs_len_5to15 + obs_len_15to25 + obs_len_gt25 + obs_len_unsized)],
          nrow(y) == 95L * 50L, y[, .N, by = eventID][, all(N == 50L)])

# trawl and visit facts
mv <- function(type) { x <- mf[measurementType == type]; stopifnot(!anyDuplicated(x$id)); setNames(x$measurementValue, x$id) }
tl <- mv("The physical length of a sample upon which measurements have been made, length that was trawled along the shore, transect length")
td <- mv("The period of time during which a sample was collected or an observation was made, duration of the trawl")
at <- mv("air temperature")
stopifnot(all(names(tl) %in% tr$eventID), all(names(td) %in% tr$eventID), all(names(at) %in% vis$eventID),
          all(grepl("^\\d+$", tl)), all(grepl("^\\d+$", td)), all(grepl("^-?\\d+(\\.\\d+)?$", at)))
tr <- tr[!eventID %in% DROPPED]
tr[, `:=`(unit = gsub("[^A-Za-z0-9]+", "_", tolower(locationID)), yr = as.integer(substr(eventDate, 1, 4)),
          obs_trawl_length_m = as.integer(tl[eventID]), obs_trawl_duration_min = as.integer(td[eventID]),
          obs_air_temp_c = as.numeric(at[parentEventID]), vn = as.integer(sub(".*_(\\d+)$", "\\1", parentEventID)))]
tr[, period := yr - 2013L]
setorder(tr, unit, eventDate, vn)
stopifnot(!anyDuplicated(tr[, .(unit, eventDate)]))
tr[, occasion := seq_len(.N), by = .(unit, period)]
vxy <- vis[match(tr$parentEventID, vis$eventID)]
tr[, `:=`(unit_decimalLatitude = as.numeric(vxy$decimalLatitude), unit_decimalLongitude = as.numeric(vxy$decimalLongitude),
          unit_beach = locationID)]

long <- merge(y, tr[, .(eventID, unit, period, occasion, date = eventDate, unit_beach, unit_decimalLatitude, unit_decimalLongitude,
                        obs_trawl_length_m, obs_trawl_duration_min, obs_air_temp_c)], by = "eventID")
long[, obs_count_estimated := est]
long <- long[, .(unit, taxon, y, y_raw, period, occasion, date, unit_beach, unit_decimalLatitude, unit_decimalLongitude,
                 obs_trawl_length_m, obs_trawl_duration_min, obs_air_temp_c, obs_count_estimated,
                 obs_len_lt2_5, obs_len_2_5to5, obs_len_5to15, obs_len_15to25, obs_len_gt25, obs_len_unsized)]
setorder(long, unit, period, occasion, taxon)
stopifnot(nrow(long) == 4750L, !anyNA(long$y), uniqueN(long$unit) == 14L, sum(long$obs_count_estimated) == 1L,
          sum(long$y) == sum(o$n), long[, uniqueN(paste(unit_decimalLatitude, unit_decimalLongitude)), by = unit][, all(V1 == 1L)])

taxa <- make_taxa(TX$taxon, TX$sci, taxonRank = TX$rank, lookupName = fifelse(is.na(TX$lookup), TX$sci, TX$lookup),
                  taxonRemarks = TX$remark, allow_higher = "PALAEM", no_key = "PLEURN")
taxa[, taxon_iucnCategory := unname(mapply(function(k, s) if (is.na(k)) NA_character_ else iucn_category(k, s), taxonID, scientificName))]
print(taxa[, .(taxon, scientificName, taxonRank, gbifMatchType, gbifAcceptedName, taxon_iucnCategory)])
stopifnot(!any(taxa$taxon_iucnCategory %in% c("VU", "EN", "CR")))
taxa[, taxon_size_classed := as.integer(taxon %in% TX[base %in% SIZED, taxon])]
periods <- data.table(period = 1:5, year = 2014:2018)
stopifnot(setequal(long$period, periods$period))

dataset <- list(
  title = sprintf("SeaWatch-B: citizen push-net counts of %d fish, crab, shrimp and jellyfish taxa in %d trawls at %d Belgian beaches, 2014-2018",
                  uniqueN(long$taxon), uniqueN(long[, .(unit, period, occasion)]), uniqueN(long$unit)),
  creator = "Seys, Jan; Pint, Silke; Vervaele, K.; Vanhaecke, P.; et al.; Flanders Marine Institute (VLIZ)",
  pubDate = "2020", doi = "10.14284/401", sourceURL = "https://doi.org/10.14284/401",
  citation = "Seys J, Pint S, Vervaele K, Vanhaecke P, Van Landschoot W, Saevels M, Goossens H, Berkers M, Balcaen R, Coppens S, Vanden Eede S, Fabrice A, Willaert M, Nelen L, Colpaert N, Quartier M, Verbeke D; Flanders Marine Institute (VLIZ) (2020). SeaWatch-B: citizens monitoring the Belgian North Sea from the beach (2014-2018). Marine Data Archive. https://doi.org/10.14284/401",
  intellectualRights = list(spdx = "CC-BY-NC-SA-4.0", url = "https://creativecommons.org/licenses/by-nc-sa/4.0/"),
  abstract = sprintf("SeaWatch-B is a VLIZ citizen-science programme in which volunteers visit Belgian beaches about once a season at low tide and record a fixed set of measurements. This table is the push-net component: a small shrimp net pulled along the shore (mostly over 100 m), with every animal of a %d-box field sheet counted (fish, crabs, shrimps, jellyfish, echinoderms). Flatfish are counted by size class; the table sums the classes and keeps them as obs_len_* columns. %d trawls at %d beaches, June 2014 to June 2018. One row per trawl and taxon, y = individuals counted; the unit is the beach, the period a calendar year, the occasion a trawl within it.",
                     uniqueN(long$taxon), uniqueN(long[, .(unit, period, occasion)]), uniqueN(long$unit)),
  samplingProtocol = "Push-net (hand-pulled shrimp net) haul along the shore at low tide over a measured length (mostly 100 m), by trained volunteers about once a season per beach; all individuals of the field-sheet taxa counted, flatfish by size class (Seys et al. 2020, EML).",
  samplingProtocolCode = "trawl", surveyEvidence = "sample_table", responseType = "count", unitKind = "site",
  closure = "open", closureNote = "Visits within a year are seasonal (one to seven per beach-year, mostly two to four), so abundance changes across the occasions of a period.",
  occasionKind = "time", taxonInclusion = "target", effortColumn = "obs_trawl_length_m",
  geographicCoverage = "Belgian North Sea coast: 14 beaches from Westende to Heist (one point per beach)",
  temporalCoverage = "2014-06/2018-06",
  coordinatesCoarsened = list(value = FALSE, method = "One point per beach as published; public beaches, no flagged taxon."),
  notes = "Citizen-science counts. The field sheet's higher-rank boxes (unidentified flatfish, Scophthalmus turbot-or-brill, Pleuronectinae flounder-or-dab, Clupeidae herring-or-sprat, Scyphozoa, Portunidae, Palaemon, amphipods) are their own taxa, overlapping the named species; taxonRemarks gives the source wording. Pleurobrachia pileus '>1000' at one trawl ships as 1000 with obs_count_estimated = 1. Two Palaemon counts are recorded as '0 (abundant afterwards)' and ship as 0 with the text in y_raw. Trawl length (obs_trawl_length_m, 50 to 450 m, mostly 100) and duration vary; effort is not standardised.",
  notShipped = list(partial_trawls = "3 trawls with partial field sheets (Blankenberge_57: 11 boxes, all absent; Koksijde_49 and Koksijde_53: one box each)",
                    trawl_missing_box = "Duinbergen_17: no row for the unidentified-jellyfish box, so the trawl is dropped for every taxon (shared-detector ruling)",
                    other_methods = "the visit's washed-up jellyfish and strandline counts: separate methods (the Patella and Arenicola counts are the sibling tables seys_2020_belgium_patella_count and seys_2020_belgium_arenicola_count)",
                    individual_lengths = "4 individual length measurements",
                    visit_times = "low tide time and survey start/end times"))
ds <- write_table(long, TABLE, dataset, taxa = taxa, periods = periods, script = sprintf("data/%s.R", TABLE))

stage_dict_row(TABLE,
  description = sprintf("SeaWatch-B citizen-science push-net counts of %d fish, crab, shrimp and jellyfish taxa on about seasonal visits to %d Belgian beaches, 2014-2018.",
                        uniqueN(long$taxon), uniqueN(long$unit)),
  url = "https://doi.org/10.14284/401",
  reference = "Seys J, et al.; Flanders Marine Institute (VLIZ) (2020). SeaWatch-B: citizens monitoring the Belgian North Sea from the beach (2014-2018). Marine Data Archive.",
  doi_paper = "", doi_data = "10.14284/401", original_license = "CC BY-NC-SA 4.0 (IMIS); CC BY-NC 4.0 (EML, GBIF); stricter governs",
  derived_license = "CC BY-NC-SA 4.0",
  notes = "VLIZ IPT DwC-A (seawatch-b, 2020-11-05), GBIF 3b91f3e4-17da-4965-a8d5-4e8c9296477b; found via EDITO / EurOBIS (IMIS 6380). Push-net component only.",
  source_via = "VLIZ IPT")
stage_tag_row(TABLE, ds, taxon_group = "Multiple", model_family = "N-mixture (multi-species, multi-season)",
  sampling_protocol = "trawl", design = "Multi-season (5 years; seasonal visits per beach)",
  realm = "Marine", country = "BEL", coordinates = "As published",
  notes = "Citizen-science shore push-net counts with flatfish size classes.")

# ---------------------------------------------------------------------------------------------------------------------
# Sibling tables (ruling 2026-11-13): Patella vulgata on groynes and Arenicola casts on the low beach, one count per visit
CNT_T <- "Count (in assayed sample) of biological entity specified elsewhere"
one_method <- function(suffix, n_ev, ev_type, occ_code, sci, area_type) {
  e <- ev[endsWith(eventID, paste0("_", suffix))]
  stopifnot(nrow(e) == n_ev, all(e$type == ev_type), all(e$parentEventID %in% vis$eventID), !anyDuplicated(e$parentEventID),
            all(e$eventID == paste0(e$parentEventID, "_", suffix)),
            all(e$eventDate == vis$eventDate[match(e$parentEventID, vis$eventID)]),
            all(e$locationID == vis$locationID[match(e$parentEventID, vis$eventID)]))
  x <- oc[eventID %in% e$eventID]
  stopifnot(nrow(x) == n_ev, !anyDuplicated(x$eventID), all(x$scientificName == sci),
            all(x$occurrenceID == paste0(e$parentEventID[match(x$eventID, e$eventID)], "_", occ_code)))
  m <- mf[id %in% e$eventID]
  stopifnot(setequal(unique(m$measurementType), c(CNT_T, area_type)), m[, .N, by = .(id, measurementType)][, all(N == 1L)],
            nrow(m) == 2L * n_ev, all(m[measurementType == CNT_T, occurrenceID] %in% x$occurrenceID))
  e[, `:=`(v = m[measurementType == CNT_T][match(e$eventID, id), measurementValue],
           area = m[measurementType == area_type][match(e$eventID, id), measurementValue],
           status = x$occurrenceStatus[match(e$eventID, x$eventID)])]
  stopifnot(!anyNA(e$v), !anyNA(e$area), all(grepl("^\\d+(\\.\\d+)?$", e$area)), all(grepl("^\\d+(\\.\\d+)?$", e$v)))
  e[, `:=`(unit = gsub("[^A-Za-z0-9]+", "_", tolower(locationID)), period = as.integer(substr(eventDate, 1, 4)) - 2013L,
           vn = as.integer(sub(".*_(\\d+)$", "\\1", parentEventID)), obs_air_temp_c = as.numeric(at[parentEventID]))]
  e[, `:=`(unit_decimalLatitude = as.numeric(vis$decimalLatitude[match(parentEventID, vis$eventID)]),
           unit_decimalLongitude = as.numeric(vis$decimalLongitude[match(parentEventID, vis$eventID)]))]
  e[]
}
sib_dataset <- function(title, abstract, protocol, code, notes, notShipped, units, extra = list()) c(list(
  title = title,
  creator = "Seys, Jan; Pint, Silke; Vervaele, K.; Vanhaecke, P.; et al.; Flanders Marine Institute (VLIZ)",
  pubDate = "2020", doi = "10.14284/401", sourceURL = "https://doi.org/10.14284/401",
  citation = dataset$citation, intellectualRights = dataset$intellectualRights,
  abstract = abstract, samplingProtocol = protocol, samplingProtocolCode = code, surveyEvidence = "sample_table",
  responseType = "count", unitKind = "site", closure = "open",
  closureNote = "Visits within a year are seasonal (mostly two to four per beach-year), so abundance changes across the occasions of a period.",
  occasionKind = "time", taxonInclusion = "single",
  geographicCoverage = sprintf("Belgian North Sea coast: %d beaches from Koksijde to Duinbergen (one point per beach)", units),
  temporalCoverage = "2014-06/2018-06",
  coordinatesCoarsened = list(value = FALSE, method = "One point per beach as published; public beaches, no flagged taxon."),
  notes = notes), extra, list(notShipped = notShipped))
finish <- function(e) {
  setorder(e, unit, eventDate, vn)
  stopifnot(!anyDuplicated(e[, .(unit, eventDate)]))
  e[, occasion := seq_len(.N), by = .(unit, period)]
  e
}

## Patella vulgata: total of ten 0.5 x 0.5 m quadrats on one groyne per visit
pa <- one_method("patella", 87L, "quadrat", "Schaalh_TOT_2.5m2", "Patella vulgata", "The area sampled of the shore for Patella vulgata sampling")
MEANS <- c("2.19", "2.375", "2.77", "3.39")
stopifnot(all(pa$area == "2.5"), setequal(pa[!grepl("^\\d+$", v), v], MEANS), sum(!grepl("^\\d+$", pa$v)) == 4L)
pa_means <- pa[v %in% MEANS, paste0(parentEventID, " (", v, ")")]
pa <- pa[!v %in% MEANS]
pa[, y := as.integer(v)]
stopifnot(all((pa$y > 0L) == (pa$status == "present")), nrow(pa) == 83L)
pa <- finish(pa)
TP <- "seys_2020_belgium_patella_count"
long_p <- pa[, .(unit, taxon = "PATVUL", y, period, occasion, date = eventDate, unit_beach = locationID,
                 unit_decimalLatitude, unit_decimalLongitude, obs_air_temp_c)]
setorder(long_p, unit, period, occasion)
stopifnot(nrow(long_p) == 83L, !anyNA(long_p$y))
taxa_p <- make_taxa("PATVUL", "Patella vulgata", vernacularName = "common limpet",
                    taxonRemarks = "Counted only above 1 cm shell length (protocol).")
taxa_p[, taxon_iucnCategory := unname(mapply(function(k, s) if (is.na(k)) NA_character_ else iucn_category(k, s), taxonID, scientificName))]
stopifnot(!any(taxa_p$taxon_iucnCategory %in% c("VU", "EN", "CR")))
periods_p <- data.table(period = 1:5, year = 2014:2018)[period %in% long_p$period]
np <- c(units = uniqueN(long_p$unit), surveys = nrow(long_p))
dataset_p <- sib_dataset(
  title = sprintf("SeaWatch-B: citizen counts of the common limpet Patella vulgata in ten quadrats on groynes, %d surveys at %d Belgian beaches, 2014-2018", np[["surveys"]], np[["units"]]),
  abstract = sprintf("SeaWatch-B is a VLIZ citizen-science programme in which volunteers visit Belgian beaches about once a season at low tide. On beaches with groynes, the volunteer returns to the groyne chosen at the first survey and, as far seaward as possible, places ten 0.5 x 0.5 m quadrats haphazardly over its crest and flanks, counting every limpet over 1 cm. The deposit gives the total of the ten quadrats (2.5 m2) per visit, not the quadrat counts, so the quadrats are not occasions here. %d surveys at %d beaches, 2014 to 2018. One row per survey, y = limpets counted in 2.5 m2; the unit is the beach (its groyne), the period a calendar year, the occasion a survey within it.", np[["surveys"]], np[["units"]]),
  protocol = "Ten 0.5 x 0.5 m quadrats placed haphazardly on one fixed groyne (crest, east and west flank) near the low-water line at low tide; all Patella vulgata > 1 cm counted; total over the ten quadrats (2.5 m2) deposited (SeaWatch-B field brochure, VLIZ; Seys et al. 2019).",
  code = "quadrat_count",
  notes = "Citizen-science counts. Only beaches with a groyne are surveyed (Seys et al. 2019: several beaches have none). The groyne is chosen at the first survey and kept unless it is sanded over; the deposit does not record a change of groyne. Sampled area is 2.5 m2 at every survey. Same units (beach keys) as the push-net table seys_2020_belgium_seawatch_count.",
  notShipped = list(mean_values = sprintf("4 surveys whose deposited value is a mean, not a count (%s): the count is not recoverable, so the survey is dropped", paste(pa_means, collapse = ", ")),
                    quadrat_counts = "per-quadrat counts and photos: recorded on the field sheet, not deposited"),
  units = np[["units"]])
ds_p <- write_table(long_p, TP, dataset_p, taxa = taxa_p, periods = periods_p, script = "data/seys_2020_belgium_seawatch_count.R")
stage_dict_row(TP,
  description = sprintf("SeaWatch-B citizen-science counts of the common limpet Patella vulgata in ten 0.5 x 0.5 m quadrats on a groyne, seasonal visits to %d Belgian beaches, 2014-2018.", np[["units"]]),
  url = "https://doi.org/10.14284/401",
  reference = "Seys J, et al.; Flanders Marine Institute (VLIZ) (2020). SeaWatch-B: citizens monitoring the Belgian North Sea from the beach (2014-2018). Marine Data Archive.",
  doi_paper = "", doi_data = "10.14284/401", original_license = "CC BY-NC-SA 4.0 (IMIS); CC BY-NC 4.0 (EML, GBIF); stricter governs",
  derived_license = "CC BY-NC-SA 4.0",
  notes = "VLIZ IPT DwC-A (seawatch-b, 2020-11-05), GBIF 3b91f3e4-17da-4965-a8d5-4e8c9296477b; found via EDITO / EurOBIS (IMIS 6380). Patella component; 4 mean values dropped.",
  source_via = "VLIZ IPT")
stage_tag_row(TP, ds_p, taxon_group = "Invertebrates", model_family = "N-mixture (single-species, multi-season)",
  sampling_protocol = "quadrat_count", design = "Multi-season (5 years; seasonal visits per beach)",
  realm = "Marine", country = "BEL", coordinates = "As published",
  notes = "Citizen-science limpet counts on groynes, total of ten quadrats per visit.")

## Arenicola: casts on two 2 m strips (normally 2 x 100 m = 400 m2) per visit
ar <- one_method("arenicula", 101L, "sample", "PierAantal", "Arenicola", "The area sampled of the shore for Arenicola sp. sandpiles")
stopifnot(all(grepl("^\\d+$", ar$v)), setequal(ar$area, c("200", "300", "400", "800")), sum(ar$area == "400") == 90L)
ar[, `:=`(y = as.integer(v), obs_area_m2 = as.integer(area))]
stopifnot(all((ar$y > 0L) == (ar$status == "present")), nrow(ar) == nrow(vis), setequal(ar$parentEventID, vis$eventID))
ar <- finish(ar)
TA <- "seys_2020_belgium_arenicola_count"
long_a <- ar[, .(unit, taxon = "ARENIC", y, period, occasion, date = eventDate, unit_beach = locationID,
                 unit_decimalLatitude, unit_decimalLongitude, obs_area_m2, obs_air_temp_c)]
setorder(long_a, unit, period, occasion)
stopifnot(nrow(long_a) == 101L, !anyNA(long_a$y), uniqueN(long_a$unit) == 14L)
taxa_a <- make_taxa("ARENIC", "Arenicola", vernacularName = "lugworms", taxonRank = "genus", lookupName = "Arenicola Lamarck, 1801",
                    taxonRemarks = "y counts casts (the coiled 'toothpaste' sand heaps a lugworm leaves at its burrow), a sign of the animal, not worms. The deposit identifies to genus; the protocol's 'zeepier' is the lugworm, on Belgian beaches mainly Arenicola marina.")
taxa_a[, taxon_iucnCategory := NA_character_]
periods_a <- data.table(period = 1:5, year = 2014:2018)[period %in% long_a$period]
na_ <- c(units = uniqueN(long_a$unit), surveys = nrow(long_a))
dataset_a <- sib_dataset(
  title = sprintf("SeaWatch-B: citizen counts of lugworm (Arenicola) casts on the low beach, %d surveys at %d Belgian beaches, 2014-2018", na_[["surveys"]], na_[["units"]]),
  abstract = sprintf("SeaWatch-B is a VLIZ citizen-science programme in which volunteers visit Belgian beaches about once a season at low tide. Just after low water the volunteer walks 100 m along a 2 m wide strip 10 m from the waterline and again 30 m from it, counting lugworm casts, and records the total and the area counted (normally 400 m2). y is the number of casts, a sign of the animal, not a count of worms. %d surveys (every visit) at %d beaches, June 2014 to June 2018. One row per survey; the unit is the beach, the period a calendar year, the occasion a survey within it; obs_area_m2 is the area counted.", na_[["surveys"]], na_[["units"]]),
  protocol = "Lugworm casts counted just after low water on two 2 m wide strips, 100 m long, at 10 m and 30 m from the waterline; counts and areas summed (normally 400 m2); with very many casts a narrower or shorter strip may be counted (SeaWatch-B field brochure, VLIZ; Seys et al. 2019).",
  code = "sign_survey",
  notes = sprintf("Citizen-science counts of casts, not of worms: a worm can leave more than one cast between tides and bait digging disturbs the beach. Area counted varies (obs_area_m2: 200 m2 at %d surveys, 300 at %d, 400 at %d, 800 at %d); the brochure allows a reduced strip when casts are very many and says the counts are then scaled, and the deposit does not say whether any value is a scaled count. The deposit identifies the taxon to genus (Arenicola). Same units (beach keys) as the push-net table seys_2020_belgium_seawatch_count.",
                  sum(long_a$obs_area_m2 == 200L), sum(long_a$obs_area_m2 == 300L), sum(long_a$obs_area_m2 == 400L), sum(long_a$obs_area_m2 == 800L)),
  notShipped = list(none = "nothing: every visit has one cast count and its area"),
  units = na_[["units"]], extra = list(effortColumn = "obs_area_m2"))
ds_a <- write_table(long_a, TA, dataset_a, taxa = taxa_a, periods = periods_a, script = "data/seys_2020_belgium_seawatch_count.R")
stage_dict_row(TA,
  description = sprintf("SeaWatch-B citizen-science counts of lugworm (Arenicola) casts, a sign of the worms, on two low-beach strips (normally 400 m2), seasonal visits to %d Belgian beaches, 2014-2018.", na_[["units"]]),
  url = "https://doi.org/10.14284/401",
  reference = "Seys J, et al.; Flanders Marine Institute (VLIZ) (2020). SeaWatch-B: citizens monitoring the Belgian North Sea from the beach (2014-2018). Marine Data Archive.",
  doi_paper = "", doi_data = "10.14284/401", original_license = "CC BY-NC-SA 4.0 (IMIS); CC BY-NC 4.0 (EML, GBIF); stricter governs",
  derived_license = "CC BY-NC-SA 4.0",
  notes = "VLIZ IPT DwC-A (seawatch-b, 2020-11-05), GBIF 3b91f3e4-17da-4965-a8d5-4e8c9296477b; found via EDITO / EurOBIS (IMIS 6380). Arenicola component; y = casts, not worms.",
  source_via = "VLIZ IPT")
stage_tag_row(TA, ds_a, taxon_group = "Invertebrates", model_family = "N-mixture (single-species, multi-season)",
  sampling_protocol = "sign_survey", design = "Multi-season (5 years; seasonal visits per beach)",
  realm = "Marine", country = "BEL", coordinates = "As published",
  notes = "Citizen-science lugworm cast counts (a sign, not individuals) with area counted as effort.")
