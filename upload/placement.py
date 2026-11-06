"""Which core shard each table in an upload goes to. Pure: no Redivis calls.

The uploader lists every shard (draft if one is open, else the latest release)
and hands the names here. The rules are in `redivis_config.py`; in short, a
table already on Redivis is updated where it lives, a new one goes to the
default shard (or `--dataset`), a side table goes wherever its core goes, and no
shard may pass the table cap.
"""
from __future__ import annotations

from dataclasses import dataclass, field


def base_of(table: str) -> str:
    """The core table a name belongs to: `foo__taxa` -> `foo`. Core names never contain `__`."""
    return table.split("__", 1)[0]


@dataclass
class Placement:
    home: dict[str, str] = field(default_factory=dict)      # table -> shard name
    errors: dict[str, str] = field(default_factory=dict)    # table -> why it cannot be placed
    new: dict[str, list[str]] = field(default_factory=dict)  # shard -> tables it would gain
    over_cap: dict[str, int] = field(default_factory=dict)  # shard -> tables after this upload, if > cap
    over_warn: dict[str, int] = field(default_factory=dict)  # shard -> tables after, if > warn (and <= cap)


def place(tables: list[str], listing: dict[str, set[str]], default: str,
          forced: str | None = None, cap: int = 1000, warn: int = 950) -> Placement:
    """Place `tables` (core and side table names) into shards.

    `listing` maps each shard name, oldest first, to the table names it holds.
    `forced` is an explicit `--dataset`: it decides where NEW tables go and is
    an error for a table that already lives in a different shard.
    """
    out = Placement()
    holders: dict[str, list[str]] = {}
    for t in tables:
        b = base_of(t)
        if b not in holders:
            holders[b] = [s for s, names in listing.items()
                          if any(n == b or n.startswith(b + "__") for n in names)]
        h = holders[b]
        if len(h) > 1:
            out.errors[t] = (f"`{b}` is already in more than one shard ({', '.join(h)}); "
                             "readers would see only the newest copy. Withdraw one by hand first.")
        elif len(h) == 1:
            if forced and forced != h[0]:
                out.errors[t] = (f"`{b}` already lives in {h[0]}; an existing table is updated in "
                                 f"the shard that holds it, so --dataset {forced} does not apply")
            else:
                out.home[t] = h[0]
        else:
            out.home[t] = forced or default
    for t, s in out.home.items():
        if t not in listing.get(s, set()):
            out.new.setdefault(s, []).append(t)
    for s, gained in out.new.items():
        total = len(listing.get(s, set())) + len(gained)
        if total > cap:
            out.over_cap[s] = total
        elif total > warn:
            out.over_warn[s] = total
    return out
