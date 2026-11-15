import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import manifest  # noqa: E402


def r(tag, ts, n):
    return {"tag": tag, "released_at": ts, "n_tables": n}


def test_shards_released_together_are_one_eco_version():
    ev = manifest.core_events({
        "eco_redivis_version": [r("v1.0", "2026-11-01T00:00:00Z", 10), r("v1.1", "2026-11-02T00:00:00Z", 20)],
        "eco_2_redivis_version": [r("v1.0", "2026-11-02T00:02:00Z", 5), r("v1.1", "2026-11-03T00:00:00Z", 7)],
    })
    assert [e["tags"] for e in ev] == [
        {"eco_redivis_version": "v1.0", "eco_2_redivis_version": ""},
        {"eco_redivis_version": "v1.1", "eco_2_redivis_version": "v1.0"},
        {"eco_redivis_version": "v1.1", "eco_2_redivis_version": "v1.1"},   # eco_2 alone is a version too
    ]
    assert [e["n_tables"] for e in ev] == [10, 25, 27]
    assert ev[1]["released_at"] == "2026-11-02T00:00:00Z"


def test_build_pairs_eco_meta_and_keeps_columns():
    ev = manifest.core_events({c: [] for c in manifest.CORE_COLUMNS}      # every registered shard, as main() passes
                              | {"eco_redivis_version": [r("v1.0", "2026-11-01T00:00:00Z", 10)]})
    rows = manifest.build(ev, [r("v1.0", "2026-11-01T01:00:00Z", 3)])
    assert rows[0]["eco_meta_redivis_version"] == "v1.0"
    assert rows[0]["eco_2_redivis_version"] == ""
    assert set(rows[0]) == set(manifest.COLUMNS)


def _fake_redivis(monkeypatch, versions, counts):
    """versions: {dataset name: [(tag, released_at)]}; counts: {(name, tag): n}. Records what was counted."""
    counted = []

    def released(d, count_after=""):
        out = []
        for tag, ts in versions.get(d.name, []):
            n = None
            if count_after is not None and ts > count_after:
                counted.append((d.name, tag)); n = counts[(d.name, tag)]
            out.append({"tag": tag, "released_at": ts, "n_tables": n})
        return out

    def count(d, tag):
        counted.append((d.name, tag)); return counts[(d.name, tag)]

    monkeypatch.setattr(manifest, "released_versions", released)
    monkeypatch.setattr(manifest, "count_tables", count)
    return counted


def _row(v, date, tags, meta, n, note=""):
    row = {c: "" for c in manifest.COLUMNS}
    row.update({"eco_version": str(v), "date": date, **tags, "eco_meta_redivis_version": meta,
                "n_tables": str(n), "note": note})
    return row


def test_incremental_appends_counting_only_new_releases(monkeypatch):
    old = "2026-11-01T00:00:00Z"
    existing = [_row(1, "2026-10-01T00:00:00Z", {"eco_redivis_version": "v0.9"}, "v0.9", 5, "first"),
                _row(2, old, {"eco_redivis_version": "v1.0"}, "v1.0", 10, "second")]
    counted = _fake_redivis(monkeypatch,
        {"eco": [("v0.9", "2026-10-01T00:00:00Z"), ("v1.0", old)],
         "eco_2": [("v1.0", "2026-11-02T00:00:00Z")],
         "eco_meta": [("v0.9", "2026-10-01T01:00:00Z"), ("v1.0", "2026-11-01T01:00:00Z"), ("v1.1", "2026-11-02T01:00:00Z")]},
        {("eco", "v1.0"): 10, ("eco_2", "v1.0"): 4})
    rows, why = manifest.incremental(existing)
    assert why is None
    assert ("eco", "v0.9") not in counted                      # the history is not re-listed
    assert rows[:2] == existing                                 # earlier rows and notes kept as written
    assert rows[2]["eco_version"] == "3" and rows[2]["eco_2_redivis_version"] == "v1.0"
    assert rows[2]["eco_redivis_version"] == "v1.0" and rows[2]["n_tables"] == "14"
    assert rows[2]["eco_meta_redivis_version"] == "v1.1"


def test_incremental_nothing_new_counts_nothing_and_refreshes_meta(monkeypatch):
    existing = [_row(1, "2026-11-01T00:00:00Z", {"eco_redivis_version": "v1.0"}, "v1.0", 10)]
    counted = _fake_redivis(monkeypatch,
        {"eco": [("v1.0", "2026-11-01T00:00:00Z")],
         "eco_meta": [("v1.0", "2026-11-01T00:30:00Z"), ("v1.1", "2026-11-01T02:00:00Z")]}, {})
    rows, why = manifest.incremental(existing)
    assert why is None and counted == []
    assert len(rows) == 1 and rows[0]["eco_meta_redivis_version"] == "v1.1" and rows[0]["n_tables"] == "10"


def test_incremental_refuses_when_last_row_disagrees(monkeypatch):
    existing = [_row(1, "2026-11-01T00:00:00Z", {"eco_redivis_version": "v1.0"}, "v1.0", 10)]
    _fake_redivis(monkeypatch, {"eco": [("v1.1", "2026-11-01T00:00:00Z")], "eco_meta": []}, {})
    rows, why = manifest.incremental(existing)
    assert rows == [] and "--full" in why
