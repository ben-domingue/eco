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
    ev = manifest.core_events({"eco_redivis_version": [r("v1.0", "2026-11-01T00:00:00Z", 10)],
                               "eco_2_redivis_version": []})
    rows = manifest.build(ev, [r("v1.0", "2026-11-01T01:00:00Z", 3)])
    assert rows[0]["eco_meta_redivis_version"] == "v1.0"
    assert rows[0]["eco_2_redivis_version"] == ""
    assert set(rows[0]) == set(manifest.COLUMNS)
