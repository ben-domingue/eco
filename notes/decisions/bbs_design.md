# Breeding Bird Survey: design decisions (issue #24)

Start with "Choice" and "Ruling requests", then the trap table.

Status: written 2026-11-04 before the build and corrected after it; "Review round" and "After the build" at the end record what changed. Every number is measured from the 2026 release (DOI 10.5066/P144YU3S).

## Choice

39 core tables, all from one script, `data/ziolkowski_2026_bbs.R`.

| Set | Tables | Design | Years | Rows | Size |
|---|---|---|---|---|---|
| A, national coverage | `ziolkowski_2026_bbs_bcr<N>_count`, one per BCR (37) | one row per run x taxon, `occasion` = run order in the route-year | 1966-2025 | 42,067,219 | 3.42 GB |
| B, replication | `ziolkowski_2026_bbs_bcr15_block` | five 10-stop blocks per run | 1968-2025 | 1,279,278 | 104 MB |
| B, replication | `ziolkowski_2026_bbs_bcr15_stop` | 50 stops per run | 2009-2025 | 3,957,863 | 334 MB |

Total 3.86 GB against a 4 GB budget. Full build: under 2 minutes, 3.4 GB peak memory, against a limit of 60 minutes and 8 GB. Largest table: BCR 28 with 3,302,915 rows.

## The measured grid

Rows and CSV size for the 144,146 runs in the release, with `pool = region` meaning taxa recorded in the region in the breeding or the non-breeder files. Rows = runs x pool x occasions. GB here is a model at about 83 bytes a row, before the size decisions below; the build measured 81.4.

| Design | Level | Rows, full list (764 taxa) | Rows, region pool | GB, region pool | Tables at 5M a table |
|---|---|---|---|---|---|
| Route run | national | 110,127,544 | 110,127,544 | 9.19 | 23 |
| Route run | BCR | 110,127,544 | 42,067,219 | 3.51 | 37 |
| Route run | state | 110,127,544 | 38,391,247 | 3.21 | 62 |
| Block | national | 550,637,720 | 550,637,720 | 45.95 | 111 |
| Block | BCR | 550,637,720 | 210,336,095 | 17.56 | 63 |
| Block | state | 550,637,720 | 191,956,235 | 16.02 | 74 |
| Stop, 1997 on | national | 3,272,517,600 | 3,272,517,600 | 290.8 | 655 |
| Stop, 1997 on | BCR | 3,272,517,600 | 1,259,678,800 | 111.9 | 272 |
| Stop, 1997 on | state | 3,272,517,600 | 1,152,131,800 | 102.4 | 263 |

Limits: 5M rows a core; 4 GB in total, set from the 9 GB of disk free at the start; about 40 tables; 60 minutes and 8 GB for the build; no invented zeros.

The rule was to take the finest design with national coverage inside the limits. Only route run x BCR x region pool passes the row, size and table limits. State level fits sizes but needs 62 tables. Block needs 63 tables and 17.6 GB, so it and stop are pilot-region only.

Why BCR 15 for Set B (Sierra Nevada, 40 routes, 1,095 runs): both BCRs where a full stop table from 1997 fits, BCR 20 (21 routes) and BCR 36 (28), fall below the sample floor of 30 units. Among BCRs with at least 30 routes, with the block table for all years and the stop table within 5M rows and the remaining 0.48 GB, BCR 15 keeps the longest stop series: 2009-2025, 367 runs on 34 routes. The year range was narrowed instead of cutting taxa. Next were BCR 34 (from 2011), BCR 37 (2014), BCR 26 (2015).

Species cut, not applied: keeping only taxa recorded on at least 1% of a region's runs would save 41.1% of Set A rows (42.1M to 24.8M). That removes real zeros, so it stays a figure for Ben.

## The issue's four questions

1. **Scale.** Set A plus a Set B pilot, as above.
2. **Zero-fill width.** Each table's pool is every taxon recorded in that table's runs, in the breeding or the non-breeder files. Observers record every bird at every run, so a zero against a regional taxon is a fair statement. The text goes in `surveyEvidenceNote`.
3. **Run quality.** Every run is kept, flagged by `obs_run_type`, `obs_quality_current`, `obs_rpid`. USGS and `bbsBayes2` analyse `RunType = 1` only; that filter is one line for a user. RunType 1 is exactly RouteTypeDetailID 1 + RPID 101 + QualityCurrentID 1, with 0 exceptions in 144,146 runs, and the script asserts it.
4. **Release.** 2026 release, 1966-2025. No newer count release or erratum was found on any reachable source on 2026-11-04.

## Table columns

Core: `unit` (`840_46_012`), `taxon` (`A04650`), `y`, `period`, `occasion`, `date`, `observer`, then `obs_`: `obs_rpid`, `obs_run_type`, `obs_quality_current`, `obs_start_temp`, `obs_end_temp`, `obs_temp_scale`, `obs_start_wind`, `obs_end_wind`, `obs_start_sky`, `obs_end_sky`, `obs_start_minute`, `obs_end_minute`, `obs_assistant`, `obs_nonbreeder_count`. The count tables add `obs_last_stop`, the block table `obs_block_stops`, the stop table `obs_cars` and `obs_noise`.

- `obs_nonbreeder_count`: the recorded count where a non-breeder record exists; 0 from 1999 where none does; NA before 1999 where none does, because the deposit cannot say. So the published breeding count is `y - obs_nonbreeder_count`, reading NA as 0, in every year, and NA marks the rows whose zero cannot exclude a non-breeder.
- `obs_last_stop`: the last stop with evidence of sampling, K below, from 1997; NA before. `obs_block_stops`: stops of that block up to K, 1 to 10, from 1997; NA before.

- `period` = year - 1965, the same index in every table, with `year` in `__periods`. 2020 had no field work (0 rows in all six data files), so period 55 never occurs; it stays listed in `__periods` with `n_runs = 0`.
- `__units`: `unit_route_name`, `unit_country_num`, `unit_state_num`, `unit_route`, `unit_stratum`, `unit_bcr`, `unit_route_type_id`, `unit_route_type_detail_id`, `unit_active`, `unit_decimalLatitude`, `unit_decimalLongitude`, `unit_coordinateUncertaintyInMeters`. These are route start points as USGS publishes them, not bird locations; the uncertainty is the route length, about 39,200 m, as an upper bound on how far a counted bird's stop lies from that point. `coordinatesCoarsened = list(value = FALSE, method = ...)` under E7's agency rule. In `__units` rather than the core: three unit columns in the core would cost 0.5 to 1 GB. `eco_to_array()` and `eco_to_unmarked()` read `unit_*` from the core only, so `siteCovs` starts empty and a user joins `__units`.
- `__taxa`: `make_taxa()` output plus `taxon_aou`, `taxon_first_year`, `taxon_last_year`, `taxon_nonbreeder_share_1999on`, all national. A zero before `taxon_first_year` can mean the category did not exist yet: Western and Clark's Grebe have no records before 1986, and the birds sit under the unidentified pair, which is also in the pool.
- `__periods`: `period`, `year`, `n_runs`, `n_routes`, `nonbreeder_records_preserved`, and on the block table `stop_data_complete`.

Three size decisions keep the total under 4 GB. Full covariates with `AOU04650`, `HH:MM` and `StopTotal` as a column came to about 4.2 GB.

| Change | Saves | Loses |
|---|---|---|
| `taxon` = `A04650`, not `AOU04650` | 93 MB | nothing; `taxon_aou` holds the source code |
| start and end as minutes after midnight (`290`), not `HH:MM` | about 175 MB | nothing; an integer that needs no leading-zero care |
| no per-taxon `StopTotal` | 92 MB, of which `obs_last_stop` spends about the same back | a per-taxon summary with 322 impossible values before 1997, which also needs a stop-level merge in 18 cases |

Values are shipped as published, with these exceptions, all counted by assertion:
- `NULL`, blank and wind or sky code 9 ("no data" in the metadata) become NA.
- Lower-case `f` and `c` in `TempScale` become `F` and `C`.
- `obs_cars` is the value where `RecordedCar = 1` or `Car > 0`, else NA: a positive count is data, while a 0 means "not recorded" in most `RecordedCar = 0` runs. `obs_noise` is NA where the run has no VehicleData row.
- Temperatures are not converted: value plus scale. Impossible values (562, 999) stay, as recorded observations; the counts are asserted.

## Traps and how each is handled

| Trap | Measured | Handling |
|---|---|---|
| Stop data complete only from 1997 | 86,210 of 86,210 runs from 1997; 293 of 57,936 before, and those are 73% complete | Stop table starts in 1997. The block table takes all years from `States`. |
| False zeros from non-breeders | 10,638 summary records, 18 run x taxon pairs in both files (17 Cedar Waxwing) | `y` = breeding + non-breeder at the design's level, added not replaced. `obs_nonbreeder_count` is the non-breeder part, so `y - obs_nonbreeder_count` equals the published breeding count. |
| Non-breeders not preserved before 1999 | 162 records in 63,817 runs before 1999, against 0.130 a run after; about 8,160 expected unseen, 0.25% of detections but 99% of Snow Goose and Black-bellied Plover, 39% of Greater Yellowlegs, 6.9% in BCR 33 | **Cannot be repaired from the deposit.** Row-level NA in `obs_nonbreeder_count`, `taxon_nonbreeder_share_1999on` in `__taxa`, `nonbreeder_records_preserved` in `__periods`. See Ruling request 1. |
| RPID breaks the key | 103 route-years have 2 to 4 runs; 311 experimental runs nearly always replace the standard run | `occasion` = run order by date, start time, RPID. RPID is unique in a route-year, so it cannot tie. `occasion = 1` is not always the standard run (26 route-years), so `obs_rpid` says which. Stop and block tables keep RPID 101 only. |
| Partial runs | Detail 3: 142 runs, 25 or 30 stops. Empty stops are often real (BCR 33: 40% of runs with 6 or more). VehicleData cannot say how many stops were sampled. | Route-run `y` is a whole-run total and stays fair. Block and stop tables use Detail 1 or 2, drop trailing stops or blocks with no evidence of sampling (below), and declare `surveyEvidence = inferred`. Count tables stay `sample_table`. |
| Code rounding | leading zeros in `AOU`, `StateNum`, `Route` | Read as text; letter prefix on `taxon`; `_` in `unit`. |
| Non-species taxa | 93 of 764 (67 unidentified groups, 17 forms, 8 hybrids, 1 alias) | Kept as their own `taxon` with a rank in `__taxa`. No roll-up: that is an analysis choice. |
| Mixed temperature units | 16,173 C, 127,858 F, 113 no scale | `obs_temp_scale` shipped. |
| 2020 | 0 runs | Asserted. Period 55 has no rows, and `eco_to_umf(colext)` builds `numPrimary = max(period)`, which by arithmetic breaks on 36 of 37 tables and is accepted silently on BCR 12, misaligning years after 2020 (tested on BCR 12, 13 and 15, see below). Notes say to filter and pad; the converter needs its own issue. Compressing `period` would make 2019 and 2021 look adjacent. |
| Encoding | Routes and SpeciesList are Windows-1252 | Decoded, written as UTF-8. |
| Pipeline drops rows for absent cores | six core tables are absent here | Stages run in a scratch root and merged, so old rows stay byte-identical; checked by a script. |
| `rebuild.yml` | 180 min, one failure stops everything, ScienceBase refuses direct downloads | Build target under 60 min. The raw files must be in the Actions cache. Raised in the PR, along with the five older ScienceBase scripts. *Superseded:* the downloads work from the item's JSON record; see "After review". |

**The survey set at stop and block level.** The evidence that a stop was sampled is a bird record in any file, or `Car > 0` or `Noise > 0`. Let K be the last stop with evidence. Stops 1 to K are surveys; zero at an empty stop before K is fair because the observer went on past it. Stops after K have no row and their count goes in `notShipped`. The rule costs 16,088 of 4.28M stops (0.38%) from 1997 nationally. It can drop a real zero at the tail. A mid-route skip inside a run cannot be seen in this deposit, and the notes say so: that is the one place a stop zero could be unsupported. `obs_quality_current = 0` marks most truncated runs. Blocks use the same rule on `ceiling(K / 10)`; before 1997, K comes from the last non-zero block.

## Set A's use of a route total

E1 says a row is never an aggregate. Here `y` on a Set A table is the run's total, which sums the 50 stops of one run. The reading taken: the rule concerns aggregates across surveys, and a run is the survey the source defines and publishes (`SpeciesTotal`). Set B gives the finer record where it fits. For Ben to confirm.

## What is not shipped

- Stop and block tables outside BCR 15, and stop rows for BCR 15 before 2009, for size. So 99.2% of runs have no block table and 99.7% no stop table: the national tables are effectively single-occasion route totals across years, which the issue allows as a fallback.
- `TotalSpp`, which counts breeding records only: used as an assertion.
- Per-taxon `StopTotal`, see above.
- 90 `MigrantSummary` records without a `Migrants` twin are in Set A and the block table but cannot enter a stop table; all are from before 1997, so none is lost.

## What BBS says about the open issues

- **#31, split or per-unit list.** A per-route pool would make 15,302,268 rows in one table, or 37,331,524 with a per-stratum pool, against 42,067,219 in 37 BCR tables. One table with `cluster_id` becomes possible, at the cost of changing E4. BBS is the strongest case for option 2 so far; no change here.
- **#40, national pools under E4.2.** A national pool would be 110,127,544 rows and 9.19 GB; a 1% species cut would be 53,189,874. This is 62% more volume than BCR pools purely from cross-region zeros.

## Ruling requests

1. **Zeros before 1999.** The deposit has almost no non-breeder record before 1999, so a bird classed non-breeding then shows as `y = 0`. Scale: 0.25% of detections, about 8,160 records, mostly on common migrants, but nearly all records for taxa such as Snow Goose and 6.9% in BCR 33. The options were (a) ship with row, taxon and period flags and the numbers, (b) start at 1999 and lose 33 years, (c) two tables per BCR, which breaks the table limit. Taken: (a). For those years `y = 0` with `obs_nonbreeder_count` NA means "no record in this release".
2. **Non-breeders in `y`.** `y` includes them so that a recorded bird is never `y = 0` (E4). The cost: `y` has a step at 1999 (Greater Yellowlegs 15% of birds from 1999, Snow Goose 38%), which `y - obs_nonbreeder_count` removes. No analysis on record uses those files; USGS and `bbsBayes2` read breeding files only. The alternative for Ben: `y` = published `SpeciesTotal` throughout with the non-breeder count as a covariate. That gives one quantity over 60 years but writes `y = 0` for 10,476 recorded records from 1999, against E4's wording.
3. **Run total as `y`** (above).
4. **Dropped tail stops** (above): the survey set at stop and block level is inferred, so those tables say `inferred`.
5. **ECCC co-release.** The DOI record and the USGS data page say CC0 1.0; the release XML names no licence and asks for citation and acknowledgement; ECCC co-approves the release and names no Canadian licence.

## Review round

This draft was reviewed against the standard and the raw data on 2026-11-04: 1 blocker, 8 should-fix items, 7 notes.

Accepted:
- Replaced a misleading 0.044% figure with the numbers above, and made `obs_nonbreeder_count` NA before 1999 where no record exists. Kept the recorded value for the 162 records that do exist, so reconciliation works in every year.
- `surveyEvidence = inferred` on block and stop tables.
- `taxon_first_year`, `taxon_last_year`, `taxon_nonbreeder_share_1999on`, `taxon_aou` in `__taxa`.
- `obs_last_stop` and `obs_block_stops` as effort. `obs_cars` keeps positive values whatever `RecordedCar` says.
- Set B moved from BCR 20 (21 routes, below the sample floor) to BCR 15.
- Minutes after midnight. `unit_decimalLatitude` naming and an uncertainty, per E7.
- Notes on `colext`, BCR numbering (`bbsBayes2` has renumbered some BCRs; this release keeps 1 to 37), and that the national tables are single-occasion.

Not taken:
- `y` = published breeding count as the default: it writes `y = 0` for recorded birds, which breaks the no-invented-zeros limit. It stays as the alternative in Ruling request 2.
- `taxon_first_full_year` with a threshold: the share column gives the same and a threshold is a modelling choice.
- Several block pilots in place of the stop table: the issue's replication row asks for stops, and one BCR with both allows stops to be summed to blocks.

Held up under test: the stop rule (VehicleData moves K in 0.52% of runs, non-breeder records in 13 runs, `Migrants` and `MigrantSummary` agree on K), the pre-1997 block rule (agrees on 99.98% of runs from 1997), the key, the E1 reading, the size model (within 1.4%) and the licence reading.

## After the build

- Independent check from the raw files with its own Python: 47,304,360 rows, 0 differences, 0 false zeros, all 144,146 runs in exactly one count table, 30 records traced back to the raw files, byte-identical double build of BCR 1.
- `eco_to_unmarked(family = "colext")`, tested with `unmarked` 1.5.2: errors on BCR 13 and 15; accepts BCR 12 silently, as the review predicted. Filtering to `occasion == 1` alone still errors, so a user must pad periods.
- BCR names come from the release XML; `RouteTypeDetailID` 3 routes count fewer stops and are flagged in the count tables' `designNote`.
- `rebuild.yml`: the script skips loudly in Actions when raw files are absent, so it does not stop `run_all.R` for every other table. A fresh rebuild elsewhere needs the raw files downloaded by hand. *Superseded:* the script now resolves the download URLs itself, with no CI skip; see "After review".
- Corrections: 322 impossible `StopTotal` values, not 323; with the non-breeder files, 10 taxa occur only before 1997 and 86 only from 1997.


## After review (2026-11-04, PR #57)

Ben ruled on the PR. Standard v1.1-draft had merged after this design was written (#56), and its ruling #31 makes one
protocol x response type one table. A different taxon list per region is allowed only where the source says the taxa
surveyed for differ (`__survey_taxa`). BBS records every bird on every run, so the 37 per-BCR tables, whose purpose was
fewer zero rows, are replaced by one national table:

- `ziolkowski_2026_bbs_count`: all 144,146 runs x all 764 taxa (every taxon of SpeciesList is recorded somewhere),
  110,127,544 rows. This is the "Route run, national" row of the measured grid above. It is stored as period parts of at most
  5,000,000 rows (`output/ziolkowski_2026_bbs_count.parts/`, standard E4, now stated as a layout), and on Redivis it is
  one table. The 4 GB budget came from the build machine's disk, not from the standard. To work by region, filter on
  `unit_bcr` or `unit_stratum` from `__units`.
- `ziolkowski_2026_bbs_bcr15_block` and `ziolkowski_2026_bbs_bcr15_stop` stay as built: the replication pilot.
- The six ruling requests above are accepted as built: CC0 with the citation; non-breeders in `y` with
  `obs_nonbreeder_count`; zeros before 1999 kept and flagged; the run total as `y` (E1 now says "never an aggregate
  *across surveys*"); tail stops `inferred`; the #31 and #40 numbers, which #31 now settles.
- v1.1 fields: `closure` is `closed` for the count table (occasions are replicate runs within one breeding season) and
  `dependent` for the block and stop tables (consecutive stops along one route, one moving observer, a bird can be
  counted twice). The prose that was in `closure` is now in `closureNote`. `occasionKind` is `time` for the count table
  and `spatial` for the block and stop tables; `taxonInclusion` is `recorded`. Under v1.1's exact GBIF matching, the
  survey's 61 categories that are not one backbone taxon (50 species complexes, 8 hybrids, 3 functional groups) have
  no key, and `taxonRemarks` says why. Porphyrio martinicus is looked up as GBIF's *P. martinica*.
- Downloads: ScienceBase serves the files at the URLs in the item's JSON record (`files[].url`, `?f=__disk__<hash>`).
  The `?name=<file>` pattern returns 404. The script now resolves the URLs itself, so no hand download and no CI skip;
  all ten sha256 match.
- Milan reran the raw-file check on the national table at 5516d73 (#62): 0 differences and 0 false zeros over all 26
  parts, all 7,573,059 source run x taxon records present, sum of `y` 107,000,446 on both sides.
