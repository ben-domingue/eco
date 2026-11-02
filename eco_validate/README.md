# eco-validate

Check a table against the eco data standard (`standard.md`, v1.0-draft) and
exit non-zero if anything blocks. Pandas and the standard library only; no
Redivis, no network. It is the gate the uploader runs and the piece a
contributor runs before depositing a table.

    pip install /path/to/eco/eco_validate      # or, from the repo root, without installing:
    python3 -m eco_validate.cli output/

    eco-validate output/                        # every core table in output/
    eco-validate output/kery_2005_mallard_count.csv
    eco-validate output/ --profile format       # the clauses only, no intake policy
    eco-validate output/ --irw                  # also irw-validate on the IRW view
    eco-validate output/ --strict               # warnings block too
    eco-validate output/ --json                 # machine-readable, for CI
    eco-validate output/ -v                     # every affected case, not the first few

Exit codes: 0 ok, 1 something blocks, 2 bad input.

CI runs `eco-validate output/` and these tests on every pull request
(`.github/workflows/tests.yml`). To release the package: bump `version` in
`pyproject.toml` and `__version__` in `__init__.py` in one commit on main, then
`git tag eco-validate-vX.Y.Z && git push origin eco-validate-vX.Y.Z`;
`release-eco-validate.yml` builds the wheel, smoke-tests it in a bare venv and
attaches it to a GitHub release. PyPI is not wired (see that workflow's header).

## What is validated

A *core table* is `<name>.csv` with `unit, taxon, y` as its first columns. Its
side tables and metadata are picked up from beside it by name: `<name>__taxa.csv`
(required), `<name>__periods.csv` (required when `period` exists), `__units`,
`__traps`, and `<name>__dataset.json` (required). Naming a side table on the
command line validates its core table.

Every finding names its **check** and, when the check tests the format, the
**clause** of `standard.md` it enforces. A table *conforms* when no
clause-bearing check errors; it *passes the gate* when nothing errors. The two
differ by intake policy, which is not part of the format.

| Clause | Checks |
|---|---|
| E1 core columns | `required_columns`, `column_order` (warn), `key_na`, `treat_binary` (warn) |
| E2 encoding of `y` | `y_numeric`, `y_response_type` (against `responseType`), `y_raw_without_recode` (warn) |
| E3 uniqueness | `dup_key` on `(unit, taxon, trap, period, occasion)` |
| E4 explicit zeros | `y_na`, `explicit_zero_taxa` (every survey has every taxon), `survey_evidence` (warn when `inferred`) |
| E5 covariates | `undefined_columns`, `legacy_prefix` (`cov_`, `itemcov_`, `periodcov_`), `covariate_level` (`unit_*` constant within unit, `period_*` within unit x period, `taxon_*` within taxon) |
| E6 side tables | `side_taxa` (set-equal to core `taxon`, lists `scientificName`, `taxonRank`, `taxonID`), `side_periods`, `side_units`, `side_traps` (cover the core), `side_key_na` |
| E7 spatial | `coordinates_declared` (`coordinatesCoarsened` key present when coordinates exist, in the core or `__units`), `crs_declared` (for `unit_x` / `unit_y`), `coordinates_sensitive` (warn: IUCN CR/EN/VU taxon with coordinates finer than 0.1 degree) |
| E8 time | `date_iso`, `index_integer` (`period`, `occasion`) |
| E10 metadata | `meta_present`, `meta_required`, `meta_vocab` (`responseType`, `surveyEvidence`, `unitKind`, `intellectualRights.spdx`), `meta_conditional` (`stateCodes`, `multinomialType` / `distanceBreaks`, `surveyEvidenceNote`, `effortColumn = "obs_trials"` for `binomial_count`) |
| intake policy | `table_name`, `standard_version` (`eco v1.0`), `sample_floor` (warn), `replication` (warn) |

`--irw` adds irw-validate (upload profile) on the IRW view of the table
(`eco_to_irw`: `id/item/resp`, `cov_`/`itemcov_`/`periodcov_` prefixes,
Unix-second dates), as checks `irw:<name>`. IRW's errors block; its warnings
warn; an IRW view that does not conform to IRW 1.0 is a warning
(`irw:conformance`). `irw_validate` must be importable or `IRW_SRC` must point
at the `ben-domingue/irw` `src` checkout; when it is neither, the finding is an
error, never a silent pass.

## From Python and R

```python
from eco_validate import validate_file, validate_frame
r = validate_file("output/kery_2005_mallard_count.csv")
r.ok, r.conforms, r.nonconforming, [(f.check, f.clause, f.message) for f in r.findings]
```

`validate_frame(df, name=..., dataset=..., taxa=..., periods=..., units=...)`
validates in memory; side tables and metadata not passed are not reported
missing. The R build step (`write_table()` in `lib/eco_common.R`) keeps its own
twin, `validate_eco()` + `check_dataset_meta()`; `tests/test_validate.py`
asserts the two agree on the controlled vocabularies and required fields.

## Tests

    python3 -m pytest eco_validate/tests -q

The corpus in `output/` must pass, every check fires on a fixture that breaks
one thing, and every check name is classified as a clause or intake policy.
