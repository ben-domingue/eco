import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "upload"))
sys.path.insert(0, str(ROOT))

from placement import place  # noqa: E402
import redivis_config as rc  # noqa: E402

LISTING = {"eco": {"a", "a__taxa", "b", "b__taxa"}, "eco_2": {"c", "c__taxa"}}


def test_new_tables_go_to_the_default_with_their_side_tables():
    p = place(["d", "d__taxa", "d__periods"], LISTING, default="eco_2")
    assert p.home == {"d": "eco_2", "d__taxa": "eco_2", "d__periods": "eco_2"}
    assert sorted(p.new["eco_2"]) == ["d", "d__periods", "d__taxa"]
    assert not p.errors


def test_existing_tables_are_updated_where_they_live():
    p = place(["a", "a__taxa", "c"], LISTING, default="eco_2")
    assert p.home == {"a": "eco", "a__taxa": "eco", "c": "eco_2"}
    assert p.new == {}


def test_a_new_side_table_follows_its_core():
    p = place(["a__periods"], LISTING, default="eco_2")
    assert p.home == {"a__periods": "eco"}
    assert p.new == {"eco": ["a__periods"]}


def test_forced_dataset_places_new_tables_but_never_moves_one():
    p = place(["d", "a"], LISTING, default="eco_2", forced="eco")
    assert p.home == {"d": "eco", "a": "eco"} and not p.errors
    p = place(["c"], LISTING, default="eco_2", forced="eco")
    assert "already lives in eco_2" in p.errors["c"]


def test_a_name_in_two_shards_is_refused():
    p = place(["x"], {"eco": {"x"}, "eco_2": {"x__taxa"}}, default="eco_2")
    assert "more than one shard" in p.errors["x"]


def test_prefix_names_do_not_collide():
    # `ab` is not a side table of `a`
    p = place(["a"], {"eco": {"ab"}, "eco_2": set()}, default="eco_2")
    assert p.home == {"a": "eco_2"}


def test_cap_and_warning_count_existing_tables():
    listing = {"eco": {f"t{i}" for i in range(998)}, "eco_2": set()}
    p = place(["n1", "n1__taxa", "n2"], listing, default="eco", cap=1000, warn=950)
    assert p.over_cap == {"eco": 1001}
    p = place(["n1"], listing, default="eco", cap=1000, warn=950)
    assert p.over_warn == {"eco": 999} and not p.over_cap
    assert not place(["t1"], listing, default="eco").over_cap   # an update adds nothing


def test_registry():
    assert [d.name for d in rc.CORE_SHARDS][:2] == ["eco", "eco_2"]
    if not rc.CORE_DEFAULT:
        assert rc.default_shard({"eco": 690, "eco_2": 0}).name == "eco"
        assert rc.default_shard({"eco": rc.SWITCH_AT, "eco_2": 0}).name == "eco_2"
        assert rc.default_shard({"eco": 999, "eco_2": 999}).name == rc.CORE_SHARDS[-1].name
    assert rc.shard("eco").qualified == "eco:4j5q"
    assert rc.shard("eco_2").manifest_column == "eco_2_redivis_version"
    assert len({d.name for d in rc.CORE_SHARDS}) == len(rc.CORE_SHARDS)
    assert len({d.ref for d in rc.CORE_SHARDS} | {rc.META.ref}) == len(rc.CORE_SHARDS) + 1
