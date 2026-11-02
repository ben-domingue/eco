# Tags vocabulary (draft)

`tags_auto.csv` plays the role of IRW's "IRW Tags" sheet: one row per table with
the filterable attributes that are not derivable from the data file itself.
Every row staged by a `data/` script carries `rater = claude-auto`, as IRW's
tagger does. Human tags go in `tags_human.csv` (same columns, `rater` = initials);
`metadata/03_tags.R` unions the two, a non-blank human cell winning its cell, and
halts on a value outside the closed vocabularies below. The counts and
`sample_floor` are not tags: `metadata/01_metadata.R` computes them from `output/`.

| Column | Values |
|---|---|
| `table` | the table name |
| `rater` | `claude-auto` for staged rows; initials for human rows |
| `taxon_group` | `Mammals`, `Birds`, `Fish`, `Amphibians`, `Reptiles`, `Invertebrates`, `Plants`, `Multiple`; closed |
| `response_type` | `detection`, `count`, `state`, `ordinal`, `multinomial_cell`, `detection_event` (standard E2); closed |
| `model_family` | free text from the standard's section 3 list: `Single-season occupancy`, `N-mixture`, `Multinomial N-mixture`, `CJS capture-recapture`, `Dynamic occupancy`, `Community occupancy`, `Multi-state dynamic occupancy`, `Spatial capture-recapture`, `Distance sampling`; qualifiers in parentheses |
| `unit_kind` | `site`, `individual`; closed |
| `sampling_protocol` | `samplingProtocolCode`: `camera_trap`, `point_count`, `line_transect`, `mist_net`, `live_trap`, `removal`, `double_observer`, `eDNA`, `acoustic`, `territory_survey`, `compiled_collections`, ... |
| `design` | starts with `Single-season`, `Multi-season`, `Multi-session` or `Robust design`; detail in parentheses |
| `realm` | `Terrestrial`, `Freshwater`, `Marine`; closed |
| `country` | ISO 3166-1 alpha-3; several separated by commas |
| `coordinates` | starts with `None in source`, `As published`, `Coarsened (0.1 deg)`, `Coarsened (by the source` or `Coarsened (trap coordinates centred` (SCR arrays of flagged taxa keep inter-trap geometry); a qualifier in parentheses may follow |
| `notes` | anything a user filtering on the above should know |
| `status` | `tagged`, or `tagged; do_not_publish: <reason>` for a table that must not ship (the uploader refuses it). The earlier `hold: below sample floor` value is retired |

Not carried over from IRW's sheet: construct name, item text, age range, sample
type, language. Their analogues here are the `taxa` side table (taxon
resolution and traits) and `samplingProtocol`.
