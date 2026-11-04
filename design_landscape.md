# The range of study designs in ecological detection data, and how each meets the standard

*Written 2026-11-01 as the checklist for the open scope questions in `standard_draft.md`
§12 and for spotting a design that would need a new family. Groups A and B are the
present scope; C is where to look for a new family; D is out of scope by definition.
"AHM" is Kéry & Royle, *Applied Hierarchical Modeling in Ecology*, vols. 1–2, whose
chapter structure is also the structure of `unmarked` and `nimbleEcology`.*

The one idea behind all of group A: a **unit** (site or animal) carries a **latent
state** (occupied / abundance / alive / in state s), observed **imperfectly** on
**repeated occasions**. The replication is what makes detection separable from the
state, and it is what the core table's `occasion` column records. A design is a
candidate for a new family when the observation is not of that form.

## A. Fits the standard as written (v1 core)

| Design | What the raw data looks like | Canonical model / software | Mapping | Built or round-tripped? |
|---|---|---|---|---|
| Single-season site occupancy | site × visit 0/1 matrix | `unmarked::occu`, `dOcc` (AHM1 ch. 10) | `unit` = site, `occasion` = visit, `y` ∈ {0,1} | willow tit (rt), tapir, Malhotra |
| Royle–Nichols (abundance-induced heterogeneity) | same as above | `unmarked::occuRN` | identical table; model choice only | — |
| Dynamic (multi-season) occupancy | site × year × visit | `colext`, `dDynOcc` (AHM2 ch. 4) | `period` = year, `occasion` = visit, `period_*` for yearly site covariates | crossbill (rt), Frimpong, Uher-Koch |
| N-mixture repeated counts | site × visit counts | `pcount`, `dNmixture` (AHM1 ch. 6) | `y` = count | mallard (rt) |
| Open N-mixture (Dail–Madsen) | site × year × visit counts | `pcountOpen` | `period` + `occasion` | — |
| Community (multi-species) occupancy or abundance | site × visit × species array | `spOccupancy::msPGOcc`, `occuComm`, AHM1 ch. 11 | `taxon` = species; a 0 row for every species at every survey | MHB 2014 (rt), Malhotra, Palacio, Frimpong |
| Multi-species occupancy with interactions (Rota et al. 2016) | same array, 2–4 species | `unmarked::occuMulti` | identical table; co-occurrence is a model choice | — |
| Dynamic community | site × year × visit × species | AHM2 ch. 5 | `period` + `occasion` + `taxon` | Palacio, Frimpong |
| Multi-state occupancy (breeding status, disease, false positives) | site × visit with state codes 0/1/2 | `occuFP`, AHM2 ch. 6–7 | `y` = state code, `y_raw` = label, `stateCodes` in metadata | loon |
| Host–pathogen occupancy | host individual × sample 0/1 | same as occupancy | `unit` = host, `taxon` = pathogen; a clean case of the species-as-item view | — |
| CJS / Jolly–Seber / Pradel | capture histories `0110100` | `marked::crm`, `dCJS`, MARK | `unit` = animal, `period` = session, `y` ∈ {0,1}; losses on capture via `obs_removed` | dipper (rt), Elaenia |
| Closed-population capture–recapture (M0, Mt, Mh, Huggins) | capture histories within one session | `Rcapture`, MARK closed models | one `period`, `occasion` = trapping night | — |
| Robust design | sessions × secondary occasions | MARK RD, `dCJS` + closed | `period` + `occasion` | — |
| Multi-state capture–recapture (Arnason–Schwarz) | histories with state letters `A0BB0` | MARK, `marked` MS | `y` = state code, `y_raw` = letter; same as multi-state occupancy | — |
| Dead recovery, mark–resight, live–dead | histories with recovery codes (`LD` pairs) | Brownie, Burnham, PNE | `y_raw` = code (`10`,`01`,`11`), `y` = 1 if encountered; `responseType = state` | — |
| Repeated-count indices with within-route replication (BBS 50 stops, Christmas Bird Count) | route × year × stop counts | N-mixture or trend models | `unit` = route, `period` = year, `occasion` = stop | `ziolkowski_2026_bbs_bcr15_stop` (`occasion` = stop), `ziolkowski_2026_bbs_bcr15_block` (`occasion` = 10-stop block), and route-run totals for every BCR in `ziolkowski_2026_bbs_bcr<N>_count` |
| Trap arrays summed per session (pitfall, seed, sign/track counts) | trap-session counts | N-mixture | `unit` = trap or plot, `occasion` = session | — |
| Occasions collapsed to a binomial count (camera nights with a detection out of nights run; capture days out of active days) | site × species matrix with a trials matrix | constant-`p` occupancy / SCR with binomial observation | `responseType = binomial_count`, `obs_trials`, no `occasion` (ruling #34) | Nagarahole tigers (open SCR), Rich Botswana community |

Nothing in group A needs a decision. The gaps to fill with data are closed CR, Royle–Nichols, open N-mixture and a recovery dataset, none of which stresses the format.

## B. Fits with a declared stretch (v1, `responseType` and metadata required)

| Design | The stretch | Required metadata | Status |
|---|---|---|---|
| Removal sampling, time-removal point counts | `occasion` = removal interval, a category not a replicate | `multinomialType = removal` | ALFL (rt): identical `multinomPois` fit |
| Double-observer, dependent double-observer | `occasion` = cell (`10`,`01`,`11`) | `multinomialType = double_observer` | — |
| Binned distance sampling, hierarchical DS, camera-trap DS (Howe et al. 2017) | `occasion` = distance bin | `distanceBreaks`; for CTDS also the snapshot interval | — |
| Spatial capture–recapture | a `trap` key column, `__traps` side table with coordinates; the state space is derived at analysis time | `__traps` | experimental until a public deposit is built |
| Multi-scale occupancy (Nichols et al. 2008); eDNA site → sample → qPCR replicate | a third nesting level | `cluster_id` = site, `unit` = sample, `occasion` = replicate | not yet tested; eDNA deposits are increasingly common and worth one trial |
| Per-detection rows with scores (acoustic classifiers, continuous distance) | one row per detection plus a 0 row per survey without detections; `y = 1` on detection rows | `responseType = detection_event` | experimental (§8) |

Group B is open question 6. The rule for keeping something here rather than in C: the
likelihood can still be written from `(unit, taxon, period, occasion, y)` plus a
metadata field, and a converter back to the native frame exists. The ALFL round trip
is the evidence that the stretch is real.

## C. Where a new family would come from

These are the shapes to watch for in incoming deposits. Each breaks a clause rather
than stretching one.

| Signal | Example designs | Why it breaks the schema | What a family would need |
|---|---|---|---|
| **Two categorical axes on the observation** | point counts with distance bins × time-removal intervals (Amundson et al. 2014); double-observer × distance | `occasion` can index one category, not two; a linear index loses the structure | a `cell` table or a second index column; or accept `y_raw` = `"bin2_int3"` with a documented linearisation |
| **Continuous or censored `y`** | time-to-detection occupancy (Garrard et al. 2008), time-to-first-detection in camera traps; percent cover, biomass | `y` is a duration with right-censoring, or a continuous quantity with no detection process | `responseType = time_to_event` with `obs_censored`; or declare continuous `y` acceptable as IRW does and note no detection replication |
| **Observation is of a pair or group, not a unit × taxon** | co-detection / interaction networks, group counts with group size | the row's subject is not one unit | out of the core; possibly a `__groups` side table |
| **Certain detection** | known-fate telemetry survival, nest survival (Mayfield, logistic exposure), radio-collared survival | the format fits (individual × interval, `y` = survived) but there is no imperfect-detection process, so none of the models in A apply | decide whether to admit as a family (`survival`) with `responseType = fate`; IRW's analogue is admitting data that is not psychometric but fits the shape |
| **Single visit, no replication, community matrix** | vegan-style site × species abundance tables, single-pass surveys | fits trivially (`n_occasions = 1`), but detection is not estimable; a large share of community ecology data has this shape | admit with `n_occasions = 1` as a filterable fact (the same logic as the sample floor), or hold the line at ≥ 2 occasions |
| **Two tables are each necessary** | SCR (traps), integrated population models (counts + CR + productivity), integrated distance sampling | the likelihood needs more than the core table | SCR: already `__traps`; IPMs: several core tables under one `__dataset.json` with a `components` list |
| **The unit is a size or age class, not an organism** | length-frequency, stage-structured counts | `taxon` would have to carry a class, not a species | out, or a `__taxa` row per class with `taxonRank = class`; unlikely to be worth it |

The first two rows are the ones I expect to meet first: point-count deposits that
combine distance and time-removal are common in the North American literature, and
time-to-detection is a standard design in plant and reptile surveys.

## D. Out of scope by definition (not detection data)

- Presence-only occurrence records (most of GBIF, iNaturalist): no survey rows, so a non-detection cannot exist.
- Telemetry and movement (Movebank): a continuous location process, no latent state per unit in the above sense.
- Resource-selection / used–available designs: the "non-detection" is a sampled availability point, not a survey.
- Aggregated indices without unit-level data (national trend series).
- Model outputs posing as data (predicted occupancy surfaces, the `Dog_occu` covariate dropped from Malhotra).

## What to tell the data pipeline

When a deposit does not map cleanly, record which row of table C it hit in the
script header and in `queue/human_review.csv`, and stop rather than force it. Three
deposits hitting the same row is the signal to open a family issue. One is a note.
