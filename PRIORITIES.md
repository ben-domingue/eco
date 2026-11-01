# What to work on

Adapted 2026-11-01 from `ben-domingue/irw`'s `src/PRIORITIES.md`. Advisory: Ben
overrules it, and a direct request always wins. It exists so a session can place a
new piece of work without asking, and it ranks *kinds* of work, not issues, so it
stays right after every issue number in it is closed.

The order is IRW's (trust, gates, reach, volume) with one change: at a few dozen
tables, **volume ranks with reach, not below it**. IRW has 8,600 tables and its
problem is coverage of what it already holds; eco's problem is that a warehouse of
twenty tables is a demonstration, not a resource. The dependency sketch in issue
#19 is the ordering within a phase.

## The order

**1. Corpus trust: the warehouse is serving something wrong.**

Outranks everything. The question is not "is this broken" but "is a user getting a
wrong answer right now": a table whose zeros mean "not surveyed", a `y` that is a
model estimate, a licence that does not permit redistribution, a sensitive taxon
with exact coordinates, a `do_not_publish` table in the released version. Wrong is
worse than incomplete at any size. The label is `wrong-now`; open it first, even
when it is empty.

**2. Gates: stop the class, not the instance.**

Work that prevents a defect recurring beats work that fixes one occurrence of it.
The validator (#3, done), CI running it on every change (#4), the metadata pipeline
whose outputs the site and packages read (#5), and the release ledger (#6). The
test: if you fix the instance and nothing changes about how the next one is caught,
it was category 1 work.

**3. Reach and volume, together.**

*Reach* is anyone being able to use the tables without a Redivis login or a tour of
the repo: the R package over the public CSV endpoint (#7), the browser validator
(#8), agent-facing docs (#9), the contribution path (#17), citations (#11), the
`llms.txt` briefing (#12), vignettes (#14).

*Volume* is the next tables from the queue (#10), with licence verification and a
human-review log, running continuously. Volume means **new tables**, not polishing
existing ones; corrections to shipped tables are worth making insofar as they fall
out of a gate, and a wrong table still beats a missing one (category 1).

Why together: a package with six tables teaches nothing, and sixty tables nobody
can fetch are a Redivis folder. Alternate. A session that has just shipped a batch
should look at the reach list before starting the next batch.

**4. Later: when the corpus is large enough to need them.**

Per-table landing pages with JSON-LD and EML export (#13), the collections registry
(#15), the Python package (#16). Say "not yet" rather than quietly starting.

**5. Not borrowed from IRW, deliberately.**

Item text and its rights register (the `__taxa` side table is the whole of it), the
retroactive corpus audit, Google Sheets as a human entry surface (eco keeps tracked
CSVs), dataset sharding, the MCP server, the Stata package, the course, and data
families beyond detection / count / capture history (E9). Do not start these
unprompted.

## Which deposit to build next

A different question. Within volume, prefer, in order: a design or response type
the corpus does not yet have (check `design_landscape.md`'s "Built or
round-tripped?" column), a large well-structured deposit with a deposited survey or
effort table (so `surveyEvidence` is not `inferred`), an open licence that needs no
email, taxa GBIF resolves. A small messy deposit with an ambiguous licence can wait;
the goal is to maximise usable data, not to empty `queue/candidates.csv`.

## What the ranking assumes

| | |
|---|---|
| Scale | tens of tables, growing by batches of five or six |
| Labour | Claude Code sessions plus Ben; no hired engineer, so nothing needing a hosted backend |
| Lenses | corpus trust, then a usable resource for ecologists and for the IRT-meets-ecology question |

If the corpus reaches hundreds of tables, re-rank: volume drops back below reach,
and categories 4 and 5 get revisited.

## Where the detail lives

- The numbered issues and their rulings: `ben-domingue/eco#1` to `#19`, overview `#19`.
- Labels: `wrong-now`, `p1-trust`, `p1-standard`, `p2-gates`, `p3-reach`, `p4-volume`, `p4-later`, `borrow-from-irw`, `data queue`.
- The IRW originals this borrows from: `~/Dropbox/projects/irw/src/PRIORITIES.md` and `ARCHITECTURE.md`.
- Which document wins when two disagree: `ARCHITECTURE.md` §4.
