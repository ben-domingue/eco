# Tags vocabulary (draft)

`tags_auto.csv` plays the role of IRW's "IRW Tags" sheet: one row per table with
the filterable attributes that are not derivable from the data file itself.
Every row staged by a `data/` script carries `Rater = claude-auto`, as IRW's
tagger does, so human and automated rows stay distinguishable. The counts
(`n_units` ... `n_rows`) and `sample_floor` are copied from
`output/<table>__dataset.json` so the row never disagrees with the file.

| Column | Values |
|---|---|
| `table` | the table name |
| `rater` | `claude-auto` for staged rows; initials for human rows |
| `taxon_group` | `Mammals`, `Birds`, `Fish`, `Amphibians`, `Reptiles`, `Invertebrates`, `Plants`, `Multiple` |
| `response_type` | `detection`, `count`, `multinomial_cell`, `state` (standard section 5.3) |
| `model_family` | free text from the standard's section 3 list: `Single-season occupancy`, `N-mixture`, `Multinomial N-mixture`, `CJS capture-recapture`, `Dynamic occupancy`, `Community occupancy`, `Multi-state dynamic occupancy`, `Spatial capture-recapture`, `Distance sampling`; qualifiers in parentheses |
| `unit_kind` | `site`, `individual` |
| `sampling_protocol` | `samplingProtocolCode`: `camera_trap`, `point_count`, `line_transect`, `mist_net`, `live_trap`, `removal`, `double_observer`, `eDNA`, `acoustic`, `territory_survey`, `compiled_collections`, ... |
| `design` | `Single-season`, `Multi-season (...)`, `Multi-session (...)`, `Robust design` |
| `realm` | `Terrestrial`, `Freshwater`, `Marine` |
| `country` | ISO 3166-1 alpha-3; several separated by commas |
| `coordinates` | `None in source`, `As published`, `Coarsened (0.1 deg)` |
| `sample_floor` | `meets` or `below (reason)` against the proposed >= 30 units x >= 2 occasions/periods |
| `n_units`, `n_taxa`, `n_periods`, `n_occasions`, `n_rows` | integers |
| `notes` | anything a user filtering on the above should know |
| `status` | `tagged`, or `tagged; hold: <reason>` for tables not to be published yet |

Not carried over from IRW's sheet: construct name, item text, age range, sample
type, language. Their analogues here are the `taxa` side table (taxon
resolution and traits) and `samplingProtocol`.
