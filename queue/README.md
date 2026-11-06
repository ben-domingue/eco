# queue/

`candidates.csv` is the list collaborators consult before converting a deposit,
so two people do not build the same table. It was seeded from the discovery
pass (`../discovery_log.csv`: inspected deposits with recoverable non-detections
and conversion difficulty 1-4). Columns: `status`, `claimed_by`, plus the
deposit's source, DOI/URL, licence, data type, difficulty and notes.

`status` starts with one of these words; anything after a colon is the reason:

| `status` | Meaning |
|---|---|
| `available` | inspected and ready to build (`available: <caveat>` when something is still unverified) |
| `needs-look` | found by discovery, not yet opened |
| `claimed` | someone is building it (rarely set: the open issue is the claim) |
| `built: <table>` | built; several tables from one deposit are separated by `;` |
| `held: <reason>`, `blocked: <reason>`, `deferred: <reason>`, `not built: <reason>` | not buildable now, with the reason (often a row in `human_review.csv`) |
| `rejected <date>; <reason>` | out of scope or not eligible; kept so the deposit is not triaged again (its row in `human_review.csv` gives the ruling) |

To claim one: open a data-queue issue on `ben-domingue/eco` with the issue form
(it applies the `data queue` label), titled with the table name you intend to use
(`author_year_place_type`). The open issue is the claim; a maintainer may also
note it in `claimed_by`. In the pull request that adds your `data/` script, set
`status = built: <table>` and `claimed_by` to your name. When that pull request
merges, the script,
its `output/<table>__dataset.json`, and its dictionary, tags and metadata rows are
in `main`; the table CSVs are not tracked (#92) and go to Redivis. Add new
candidates at the bottom with `status = available` (or `needs-look` if you have not
opened the files).

## Excluded authors

We do not build deposits that list these people as authors, whatever the licence.
Discovery may still log such a deposit, but triage marks it
`rejected <date>; excluded author (<name>)` and adds a `rejected` row to `human_review.csv`.

| Author | Since | Why |
|---|---|---|
| Morgan W. Tingley | 2026-11-06 | asked us not to use their group's data (`dryad.fxpnvx0qj`) |

## Decision: the CSV stays the index, one issue per claim

Issue #17 asked whether to turn the queue into GitHub issues, as IRW does, or keep
the CSV. **Keep `candidates.csv` as the index of every candidate, and open one
issue only when someone claims a deposit** (the protocol above). This keeps the
existing model; the one change is that the pull request sets `built: <table>`
directly instead of first `claimed` and then `built` after it lands, because the
second step needed a follow-up commit and the open issue already shows the claim.

Reasons:

- **Size.** On 2026-11-05 the queue had 627 rows: 188 `available`, 190
  `needs-look`, 163 built and 86 held or blocked. One issue per row would put several hundred
  issues in a tracker that currently has one `data queue` issue, and would bury
  the issues about the standard and the tools.
- **Most rows are never claimed by a person.** Agents build batches straight from
  the CSV (`.claude/skills/eco-convert-deposit/SKILL.md`, step 0), and the
  discovery pass appends rows to it. A file is easier for both to read, filter and
  update than the issue API.
- **The status carries the reason.** `held: <reason>` and `blocked: <reason>` rows
  link to `human_review.csv` and stop the same deposit from being re-triaged. In
  issues, that history would sit in closed threads.
- **The site reads it.** `site/contribute.qmd` renders the queue table and its
  counts from this file.
- **A status change ships with the table.** The row moves to `built: <table>` in
  the same pull request as the script, so the queue cannot say a table exists
  before it does.

What the issue adds is the part a CSV does badly: a visible claim, a place for a
maintainer to answer questions before the work is done, and a link from the pull
request. That is why there is one issue per claim rather than none.

Reasons to revisit: if outside contributors start claiming deposits faster than
pull requests land, and two people collide on the same row, a claim needs to show
up in `main` sooner than the PR does.

`human_review.csv` is the IRW-style record of inspected deposits (or parts of
deposits) that were held, rejected or need a human ruling, with the reason, so
they are not re-triaged. Columns: `candidate`, `source`, `doi_or_url`, `decision`
(`held`, `blocked`, `rejected`, `needs-human`; `available` when a ruling lifts a hold
and the deposit can be built, `resolved` once it is), `reason` (appended to, never
overwritten), `date`, `reviewer`. A rejected deposit's `candidates.csv` row is
`not built: <reason>`.
