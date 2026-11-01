# tools/withdrawals/

Removing a table that has already shipped. `withdraw_table.py` deletes a core
table and its side tables from the Redivis **draft** (dry run by default,
`APPLY=1` applies), so they leave at the next release, and `ledger.py` appends one
row per table to `releases/withdrawals.csv`, the record keyed by table name. A
withdrawal that needs its own explanation is a copy of `withdraw_table.py` named
`withdraw_<what>.py` with an explicit target list; it stays here after it has run,
because the ledger row cites it by path.

Released Redivis versions are immutable, so a withdrawal is never retroactive: the
table remains in the version it shipped in, and the public record of its removal
is the `withdrawal` row in `releases/table_changes.csv`, added when the release is
live. See `releases/README.md` and `upload/README.md`.
