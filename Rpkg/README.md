# eco (R package)

Find, download and reshape tables from **eco**, an IRW-style warehouse of
ecological detection data: occupancy, repeated counts, capture histories and
community surveys, each deposit one long table with `unit`, `taxon`, `y` where
the Item Response Warehouse has `id`, `item`, `resp`. The tables are on Redivis
as [`datapages.eco`](https://redivis.com/datasets/4j5q) and are read over its
public CSV endpoint, so **no account or token is needed**.

```r
remotes::install_github("ben-domingue/eco", subdir = "Rpkg")
```

## Thirty seconds

```r
library(eco)
eco_list_tables()                                  # what is there
eco_filter(model_family = "occupancy", min_units = 30)
eco_info("schank_2015_tapir_occ")                  # dims, family, licence, citation

umf <- eco_filter(model_family = "Single-season occupancy") |>
  head(1) |> eco_fetch() |> eco_to_unmarked()
unmarked::occu(~1 ~1, umf)
```

`eco_fetch()` of one table returns a data.frame; of several (a filter result or
a character vector) a named list. `eco_to_unmarked()` maps over a list.

## The functions

| | |
|---|---|
| `eco_list_tables()`, `eco_metadata()`, `eco_biblio()`, `eco_tags()`, `eco_tag_options()` | the corpus and its descriptions, from the `eco_meta` dataset |
| `eco_filter(model_family=, response_type=, taxon_group=, protocol=, min_units=, min_occasions=, multi_species=, sample_floor=, licence=)` | choose tables; `licence = "permissive"` keeps tables open to commercial use ([Using eco responsibly](https://ben-domingue.github.io/eco/use.html)) |
| `eco_fetch(x)`; `eco_taxa()`, `eco_periods()`, `eco_units()`, `eco_traps()` | a table and its side tables |
| `eco_info(table)` | one table, or the corpus totals |
| `eco_to_array()`, `eco_to_unmarked()`, `eco_to_ch()` and their inverses `array_to_eco()`, `umf_to_eco()`, `mpois_to_eco()`, `ch_to_eco()` | reshape to and from the model packages' structures |
| `eco_check(df)` | the R twin of the repository's validator, for a table you built |
| `eco_to_irw(df)` | the IRW v1.0 view (`id`, `item`, `resp`, `cov_*`), for IRW tooling |
| `eco_cite(tables, format, file)` | cite the original deposits and papers (one entry per deposit), and eco; `eco_save_bibtex(tables, file)` is the BibTeX shortcut |
| `eco_version()`, `eco_set_version(n)`, `eco_reset_version()`, `eco_manifest()` | pin a release |
| `eco_cache_dir()`, `eco_cache_info()`, `eco_clear_cache()` | the disk cache |

## The format, briefly

One row per taxon per survey. `unit` is the thing with the latent state (a
site, camera, pond, transect, or an individual animal), `taxon` a short species
code resolved in the `__taxa` side table, `y` the observation (`responseType`
in the metadata says whether it is a detection, a count, a state, ...).
`period` and `occasion` index primary and secondary surveys. Covariates are
prefixed by the level at which they are constant: `unit_`, `period_`, `obs_`,
`taxon_`. **A row exists iff a survey happened**: `y = 0` is surveyed and not
detected, a missing row is not surveyed, `y` is never `NA`. The standard is at
<https://ben-domingue.github.io/eco/standard.html>.

## Versions

Redivis versions `eco` and `eco_meta` separately; the repository's
`releases/manifest.csv` pairs them into numbered eco versions. By default the
package reads the current release of each. `eco_set_version(1)` pins both to
what eco version 1 consisted of, so a script reproduces what it read then;
`eco_version()` says what is in force. Tables the pipeline has built but
Redivis has not yet released are listed in `attr(eco_metadata(), "unreleased")`.

## Offline

`schank_2015_tapir_occ` (22 cameras, 72 days, one Endangered tapir, 1,008 rows)
ships with the package so the converters can be tried without a network:

```r
eco_to_unmarked(schank_2015_tapir_occ) |> unmarked::occu(~1 ~1, data = _)
```

## Relation to the `irw` package

The [`irw`](https://itemresponsewarehouse.github.io/Rpkg/) R and Python
packages are hard-wired to the IRW shard list and expect `id`/`item`/`resp`,
so they cannot read `datapages.eco`. This package is the thin equivalent for
eco; `eco_to_irw()` gives an IRW view when IRW tooling is wanted.
