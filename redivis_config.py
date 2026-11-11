"""Where eco lives on Redivis: the owner, the core shards, and eco_meta.

This file is authoritative for the dataset names and reference ids on the
Python side (uploader, manifest, validate_redivis, withdrawals). The R package
carries the same lists in `Rpkg/R/config.R`; `tools/check_config_parity.py`
compares the two in CI, so adding a shard is one edit in each file.

**Why shards.** Redivis caps a dataset at 1000 tables, and a core table with its
side tables is two to five of them. As IRW does (`item_response_warehouse`,
`_2`, ...), eco adds a dataset with the same structure when the newest one nears
the cap. The rules (IRW's, except that eco fills a shard before moving on):

  * A core table and its side tables always live in the same shard.
  * Shards fill oldest first: a new table goes to the oldest shard holding
    fewer than SWITCH_AT tables (counting its draft), so eco takes new tables
    until it reaches about 950 and eco_2 after that (Ben, 2026-11-05). Setting
    CORE_DEFAULT overrides this. An existing table is updated in the shard that
    already holds it.
    Tables are never moved between shards: a copy in a second shard shadows
    the first, which is the problem moving was meant to solve.
  * Readers search the shards newest-first and take the first match; the
    uploader refuses to create a name that already exists in another shard,
    so in practice there is never a second match.
  * No upload may take a shard past TABLE_CAP tables, counting its draft; above
    TABLE_WARN the uploader says the next shard is due.

Adding a shard: Ben creates the dataset on Redivis (public access "data", like
`eco`), then append it to CORE_SHARDS here and to `.eco_cores` in
`Rpkg/R/config.R`, and run `python3 tools/check_config_parity.py`. The release
manifest grows a `<name>_redivis_version` column by itself on its next run.
"""
from __future__ import annotations

from dataclasses import dataclass

OWNER = "datapages"


@dataclass(frozen=True)
class Dataset:
    name: str   # the Redivis dataset name
    ref: str    # the reference id, which survives a rename

    @property
    def qualified(self) -> str:
        """`name:ref`, the form that keeps working if the dataset is renamed."""
        return f"{self.name}:{self.ref}"

    @property
    def manifest_column(self) -> str:
        """This dataset's column in releases/manifest.csv."""
        return f"{self.name}_redivis_version"


#: Core shards, oldest first. Each holds core tables and their side tables.
CORE_SHARDS: tuple[Dataset, ...] = (
    Dataset("eco", "4j5q"),
    Dataset("eco_2", "3fnj"),     # created by Ben 2026-11-05, with eco near 700 tables
)

#: The pipeline's own tables (metadata, biblio, tags). Not a shard.
META = Dataset("eco_meta", "241c")

#: Where NEW core tables go, overriding the fill rule while set (a shard
#: name). None: the oldest shard under SWITCH_AT.
CORE_DEFAULT: str | None = "eco_2"   # eco reached 951 tables and was published 2026-11-11 (Ben): it takes no new tables

TABLE_CAP = 1000        # Redivis' limit; an upload past it is refused
SWITCH_AT = 950         # a shard at or above this takes no new tables
TABLE_WARN = 950        # the uploader warns when an upload leaves a shard above this


def shard(name: str) -> Dataset:
    for d in CORE_SHARDS:
        if d.name == name:
            return d
    raise KeyError(f"{name!r} is not a core shard; redivis_config.CORE_SHARDS lists "
                   + ", ".join(d.name for d in CORE_SHARDS))


def default_shard(counts: dict[str, int] | None = None) -> Dataset:
    """The shard new core tables go to, given each shard's table count now.

    Without counts (no Redivis access) this cannot apply the fill rule and
    answers the newest shard; the uploader always passes them."""
    if CORE_DEFAULT:
        return shard(CORE_DEFAULT)
    if counts is None:
        return CORE_SHARDS[-1]
    for d in CORE_SHARDS:
        if counts.get(d.name, 0) < SWITCH_AT:
            return d
    return CORE_SHARDS[-1]      # every shard full: the cap check will refuse; add a shard
