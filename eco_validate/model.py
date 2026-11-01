"""Findings, reports, profiles and exit codes for `eco-validate`.

The framework is `irw_validate.model` with the IRW-specific parts removed. Two
ideas carry over unchanged:

* Every finding names the check that produced it, and every check that tests
  the format names the clause of `standard.md` it enforces (`CLAUSES`). A table
  *conforms* when no clause-bearing check errors; it *passes the gate* when no
  check errors at all. The two differ by intake policy (table name, standard
  version), which is not part of the format.
* Severity is a property of the (check, profile) pair. The `format` profile
  drops intake checks; `upload` (the default) runs everything.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterable

SEVERITIES = ("error", "warn", "info")
PROFILES = ("format", "upload")

#: The frozen standard these checks enforce: standard.md at the repo root.
STANDARD_VERSION = "1.0-draft"
STANDARD_URL = "https://ben-domingue.github.io/eco/standard.html"
#: What `standardVersion` in `__dataset.json` must start with (intake policy; the
#: uploader rejects tables built under an older draft).
STANDARD_PREFIX = "eco v1.0"

#: Check -> clause of standard.md. Only these checks bear on conformance.
#: `tests/test_validate.py` asserts that every check `checks.py` can emit is
#: either here or in INTAKE_CHECKS, so a check cannot ship unclassified.
CLAUSES = {
    "required_columns":     "E1",
    "column_order":         "E1",
    "key_na":               "E1",
    "treat_binary":         "E1",
    "undefined_columns":    "E5",
    "legacy_prefix":        "E5",
    "covariate_level":      "E5",
    "y_numeric":            "E2",
    "y_response_type":      "E2",
    "y_raw_without_recode": "E2",
    "dup_key":              "E3",
    "y_na":                 "E4",
    "explicit_zero_taxa":   "E4",
    "survey_evidence":      "E4",
    "side_taxa":            "E6",
    "side_periods":         "E6",
    "side_units":           "E6",
    "side_traps":           "E6",
    "side_key_na":          "E6",
    "coordinates_declared": "E7",
    "coordinates_sensitive": "E7",
    "crs_declared":         "E7",
    "date_iso":             "E8",
    "index_integer":        "E8",
    "meta_present":         "E10",
    "meta_required":        "E10",
    "meta_vocab":           "E10",
    "meta_conditional":     "E10",
}

#: Intake policy (standard.md, "Intake policy"): reported, not part of the format.
INTAKE_CHECKS = frozenset({
    "table_name", "standard_version", "sample_floor", "replication",
})


@dataclass(frozen=True)
class Finding:
    check: str
    severity: str          # one of SEVERITIES
    message: str
    table: str = ""
    group: str = "format"  # "format" | "intake" | "irw"
    #: Every affected case, when `message` samples or summarises them.
    details: tuple = ()

    @property
    def clause(self) -> str:
        return CLAUSES.get(self.check, "")

    def to_dict(self) -> dict:
        return {**vars(self), "clause": self.clause}


@dataclass
class Report:
    label: str
    profile: str = "upload"
    findings: list = field(default_factory=list)
    checks_run: list = field(default_factory=list)
    stats: dict = field(default_factory=dict)
    #: Side tables found next to the core table, by suffix.
    side_tables: list = field(default_factory=list)

    @property
    def errors(self) -> list:
        return [f for f in self.findings if f.severity == "error"]

    @property
    def warnings(self) -> list:
        return [f for f in self.findings if f.severity == "warn"]

    @property
    def ok(self) -> bool:
        """Would the gate accept this table under this profile?"""
        return not self.errors

    @property
    def nonconforming(self) -> list:
        """Clauses of the standard this table breaks, in clause order."""
        broken = {f.clause for f in self.errors if f.clause}
        return sorted(broken, key=lambda c: int(c[1:]))

    @property
    def conforms(self) -> bool:
        """Does the table meet the eco standard, as distinct from `ok`?

        `ok` includes intake policy and (with --irw) the IRW view; `conforms`
        asks only whether a clause-bearing check errored.
        """
        return not self.nonconforming

    def to_dict(self) -> dict:
        return {
            "label": self.label,
            "profile": self.profile,
            "standard_version": STANDARD_VERSION,
            "conforms": self.conforms,
            "nonconforming": self.nonconforming,
            "ok": self.ok,
            "stats": self.stats,
            "side_tables": self.side_tables,
            "checks_run": self.checks_run,
            "findings": [f.to_dict() for f in self.findings],
        }


def keep(finding: Finding, profile: str) -> bool:
    """Does this profile report the finding at all?"""
    if profile == "format" and finding.group != "format":
        return False
    return True


def exit_code(reports: Iterable[Report], *, strict: bool = False) -> int:
    """0 clean - 1 something blocks. 2 (bad input) is the CLI's."""
    reports = list(reports)
    if any(r.errors for r in reports):
        return 1
    if strict and any(r.warnings for r in reports):
        return 1
    return 0
