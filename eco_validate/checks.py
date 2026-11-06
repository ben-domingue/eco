"""The eco format checks, one function per rule, each yielding Findings.

Ported from `validate_eco()` (converters/eco_standard.R) and
`check_dataset_meta()` (lib/eco_common.R) so that both the R build step and
this gate test the same rules; the R twin stays for `write_table()`, which the
`data/` scripts call. Clause numbers refer to standard.md.

Every check takes a `Table` and returns a list of `Finding`s; `core.run_checks`
collects them. Nothing here reads a file or knows about profiles.
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field

import numpy as np
import pandas as pd

from .model import STANDARD_PREFIX, Finding

KEY_COLS = ("unit", "taxon", "trap", "period", "occasion")
REQUIRED = ("unit", "taxon", "y")
CORE_FIXED = ("unit", "taxon", "y", "y_raw", "trap", "period", "occasion",
              "date", "observer", "treat", "cluster_id")
PREFIXES = ("unit_", "period_", "obs_", "taxon_")
LEGACY_PREFIXES = ("cov_", "itemcov_", "periodcov_")
ISO_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}(:\d{2})?Z?)?$")

RESPONSE_TYPES = ("detection", "count", "state", "ordinal", "multinomial_cell",
                  "detection_event", "binomial_count")
SURVEY_EVIDENCE = ("sample_table", "effort_table", "deposited_matrix",
                   "row_presence", "inferred")
UNIT_KINDS = ("site", "individual")
CLOSURE = ("closed", "open", "dependent", "none")
OCCASION_KINDS = ("time", "observer", "method", "spatial", "cell", "none")
TAXON_INCLUSION = ("recorded", "target", "single")
UNIT_IDENTITY = ("both", "left", "right")
META_REQUIRED = ("title", "creator", "pubDate", "citation", "sourceURL",
                 "intellectualRights", "samplingProtocol", "samplingProtocolCode",
                 "responseType", "unitKind", "closure", "surveyEvidence",
                 "temporalCoverage", "geographicCoverage", "occasionKind",
                 "taxonInclusion")
SENSITIVE_IUCN = ("CR", "EN", "VU")
COORD_RE = re.compile(r"^(unit_)?(decimalLatitude|decimalLongitude)$|^unit_[xy]$")
SIDE_KEYS = {"taxa": "taxon", "periods": "period", "units": "unit", "traps": "trap",
             # composite key: taxon plus a subset of the survey columns (E6)
             "survey_taxa": "taxon"}

#: Intake policy: table names and the sample floor.
NAME_RE = re.compile(r"^[a-z0-9_]+$")
NAME_MAX = 40
FLOOR_UNITS = 30
FLOOR_REPLICATES = 2


@dataclass
class Table:
    """One core table and everything validated with it."""
    name: str
    df: pd.DataFrame
    dataset: dict | None = None            # parsed __dataset.json, None if absent
    side: dict = field(default_factory=dict)  # suffix -> DataFrame
    #: Which inputs were actually looked for (a frame validated alone has no
    #: side-table directory, so their absence is not a finding).
    side_searched: bool = True
    #: One part of a table stored as period parts (standard E4): checks that need
    #: the whole table (taxa never recorded, __taxa rows absent from the core,
    #: individuals never detected, the sample floor) are left to
    #: `whole_table_findings`, which sees the union of the parts.
    part: bool = False


def _f(check, severity, message, table, details=(), group="format"):
    return Finding(check, severity, message, table=table.name, group=group,
                   details=tuple(details))


def _sample(values, n=5):
    vals = [str(v) for v in values]
    return ", ".join(vals[:n]) + (f", ... ({len(vals)} total)" if len(vals) > n else "")


def _key(df):
    return [c for c in KEY_COLS if c in df.columns]


def _survey_cols(df):
    return [c for c in ("unit", "trap", "period", "occasion") if c in df.columns]


def _is_integer_valued(s: pd.Series) -> bool:
    x = pd.to_numeric(s, errors="coerce")
    if x.isna().any():
        return False
    return bool(np.all(np.equal(np.mod(x, 1), 0)))


# ---------------------------------------------------------------------------
# E1 columns
# ---------------------------------------------------------------------------

def check_required_columns(t: Table):
    cols = list(t.df.columns)
    missing = [c for c in REQUIRED if c not in cols]
    if missing:
        return [_f("required_columns", "error",
                   f"missing required column(s) {', '.join(missing)}; "
                   f"a core table has unit, taxon, y", t)]
    if cols[:3] != list(REQUIRED):
        return [_f("required_columns", "error",
                   f"unit, taxon, y must be the first three columns, in that "
                   f"order; found {', '.join(cols[:3])}", t)]
    return []


def check_column_order(t: Table):
    """Fixed columns in E1 order, then unit_*, period_*, obs_*, taxon_*."""
    cols = list(t.df.columns)
    fixed = [c for c in cols if c in CORE_FIXED]
    want = [c for c in CORE_FIXED if c in cols]
    out = []
    if fixed != want:
        out.append(_f("column_order", "warn",
                      f"fixed columns out of E1 order: {', '.join(fixed)} "
                      f"(expected {', '.join(want)})", t))
    rank = {p: i for i, p in enumerate(PREFIXES)}
    pre = [rank[next(p for p in PREFIXES if c.startswith(p))]
           for c in cols if c.startswith(PREFIXES)]
    first_pre = next((i for i, c in enumerate(cols) if c.startswith(PREFIXES)), None)
    if first_pre is not None and any(c in CORE_FIXED for c in cols[first_pre:]):
        out.append(_f("column_order", "warn",
                      "a fixed column follows a prefixed covariate; E1 puts "
                      "unit_*, period_*, obs_*, taxon_* after the fixed columns", t))
    elif pre != sorted(pre):
        out.append(_f("column_order", "warn",
                      "covariate groups out of E1 order (unit_*, period_*, "
                      "obs_*, taxon_*)", t))
    return out


def check_undefined_columns(t: Table):
    bad = [c for c in t.df.columns
           if c not in CORE_FIXED and not c.startswith(PREFIXES)
           and not c.startswith(LEGACY_PREFIXES)]
    if not bad:
        return []
    return [_f("undefined_columns", "error",
               f"column(s) not in E1 and not prefixed per E5: {_sample(bad)}",
               t, details=bad)]


def check_legacy_prefix(t: Table):
    bad = [c for c in t.df.columns if c.startswith(LEGACY_PREFIXES)]
    if not bad:
        return []
    return [_f("legacy_prefix", "error",
               f"IRW prefixes cov_/itemcov_/periodcov_ must not appear "
               f"(eco_to_irw() produces them): {_sample(bad)}", t, details=bad)]


def check_doubled_prefix(t: Table):
    """A level prefix repeated (`unit_unit_sex`, `obs_obs_effort`) is a processing
    error: a converter added the prefix to a name that already carried it (#38)."""
    bad = [c for c in t.df.columns
           if any(c.startswith(p + p) for p in PREFIXES)]
    units = t.side.get("units")
    if units is not None:
        bad += [f"__units.{c}" for c in units.columns
                if any(c.startswith(p + p) for p in PREFIXES)]
    if not bad:
        return []
    return [_f("doubled_prefix", "error",
               f"level prefix doubled (E5 prefixes once): {_sample(bad)}; "
               f"array_to_eco() adds unit_/obs_/period_ itself", t, details=bad)]


def check_key_na(t: Table):
    out = []
    for c in _key(t.df):
        s = t.df[c]
        n = int(s.isna().sum() + (s.astype(str).str.strip() == "").sum())
        if n:
            out.append(_f("key_na", "error",
                          f"{n:,} row(s) with empty `{c}`; key columns are never empty", t))
    return out


def check_treat_binary(t: Table):
    if "treat" not in t.df.columns:
        return []
    vals = set(pd.unique(t.df["treat"].dropna()))
    if vals <= {0, 1, 0.0, 1.0}:
        return []
    return [_f("treat_binary", "warn",
               f"`treat` is defined as 1/0; found {_sample(sorted(vals, key=str))}", t)]


# ---------------------------------------------------------------------------
# E2 encoding of y
# ---------------------------------------------------------------------------

def check_y_numeric(t: Table):
    if "y" not in t.df.columns:
        return []
    y = t.df["y"]
    if pd.api.types.is_numeric_dtype(y):
        return []
    coerced = pd.to_numeric(y, errors="coerce")
    bad = y[coerced.isna() & y.notna()]
    return [_f("y_numeric", "error",
               f"`y` is not numeric; {len(bad):,} non-numeric value(s) such as "
               f"{_sample(pd.unique(bad.astype(str)))}", t)]


def check_y_na(t: Table):
    if "y" not in t.df.columns:
        return []
    n = int(t.df["y"].isna().sum())
    if not n:
        return []
    return [_f("y_na", "error",
               f"{n:,} row(s) with empty `y`; a survey that did not happen has "
               f"no row, and a survey with no detection has y = 0", t)]


def check_y_response_type(t: Table):
    if "y" not in t.df.columns or not t.dataset:
        return []
    rt = t.dataset.get("responseType")
    y = pd.to_numeric(t.df["y"], errors="coerce").dropna()
    if y.empty or rt not in RESPONSE_TYPES:
        return []
    out = []
    if rt in ("detection", "detection_event"):
        bad = sorted(set(y.unique()) - {0, 1})
        if bad:
            out.append(_f("y_response_type", "error",
                          f"responseType = {rt} but y takes {_sample(bad)}; "
                          f"collapse to 0/1 and keep the count in y_raw", t))
    else:
        if (y < 0).any() or not np.all(np.equal(np.mod(y, 1), 0)):
            out.append(_f("y_response_type", "error",
                          f"responseType = {rt} but y is not a non-negative integer "
                          f"(min {y.min()}, {int((np.mod(y, 1) != 0).sum())} non-integer)", t))
    if rt == "detection_event" and (y == 1).sum() == 0:
        out.append(_f("y_response_type", "warn",
                      "responseType = detection_event with no y = 1 row", t))
    if rt == "binomial_count":
        if "occasion" in t.df.columns:
            out.append(_f("y_response_type", "error",
                          "responseType = binomial_count has no occasion column: the source "
                          "collapsed the occasions, so a row is one (unit, taxon[, trap][, period]) (E2, #34)", t))
        if "obs_trials" not in t.df.columns:
            out.append(_f("y_response_type", "error",
                          "responseType = binomial_count needs obs_trials (occasions surveyed) on every row (E2, #34)", t))
        else:
            k = pd.to_numeric(t.df["obs_trials"], errors="coerce")
            yy = pd.to_numeric(t.df["y"], errors="coerce")
            if k.isna().any() or (k < 1).any() or not np.all(np.equal(np.mod(k.dropna(), 1), 0)):
                out.append(_f("y_response_type", "error",
                              "obs_trials must be an integer >= 1 on every row (E2, #34)", t))
            over = int((yy > k).sum())
            if over:
                out.append(_f("y_response_type", "error",
                              f"{over:,} row(s) with y > obs_trials: more occasions with a detection "
                              f"than occasions surveyed (E2, #34)", t))
    return out


def check_y_raw_without_recode(t: Table):
    """`y_raw` is the observation as recorded when `y` is a recode (E1/E2). If
    `y_raw` equals `y` everywhere it carries nothing and is probably a mistake."""
    if "y_raw" not in t.df.columns or "y" not in t.df.columns:
        return []
    yr = pd.to_numeric(t.df["y_raw"], errors="coerce")
    if yr.isna().any():
        return []
    if (yr == pd.to_numeric(t.df["y"], errors="coerce")).all():
        return [_f("y_raw_without_recode", "warn",
                   "`y_raw` is identical to `y`; it is meant for the uncollapsed "
                   "value behind a recode", t)]
    return []


# ---------------------------------------------------------------------------
# E3 uniqueness, E4 explicit zeros
# ---------------------------------------------------------------------------

def check_dup_key(t: Table):
    key = _key(t.df)
    if not {"unit", "taxon"} <= set(key):
        return []
    dup = t.df.duplicated(subset=key, keep=False)
    n = int(dup.sum())
    if not n:
        return []
    hint = ("" if "occasion" in key else
            "; repeated surveys of one (unit, taxon, period) need an `occasion` column")
    ex = t.df.loc[dup, key].drop_duplicates().head(5)
    details = [", ".join(f"{k}={v}" for k, v in r.items()) for r in ex.to_dict("records")]
    return [_f("dup_key", "error",
               f"{n:,} row(s) share a key ({', '.join(key)}){hint}", t, details=details)]


def check_explicit_zero_taxa(t: Table):
    """Every conducted survey carries a row for every taxon (E4.2)."""
    if not {"unit", "taxon"} <= set(t.df.columns):
        return []
    n_taxa = t.df["taxon"].nunique()
    if n_taxa < 2:
        return []
    if (t.dataset or {}).get("unitKind") == "individual":
        # Ruling #20: the taxon is a property of an individual, so E4.2 cannot hold;
        # the stated form is one table per taxon.
        return [_f("explicit_zero_taxa", "error",
                   f"unitKind = individual with {n_taxa} taxa; an individual carries only "
                   f"its own taxon, so a multi-species deposit ships as one table per taxon (E4 ruling #20)", t)]
    cols = _survey_cols(t.df)
    if t.side.get("survey_taxa") is not None:
        return _survey_taxa_sets(t, cols)
    # Every survey carries the same SET of taxa (the whole list); counting distinct
    # taxa per survey is the set test, since every survey's taxa are a subset.
    per = t.df.groupby(cols, sort=False, dropna=False)["taxon"].nunique()
    short = per[per != n_taxa]
    if short.empty:
        return []
    return [_f("explicit_zero_taxa", "error",
               f"{len(short):,} of {len(per):,} surveys lack rows for some of the "
               f"{n_taxa} taxa; a community table carries y = 0 for every taxon "
               f"surveyed for at a conducted survey (a __survey_taxa side table "
               f"lists them when they differ between surveys)", t,
               details=[f"{dict(zip(cols, k if isinstance(k, tuple) else (k,)))}: "
                        f"{v} taxa" for k, v in short.head(20).items()])]


def _survey_taxa_sets(t: Table, cols):
    """E4.2 with a __survey_taxa side table: each survey's taxon rows equal the
    union of the side-table rows matching it."""
    st = t.side["survey_taxa"]
    match = [c for c in st.columns if c != "taxon"]
    bad = [c for c in match if c not in cols]
    if "taxon" not in st.columns or not match or bad:
        return [_f("side_survey_taxa", "error",
                   "__survey_taxa must have `taxon` plus one or more of the core survey "
                   f"columns ({', '.join(cols)})" + (f"; unknown: {', '.join(bad)}" if bad else ""), t)]
    surveys = t.df[cols].drop_duplicates().astype(str)
    stx = st[["taxon"] + match].drop_duplicates().astype(str)
    expected = surveys.merge(stx, on=match, how="left")
    unmatched = expected[expected["taxon"].isna()][cols].drop_duplicates()
    out = []
    if len(unmatched):
        out.append(_f("explicit_zero_taxa", "error",
                      f"{len(unmatched):,} survey(s) match no __survey_taxa row, so no taxon "
                      f"was surveyed for there (E4.2)", t,
                      details=[str(dict(r)) for r in unmatched.head(20).to_dict("records")]))
    expected = expected.dropna(subset=["taxon"])[cols + ["taxon"]].drop_duplicates()
    observed = t.df[cols + ["taxon"]].drop_duplicates().astype(str)
    both = expected.merge(observed, on=cols + ["taxon"], how="outer", indicator=True)
    missing = both[both["_merge"] == "left_only"]
    extra = both[both["_merge"] == "right_only"]
    if len(missing):
        out.append(_f("explicit_zero_taxa", "error",
                      f"{len(missing):,} survey x taxon row(s) listed in __survey_taxa are "
                      f"absent from the core (a taxon surveyed for carries y = 0 when not detected)",
                      t, details=[str(dict(r)) for r in missing.drop(columns="_merge").head(20).to_dict("records")]))
    if len(extra):
        out.append(_f("explicit_zero_taxa", "error",
                      f"{len(extra):,} core survey x taxon row(s) for taxa __survey_taxa does not "
                      f"list at that survey", t,
                      details=[str(dict(r)) for r in extra.drop(columns="_merge").head(20).to_dict("records")]))
    return out


def check_never_detected(t: Table):
    """E4.4: an individual never detected in the table is not a unit."""
    if t.part or (t.dataset or {}).get("unitKind") != "individual" or not {"unit", "y"} <= set(t.df.columns):
        return []
    y = pd.to_numeric(t.df["y"], errors="coerce").fillna(0)
    best = y.groupby(t.df["unit"]).max()
    never = best[best <= 0].index
    if not len(never):
        return []
    return [_f("never_detected", "error",
               f"{len(never):,} individual(s) are never detected (every y = 0); a catalogue "
               f"entry never sighted is not a unit (E4.4): {_sample(list(never))}",
               t, details=[str(u) for u in never])]


def check_unit_identity(t: Table):
    """E2 partial identity: `unit_identity` is one of both / left / right."""
    out = []
    for frame in (t.df, t.side.get("units")):
        if frame is None or "unit_identity" not in frame.columns:
            continue
        bad = sorted(set(frame["unit_identity"].dropna().astype(str)) - set(UNIT_IDENTITY))
        if bad or frame["unit_identity"].isna().any():
            out.append(_f("unit_identity", "error",
                          f"unit_identity must be one of {{{', '.join(UNIT_IDENTITY)}}} on every "
                          f"unit (E2); found {_sample(bad) if bad else 'empty values'}", t))
            break
    return out


def check_survey_evidence(t: Table):
    """`inferred` is a warning in the validator and a filterable fact (E4)."""
    if not t.dataset:
        return []
    if t.dataset.get("surveyEvidence") == "inferred":
        note = t.dataset.get("surveyEvidenceNote") or ""
        return [_f("survey_evidence", "warn",
                   "surveyEvidence = inferred: the survey set was reconstructed by "
                   "a rule" + (f" ({note[:80]}{'...' if len(note) > 80 else ''})" if note else ""), t)]
    return []


# ---------------------------------------------------------------------------
# E5 covariate levels
# ---------------------------------------------------------------------------

def check_covariate_level(t: Table):
    df = t.df
    out = []
    levels = [("unit_", ["unit"], "unit"),
              ("taxon_", ["taxon"], "taxon"),
              ("period_", ["unit", "period"], "unit x period")]
    for prefix, by, label in levels:
        if not all(b in df.columns for b in by):
            continue
        for c in [c for c in df.columns if c.startswith(prefix)]:
            n_by = df[by].drop_duplicates().shape[0]
            n_with = df[by + [c]].drop_duplicates().shape[0]
            if n_with > n_by:
                hint = " (should be obs_ or period_)" if prefix == "unit_" else ""
                out.append(_f("covariate_level", "error",
                              f"`{c}` varies within {label}{hint}: {n_with - n_by:,} "
                              f"extra combination(s)", t))
    return out


# ---------------------------------------------------------------------------
# E6 side tables
# ---------------------------------------------------------------------------

def _side_check(t: Table, suffix: str, required: bool, superset_of: str | None):
    """One side table: present when required, keyed, and covering the core."""
    check = f"side_{suffix}"
    key = SIDE_KEYS[suffix]
    side = t.side.get(suffix)
    out = []
    if side is None:
        if required and t.side_searched:
            why = ("every core table has one" if suffix == "taxa"
                   else f"`{key}` is a core column")
            out.append(_f(check, "error", f"no __{suffix} side table; {why}", t))
        return out
    if key not in side.columns:
        out.append(_f(check, "error",
                      f"__{suffix} lacks its key column `{key}` (side tables are "
                      f"typed by their key, E6)", t))
        return out
    s = side[key]
    if s.isna().any() or s.duplicated().any():
        out.append(_f("side_key_na", "error",
                      f"__{suffix}.{key} has empty or repeated values", t))
    if superset_of and key in t.df.columns:
        core_vals = set(t.df[key].dropna().astype(str))
        side_vals = set(s.dropna().astype(str))
        missing = sorted(core_vals - side_vals)
        if missing:
            out.append(_f(check, "error",
                          f"{len(missing)} core `{key}` value(s) absent from __{suffix}: "
                          f"{_sample(missing)}", t, details=missing))
        extra = sorted(side_vals - core_vals)
        if extra and suffix == "taxa" and not t.part:
            out.append(_f(check, "error",
                          f"{len(extra)} __taxa row(s) not in the core table: "
                          f"{_sample(extra)}; every __taxa row must appear in the core",
                          t, details=extra))
    return out


#: GBIF backbone kingdom usage keys (0 incertae sedis, 1 Animalia, 2 Archaea,
#: 3 Bacteria, 4 Chromista, 5 Fungi, 6 Plantae, 7 Protozoa, 8 Viruses); a twin of
#: GBIF_KINGDOM_KEYS in lib/eco_common.R.
GBIF_KINGDOM_KEYS = tuple(range(9))
GBIF_KEY_RE = r"gbif\.org/species/([0-9]+)/?$"


def check_side_taxa(t: Table):
    out = _side_check(t, "taxa", required=True, superset_of="taxon")
    side = t.side.get("taxa")
    if side is not None and "taxon" in side.columns:
        for col in ("scientificName", "taxonRank", "taxonID"):
            if col not in side.columns:
                out.append(_f("side_taxa", "warn", f"__taxa lacks `{col}` (E6 lists it)", t))
        if "taxonID" in side.columns:
            no_id = side["taxonID"].isna() | (side["taxonID"].astype(str).str.strip() == "")
            rem = (side["taxonRemarks"] if "taxonRemarks" in side.columns
                   else pd.Series([None] * len(side), index=side.index))
            no_rem = rem.isna() | (rem.astype(str).str.strip() == "")
            bad = side.loc[no_id & no_rem, "taxon"]
            if len(bad):
                out.append(_f("taxon_rows", "error",
                              f"{len(bad)} __taxa row(s) have no taxonID and no taxonRemarks saying "
                              f"why (E6: only a group the GBIF backbone does not hold): {_sample(list(bad))}",
                              t, details=[str(b) for b in bad]))
            kid = side["taxonID"].astype(str).str.extract(GBIF_KEY_RE, expand=False)
            rank = (side["taxonRank"].astype(str).str.strip().str.lower() if "taxonRank" in side.columns
                    else pd.Series([""] * len(side), index=side.index))
            king = kid.notna() & kid.fillna("-1").astype(int).isin(GBIF_KINGDOM_KEYS) & (rank != "kingdom")
            if king.any():
                rows = [f"{a}={b}" for a, b in zip(side.loc[king, "taxon"], side.loc[king, "taxonID"])]
                out.append(_f("taxon_kingdom", "error",
                              f"{len(rows)} __taxa row(s) have a GBIF kingdom as taxonID but a taxonRank "
                              f"below kingdom (a match that fell to the kingdom; E6): {_sample(rows)}",
                              t, details=rows))
    st = t.side.get("survey_taxa")
    if st is not None and side is not None and "taxon" in st.columns and "taxon" in side.columns:
        extra = sorted(set(st["taxon"].dropna().astype(str)) - set(side["taxon"].astype(str)))
        if extra:
            out.append(_f("side_survey_taxa", "error",
                          f"{len(extra)} __survey_taxa taxon/taxa not in __taxa: {_sample(extra)}",
                          t, details=extra))
    return out


def check_side_periods(t: Table):
    return _side_check(t, "periods", required="period" in t.df.columns, superset_of="period")


def check_side_units(t: Table):
    return _side_check(t, "units", required=False, superset_of="unit")


def check_side_traps(t: Table):
    return _side_check(t, "traps", required="trap" in t.df.columns, superset_of="trap")


# ---------------------------------------------------------------------------
# E7 spatial
# ---------------------------------------------------------------------------

def _coord_columns(t: Table):
    cols = list(t.df.columns)
    units = t.side.get("units")
    if units is not None:
        cols += list(units.columns)
    return [c for c in cols if COORD_RE.match(c)]


def check_coordinates_declared(t: Table):
    coords = _coord_columns(t)
    if not coords or t.dataset is None:
        return []
    if "coordinatesCoarsened" not in t.dataset:
        return [_f("coordinates_declared", "error",
                   f"coordinates present ({_sample(sorted(set(coords)))}) but "
                   f"`coordinatesCoarsened` is not declared in __dataset.json "
                   f"(null when kept as published)", t)]
    return []


def check_crs_declared(t: Table):
    coords = set(_coord_columns(t))
    if not ({"unit_x", "unit_y"} & coords) or t.dataset is None:
        return []
    if not t.dataset.get("crs"):
        return [_f("crs_declared", "error",
                   "projected coordinates unit_x / unit_y need `crs` (an EPSG code) "
                   "in __dataset.json", t)]
    return []


def check_coordinates_sensitive(t: Table):
    """Flagged taxon (IUCN CR/EN/VU in __taxa) with coordinates finer than 0.1
    degree and no coarsening declared."""
    taxa = t.side.get("taxa")
    if taxa is None or t.dataset is None:
        return []
    iucn = next((c for c in taxa.columns if c.lower() in ("taxon_iucncategory", "iucncategory")), None)
    if iucn is None:
        return []
    flagged = taxa.loc[taxa[iucn].astype(str).str.upper().isin(SENSITIVE_IUCN), "taxon"]
    cc = t.dataset.get("coordinatesCoarsened")
    if flagged.empty or cc:   # declared either way: coarsened, or why not (E7)
        return []
    local = "local" in str(t.dataset.get("crs") or "").lower()
    frames = [t.df, t.side.get("units")] + ([] if local else [t.side.get("traps")])
    for frame in frames:
        if frame is None:
            continue
        lat = next((c for c in frame.columns if c.endswith("decimalLatitude")), None)
        fine = False
        if lat is not None:
            x = pd.to_numeric(frame[lat], errors="coerce").dropna()
            fine = bool((np.abs(x * 10 - np.round(x * 10)) > 1e-9).any())
        else:
            # projected pair (E7.1): coarsened values sit on 10 km cell centres
            xc = next((c for c in frame.columns if c in ("unit_x", "x", "x_m")), None)
            if xc is not None and not local:
                x = pd.to_numeric(frame[xc], errors="coerce").dropna()
                fine = bool((np.abs((x - 5000) % 10000) > 1e-6).any())
        if fine:
            return [_f("coordinates_sensitive", "warn",
                       f"{len(flagged)} taxon/taxa flagged {'/'.join(SENSITIVE_IUCN)} "
                       f"({_sample(flagged)}) with coordinates finer than 0.1 degree "
                       f"and coordinatesCoarsened unset; E7 generalises to the 0.1 "
                       f"degree cell unless the source published them so", t)]
    return []


# ---------------------------------------------------------------------------
# E8 time
# ---------------------------------------------------------------------------

def check_date_iso(t: Table):
    if "date" not in t.df.columns:
        return []
    d = t.df["date"].dropna().astype(str).str.strip()
    d = d[d != ""]
    bad = d[~d.str.match(ISO_DATE_RE)]
    if bad.empty:
        return []
    ex = pd.unique(bad)
    hint = ""
    if all(re.fullmatch(r"\d{1,3}", v) for v in ex[:20]):
        hint = "; a day-of-year goes in obs_date_doy with `date` left empty"
    elif all(re.fullmatch(r"\d{4}", v) for v in ex[:20]):
        hint = "; a calendar year belongs to the period, in __periods"
    return [_f("date_iso", "error",
               f"{len(bad):,} `date` value(s) not ISO 8601 (YYYY-MM-DD or "
               f"YYYY-MM-DDThh:mm[:ss]Z), such as {_sample(ex)}{hint}", t)]


def check_index_integer(t: Table):
    out = []
    for c in ("period", "occasion"):
        if c not in t.df.columns:
            continue
        if not _is_integer_valued(t.df[c]):
            out.append(_f("index_integer", "error",
                          f"`{c}` must be an integer index ordered in time; found "
                          f"{_sample(pd.unique(t.df[c].astype(str)))}", t))
        elif (pd.to_numeric(t.df[c]) < 1).any():
            out.append(_f("index_integer", "warn", f"`{c}` has values below 1", t))
    return out


# ---------------------------------------------------------------------------
# E10 metadata
# ---------------------------------------------------------------------------

def check_meta_present(t: Table):
    if t.dataset is None and t.side_searched:
        return [_f("meta_present", "error",
                   "no __dataset.json; every core table has one (E10)", t)]
    return []


def check_meta_required(t: Table):
    if not t.dataset:
        return []
    missing = [k for k in META_REQUIRED if t.dataset.get(k) in (None, "", [], {})]
    if not missing:
        return []
    return [_f("meta_required", "error",
               f"__dataset.json missing required field(s): {', '.join(missing)}", t,
               details=missing)]


def check_meta_vocab(t: Table):
    if not t.dataset:
        return []
    d = t.dataset
    out = []
    vocab = (("responseType", RESPONSE_TYPES, "E2"),
             ("surveyEvidence", SURVEY_EVIDENCE, "E4"),
             ("unitKind", UNIT_KINDS, "E10"),
             ("closure", CLOSURE, "E8"),
             ("taxonInclusion", TAXON_INCLUSION, "E10"))
    ok_ = d.get("occasionKind")
    if ok_ is not None and not _occasion_kind_ok(ok_):
        out.append(_f("meta_vocab", "error",
                      f"occasionKind = `{json.dumps(ok_)}` must be one of {{{', '.join(OCCASION_KINDS)}}}, "
                      f"or a list of two distinct kinds other than `none`, outer first, for crossed "
                      f"occasions (E8)", t))
    for k, allowed, clause in vocab:
        v = d.get(k)
        if v is not None and v not in allowed:
            out.append(_f("meta_vocab", "error",
                          f"{k} = `{v}` not in {{{', '.join(allowed)}}} ({clause})", t))
    cc = d.get("coordinatesCoarsened", None)
    if cc is not None and not (isinstance(cc, dict) and isinstance(cc.get("value"), bool)
                               and isinstance(cc.get("method"), str) and cc["method"].strip()):
        out.append(_f("meta_vocab", "error",
                      "coordinatesCoarsened must be null or an object "
                      "{value: true/false, method: \"...\"} (E7/E10); found "
                      f"`{json.dumps(cc)[:60]}`", t))
    rights = d.get("intellectualRights")
    if rights is not None and not (isinstance(rights, dict) and rights.get("spdx")):
        out.append(_f("meta_vocab", "error",
                      "intellectualRights must be an object with `spdx` (and `url`)", t))
    return out


def _occasion_kind_ok(v) -> bool:
    """E8: one kind, or two distinct kinds (outer first) for crossed occasions."""
    if isinstance(v, str):
        return v in OCCASION_KINDS
    return (isinstance(v, list) and len(v) == 2 and len(set(v)) == 2
            and all(isinstance(x, str) and x in OCCASION_KINDS and x != "none" for x in v))


def check_meta_conditional(t: Table):
    if not t.dataset:
        return []
    d = t.dataset
    out = []
    rt, se = d.get("responseType"), d.get("surveyEvidence")
    if se == "inferred" and not d.get("surveyEvidenceNote"):
        out.append(_f("meta_conditional", "error",
                      "surveyEvidence = inferred needs surveyEvidenceNote stating the rule (E4)", t))
    if rt in ("state", "ordinal") and not d.get("stateCodes"):
        out.append(_f("meta_conditional", "error",
                      f"responseType = {rt} needs stateCodes (E2)", t))
    if rt == "multinomial_cell" and not (d.get("multinomialType") or d.get("distanceBreaks")):
        out.append(_f("meta_conditional", "error",
                      "responseType = multinomial_cell needs multinomialType or distanceBreaks (E2/E9)", t))
    if rt == "binomial_count" and d.get("effortColumn") != "obs_trials":
        out.append(_f("meta_conditional", "error",
                      'responseType = binomial_count needs effortColumn = "obs_trials" (E10, #34)', t))
    df = t.df
    has_occ = "occasion" in df.columns
    ok_, cl = d.get("occasionKind"), d.get("closure")
    if _occasion_kind_ok(ok_ if ok_ is not None else "") and (ok_ == "none") == has_occ:
        out.append(_f("meta_conditional", "error",
                      f"occasionKind = {ok_} but the table {'has' if has_occ else 'has no'} an "
                      f"`occasion` column (E8: `none` exactly when there is none)", t))
    if cl in CLOSURE:
        if not has_occ and cl != "none":
            out.append(_f("meta_conditional", "error",
                          f"closure = {cl} but there is no `occasion` column (E8: closure = none)", t))
        elif has_occ and cl == "none":
            grp = [c for c in ("unit", "taxon", "trap", "period") if c in df.columns]
            if (df.groupby(grp, sort=False)["occasion"].nunique() > 1).any():
                out.append(_f("meta_conditional", "error",
                              "closure = none but some unit x taxon x period has more than one "
                              "occasion (E8)", t))
    ti = d.get("taxonInclusion")
    if ti in TAXON_INCLUSION and "taxon" in df.columns and not t.part:
        n = df["taxon"].nunique()
        if (ti == "single") != (n == 1):
            out.append(_f("meta_conditional", "error",
                          f"taxonInclusion = {ti} with {n} taxa (E10: `single` exactly when the "
                          f"table has one taxon)", t))
        if ti == "recorded" and "y" in df.columns:
            best = pd.to_numeric(df["y"], errors="coerce").fillna(0).groupby(df["taxon"]).max()
            never = sorted(best[best <= 0].index.astype(str))
            if never:
                out.append(_f("meta_conditional", "error",
                              f"taxonInclusion = recorded but {len(never)} taxon/taxa are never "
                              f"recorded in this table (E10): {_sample(never)}", t, details=never))
    sc = d.get("subsampleColumn")
    if sc is not None:
        if not (isinstance(sc, str) and sc.startswith("obs_") and sc in df.columns):
            out.append(_f("meta_conditional", "error",
                          f"subsampleColumn must name an obs_ column of the core table (E10); "
                          f"found `{json.dumps(sc)[:60]}`", t))
        else:
            v = pd.to_numeric(df[sc], errors="coerce")
            bad = v.notna() & ~((v > 0) & (v <= 1))
            if (df[sc].notna() & v.isna()).any() or bad.any():
                out.append(_f("meta_conditional", "error",
                              f"subsampleColumn `{sc}` must hold the identified fraction, "
                              f"in (0, 1] or empty (E10)", t))
    tw = d.get("taxaWithheld")
    if tw is not None:
        if not (isinstance(tw, list) and all(isinstance(x, str) and x.strip() for x in tw)):
            out.append(_f("meta_conditional", "error",
                          "taxaWithheld must be a list of taxon names (E10)", t))
        else:
            known = set(df["taxon"].astype(str)) if "taxon" in df.columns else set()
            taxa = t.side.get("taxa")
            if taxa is not None and "scientificName" in taxa.columns:
                known |= set(taxa["scientificName"].dropna().astype(str))
            clash = sorted(set(tw) & known)
            if clash:
                out.append(_f("meta_conditional", "error",
                              f"taxaWithheld names taxa that have core rows: {_sample(clash)} "
                              f"(a withheld taxon has no rows, E10)", t))
    return out


# ---------------------------------------------------------------------------
# Intake policy (group "intake", no clause)
# ---------------------------------------------------------------------------

def check_table_name(t: Table):
    out = []
    if len(t.name) > NAME_MAX:
        out.append(_f("table_name", "error",
                      f"table name has {len(t.name)} characters; intake policy caps it at {NAME_MAX}",
                      t, group="intake"))
    if not NAME_RE.match(t.name):
        out.append(_f("table_name", "error",
                      "table name must be lower case [a-z0-9_] (author_year_place_type)",
                      t, group="intake"))
    elif len(t.name.split("_")) < 3:
        out.append(_f("table_name", "warn",
                      "table name does not look like author_year_taxonOrPlace_type",
                      t, group="intake"))
    return out


def check_standard_version(t: Table):
    if not t.dataset:
        return []
    ver = str(t.dataset.get("standardVersion") or "")
    if not ver.startswith(STANDARD_PREFIX):
        return [_f("standard_version", "error",
                   f"built under `{ver or 'unknown'}`, not {STANDARD_PREFIX}; "
                   f"rerun its data/ script", t, group="intake")]
    return []


def check_sample_floor(t: Table, s: dict | None = None):
    if t.part and s is None:
        return []
    s = s if s is not None else table_stats(t.df)
    if not s:
        return []
    reasons = []
    if s["n_units"] < FLOOR_UNITS:
        reasons.append(f"{s['n_units']} units < {FLOOR_UNITS}")
    binomial = bool(t.dataset) and t.dataset.get("responseType") == "binomial_count"
    if max(s["n_occasions"], s["n_periods"]) < FLOOR_REPLICATES and not binomial:
        reasons.append("no replication")
    if not reasons:
        return []
    return [_f("sample_floor", "warn",
               f"below the sample floor ({'; '.join(reasons)}); shipped and filterable, "
               f"not prioritised", t, group="intake")]


#: Within-visit replication (intake "Replication", ruled 2026-11-06): timed intervals
#: the source recorded ship as obs_int1, obs_int2, ... (E8) or as interval x band
#: cells obs_n_int1_band1, ...; time to detection as obs_ttd or obs_ttd_<unit> (E9).
WITHIN_VISIT_RE = re.compile(r"^obs_(n_)?int\d+|^obs_ttd(_|$)")


def replicated_within(t: Table, columns=None) -> str | None:
    """Why a table with one occasion and one period is still replicated (intake
    "Replication", ruled 2026-11-06), or None. `columns` lets the parted path pass
    the union's columns."""
    ds = t.dataset or {}
    cols = list(t.df.columns) if columns is None else list(columns)
    if ds.get("responseType") == "binomial_count":
        return "binomial_count"                       # inside obs_trials (#34)
    if ds.get("unitKind") == "individual" and "trap" in cols:
        return "individual units replicated over traps"   # count-detector SCR (E9)
    if any(WITHIN_VISIT_RE.match(c) for c in cols):
        return "within-visit intervals or time to detection"
    return None


def check_replication(t: Table, s: dict | None = None):
    if t.part and s is None:
        return []
    s = s if s is not None else table_stats(t.df)
    if not s or s["n_occasions"] > 1 or s["n_periods"] > 1:
        return []
    if replicated_within(t, s.get("columns")):
        return []
    return [_f("replication", "warn",
               "one occasion and one period: a single-visit matrix fits the format "
               "but supports none of E9's core models", t, group="intake")]


ALL_ZERO_NOTE = "not estimable"


def all_zero_admitted(t: Table) -> bool:
    """An all-zero table the standard admits (intake "All-zero tables", ruled
    2026-11-06): every y = 0, site units, taxonInclusion target or single."""
    ds = t.dataset or {}
    if "y" not in t.df.columns:
        return False
    y = pd.to_numeric(t.df["y"], errors="coerce")
    if not len(y) or y.isna().any() or (y != 0).any():
        return False
    return ds.get("unitKind") != "individual" and ds.get("taxonInclusion") in ("target", "single")


def check_all_zero(t: Table):
    """An admitted all-zero table: its notes say nothing was detected and that
    detection probability is not estimable from it alone (intake, 2026-11-06)."""
    if t.part or not t.dataset or not all_zero_admitted(t):
        return []
    notes = str(t.dataset.get("notes") or "")
    if ALL_ZERO_NOTE in notes.lower():
        return []
    return [_f("all_zero", "warn",
               "every y = 0: an all-zero table is admitted, but its notes must say that "
               "nothing was detected and that detection probability is not estimable from "
               "the table alone", t, group="intake")]


# ---------------------------------------------------------------------------


def table_stats(df: pd.DataFrame) -> dict:
    if not {"unit", "taxon", "y"} <= set(df.columns):
        return {}
    y = pd.to_numeric(df["y"], errors="coerce")
    yv = sorted(pd.unique(y.dropna()))
    return {
        "n_rows": int(len(df)),
        "n_units": int(df["unit"].nunique()),
        "n_taxa": int(df["taxon"].nunique()),
        "n_periods": int(df["period"].nunique()) if "period" in df.columns else 1,
        "n_occasions": int(df["occasion"].nunique()) if "occasion" in df.columns else 1,
        "n_traps": int(df["trap"].nunique()) if "trap" in df.columns else 1,
        "n_surveys": int(df[_survey_cols(df)].drop_duplicates().shape[0]),
        "y_values": ",".join(f"{v:g}" for v in yv[:12]) + (",..." if len(yv) > 12 else ""),
        "prop_zero": round(float((y == 0).mean()), 3) if len(y) else None,
        "columns": list(df.columns),
    }


#: Run order. Format checks first, in clause order; intake last.
ALL_CHECKS = (
    check_required_columns, check_column_order, check_key_na, check_treat_binary,
    check_undefined_columns, check_legacy_prefix, check_doubled_prefix, check_covariate_level,
    check_y_numeric, check_y_na, check_y_response_type, check_y_raw_without_recode,
    check_dup_key, check_explicit_zero_taxa, check_never_detected, check_unit_identity,
    check_survey_evidence,
    check_side_taxa, check_side_periods, check_side_units, check_side_traps,
    check_coordinates_declared, check_crs_declared, check_coordinates_sensitive,
    check_date_iso, check_index_integer,
    check_meta_present, check_meta_required, check_meta_vocab, check_meta_conditional,
    check_table_name, check_standard_version, check_sample_floor, check_replication,
    check_all_zero,
)
