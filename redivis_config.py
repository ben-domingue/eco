"""Where eco lives on Redivis: the owner, the core shards, and eco_meta.

This file is authoritative for the dataset names and reference ids on the
Python side (uploader, manifest, validate_redivis, withdrawals). The R package
carries the same lists in `Rpkg/R/config.R`; `tools/check_config_parity.py`
compares the two in CI, so adding a shard is one edit in each file.

**Why shards.** Redivis caps a dataset at 1000 tables, and a core table with its
side tables is two to five of them. As IRW does (`item_response_warehouse`,
`_2`, ...), eco adds a dataset with the same structure when the newest one nears
the cap. The rules, also IRW's:

  * A core table and its side tables always live in the same shard.
  * A new table goes to `CORE_DEFAULT` when that is set, else to the newest
    shard. An existing table is updated in the shard that already holds it.
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

#: Where NEW core tables go, overriding "the newest shard" while set (a shard
#: name). None: the newest shard.
CORE_DEFAULT: str | None = None

TABLE_CAP = 1000
TABLE_WARN = 950


def shard(name: str) -> Dataset:
    for d in CORE_SHARDS:
        if d.name == name:
            return d
    raise KeyError(f"{name!r} is not a core shard; redivis_config.CORE_SHARDS lists "
                   + ", ".join(d.name for d in CORE_SHARDS))


def default_shard() -> Dataset:
    """The shard new core tables go to."""
    return shard(CORE_DEFAULT) if CORE_DEFAULT else CORE_SHARDS[-1]
