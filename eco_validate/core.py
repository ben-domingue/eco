"""Load a core table with its side tables and metadata, run the checks, format
the result. `validate_file` and `validate_frame` are the public API; the CLI
and the uploader call the first, tests and R callers can use the second.

Side tables are found by name next to the core CSV: `<name>__taxa.csv`,
`__periods.csv`, `__units.csv`, `__traps.csv`, `__survey_taxa.csv`, and
`<name>__dataset.json`.

A table too large for one file is stored as period parts (standard E4):
`<name>.parts/part-NN.csv`, each holding whole periods, with the side tables
and `__dataset.json` beside the directory as for any table. `validate_file` on
the directory runs every check on each part and then the checks that need the
whole table on the union (`whole_table_findings`).
Nothing here touches the network.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import pandas as pd

from .checks import (ALL_CHECKS, SIDE_KEYS, Table, _f, _sample, check_replication,
                     check_sample_floor, table_stats)
from .model import STANDARD_VERSION, Finding, Report, keep

SIDE_SUFFIXES = tuple(SIDE_KEYS)
TABLE_SUFFIXES = (".csv",)
PARTS_SUFFIX = ".parts"


def is_parted(path: str | Path) -> bool:
    """A table stored as period parts: a directory `<name>.parts`."""
    p = Path(path)
    return p.is_dir() and p.name.endswith(PARTS_SUFFIX)


def part_files(path: str | Path) -> list[Path]:
    return sorted(Path(path).glob("part-*.csv"))


def table_name(path: str | Path) -> str:
    p = Path(path)
    return p.name[: -len(PARTS_SUFFIX)] if is_parted(p) else p.stem


def side_suffix(stem: str) -> str | None:
    """'x__taxa' -> 'taxa'; 'x' -> None. Unknown suffixes are None too: the
    directory walk then treats them as core tables and E1 reports them."""
    if "__" not in stem:
        return None
    suffix = stem.rsplit("__", 1)[1]
    return suffix if suffix in SIDE_KEYS or suffix == "dataset" else None


def is_core_table(path: str | Path) -> bool:
    p = Path(path)
    if is_parted(p):
        return True
    return p.is_file() and p.suffix.lower() in TABLE_SUFFIXES and side_suffix(p.stem) is None


def _read_csv(path: Path) -> pd.DataFrame:
    # keep_default_na=False for the key columns would hide empties; we want NA
    # detection, so read with defaults but keep strings as strings.
    return pd.read_csv(path, low_memory=False)


def _load_beside(p: Path, name: str) -> tuple[dict, dict | None]:
    side = {}
    for suffix in SIDE_SUFFIXES:
        sp = p.with_name(f"{name}__{suffix}.csv")
        if sp.exists():
            side[suffix] = _read_csv(sp)
    dataset = None
    dp = p.with_name(f"{name}__dataset.json")
    if dp.exists():
        dataset = json.loads(dp.read_text())
    return side, dataset


def load_table(path: str | Path) -> Table:
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(p)
    if is_parted(p):
        raise ValueError(f"{p} is a table stored as parts; use validate_file()")
    name = p.stem
    df = _read_csv(p)
    side, dataset = _load_beside(p, name)
    return Table(name=name, df=df, dataset=dataset, side=side, side_searched=True)


def run_checks(t: Table, profile: str = "upload") -> Report:
    report = Report(label=t.name, profile=profile, side_tables=sorted(t.side))
    for check in ALL_CHECKS:
        report.checks_run.append(check.__name__.removeprefix("check_"))
        for f in check(t):
            if keep(f, profile):
                report.findings.append(f)
    report.stats = table_stats(t.df)
    return report


def validate_frame(df: pd.DataFrame, *, name: str = "table", dataset: dict | None = None,
                   taxa=None, periods=None, units=None, traps=None, survey_taxa=None,
                   profile: str = "upload") -> Report:
    """Validate an in-memory table. Side tables and metadata you do not pass
    are not reported missing (there was nowhere to look)."""
    side = {k: v for k, v in (("taxa", taxa), ("periods", periods),
                              ("units", units), ("traps", traps),
                              ("survey_taxa", survey_taxa)) if v is not None}
    t = Table(name=name, df=df, dataset=dataset, side=side, side_searched=False)
    return run_checks(t, profile)


def validate_file(path: str | Path, *, profile: str = "upload", irw: bool = False) -> Report:
    p = Path(path)
    if not p.exists() and p.suffix == ".csv" and p.with_name(p.stem + PARTS_SUFFIX).is_dir():
        p = p.with_name(p.stem + PARTS_SUFFIX)      # `<name>.csv` named for a parted table
    if is_parted(p):
        return validate_parts(p, profile=profile, irw=irw)
    t = load_table(p)
    report = run_checks(t, profile)
    if irw:
        report.findings.extend(irw_findings(t))
        report.checks_run.append("irw_view")
    return report


class _PartsAccumulator:
    """What the whole-table checks need from each part, without holding the parts."""

    def __init__(self):
        self.columns: list | None = None
        self.col_mismatch: list = []
        self.periods: dict = {}          # period -> part file
        self.overlap: list = []
        self.taxa_sets: list = []        # (part, frozenset)
        self.best = {}                   # taxon -> max y
        self.unit_best = {}              # unit -> max y (individual tables)
        self.units, self.occasions, self.traps = set(), set(), set()
        self.cov_pairs: dict = {}        # column -> set of (key, value)
        self.n_rows = self.n_surveys = self.n_zero = 0
        self.y_values = set()
        self.rows_by_part: dict = {}
        self.date_max = None             # latest `date`, Unix seconds (IRW view)

    def add(self, part: Path, df: pd.DataFrame):
        cols = list(df.columns)
        if self.columns is None:
            self.columns = cols
        elif cols != self.columns:
            self.col_mismatch.append(part.name)
        if "period" in df.columns:
            for per in pd.unique(df["period"]):
                if per in self.periods:
                    self.overlap.append(f"period {per} in {self.periods[per]} and {part.name}")
                else:
                    self.periods[per] = part.name
        if "taxon" in df.columns:
            self.taxa_sets.append((part.name, frozenset(df["taxon"].astype(str).unique())))
            y = pd.to_numeric(df["y"], errors="coerce").fillna(0) if "y" in df.columns else None
            if y is not None:
                for k, v in y.groupby(df["taxon"].astype(str)).max().items():
                    self.best[k] = max(self.best.get(k, v), v)
                for k, v in y.groupby(df["unit"].astype(str)).max().items():
                    self.unit_best[k] = max(self.unit_best.get(k, v), v)
                self.n_zero += int((y == 0).sum())
                if len(self.y_values) <= 10000:
                    self.y_values |= set(pd.unique(y.dropna()))
        if "unit" in df.columns:
            self.units |= set(df["unit"].astype(str).unique())
        if "occasion" in df.columns:
            self.occasions |= set(pd.unique(df["occasion"]))
        if "trap" in df.columns:
            self.traps |= set(df["trap"].astype(str).unique())
        for prefix, key in (("unit_", "unit"), ("taxon_", "taxon")):
            if key not in df.columns:
                continue
            for c in [c for c in df.columns if c.startswith(prefix)]:
                pairs = df[[key, c]].drop_duplicates().astype(str)
                self.cov_pairs.setdefault((key, c), set()).update(map(tuple, pairs.to_numpy()))
        from .checks import _survey_cols
        self.n_surveys += int(df[_survey_cols(df)].drop_duplicates().shape[0])
        self.n_rows += len(df)
        self.rows_by_part[part.name] = len(df)
        if "date" in df.columns:
            m = eco_to_irw(pd.DataFrame({"date": pd.unique(df["date"].dropna())}))["date"].max()
            if pd.notna(m):
                self.date_max = int(m) if self.date_max is None else max(self.date_max, int(m))

    def stats(self) -> dict:
        yv = sorted(self.y_values)
        return {
            "n_rows": self.n_rows, "n_units": len(self.units), "n_taxa": len(self.best),
            "n_periods": len(self.periods) if self.periods else 1,
            "n_occasions": len(self.occasions) if self.occasions else 1,
            "n_traps": len(self.traps) if self.traps else 1,
            "n_surveys": self.n_surveys,
            "y_values": ",".join(f"{v:g}" for v in yv[:12]) + (",..." if len(yv) > 12 else ""),
            "prop_zero": round(self.n_zero / self.n_rows, 3) if self.n_rows else None,
            "columns": self.columns or [],
        }


def whole_table_findings(t: Table, acc: _PartsAccumulator, parts: list[Path]) -> list:
    """The checks that need every part at once (standard E4: every clause applies
    to the union of a table's parts)."""
    out = []
    d = t.dataset or {}
    if acc.col_mismatch:
        out.append(_f("table_parts", "error",
                      f"parts differ in their columns from {parts[0].name}: {_sample(acc.col_mismatch)}", t))
    if acc.overlap:
        out.append(_f("table_parts", "error",
                      f"{len(acc.overlap)} period(s) appear in more than one part; each part holds "
                      f"whole periods (E4)", t, details=acc.overlap))
    manifest = d.get("parts")
    if manifest is not None:
        listed = {m.get("file"): m.get("n_rows") for m in manifest if isinstance(m, dict)}
        if set(listed) != set(acc.rows_by_part):
            out.append(_f("table_parts", "error",
                          f"__dataset.json `parts` lists {sorted(listed)}, the directory holds "
                          f"{sorted(acc.rows_by_part)}", t))
        else:
            bad = [f for f, n in listed.items() if n != acc.rows_by_part[f]]
            if bad:
                out.append(_f("table_parts", "error",
                              f"row counts in __dataset.json `parts` differ from the files: {_sample(bad)}", t))
    else:
        out.append(_f("table_parts", "error",
                      "a table stored as parts needs `parts` in __dataset.json (file, periods, n_rows)", t))
    union = frozenset(acc.best)
    if t.side.get("survey_taxa") is None and len(union) > 1:
        short = [p for p, s in acc.taxa_sets if s != union]
        if short:
            out.append(_f("explicit_zero_taxa", "error",
                          f"{len(short)} part(s) lack rows for some of the table's {len(union)} taxa; every "
                          f"survey carries every taxon (E4.2)", t, details=short))
    for (key, c), pairs in acc.cov_pairs.items():
        n_keys = len({k for k, _ in pairs})
        if len(pairs) > n_keys:
            out.append(_f("covariate_level", "error",
                          f"`{c}` varies within {key} across parts: {len(pairs) - n_keys:,} extra "
                          f"combination(s)", t))
    side = t.side.get("taxa")
    if side is not None and "taxon" in side.columns:
        extra = sorted(set(side["taxon"].dropna().astype(str)) - set(union))
        if extra:
            out.append(_f("side_taxa", "error",
                          f"{len(extra)} __taxa row(s) not in the core table: {_sample(extra)}; every "
                          f"__taxa row must appear in the core", t, details=extra))
    if d.get("unitKind") == "individual":
        never = sorted(u for u, v in acc.unit_best.items() if v <= 0)
        if never:
            out.append(_f("never_detected", "error",
                          f"{len(never):,} individual(s) are never detected (every y = 0); a catalogue "
                          f"entry never sighted is not a unit (E4.4): {_sample(never)}", t, details=never))
    ti = d.get("taxonInclusion")
    if ti in ("single", "recorded", "target"):
        n = len(union)
        if (ti == "single") != (n == 1):
            out.append(_f("meta_conditional", "error",
                          f"taxonInclusion = {ti} with {n} taxa (E10: `single` exactly when the "
                          f"table has one taxon)", t))
        if ti == "recorded":
            never = sorted(k for k, v in acc.best.items() if v <= 0)
            if never:
                out.append(_f("meta_conditional", "error",
                              f"taxonInclusion = recorded but {len(never)} taxon/taxa are never "
                              f"recorded in this table (E10): {_sample(never)}", t, details=never))
    s = acc.stats()
    out += check_sample_floor(t, s) + check_replication(t, s)
    return out


# irw_validate's `date_range*` warns when the IRW view's maximum date is below this
# (irw_validate/_checks.py); per part it misfires on a table whose early parts predate 1973.
IRW_DATE_RANGE = "irw:date_range*"
IRW_DATE_FLOOR = 1e8


def validate_parts(path: str | Path, *, profile: str = "upload", irw: bool = False) -> Report:
    """Validate a table stored as period parts, one part in memory at a time."""
    d = Path(path)
    name = table_name(d)
    parts = part_files(d)
    side, dataset = _load_beside(d, name)
    report = Report(label=name, profile=profile, side_tables=sorted(side))
    if not parts:
        report.findings.append(Finding("table_parts", "error", f"{d} holds no part-*.csv files",
                                       table=name, group="format"))
        return report
    acc = _PartsAccumulator()
    seen: dict = {}
    irw_msgs: dict = {}                  # (check, severity) -> {part: message}
    for part in parts:
        df = _read_csv(part)
        t = Table(name=name, df=df, dataset=dataset, side=side, side_searched=True, part=True)
        found = []
        for check in ALL_CHECKS:
            if part is parts[0]:
                report.checks_run.append(check.__name__.removeprefix("check_"))
            found += [f for f in check(t) if keep(f, profile)]
        if irw:
            found += irw_findings(t)
        for f in found:
            # IRW-view findings carry per-part figures in the message; one per check is enough
            k = (f.check, f.severity) if f.group == "irw" else (f.check, f.severity, f.message)
            if f.group == "irw":
                irw_msgs.setdefault(k, {})[part.name] = f.message
            if k in seen:
                seen[k] = (seen[k][0], seen[k][1] + [part.name])
            else:
                seen[k] = (f, [part.name])
        acc.add(part, df)
        del df, t
    for f, where in seen.values():
        if f.check == IRW_DATE_RANGE:
            # A check on the maximum: judge it on the whole table's, not part 1's (#57).
            if acc.date_max is None or acc.date_max >= IRW_DATE_FLOOR:
                continue
            f = Finding(f.check, f.severity, f"date max={acc.date_max} over all parts — looks too "
                        f"small for Unix seconds; verify units", table=f.table, group=f.group)
        msgs = irw_msgs.get((f.check, f.severity), {})
        message, extra = f.message, ()
        if len(set(msgs.values())) > 1:
            # IRW checks run per part; when their figures differ, say whose figure the
            # headline carries and list every part's.
            message = f"{f.message} (figures from {where[0]}; each part's below)"
            extra = tuple(f"{k}: {v}" for k, v in msgs.items())
        details = tuple(f.details) + extra + (f"in {len(where)} of {len(parts)} parts: {', '.join(where[:5])}"
                                              + (", ..." if len(where) > 5 else ""),)
        report.findings.append(Finding(f.check, f.severity, message, table=f.table,
                                       group=f.group, details=details))
    whole = Table(name=name, df=pd.DataFrame(), dataset=dataset, side=side, side_searched=True, part=True)
    report.findings += [f for f in whole_table_findings(whole, acc, parts) if keep(f, profile)]
    report.checks_run += ["table_parts"] + (["irw_view"] if irw else [])
    report.stats = acc.stats()
    return report


# ---------------------------------------------------------------------------
# The IRW view (optional): the same table under IRW v1.0 names, checked with
# irw-validate so "an eco table is a valid IRW table" stays a tested claim.
# Mirrors eco_to_irw() in converters/eco_standard.R.
# ---------------------------------------------------------------------------

IRW_SRC_ENV = "IRW_SRC"
_DEFAULT_IRW_SRC = Path.home() / "Dropbox" / "projects" / "irw" / "src"


def eco_to_irw(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    # SCR: IRW has no trap key, so a trap becomes part of the item (traps as items,
    # the reading standard_draft.md gives SCR): item = "<taxon>:<trap>", and the
    # key (id, item, period, occasion) is unique again.
    if "trap" in out.columns:
        out["taxon"] = out["taxon"].astype(str) + ":" + out["trap"].astype(str)
        out = out.drop(columns=["trap"])
    ren = {"unit": "id", "taxon": "item", "y": "resp", "y_raw": "resp_raw", "observer": "rater"}
    out = out.rename(columns={k: v for k, v in ren.items() if k in out.columns})
    out.columns = [c.replace("unit_", "cov_", 1) if c.startswith("unit_") else
                   c.replace("taxon_", "itemcov_", 1) if c.startswith("taxon_") else
                   c.replace("period_", "periodcov_", 1) if c.startswith("period_") else c
                   for c in out.columns]
    if "date" in out.columns:
        d = out["date"].astype("string")
        d = d.where(d.str.len() != 10, d + "T00:00:00Z")
        ts = pd.to_datetime(d, utc=True, errors="coerce", format="ISO8601")
        # Seconds since the epoch; resolution-independent (pandas 3 parses to microseconds).
        secs = (ts - pd.Timestamp(0, tz="UTC")) // pd.Timedelta(seconds=1)
        out["date"] = secs.astype("Int64")
    first = [c for c in ("id", "item", "resp", "resp_raw", "period", "occasion",
                         "date", "rater", "treat", "cluster_id") if c in out.columns]
    return out[first + [c for c in out.columns if c not in first]]


def _import_irw_validate():
    try:
        import irw_validate  # noqa: F401
        return irw_validate
    except ImportError:
        pass
    src = Path(os.environ.get(IRW_SRC_ENV) or _DEFAULT_IRW_SRC)
    if (src / "irw_validate").is_dir():
        sys.path.insert(0, str(src))
        try:
            import irw_validate
            return irw_validate
        except ImportError:
            return None
    return None


def irw_findings(t: Table) -> list:
    """Run irw-validate (upload profile) on the IRW view. Its errors block, its
    warnings warn, each under check `irw:<name>`. A missing irw_validate is an
    error, never a silent pass."""
    mod = _import_irw_validate()
    if mod is None:
        return [Finding("irw:unavailable", "error",
                        f"irw_validate not importable; pip install irw-validate or set "
                        f"{IRW_SRC_ENV} to the ben-domingue/irw src checkout",
                        table=t.name, group="irw")]
    view = eco_to_irw(t.df)
    try:
        rep = mod.validate_frame(view, label=t.name, profile="upload")
    except TypeError:
        rep = mod.validate_frame(view, t.name, profile="upload")
    out = []
    for f in rep.findings:
        if f.severity not in ("error", "warn"):
            continue
        out.append(Finding(f"irw:{f.check}", f.severity, f.message, table=t.name,
                           group="irw", details=tuple(getattr(f, "details", ()))))
    conforms = getattr(rep, "conforms", None)
    if conforms is False:
        out.append(Finding("irw:conformance", "warn",
                           f"IRW view does not conform to IRW {getattr(mod, 'STANDARD_VERSION', '1.0')}: "
                           f"{', '.join(rep.nonconforming)}", table=t.name, group="irw"))
    return out


# ---------------------------------------------------------------------------

def format_report(report: Report, *, verbose: bool = False) -> str:
    lines = [f"{report.label} [{report.profile}]"]
    verdict = "conforms" if report.conforms else f"does not conform ({', '.join(report.nonconforming)})"
    lines.append(f"  eco standard {STANDARD_VERSION}: {verdict}")
    if report.profile != "format":
        gate = "passes" if report.ok else f"blocked by {len(report.errors)} error(s)"
        lines.append(f"  {report.profile} gate: {gate}")
    s = report.stats
    if s:
        lines.append(f"  {s['n_rows']:,} rows, {s['n_units']:,} units, {s['n_taxa']} taxa, "
                     f"{s['n_periods']} period(s), {s['n_occasions']} occasion(s); "
                     f"side tables: {', '.join(report.side_tables) or 'none'}")
    if not report.findings:
        lines.append(f"  ok -- {len(report.checks_run)} checks, nothing to report")
    order = {"error": 0, "warn": 1, "info": 2}
    for f in sorted(report.findings, key=lambda f: order.get(f.severity, 3)):
        where = f"[{f.clause}]" if f.clause else f"[{f.group}]"
        lines.append(f"  {f.severity.upper():5s} {f.check:22s} {where:8s} {f.message}")
        if verbose:
            lines.extend(f"        - {d}" for d in f.details)
    return "\n".join(lines)
