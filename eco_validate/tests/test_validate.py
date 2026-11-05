"""Regression tests for eco-validate.

Two kinds: the corpus in output/ passes (so a change to a check that breaks a
shipped table is caught here, not at upload), and each check fires on a
fixture built by breaking one thing. Run from the repo root:

    python3 -m pytest eco_validate/tests -q
"""
from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

import pandas as pd
import pytest

from eco_validate import checks, validate_file, validate_frame
from eco_validate.cli import main
from eco_validate.model import CLAUSES, INTAKE_CHECKS

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "output"
CORE = sorted([p for p in OUT.glob("*.csv") if "__" not in p.stem] + list(OUT.glob("*.parts")))


# ---------------------------------------------------------------------------
# The corpus
# ---------------------------------------------------------------------------

@pytest.mark.skipif(not CORE, reason="no output/ corpus in this checkout")
@pytest.mark.parametrize("path", CORE, ids=[p.name.removesuffix(".parts").removesuffix(".csv") for p in CORE])
def test_corpus_passes(path):
    r = validate_file(path)
    assert r.ok, [f"{f.check}: {f.message}" for f in r.errors]
    assert r.conforms


@pytest.mark.skipif(not CORE, reason="no output/ corpus in this checkout")
def test_cli_over_output_dir(capsys):
    assert main([str(OUT), "--json"]) == 0
    reports = json.loads(capsys.readouterr().out)
    assert len(reports) == len(CORE)
    assert all(r["ok"] for r in reports)


# ---------------------------------------------------------------------------
# Every check is classified
# ---------------------------------------------------------------------------

def test_every_check_has_clause_or_is_intake():
    """A check cannot ship unclassified: each name `checks.py` can emit is
    either a clause of the standard or declared intake policy."""
    src = (ROOT / "eco_validate" / "checks.py").read_text()
    emitted = set(re.findall(r'_f\("([a-z_]+)"', src))
    assert emitted, "no checks found"
    unclassified = emitted - set(CLAUSES) - INTAKE_CHECKS
    assert not unclassified, unclassified
    assert not (set(CLAUSES) & INTAKE_CHECKS)


def test_r_twin_vocabularies_match():
    """lib/eco_common.R and checks.py must agree on the controlled vocabularies
    and the required metadata fields, or the build step and the gate drift."""
    r = (ROOT / "lib" / "eco_common.R").read_text()

    def r_vec(name):
        m = re.search(name + r"\s*<-\s*c\(([^)]*)\)", r)
        return tuple(re.findall(r'"([^"]+)"', m.group(1)))
    assert r_vec("RESPONSE_TYPES") == checks.RESPONSE_TYPES
    assert r_vec("SURVEY_EVIDENCE") == checks.SURVEY_EVIDENCE
    assert r_vec("CLOSURE") == checks.CLOSURE
    assert r_vec("OCCASION_KINDS") == checks.OCCASION_KINDS
    assert r_vec("TAXON_INCLUSION") == checks.TAXON_INCLUSION
    assert r_vec("UNIT_IDENTITY") == checks.UNIT_IDENTITY
    m = re.search(r"req <- c\((.*?)\)\n", r, re.S)
    assert tuple(re.findall(r'"([^"]+)"', m.group(1))) == checks.META_REQUIRED


# ---------------------------------------------------------------------------
# Fixtures: a small valid community table, then break one thing at a time
# ---------------------------------------------------------------------------

def good_frame():
    rows = []
    for u in range(1, 41):
        for occ in (1, 2):
            for tx in ("AAA", "BBB"):
                rows.append({"unit": u, "taxon": tx, "y": int((u + occ) % 3 == 0),
                             "occasion": occ, "date": f"2020-05-{occ:02d}",
                             "unit_elev": u * 10.0, "obs_wind": occ * 1.5})
    return pd.DataFrame(rows)


def good_meta(**over):
    d = {"title": "t", "creator": "c", "pubDate": "2020", "citation": "x",
         "sourceURL": "https://example.org", "intellectualRights": {"spdx": "CC0-1.0", "url": "u"},
         "samplingProtocol": "p", "samplingProtocolCode": "point_count",
         "responseType": "detection", "unitKind": "site", "closure": "closed",
         "surveyEvidence": "deposited_matrix", "temporalCoverage": "2020",
         "geographicCoverage": "nowhere", "occasionKind": "time",
         "taxonInclusion": "recorded", "standardVersion": "eco v1.1-draft (2026-11-03)"}
    d.update(over)
    return d


def good_taxa():
    return pd.DataFrame({"taxon": ["AAA", "BBB"], "scientificName": ["A a", "B b"],
                         "taxonRank": ["species"] * 2, "taxonID": ["g1", "g2"]})


_DEFAULT = object()


def run(df=None, meta=None, taxa=_DEFAULT, **side):
    df = good_frame() if df is None else df
    meta = good_meta() if meta is None else meta
    taxa = good_taxa() if taxa is _DEFAULT else taxa
    return validate_frame(df, name="smith_2020_place_comm", dataset=meta, taxa=taxa, **side)


def checks_of(report, severity=None):
    return {f.check for f in report.findings if severity is None or f.severity == severity}


def test_fixture_is_clean():
    r = run()
    assert r.ok and r.conforms, [f.message for f in r.findings]
    assert not r.findings


def test_required_columns_and_order():
    df = good_frame().drop(columns="taxon")
    assert "required_columns" in checks_of(run(df), "error")
    df = good_frame()[["taxon", "unit", "y", "occasion"]]
    r = run(df)
    assert "required_columns" in checks_of(r, "error")
    assert "E1" in r.nonconforming


def test_undefined_and_legacy_columns():
    df = good_frame(); df["elev"] = 1
    assert "undefined_columns" in checks_of(run(df), "error")
    df = good_frame(); df["cov_elev"] = 1
    assert "legacy_prefix" in checks_of(run(df), "error")
    for c in ("unit_unit_sex", "obs_obs_effort", "period_period_rain", "taxon_taxon_mass"):
        df = good_frame(); df[c] = 1
        r = run(df)
        assert "doubled_prefix" in checks_of(r, "error") and "E5" in r.nonconforming, c
    df = good_frame(); df["unit_obs_count"] = 1        # two different levels is not doubling
    assert "doubled_prefix" not in checks_of(run(df))
    r = run(units=pd.DataFrame({"unit": range(1, 41), "unit_unit_elev": 1.0}))
    assert "doubled_prefix" in checks_of(r, "error")


def test_y_rules():
    df = good_frame(); df.loc[0, "y"] = None
    assert "y_na" in checks_of(run(df), "error")
    df = good_frame(); df["y"] = df["y"].astype(str); df.loc[0, "y"] = "x"
    assert "y_numeric" in checks_of(run(df), "error")
    df = good_frame(); df.loc[0, "y"] = 3
    assert "y_response_type" in checks_of(run(df), "error")        # detection but y = 3
    assert "y_response_type" not in checks_of(run(df, good_meta(responseType="count")))
    df.loc[0, "y"] = -1
    assert "y_response_type" in checks_of(run(df, good_meta(responseType="count")), "error")


def test_dup_key_and_explicit_zero():
    df = pd.concat([good_frame(), good_frame().head(2)])
    assert "dup_key" in checks_of(run(df), "error")
    df = good_frame().iloc[1:]                       # drop one taxon row from one survey
    r = run(df)
    assert "explicit_zero_taxa" in checks_of(r, "error")
    assert "E4" in r.nonconforming


def test_individual_units_one_taxon_per_table():
    # Ruling #20: a multi-taxon table whose units are individuals is rejected as such,
    # even when every survey has every taxon; a single-taxon one is fine.
    df = good_frame()
    r = run(df, good_meta(unitKind="individual"))
    msgs = [f.message for f in r.findings if f.check == "explicit_zero_taxa"]
    assert msgs and "one table per taxon" in msgs[0]
    one = df[df["taxon"] == df["taxon"].iloc[0]]
    assert "explicit_zero_taxa" not in checks_of(run(one, good_meta(unitKind="individual")))


def test_covariate_level():
    df = good_frame(); df["unit_elev"] = range(len(df))
    assert "covariate_level" in checks_of(run(df), "error")
    df = good_frame(); df["taxon_mass"] = range(len(df))
    assert "covariate_level" in checks_of(run(df), "error")
    df = good_frame(); df["period"] = 1; df["period_hab"] = df["unit"]   # constant within unit x period
    r = run(df, periods=pd.DataFrame({"period": [1]}))
    assert "covariate_level" not in checks_of(r)


def test_side_tables():
    r = run(taxa=good_taxa().iloc[:1])
    assert "side_taxa" in checks_of(r, "error")                     # core taxon missing
    extra = pd.concat([good_taxa(), pd.DataFrame({"taxon": ["CCC"]})])
    assert "side_taxa" in checks_of(run(taxa=extra), "error")       # taxa row not in core
    assert "side_taxa" in checks_of(run(taxa=good_taxa().rename(columns={"taxon": "code"})), "error")
    df = good_frame(); df["period"] = 1
    r = run(df, periods=pd.DataFrame({"period": [2]}))
    assert "side_periods" in checks_of(r, "error")
    r = run(units=pd.DataFrame({"unit": [1, 2]}))
    assert "side_units" in checks_of(r, "error")
    r = run(units=pd.DataFrame({"unit": list(range(1, 51))}))      # a frame may exceed the core
    assert "side_units" not in checks_of(r)


def test_coordinates():
    df = good_frame(); df["unit_decimalLatitude"] = 45.123; df["unit_decimalLongitude"] = 7.0
    r = run(df)
    assert "coordinates_declared" in checks_of(r, "error")
    assert "coordinates_declared" not in checks_of(run(df, good_meta(coordinatesCoarsened=None)))
    # via __units only
    r = run(units=pd.DataFrame({"unit": range(1, 41), "unit_decimalLatitude": 1.0}))
    assert "coordinates_declared" in checks_of(r, "error")
    # projected needs crs
    df = good_frame(); df["unit_x"] = 1.0; df["unit_y"] = 2.0
    r = run(df, good_meta(coordinatesCoarsened=None))
    assert "crs_declared" in checks_of(r, "error")
    # sensitive taxon with fine coordinates warns
    df = good_frame(); df["unit_decimalLatitude"] = 45.123; df["unit_decimalLongitude"] = 7.0
    taxa = good_taxa(); taxa["taxon_iucnCategory"] = ["EN", "LC"]
    r = run(df, good_meta(coordinatesCoarsened=None), taxa=taxa)
    assert "coordinates_sensitive" in checks_of(r, "warn")
    df["unit_decimalLatitude"] = 45.1
    assert "coordinates_sensitive" not in checks_of(run(df, good_meta(coordinatesCoarsened=None), taxa=taxa))


def test_time():
    df = good_frame(); df["date"] = "2020"
    assert "date_iso" in checks_of(run(df), "error")
    df = good_frame(); df["date"] = "2020-05-01T10:30Z"
    assert "date_iso" not in checks_of(run(df))
    df = good_frame(); df["occasion"] = df["occasion"].map({1: "a", 2: "b"})
    assert "index_integer" in checks_of(run(df), "error")


def test_metadata():
    m = good_meta(); del m["surveyEvidence"]
    r = run(meta=m)
    assert "meta_required" in checks_of(r, "error") and "E10" in r.nonconforming
    assert "meta_vocab" in checks_of(run(meta=good_meta(responseType="presence")), "error")
    assert "meta_vocab" in checks_of(run(meta=good_meta(unitKind="plot")), "error")
    assert "meta_conditional" in checks_of(run(meta=good_meta(surveyEvidence="inferred")), "error")
    r = run(meta=good_meta(surveyEvidence="inferred", surveyEvidenceNote="span"))
    assert "meta_conditional" not in checks_of(r)
    assert "survey_evidence" in checks_of(r, "warn")
    assert "meta_conditional" in checks_of(run(meta=good_meta(responseType="ordinal")), "error")
    # coordinatesCoarsened: null or {value: bool, method: str} (#38, #40)
    for bad in ("TRUE", True, {"value": True}, {"value": "yes", "method": "m"}, {"value": False, "method": ""}):
        assert "meta_vocab" in checks_of(run(meta=good_meta(coordinatesCoarsened=bad)), "error"), bad
    for ok in (None, {"value": False, "method": "kept as published"}, {"value": True, "method": "0.1 degree cell"}):
        assert "meta_vocab" not in checks_of(run(meta=good_meta(coordinatesCoarsened=ok))), ok
    assert "meta_conditional" in checks_of(run(meta=good_meta(responseType="multinomial_cell")), "error")


def test_binomial_count_rules():
    """Ruling #34: no occasion, obs_trials on every row, y <= obs_trials, effortColumn declared."""
    df = good_frame()
    df = df.groupby(["unit", "taxon"], as_index=False).agg(y=("y", "sum"))
    df["obs_trials"] = 3
    df = df[["unit", "taxon", "y", "obs_trials"]]
    meta = good_meta(responseType="binomial_count", effortColumn="obs_trials",
                     occasionKind="none", closure="none")
    r = run(df=df, meta=meta)
    assert r.ok, [f.message for f in r.errors]
    assert "replication" not in checks_of(r)
    assert "meta_conditional" in checks_of(run(df=df, meta=good_meta(
        responseType="binomial_count", occasionKind="none", closure="none")), "error")
    bad = df.copy(); bad.loc[bad.index[0], "y"] = 9
    assert "y_response_type" in checks_of(run(df=bad, meta=meta), "error")
    assert "y_response_type" in checks_of(run(df=df.drop(columns="obs_trials"), meta=meta), "error")
    assert "y_response_type" in checks_of(run(df=good_frame().assign(obs_trials=1), meta=meta), "error")
    assert "meta_present" not in checks_of(run(meta=None))          # a frame alone: nowhere to look


def test_intake_profile_split():
    df = good_frame()[good_frame()["unit"] <= 10]
    r = run(df)
    assert "sample_floor" in checks_of(r, "warn")
    assert validate_frame(df, name="smith_2020_place_comm", dataset=good_meta(),
                          taxa=good_taxa(), profile="format").findings == []
    r = validate_frame(good_frame(), name="Bad Name", dataset=good_meta(), taxa=good_taxa())
    assert "table_name" in checks_of(r, "error") and r.conforms and not r.ok
    r = run(meta=good_meta(standardVersion="eco v0.3"))
    assert "standard_version" in checks_of(r, "error") and r.conforms


# ---------------------------------------------------------------------------
# Files: side tables found by name, exit codes, the peer's regression
# ---------------------------------------------------------------------------

@pytest.mark.skipif(not CORE, reason="no output/ corpus in this checkout")
def test_removing_survey_evidence_blocks(tmp_path):
    src = OUT / "kery_2010_crossbill_dynocc"
    for f in OUT.glob("kery_2010_crossbill_dynocc*"):
        shutil.copy(f, tmp_path / f.name)
    mp = tmp_path / "kery_2010_crossbill_dynocc__dataset.json"
    d = json.loads(mp.read_text()); del d["surveyEvidence"]; mp.write_text(json.dumps(d))
    r = validate_file(tmp_path / "kery_2010_crossbill_dynocc.csv")
    assert not r.ok and "E10" in r.nonconforming
    assert main([str(tmp_path)]) == 1
    # a side table named on the command line validates its core table
    assert main([str(tmp_path / "kery_2010_crossbill_dynocc__taxa.csv")]) == 1
    (tmp_path / "kery_2010_crossbill_dynocc__taxa.csv").unlink()
    assert "side_taxa" in checks_of(validate_file(tmp_path / "kery_2010_crossbill_dynocc.csv"), "error")


def test_missing_metadata_file_is_an_error(tmp_path):
    good_frame().to_csv(tmp_path / "smith_2020_place_comm.csv", index=False)
    good_taxa().to_csv(tmp_path / "smith_2020_place_comm__taxa.csv", index=False)
    r = validate_file(tmp_path / "smith_2020_place_comm.csv")
    assert "meta_present" in checks_of(r, "error")


def test_cli_bad_input(tmp_path):
    assert main([str(tmp_path)]) == 2
    assert main([str(tmp_path / "nope.csv")]) == 2


def test_strict_turns_warnings_into_exit_1(tmp_path):
    df = good_frame()[good_frame()["unit"] <= 10]
    df.to_csv(tmp_path / "smith_2020_place_comm.csv", index=False)
    good_taxa().to_csv(tmp_path / "smith_2020_place_comm__taxa.csv", index=False)
    (tmp_path / "smith_2020_place_comm__dataset.json").write_text(json.dumps(good_meta()))
    assert main([str(tmp_path)]) == 0
    assert main([str(tmp_path), "--strict"]) == 1


def test_eco_to_irw_folds_trap_into_item():
    from eco_validate import eco_to_irw
    import pandas as pd
    scr = pd.DataFrame({"unit": ["a", "a", "b"], "taxon": "RAT", "y": [0, 1, 0],
                        "trap": ["t1", "t2", "t1"], "period": 1, "occasion": 1})
    v = eco_to_irw(scr)
    assert "trap" not in v.columns
    assert list(v["item"]) == ["RAT:t1", "RAT:t2", "RAT:t1"]
    assert not v.duplicated(["id", "item", "period", "occasion"]).any()


def test_eco_to_irw_view():
    from eco_validate import eco_to_irw
    v = eco_to_irw(good_frame())
    assert list(v.columns[:3]) == ["id", "item", "resp"]
    assert "cov_elev" in v.columns and "obs_wind" in v.columns
    assert v["date"].iloc[0] == 1588291200          # 2020-05-01T00:00:00Z


# ---------------------------------------------------------------------------
# v1.1-draft rules
# ---------------------------------------------------------------------------

def test_closure_and_occasion_kind():
    assert "meta_vocab" in checks_of(run(meta=good_meta(closure="occasion")), "error")
    assert "meta_vocab" in checks_of(run(meta=good_meta(occasionKind="visit")), "error")
    assert "meta_vocab" in checks_of(run(meta=good_meta(taxonInclusion="all")), "error")
    # occasionKind none exactly when there is no occasion column
    assert "meta_conditional" in checks_of(run(meta=good_meta(occasionKind="none")), "error")
    one = good_frame()[good_frame()["occasion"] == 1].drop(columns="occasion")
    r = run(one, good_meta(occasionKind="time", closure="none"))
    assert "meta_conditional" in checks_of(r, "error")
    r = run(one, good_meta(occasionKind="none", closure="closed"))
    assert "meta_conditional" in checks_of(r, "error")
    assert "meta_conditional" not in checks_of(run(one, good_meta(occasionKind="none", closure="none")))
    # closure none with an occasion column needs one occasion per unit x taxon x period
    assert "meta_conditional" in checks_of(run(meta=good_meta(closure="none")), "error")
    for kind in ("observer", "method", "spatial", "cell"):
        assert "meta_conditional" not in checks_of(run(meta=good_meta(occasionKind=kind))), kind
    assert "meta_required" in checks_of(run(meta={k: v for k, v in good_meta().items()
                                                  if k != "occasionKind"}), "error")


def test_taxon_inclusion_and_withheld():
    assert "meta_conditional" in checks_of(run(meta=good_meta(taxonInclusion="single")), "error")
    df = good_frame(); df = df[df["taxon"] == "AAA"]
    r = run(df, good_meta(taxonInclusion="recorded"), taxa=good_taxa().iloc[:1])
    assert "meta_conditional" in checks_of(r, "error")
    r = run(df, good_meta(taxonInclusion="single"), taxa=good_taxa().iloc[:1])
    assert "meta_conditional" not in checks_of(r)
    assert "meta_conditional" in checks_of(run(meta=good_meta(taxaWithheld="X y")), "error")
    assert "meta_conditional" in checks_of(run(meta=good_meta(taxaWithheld=["A a"])), "error")
    assert "meta_conditional" not in checks_of(run(meta=good_meta(taxaWithheld=["Z z"])))


def test_survey_taxa():
    # unit 1-20 surveyed for AAA and BBB, units 21-40 for AAA only
    df = good_frame()
    df = df[~((df["unit"] > 20) & (df["taxon"] == "BBB"))]
    assert "explicit_zero_taxa" in checks_of(run(df), "error")
    st = pd.DataFrame([{"unit": u, "taxon": t} for u in range(1, 41)
                       for t in (("AAA", "BBB") if u <= 20 else ("AAA",))])
    r = run(df, survey_taxa=st)
    assert r.ok, [f.message for f in r.errors]
    # a listed taxon missing from a survey, and an unlisted one present
    assert "explicit_zero_taxa" in checks_of(run(df.iloc[1:], survey_taxa=st), "error")
    assert "explicit_zero_taxa" in checks_of(run(good_frame(), survey_taxa=st), "error")
    # a survey that no row matches
    assert "explicit_zero_taxa" in checks_of(run(df, survey_taxa=st[st["unit"] != 5]), "error")
    # bad columns, and taxa not in __taxa
    assert "side_survey_taxa" in checks_of(run(df, survey_taxa=st.rename(columns={"unit": "site"})), "error")
    st2 = pd.concat([st, pd.DataFrame({"unit": [1], "taxon": ["CCC"]})])
    assert "side_survey_taxa" in checks_of(run(df, survey_taxa=st2), "error")
    # matching on occasion only works too
    sto = pd.DataFrame({"occasion": [1, 1, 2], "taxon": ["AAA", "BBB", "AAA"]})
    dfo = good_frame(); dfo = dfo[~((dfo["occasion"] == 2) & (dfo["taxon"] == "BBB"))]
    assert run(dfo, survey_taxa=sto).ok


def test_survey_taxa_file_is_a_side_table(tmp_path):
    from eco_validate.core import is_core_table, load_table
    df = good_frame()
    df.to_csv(tmp_path / "smith_2020_place_comm.csv", index=False)
    pd.DataFrame({"occasion": [1, 2], "taxon": ["AAA", "AAA"]}).to_csv(
        tmp_path / "smith_2020_place_comm__survey_taxa.csv", index=False)
    assert not is_core_table(tmp_path / "smith_2020_place_comm__survey_taxa.csv")
    assert "survey_taxa" in load_table(tmp_path / "smith_2020_place_comm.csv").side


def test_never_detected_individuals():
    df = pd.DataFrame({"unit": [1, 1, 2, 2], "taxon": "AAA", "y": [1, 0, 0, 0],
                       "period": [1, 2, 1, 2]})
    meta = good_meta(unitKind="individual", closure="none", occasionKind="none",
                     taxonInclusion="single")
    taxa = good_taxa().iloc[:1]
    per = pd.DataFrame({"period": [1, 2]})
    r = run(df, meta, taxa=taxa, periods=per)
    assert "never_detected" in checks_of(r, "error") and "E4" in r.nonconforming
    assert "never_detected" not in checks_of(run(df[df["unit"] == 1], meta, taxa=taxa, periods=per))
    # site tables may have all-zero units
    assert "never_detected" not in checks_of(run(df, good_meta(closure="none", occasionKind="none",
                                                               taxonInclusion="single"),
                                                 taxa=taxa, periods=per))


def test_unit_identity():
    df = good_frame(); df["unit_identity"] = "both"
    assert "unit_identity" not in checks_of(run(df))
    df.loc[df["unit"] == 3, "unit_identity"] = "flank"
    assert "unit_identity" in checks_of(run(df), "error")


def test_taxon_id_needs_remarks():
    taxa = good_taxa(); taxa.loc[1, "taxonID"] = None
    assert "taxon_rows" in checks_of(run(taxa=taxa), "error")
    taxa["taxonRemarks"] = [None, "subfamily absent from the GBIF backbone"]
    assert "taxon_rows" not in checks_of(run(taxa=taxa))


def test_trap_coordinates_of_flagged_taxa():
    df = good_frame(); df = df[df["taxon"] == "AAA"].copy()
    df["trap"] = 1
    taxa = good_taxa().iloc[:1].copy(); taxa["taxon_iucnCategory"] = "EN"
    traps = pd.DataFrame({"trap": [1], "x": [512345.0], "y": [6123456.0]})
    meta = good_meta(taxonInclusion="single", coordinatesCoarsened=None, crs="EPSG:32736")
    r = run(df, meta, taxa=taxa, traps=traps)
    assert "coordinates_sensitive" in checks_of(r, "warn")
    meta = good_meta(taxonInclusion="single", coordinatesCoarsened=None,
                     crs="local: metres, centred on the array")
    assert "coordinates_sensitive" not in checks_of(run(df, meta, taxa=taxa, traps=traps))
    snapped = traps.assign(x=515000.0, y=6125000.0)
    meta = good_meta(taxonInclusion="single", coordinatesCoarsened=None, crs="EPSG:32736")
    assert "coordinates_sensitive" not in checks_of(run(df, meta, taxa=taxa, traps=snapped))


def test_crossed_occasion_kind_and_recorded_taxa():
    for ok in (["method", "spatial"], ["time", "method"]):
        r = run(meta=good_meta(occasionKind=ok))
        assert "meta_vocab" not in checks_of(r) and "meta_conditional" not in checks_of(r), ok
    for bad in (["method"], ["method", "method"], ["time", "none"], ["a", "b"], ["time", "method", "spatial"]):
        assert "meta_vocab" in checks_of(run(meta=good_meta(occasionKind=bad)), "error"), bad
    one = good_frame()[good_frame()["occasion"] == 1].drop(columns="occasion")
    assert "meta_conditional" in checks_of(run(one, good_meta(occasionKind=["time", "method"], closure="none")), "error")
    # recorded: every taxon has a detection
    df = good_frame(); df.loc[df["taxon"] == "BBB", "y"] = 0
    assert "meta_conditional" in checks_of(run(df), "error")
    assert "meta_conditional" not in checks_of(run(df, good_meta(taxonInclusion="target")))


# ---------------------------------------------------------------------------
# Tables stored as period parts (standard E4)
# ---------------------------------------------------------------------------

def _parted_frame():
    rows = []
    for per in (1, 2, 3, 4):
        for u in range(1, 41):
            for tx in ("AAA", "BBB"):
                rows.append({"unit": f"u{u}", "taxon": tx, "y": int((u + per) % 3 == 0),
                             "period": per, "occasion": 1})
    return pd.DataFrame(rows)


def write_parted(tmp_path, df=None, groups=((1, 2), (3, 4)), meta=None, manifest=True):
    df = _parted_frame() if df is None else df
    name = "smith_2020_place_count"
    d = tmp_path / f"{name}.parts"
    d.mkdir()
    parts = []
    for k, g in enumerate(groups, 1):
        sub = df[df["period"].isin(g)]
        fn = f"part-{k:02d}.csv"
        sub.to_csv(d / fn, index=False)
        parts.append({"file": fn, "periods": list(g), "n_rows": len(sub)})
    m = meta or good_meta(closure="open", responseType="detection")
    if manifest:
        m["parts"] = parts
    (tmp_path / f"{name}__dataset.json").write_text(json.dumps(m))
    good_taxa().to_csv(tmp_path / f"{name}__taxa.csv", index=False)
    pd.DataFrame({"period": [1, 2, 3, 4]}).to_csv(tmp_path / f"{name}__periods.csv", index=False)
    return d


def test_parted_table_passes_and_counts_the_union(tmp_path):
    d = write_parted(tmp_path)
    r = validate_file(d)
    assert r.ok and r.conforms, [f"{f.check}: {f.message}" for f in r.findings]
    assert r.stats["n_rows"] == len(_parted_frame()) and r.stats["n_periods"] == 4
    # the CLI finds the directory, and `<name>.csv` resolves to it
    assert main([str(tmp_path)]) == 0
    assert main([str(d)]) == 0                # the directory named itself is one table
    assert validate_file(tmp_path / "smith_2020_place_count.csv").ok


def test_parted_table_whole_table_checks(tmp_path):
    df = _parted_frame()
    # a taxon recorded only in one part is recorded in the table: no finding
    df.loc[df["taxon"] == "BBB", "y"] = 0
    df.loc[(df["taxon"] == "BBB") & (df["period"] == 4) & (df["unit"] == "u1"), "y"] = 1
    (tmp_path / "a").mkdir(); (tmp_path / "b").mkdir()
    assert validate_file(write_parted(tmp_path / "a", df)).ok
    # never recorded anywhere: an error only the union can see
    df.loc[df["taxon"] == "BBB", "y"] = 0
    r = validate_file(write_parted(tmp_path / "b", df))
    assert "meta_conditional" in checks_of(r, "error")


def test_parted_table_structure_errors(tmp_path):
    for sub, kw in (("overlap", {"groups": ((1, 2), (2, 3, 4))}),
                    ("nomanifest", {"manifest": False})):
        (tmp_path / sub).mkdir()
        r = validate_file(write_parted(tmp_path / sub, **kw))
        assert "table_parts" in checks_of(r, "error"), sub
    # a part missing a taxon breaks E4.2 across parts
    (tmp_path / "short").mkdir()
    df = _parted_frame()
    df = df[~((df["taxon"] == "BBB") & df["period"].isin([3, 4]))]
    r = validate_file(write_parted(tmp_path / "short", df))
    assert "explicit_zero_taxa" in checks_of(r, "error")
    # a unit covariate that differs between parts
    (tmp_path / "cov").mkdir()
    df = _parted_frame(); df["unit_elev"] = 1.0
    df.loc[df["period"] == 4, "unit_elev"] = 2.0
    r = validate_file(write_parted(tmp_path / "cov", df))
    assert "covariate_level" in checks_of(r, "error")
