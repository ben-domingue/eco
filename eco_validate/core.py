"""Load a core table with its side tables and metadata, run the checks, format
the result. `validate_file` and `validate_frame` are the public API; the CLI
and the uploader call the first, tests and R callers can use the second.

Side tables are found by name next to the core CSV: `<name>__taxa.csv`,
`__periods.csv`, `__units.csv`, `__traps.csv`, and `<name>__dataset.json`.
Nothing here touches the network.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import pandas as pd

from .checks import ALL_CHECKS, SIDE_KEYS, Table, table_stats
from .model import STANDARD_VERSION, Finding, Report, keep

SIDE_SUFFIXES = tuple(SIDE_KEYS)
TABLE_SUFFIXES = (".csv",)


def side_suffix(stem: str) -> str | None:
    """'x__taxa' -> 'taxa'; 'x' -> None. Unknown suffixes are None too: the
    directory walk then treats them as core tables and E1 reports them."""
    if "__" not in stem:
        return None
    suffix = stem.rsplit("__", 1)[1]
    return suffix if suffix in SIDE_KEYS or suffix == "dataset" else None


def is_core_table(path: str | Path) -> bool:
    p = Path(path)
    return p.suffix.lower() in TABLE_SUFFIXES and side_suffix(p.stem) is None


def _read_csv(path: Path) -> pd.DataFrame:
    # keep_default_na=False for the key columns would hide empties; we want NA
    # detection, so read with defaults but keep strings as strings.
    return pd.read_csv(path, low_memory=False)


def load_table(path: str | Path) -> Table:
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(p)
    name = p.stem
    df = _read_csv(p)
    side = {}
    for suffix in SIDE_SUFFIXES:
        sp = p.with_name(f"{name}__{suffix}.csv")
        if sp.exists():
            side[suffix] = _read_csv(sp)
    dataset = None
    dp = p.with_name(f"{name}__dataset.json")
    if dp.exists():
        dataset = json.loads(dp.read_text())
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
                   taxa=None, periods=None, units=None, traps=None,
                   profile: str = "upload") -> Report:
    """Validate an in-memory table. Side tables and metadata you do not pass
    are not reported missing (there was nowhere to look)."""
    side = {k: v for k, v in (("taxa", taxa), ("periods", periods),
                              ("units", units), ("traps", traps)) if v is not None}
    t = Table(name=name, df=df, dataset=dataset, side=side, side_searched=False)
    return run_checks(t, profile)


def validate_file(path: str | Path, *, profile: str = "upload", irw: bool = False) -> Report:
    t = load_table(path)
    report = run_checks(t, profile)
    if irw:
        report.findings.extend(irw_findings(t))
        report.checks_run.append("irw_view")
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
